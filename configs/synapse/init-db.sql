-- PostgreSQL initialization for Matrix Synapse
-- HomeLab - Secure Communications

-- Create synapse user if not exists (handled by Docker env vars)
-- CREATE USER synapse WITH PASSWORD 'synapse_secret';

-- Create database with proper encoding
-- CREATE DATABASE synapse
--     ENCODING 'UTF8'
--     LC_COLLATE='C'
--     LC_CTYPE='C'
--     TEMPLATE=template0
--     OWNER synapse;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE synapse TO synapse;

-- Enable required extensions
\c synapse
CREATE EXTENSION IF NOT EXISTS pg_trgm;
