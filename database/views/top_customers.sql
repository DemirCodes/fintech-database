-- Müşteri bazlı analiz 

CREATE OR REPLACE VIEW payment.vw_top_customers AS
SELECT 
    customer_id as "Müşteri No",
    count(*) as "İşlem Sayısı",
    sum(amount) as "Toplam Ciro"
FROM payment.transactions
WHERE status = 'COMPLETED'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;   