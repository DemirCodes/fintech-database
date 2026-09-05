-- Günlük Ciro Raporu (Geliştirme/Taslak)

CREATE OR REPLACE VIEW payment.vw_daily_revenue AS
SELECT 
    DATE_TRUNC('day', created_at)::date AS gun,
    COUNT(*) AS islem_sayisi,
    SUM(amount) AS gunluk_ciro
FROM payment.transactions
WHERE status = 'COMPLETED'
GROUP BY gun
ORDER BY gun DESC;

