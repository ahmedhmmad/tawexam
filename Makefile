SHELL := /bin/sh

dev:
	docker compose up --build

prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d

logs:
	docker compose logs -f --tail=200

db:
	docker compose exec postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB

shell:
	docker compose exec backend sh

migrate:
	docker compose exec backend npx prisma migrate deploy

seed:
	docker compose exec backend npx prisma db seed

