import {
    registerDecorator,
    ValidationArguments,
    ValidationOptions,
} from 'class-validator';
import { Gender } from '../enums/master.enum';

export function IsValidGender(validationOptions?: ValidationOptions) {
    return function (object: Object, propertyName: string) {
        registerDecorator({
            name: 'isValidGender',
            target: object.constructor,
            propertyName,
            options: validationOptions,
            validator: {
                validate(value: any) {
                    if (value === null || value === undefined) return true;
                    return Object.values(Gender).includes(value);
                },
                defaultMessage(args: ValidationArguments) {
                    return `Invalid gender. Allowed types are ${Object.values(Gender).join(', ')}`;
                },
            },
        });
    };
}
