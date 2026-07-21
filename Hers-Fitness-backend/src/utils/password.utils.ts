import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

export default class PasswordUtils {
  /**
   * Asynchronously generates a bcrypt hash for the provided plain text password.
   *
   * @param password - The plain text password to hash.
   * @returns A promise that resolves to the hashed password string.
   */
  static async hashPassword(password: string): Promise<string> {
    const saltRounds = 10;
    return bcrypt.hash(password, saltRounds);
  }

  /**
   * Compares a plain text password with a hashed password to determine if they match.
   *
   * @param plainTextPassword - The plain text password to verify.
   * @param hashedPassword - The hashed password to compare against.
   * @returns A promise that resolves to `true` if the passwords match, or `false` otherwise.
   */
  static async comparePassword(plainTextPassword: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(plainTextPassword, hashedPassword);
  }

  /**
   * Validates if the provided password meets the criteria for a strong password.
   *
   * @param password - The password to validate.
   * @returns `true` if the password is strong, `false` otherwise.
   */
  static isStrongPassword(password: string): boolean {
    // A simple check for strong password criteria
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChars = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    const isLongEnough = password.length >= 8;

    return hasUpperCase && hasLowerCase && hasNumbers && hasSpecialChars && isLongEnough;
  }

  /**
   * Generates a random token of specified length.
   *
   * @param length - The length of the token to generate (default is 32).
   * @returns A string representing the generated token.
   */
  static generateRandomToken(length = 32): string {
    return randomBytes(length).toString('hex'); // returns a 64-character token
  }
}
