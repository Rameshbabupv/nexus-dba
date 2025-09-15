#!/bin/bash
# ================================================================
# NEXUS HRMS - Docker QA Environment Setup
# ================================================================
# Purpose: Set up NEXUS HRMS database using Docker containers
# Usage: ./docker-qa-setup.sh [environment]
# ================================================================

set -e  # Exit on any error

# Configuration
ENVIRONMENT=${1:-"qa"}
POSTGRES_VERSION="15.4"
DB_NAME="nexus_hrms_${ENVIRONMENT}"
DB_USER="nexus_${ENVIRONMENT}"
DB_PASSWORD="nexus_${ENVIRONMENT}_pass_2024"
DB_PORT="5433"  # Different from default to avoid conflicts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to create Docker network if it doesn't exist
create_network() {
    if ! docker network ls | grep -q "nexus-network"; then
        print_status "Creating Docker network..."
        docker network create nexus-network
        print_success "Docker network 'nexus-network' created"
    else
        print_success "Docker network 'nexus-network' already exists"
    fi
}

# Function to start PostgreSQL container
start_postgres() {
    local container_name="nexus-postgres-${ENVIRONMENT}"

    # Stop and remove existing container if it exists
    if docker ps -a | grep -q "$container_name"; then
        print_status "Stopping existing PostgreSQL container..."
        docker stop "$container_name" > /dev/null 2>&1 || true
        docker rm "$container_name" > /dev/null 2>&1 || true
    fi

    print_status "Starting PostgreSQL container..."
    docker run -d \
        --name "$container_name" \
        --network nexus-network \
        -e POSTGRES_DB="$DB_NAME" \
        -e POSTGRES_USER="$DB_USER" \
        -e POSTGRES_PASSWORD="$DB_PASSWORD" \
        -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8" \
        -p "${DB_PORT}:5432" \
        -v "nexus-postgres-${ENVIRONMENT}-data:/var/lib/postgresql/data" \
        postgres:${POSTGRES_VERSION}

    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec "$container_name" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
            print_success "PostgreSQL is ready!"
            break
        fi

        echo -n "."
        sleep 2
        ((attempt++))
    done

    if [ $attempt -gt $max_attempts ]; then
        print_error "PostgreSQL failed to start within expected time"
        exit 1
    fi
}

# Function to load schema and data
load_database() {
    local container_name="nexus-postgres-${ENVIRONMENT}"

    print_status "Loading database schema and data..."

    # Copy SQL files to container
    docker cp ../01_nexus_foundation_schema.sql "$container_name:/tmp/"
    docker cp qa-sample-data.sql "$container_name:/tmp/"

    # Execute foundation schema
    print_status "Loading foundation schema..."
    docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -f /tmp/01_nexus_foundation_schema.sql > /dev/null 2>&1

    # Fix audit log issues
    print_status "Applying audit log fixes..."
    docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -c "
    -- Fix audit_log partitioning
    DROP TABLE IF EXISTS nexus_audit.audit_log CASCADE;

    CREATE TABLE nexus_audit.audit_log (
        audit_id BIGINT DEFAULT nextval('nexus_foundation.global_id_seq'),
        company_id BIGINT NOT NULL,
        schema_name VARCHAR(64) NOT NULL,
        table_name VARCHAR(64) NOT NULL,
        operation_type VARCHAR(10) NOT NULL,
        record_id BIGINT,
        old_values JSONB,
        new_values JSONB,
        changed_fields JSONB,
        user_id BIGINT,
        session_id VARCHAR(100),
        ip_address INET,
        user_agent TEXT,
        operation_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        business_context JSONB,
        PRIMARY KEY (audit_id, operation_timestamp),
        CONSTRAINT chk_operation_type CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT'))
    ) PARTITION BY RANGE (operation_timestamp);

    -- Create partitions
    CREATE TABLE nexus_audit.audit_log_2024_09 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
    CREATE TABLE nexus_audit.audit_log_2024_10 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
    CREATE TABLE nexus_audit.audit_log_2024_11 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
    CREATE TABLE nexus_audit.audit_log_2024_12 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
    CREATE TABLE nexus_audit.audit_log_2025_09 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
    CREATE TABLE nexus_audit.audit_log_2025_10 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

    -- Create indexes
    CREATE INDEX idx_audit_log_company_time ON nexus_audit.audit_log(company_id, operation_timestamp);
    CREATE INDEX idx_audit_log_table_operation ON nexus_audit.audit_log(schema_name, table_name, operation_type);
    CREATE INDEX idx_audit_log_user ON nexus_audit.audit_log(user_id, operation_timestamp);
    CREATE INDEX idx_audit_log_record ON nexus_audit.audit_log(table_name, record_id);

    -- Fix audit function
    DROP FUNCTION IF EXISTS nexus_foundation.get_current_user_context();
    CREATE OR REPLACE FUNCTION nexus_foundation.get_current_user_context()
    RETURNS TABLE(user_id BIGINT, company_id BIGINT, session_id TEXT) AS \$\$
    BEGIN
        RETURN QUERY SELECT
            COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0),
            COALESCE(current_setting('app.current_company_id', true)::BIGINT, 0),
            COALESCE(current_setting('app.current_session_id', true), '');
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;
    " > /dev/null 2>&1

    # Load sample data
    print_status "Loading QA sample data..."
    docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -f /tmp/qa-sample-data.sql > /dev/null 2>&1

    print_success "Database schema and data loaded successfully"
}

