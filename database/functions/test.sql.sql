-- Active: 1788550056509@@127.0.0.1@55432@fintech
SELECT
    conrelid::regclass AS tablo,
    a.attname AS kolon,
    confrelid::regclass AS referans_tablo,
    af.attname AS referans_kolon
FROM pg_constraint c
JOIN pg_attribute a
    ON a.attnum = ANY(c.conkey)
    AND a.attrelid = c.conrelid
JOIN pg_attribute af
    ON af.attnum = ANY(c.confkey)
    AND af.attrelid = c.confrelid
WHERE c.contype = 'f'
ORDER BY tablo, kolon;