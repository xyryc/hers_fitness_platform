import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';
import { STATIC_CONTENT_KEYS, StaticContentKey } from '../../user/static-content.utils';

export { STATIC_CONTENT_KEYS };

export class UpsertStaticContentDto {
    @ApiProperty({ description: 'Page heading / title', example: 'Privacy Policy' })
    @IsString()
    @IsNotEmpty()
    title: string;

    @ApiProperty({ description: 'Full page body — plain text or HTML/markdown', example: '<h1>Privacy Policy</h1><p>...</p>' })
    @IsString()
    @IsNotEmpty()
    content: string;
}

export class AdminStaticContentResponseDto {
    key: StaticContentKey;
    title: string;
    content: string;
    createdAt: Date;
    updatedAt: Date | null;

    constructor(data: {
        key: string;
        title: string;
        content: string;
        createdAt: Date;
        updatedAt: Date | null;
    }) {
        this.key = data.key as StaticContentKey;
        this.title = data.title;
        this.content = data.content;
        this.createdAt = data.createdAt;
        this.updatedAt = data.updatedAt ?? null;
    }
}
