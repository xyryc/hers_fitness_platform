import crypto from 'crypto';

export default class Miscellaneous {
  /**
   * Utility function to create a valid filename.
   * Only allows A-Z, a-z, 0-9, and .
   * Ensures filename does not start or end with a period.
   * Optionally trims filename to a specified maximum length.
   *
   * @param filename - The original filename
   * @param maxLength - Optional maximum length of the filename
   * @returns - A sanitized filename
   */
  static createValidFilename(filename: string, maxLength?: number): string {
    // Replace any character that is not A-Z, a-z, 0-9, or . with an underscore
    let sanitizedFilename = filename.replace(/[^A-Za-z0-9.]/g, '_');

    // Ensure the filename does not start or end with a period
    sanitizedFilename = sanitizedFilename.replace(/^\.+|\.+$/g, '');

    // If maxLength is provided, trim the filename to the specified length
    if (maxLength && sanitizedFilename.length > maxLength) {
      sanitizedFilename = sanitizedFilename.substring(0, maxLength);
    }

    return sanitizedFilename.toLowerCase();
  }

  static convertDateToUTC(date: Date): Date {
    return new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds()));
  }

  static sanitize(str: string): string {
    return str.toLowerCase().replace(/[^a-z0-9]/g, '');
  }

  static generateSuffix(length = 4): string {
    return crypto.randomInt(Math.pow(10, length - 1), Math.pow(10, length)).toString();
  }
}
