export interface CountryEntity {
    name: string;
    code: string;
    codeIso3: string;
    createdAt: Date;
    updatedAt?: Date | null;
}
