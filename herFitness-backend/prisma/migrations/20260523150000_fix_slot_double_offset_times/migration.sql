-- Fix availability slots whose startAt/endAt were stored with the UTC offset applied
-- twice instead of once (double-offset bug in DateTimeUtils.fromLocalDateTime).
--
-- How to detect affected rows:
--   When the bug was active (server in UTC+6 / Asia/Dhaka), each slot was stored as:
--     stored_startAt = input_time_as_UTC - 2 * 6h = input_time_as_UTC - 12h
--   So: input_time_as_UTC - stored_startAt = exactly 12 hours (43200 seconds)
--
-- Fix: add back the missing 6 hours (one offset's worth).

UPDATE fitness_class_availability_slots
SET
    start_at = start_at + INTERVAL '6 hours',
    end_at   = end_at   + INTERVAL '6 hours'
WHERE
    ABS(
        EXTRACT(EPOCH FROM (
            (date || 'T' || start_time || ':00Z')::timestamptz - start_at
        ))
    ) BETWEEN 43100 AND 43300;  -- 43200 seconds = 12h, ±100s tolerance for edge cases
