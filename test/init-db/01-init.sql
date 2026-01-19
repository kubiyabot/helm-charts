-- Initialize databases and extensions for testing
-- This script runs on PostgreSQL startup

-- Create additional databases
CREATE DATABASE memories;

-- Enable pgvector extension on default database
CREATE EXTENSION IF NOT EXISTS vector;

-- Connect to memories database and enable pgvector
\c memories
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant all privileges to kubiya user
\c agent_control_plane
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kubiya;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kubiya;

\c memories
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kubiya;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kubiya;
