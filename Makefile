.PHONY: up down restart logs status clean

# Başlat
up:
	docker compose up -d

# Durdur
down:
	docker compose down

# Yeniden başlat
restart:
	docker compose restart

# Logları izle
logs:
	docker compose logs -f

# Durum kontrol
status:
	docker compose ps

# Temizlik (volume'ları siler - DİKKAT!)
clean:
	docker compose down -v

# PostgreSQL'e bağlan
psql:
	docker exec -it fintech_postgres psql -U $${POSTGRES_USER} -d $${POSTGRES_DB}

# Flyway migrate çalıştır
migrate:
	docker exec -it fintech_flyway flyway migrate

# Flyway temizle (DİKKAT!)
flyway-clean:
	docker exec -it fintech_flyway flyway clean