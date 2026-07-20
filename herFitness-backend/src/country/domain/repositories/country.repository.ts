import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { Prisma } from 'prisma/generated/prisma/client';
import { CountryEntity } from '../entities/country.entity';

@Injectable()
export class CountryRepository {

    constructor(private readonly prisma: PrismaService) { }

    private getSelectPattern(): Prisma.CountrySelect {
        return {
            name: true,
            code: true,
            codeIso3: true,
            createdAt: true,
            updatedAt: true,
        }
    }

    /**
     * Finds all countries in the database
     * @returns An array of CountryEntity objects
     */
    async findAll(): Promise<CountryEntity[] | null> {
        const countries = await this.prisma.country.findMany({
            select: this.getSelectPattern()
        });
        return countries.map((country) => this.mapToEntity(country));
    }

    /**
     * Finds a country by its ISO 3 code
     * @param codeIso3 The ISO 3 code of the country to find
     * @returns The CountryEntity object if found, null otherwise
     */
    async findByCodeIso3(codeIso3: string): Promise<CountryEntity | null> {
        const country = await this.prisma.country.findUnique({
            where: {
                codeIso3,
            },
            select: this.getSelectPattern()
        });
        return country ? this.mapToEntity(country) : null;
    }

    /**
     * Finds a country by its ISO 2 code
     * @param code The ISO 2 code of the country to find
     * @returns The CountryEntity object if found, null otherwise
     */
    async findByCode(code: string): Promise<CountryEntity | null> {
        const country = await this.prisma.country.findUnique({
            where: {
                code,
            },
            select: this.getSelectPattern()
        });
        return country ? this.mapToEntity(country) : null;
    }

    /**
     * Maps a Prisma Country to a CountryEntity
     * @param country The Prisma Country to map
     * @returns The mapped CountryEntity
     */
    mapToEntity(country: Prisma.CountryGetPayload<{
        select: {
            name: true;
            code: true;
            codeIso3: true;
            createdAt: true;
            updatedAt: true;
        }
    }>): CountryEntity {
        return {
            name: country.name,
            code: country.code,
            codeIso3: country.codeIso3,
            createdAt: country.createdAt,
            updatedAt: country.updatedAt,
        };
    }

}
