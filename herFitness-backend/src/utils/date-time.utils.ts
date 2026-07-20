export class DateTimeUtils {
    static getDefaultTimeZone(): string {
        return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
    }

    static normalizeTimeZone(timeZone?: string | null): string {
        if (!timeZone) {
            return DateTimeUtils.getDefaultTimeZone();
        }

        try {
            new Intl.DateTimeFormat('en-US', { timeZone }).format(new Date());
            return timeZone;
        } catch {
            return DateTimeUtils.getDefaultTimeZone();
        }
    }

    static fromLocalDateTime(date: string, time: string, timeZone?: string | null): Date {
        const resolvedTimeZone = DateTimeUtils.normalizeTimeZone(timeZone);
        let utcDate = new Date(`${date}T${time}:00.000Z`);
        const [targetHour, targetMinute] = time.split(':').map(Number);

        for (let index = 0; index < 3; index += 1) {
            const parts = DateTimeUtils.getZonedParts(utcDate, resolvedTimeZone);
            if (parts.hour === targetHour && parts.minute === targetMinute) break;
            const zonedAsUtc = Date.UTC(
                parts.year,
                parts.month - 1,
                parts.day,
                parts.hour,
                parts.minute,
                parts.second,
            );
            const offset = zonedAsUtc - utcDate.getTime();
            utcDate = new Date(utcDate.getTime() - offset);
        }

        return utcDate;
    }

    static formatTime(date: Date, timeZone?: string | null): string {
        return new Intl.DateTimeFormat('en-GB', {
            timeZone: DateTimeUtils.normalizeTimeZone(timeZone),
            hour: '2-digit',
            minute: '2-digit',
            hour12: false,
        }).format(date);
    }

    private static getZonedParts(date: Date, timeZone: string): {
        year: number;
        month: number;
        day: number;
        hour: number;
        minute: number;
        second: number;
    } {
        const formatter = new Intl.DateTimeFormat('en-US', {
            timeZone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false,
        });

        const values = Object.fromEntries(
            formatter.formatToParts(date)
                .filter((part) => part.type !== 'literal')
                .map((part) => [part.type, Number(part.value)]),
        );

        return {
            year: values.year,
            month: values.month,
            day: values.day,
            hour: values.hour === 24 ? 0 : values.hour,
            minute: values.minute,
            second: values.second,
        };
    }
}
