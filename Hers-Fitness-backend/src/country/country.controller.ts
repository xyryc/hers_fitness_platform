import { Controller, Get, Param } from '@nestjs/common';
import { CountryService } from './country.service';
import { CountryResponseDto } from './dto/country.response.dto';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('8. System')
@Controller('countries')
export class CountryController {

    constructor(
        private readonly countryService: CountryService
    ) { }

    @Get()
    async findAll(): Promise<CountryResponseDto[] | null> {
        const countries = await this.countryService.findAll();
        return countries;
    }

    @Get('code-iso3/:codeIso3')
    async findByCodeIso3(@Param('codeIso3') codeIso3: string): Promise<CountryResponseDto | null> {

        const country = await this.countryService.findByCodeIso3(codeIso3);

        if (!country) {
            throw new NotFoundAppException('Country not found', 'COUNTRY_NOT_FOUND');
        }

        return country;
    }

    @Get('code/:code')
    async findByCode(@Param('code') code: string): Promise<CountryResponseDto | null> {
        const country = await this.countryService.findByCode(code);
        return country;
    }

}
