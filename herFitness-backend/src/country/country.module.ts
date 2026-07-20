import { Module } from '@nestjs/common';
import { CountryService } from './country.service';
import { CountryController } from './country.controller';
import { CountryRepository } from './domain/repositories/country.repository';

@Module({
  controllers: [CountryController],
  providers: [CountryService, CountryRepository],
  exports: [CountryService],
})
export class CountryModule { }
