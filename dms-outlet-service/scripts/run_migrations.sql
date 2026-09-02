-- scripts/run_migrations.sql
-- Run schema migrations in order
-- Usage: psql -U postgres -d dms -f scripts/run_migrations.sql

\echo '=== Migration 1: Value Set + Address ==='
\i ../sql/01_schema_value_set.sql

\echo '=== Migration 2: Outlets + Enterprise ==='
\i ../sql/02_schema_outlets.sql

\echo '=== Migration 3: Seed Data ==='
\i ../sql/03_seed_data.sql

\echo '=== All migrations completed ==='