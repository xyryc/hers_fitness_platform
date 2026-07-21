import { Expose } from "class-transformer";

export class CountryResponseDto {

    @Expose()
    name: string;

    @Expose()
    code: string;

    @Expose()
    codeIso3: string;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt?: Date | null;

    constructor(partial: Partial<CountryResponseDto>) {
        Object.assign(this, partial);
    }
}