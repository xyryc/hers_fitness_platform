import {
    ConnectedSocket,
    MessageBody,
    OnGatewayConnection,
    OnGatewayDisconnect,
    SubscribeMessage,
    WebSocketGateway,
    WebSocketServer,
} from '@nestjs/websockets';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';
import { AppConfig } from 'src/config/app.config';
import { ChatService } from './chat.service';
import { SendChatMessageDto } from './dto/chat-message.dto';

type AuthenticatedSocket = Socket & {
    user?: {
        id: string;
        email?: string;
    };
};

@WebSocketGateway({
    namespace: 'chat',
    cors: {
        origin: '*',
    },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server!: Server;

    constructor(
        private readonly jwtService: JwtService,
        private readonly appConfig: AppConfig,
        private readonly chatService: ChatService,
    ) { }

    async handleConnection(client: AuthenticatedSocket) {
        try {
            const token = this.getToken(client);
            if (!token) {
                client.disconnect(true);
                return;
            }

            const payload = await this.jwtService.verifyAsync(token, {
                secret: this.appConfig.jwt.secret,
            });

            client.user = {
                id: payload.id,
                email: payload.email,
            };
        } catch (error) {
            client.disconnect(true);
            return;
        }

        // ── In-app active status ────────────────────────────────────────────
        // Join every conversation room the user belongs to and mark them ACTIVE
        // in the DB so that REST callers (e.g. fetchConversations) also see the
        // correct status. This implements "active while the app is open" rather
        // than "active only when a specific conversation screen is open".
        //
        // We use Promise.allSettled so a single failing conversation (e.g.
        // a deleted record) never boots the user from the socket.
        try {
            const conversationIds = await this.chatService.findConversationIds(client.user!.id);
            await Promise.allSettled(
                conversationIds.map(async (convId) => {
                    const room = this.getConversationRoom(convId);
                    await client.join(room);
                    const updated = await this.chatService.updateActiveStatus(
                        client.user!.id,
                        convId,
                        true,
                    );
                    if (updated) {
                        // Notify the OTHER participant(s) in the room.
                        client.to(room).emit('chat:status', updated);
                    }
                }),
            );
        } catch {
            // Non-fatal: user is still connected; they just won't appear active
            // in the conversations list until the next join/reconnect.
        }
    }

    async handleDisconnect(client: AuthenticatedSocket) {
        if (!client.user?.id) return;

        // Collect all conversation rooms BEFORE any async work — the rooms Set
        // may be mutated once the socket is fully torn down.
        const conversationRooms = Array.from(client.rooms).filter((r) =>
            r.startsWith('conversation:'),
        );

        for (const room of conversationRooms) {
            const conversationId = room.replace('conversation:', '');
            try {
                // Update DB so REST callers (e.g. fetchConversations) see the correct
                // INACTIVE status even if they never receive the socket event.
                const conversation = await this.chatService.updateActiveStatus(
                    client.user.id,
                    conversationId,
                    false,
                );
                if (conversation) {
                    // Broadcast the full updated conversation so Flutter clients
                    // can update both the green dot and the "Active now" label.
                    this.server.to(room).emit('chat:status', conversation);
                }
            } catch {
                // The conversation may have been deleted or the user may not be a
                // recognised participant. Fall back to the lightweight event so the
                // other participant can still mark them as offline in the UI.
                this.server.to(room).emit('chat:userDisconnected', {
                    userId: client.user.id,
                });
            }
        }
    }

    @SubscribeMessage('chat:join')
    async joinConversation(
        @ConnectedSocket() client: AuthenticatedSocket,
        @MessageBody() body: { conversationId: string },
    ) {
        if (!client.user?.id) return { ok: false };

        await this.chatService.ensureConversationParticipant(client.user.id, body.conversationId);
        await client.join(this.getConversationRoom(body.conversationId));
        const conversation = await this.chatService.updateActiveStatus(client.user.id, body.conversationId, true);

        this.server.to(this.getConversationRoom(body.conversationId)).emit('chat:status', conversation);
        return { ok: true, conversation };
    }

    // chat:leave is intentionally removed.
    // Active status is now in-app: the user is ACTIVE for the entire time their
    // socket is connected (app open) and INACTIVE only when it disconnects (app
    // closed / backgrounded). Navigating away from a conversation screen no
    // longer triggers a status change.

    @SubscribeMessage('chat:sendMessage')
    async sendMessage(
        @ConnectedSocket() client: AuthenticatedSocket,
        @MessageBody() body: { conversationId: string } & SendChatMessageDto,
    ) {
        if (!client.user?.id) return { ok: false };

        const message = await this.chatService.sendMessage(client.user.id, body.conversationId, body);
        // Use client.to() so the sender does NOT receive their own echo.
        // this.server.to() includes the sender, which causes duplicate handling
        // on the sending device and can corrupt the pending→confirmed message flow.
        client.to(this.getConversationRoom(body.conversationId)).emit('chat:message', message);
        return { ok: true, message };
    }

    @SubscribeMessage('chat:typing')
    async typing(
        @ConnectedSocket() client: AuthenticatedSocket,
        @MessageBody() body: { conversationId: string; isTyping: boolean },
    ) {
        if (!client.user?.id) return { ok: false };

        await this.chatService.ensureConversationParticipant(client.user.id, body.conversationId);
        client.to(this.getConversationRoom(body.conversationId)).emit('chat:typing', {
            conversationId: body.conversationId,
            userId: client.user.id,
            isTyping: body.isTyping,
        });

        return { ok: true };
    }

    @SubscribeMessage('chat:seen')
    async seen(
        @ConnectedSocket() client: AuthenticatedSocket,
        @MessageBody() body: { conversationId: string },
    ) {
        if (!client.user?.id) return { ok: false };

        const messages = await this.chatService.markSeen(client.user.id, body.conversationId);
        const seenAt = messages.length > 0 ? messages[0].seenAt : new Date();
        // Broadcast to the OTHER participant only (not the viewer who triggered seen).
        // Also include a top-level seenAt so the Flutter client can read it directly
        // without having to dig into the messages array.
        client.to(this.getConversationRoom(body.conversationId)).emit('chat:seen', {
            conversationId: body.conversationId,
            seenByUserId: client.user.id,
            seenAt,
            messages,
        });

        return { ok: true };
    }

    /**
     * Called by ChatController after a REST image upload so the OTHER
     * participant receives the new message in real-time via socket.
     * We use server.to(room) here (not client.to) because this is invoked
     * from the HTTP controller, not from within a socket handler — there is
     * no "client" socket to exclude, and the sender already received the
     * message as the REST response.
     */
    broadcastNewMessage(conversationId: string, message: any): void {
        const room = this.getConversationRoom(conversationId);
        this.server.to(room).emit('chat:message', message);
    }

    private getConversationRoom(conversationId: string): string {
        return `conversation:${conversationId}`;
    }

    private getToken(client: Socket): string | null {
        const authToken = client.handshake.auth?.token;
        if (typeof authToken === 'string') return authToken.replace(/^Bearer\s+/i, '');

        const header = client.handshake.headers.authorization;
        if (typeof header === 'string') return header.replace(/^Bearer\s+/i, '');

        return null;
    }
}
