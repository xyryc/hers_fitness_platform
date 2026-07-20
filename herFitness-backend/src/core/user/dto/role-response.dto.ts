import { Expose } from 'class-transformer';

export class RoleResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string;

    @Expose()
    description?: string | null;

    constructor(partial: Partial<RoleResponseDto>) {
        Object.assign(this, partial);
    }
}