# Function to verify setup
verify_setup() {
    local container_name="nexus-postgres-${ENVIRONMENT}"

    print_status "Verifying database setup..."

    # Get counts
    local schema_count=$(docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name LIKE 'nexus%';
    " | xargs)

    local table_count=$(docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'nexus_foundation' AND table_type = 'BASE TABLE';
    " | xargs)

    local company_count=$(docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM nexus_foundation.company_master;
    " | xargs)

    local user_count=$(docker exec "$container_name" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM nexus_foundation.user_master;
    " | xargs)

    echo "Verification Results:"
    echo "  Schemas: $schema_count (expected: 3)"
    echo "  Tables: $table_count (expected: 8+)"
    echo "  Companies: $company_count (expected: 3)"
    echo "  Users: $user_count (expected: 14+)"

    if [ "$schema_count" -eq "3" ] && [ "$table_count" -ge "8" ] && [ "$company_count" -ge "3" ]; then
        print_success "Database verification passed!"
    else
        print_warning "Database verification had some issues (check manually)"
    fi
}

# Function to create connection info
create_connection_info() {
    echo ""
    echo "================================================================"
    print_success "QA Environment Setup Complete!"
    echo "================================================================"
    echo "Database Connection Details:"
    echo "  Host: localhost"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo ""
    echo "Connection String:"
    echo "  postgresql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$DB_NAME"
    echo ""
    echo "psql Command:"
    echo "  psql -h localhost -p $DB_PORT -U $DB_USER -d $DB_NAME"
    echo ""
    echo "Docker Commands:"
    echo "  Start:   docker start nexus-postgres-${ENVIRONMENT}"
    echo "  Stop:    docker stop nexus-postgres-${ENVIRONMENT}"
    echo "  Logs:    docker logs nexus-postgres-${ENVIRONMENT}"
    echo "  Connect: docker exec -it nexus-postgres-${ENVIRONMENT} psql -U $DB_USER -d $DB_NAME"
    echo ""
    echo "pgAdmin Connection:"
    echo "  Server: localhost"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo "================================================================"
}

# Main execution
main() {
    echo "================================================================"
    echo "NEXUS HRMS - Docker QA Environment Setup"
    echo "================================================================"
    echo "Environment: $ENVIRONMENT"
    echo "PostgreSQL Version: $POSTGRES_VERSION"
    echo "Database: $DB_NAME"
    echo "Port: $DB_PORT"
    echo "================================================================"

    check_docker
    create_network
    start_postgres
    sleep 5  # Give PostgreSQL a moment to fully initialize
    load_database
    verify_setup
    create_connection_info
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi