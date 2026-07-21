import { Injectable } from '@nestjs/common';
import { CountryRepository } from './domain/repositories/country.repository';
import { PrismaService } from 'src/database/prisma.service';
import { CountryResponseDto } from './dto/country.response.dto';

@Injectable()
export class CountryService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly countryRepository: CountryRepository
    ) { }

    /**
     * Finds all countries in the database
     * @returns An array of CountryResponseDto objects
     */
    async findAll(): Promise<CountryResponseDto[] | null> {
        const countries = await this.countryRepository.findAll();
        if (!countries) return null;
        return countries.map((country) => new CountryResponseDto(country));
    }

    /**
     * Finds a country by its ISO 3 code
     * @param codeIso3 The ISO 3 code of the country to find
     * @returns The CountryResponseDto object if found, null otherwise
     */
    async findByCodeIso3(codeIso3: string): Promise<CountryResponseDto | null> {
        const country = await this.countryRepository.findByCodeIso3(codeIso3);
        if (!country) return null;
        return new CountryResponseDto(country);
    }

    async findByCode(code: string): Promise<CountryResponseDto | null> {
        const country = await this.countryRepository.findByCode(code);
        if (!country) return null;
        return new CountryResponseDto(country);
    }
}
