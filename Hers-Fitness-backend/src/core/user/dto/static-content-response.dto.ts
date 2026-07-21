import { Expose } from 'class-transformer';

export class StaticContentResponseDto {
    @Expose() key!: string;
    @Expose() title!: string;
    @Expose() content!: string;
    @Expose() updatedAt!: Date | null;

    constructor(partial: Partial<StaticContentResponseDto>) {
        Object.assign(this, partial);
    }
}
