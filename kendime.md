1. Sorgu Planlama ve Optimizasyon (EXPLAIN ANALYZE)
Neden bazı sorgular yavaş?

Plan nasıl okunur?

En çok zaman hangi adımda harcanıyor?

2. Index Stratejileri (Doğru Index'i Seç)
B-Tree: Ne zaman?

Hash: Ne zaman?

GIN: Ne zaman? (Full-text, JSONB)

GiST: Ne zaman? (Coğrafi)

BRIN: Ne zaman? (Büyük tablolar)

3. Partition ve Sharding (Veri Dağıtma)
Partition: Tabloyu böl.

Sharding: Veritabanını böl.

Ne zaman kullanılır? Çok büyük veri, tarihsel veri.

4. JOIN Stratejileri
Nested Loop: Ne zaman?

Hash Join: Ne zaman?

Merge Join: Ne zaman?

5. Caching ve Önbellek Stratejileri
Query cache.

Application cache (Redis).

Materialized Views.

6. Veritabanı İzleme ve Bakım
Vacuum ve Autovacuum (PostgreSQL'in hayat kurtarıcısı).

pg_stat_statements (En yavaş sorgular).

Log analizi.

🛠️ BUNLARI ANLATMAYA NEREDEN BAŞLAYALIM?
Sen söyle, ben anlatayım:

EXPLAIN ANALYZE ile başlayalım mı? → Sorgu planı okuma.

Index türleri ile başlayalım mı? → Doğru index hangisi?

Hemen Partition ile başlayalım mı? → Büyük tabloları nasıl bölelim?