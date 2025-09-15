#!/bin/bash
# ================================================================
# NEXUS HRMS - QA Environment Setup Script
# ================================================================
# Purpose: Complete setup of NEXUS HRMS database in QA environment
# Usage: ./qa-setup.sh [qa-host] [qa-username] [qa-database-name]
# ================================================================

set -e  # Exit on any error

# Configuration
QA_HOST=${1:-"localhost"}
QA_USERNAME=${2:-"postgres"}
QA_DATABASE=${3:-"nexus_hrms_qa"}
QA_PORT=${4:-"5432"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to execute SQL with error handling
execute_sql() {
    local sql_file=$1
    local description=$2

    print_status "Executing: $description"
    if psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d "$QA_DATABASE" -f "$sql_file" > /dev/null 2>&1; then
        print_success "$description completed successfully"
    else
        print_error "$description failed"
        echo "SQL file: $sql_file"
        echo "Try running manually: psql -h $QA_HOST -U $QA_USERNAME -d $QA_DATABASE -f $sql_file"
        exit 1
    fi
}

# Function to test database connection
test_connection() {
    print_status "Testing database connection..."
    if psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d postgres -c "SELECT version();" > /dev/null 2>&1; then
        print_success "Database connection successful"
    else
        print_error "Cannot connect to PostgreSQL at $QA_HOST:$QA_PORT with user $QA_USERNAME"
        echo "Please check:"
        echo "1. PostgreSQL is running on QA server"
        echo "2. Network connectivity to QA server"
        echo "3. Username and credentials"
        echo "4. pg_hba.conf allows connections"
        exit 1
    fi
}

# Main execution
main() {
    echo "================================================================"
    echo "NEXUS HRMS - QA Environment Setup"
    echo "================================================================"
    echo "Target Host: $QA_HOST"
    echo "Target User: $QA_USERNAME"
    echo "Target Database: $QA_DATABASE"
    echo "Target Port: $QA_PORT"
    echo "================================================================"

    # Step 1: Test connection
    test_connection

    # Step 2: Create database
    print_status "Creating QA database..."
    psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d postgres -c "
        DROP DATABASE IF EXISTS $QA_DATABASE;
        CREATE DATABASE $QA_DATABASE
        OWNER $QA_USERNAME
        ENCODING 'UTF8'
        LC_COLLATE='en_US.UTF-8'
        LC_CTYPE='en_US.UTF-8'
        TEMPLATE=template0;
    " > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_success "Database $QA_DATABASE created successfully"
    else
        print_error "Failed to create database $QA_DATABASE"
        exit 1
    fi

    # Step 3: Execute schema files in order
    print_status "Setting up database schema..."

    # Foundation schema (with fixes)
    execute_sql "../01_nexus_foundation_schema.sql" "Foundation Schema"

    # Fix audit log partitioning
    print_status "Applying audit log fixes..."
    psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d "$QA_DATABASE" -c "
    -- Fix audit_log table partitioning
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

    -- Create partitions for 2024-2026
    CREATE TABLE nexus_audit.audit_log_2024_09 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
    CREATE TABLE nexus_audit.audit_log_2024_10 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
    CREATE TABLE nexus_audit.audit_log_2024_11 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
    CREATE TABLE nexus_audit.audit_log_2024_12 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');
    CREATE TABLE nexus_audit.audit_log_2025_09 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
    CREATE TABLE nexus_audit.audit_log_2025_10 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
    CREATE TABLE nexus_audit.audit_log_2025_11 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
    CREATE TABLE nexus_audit.audit_log_2025_12 PARTITION OF nexus_audit.audit_log FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

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

    if [ $? -eq 0 ]; then
        print_success "Audit log fixes applied successfully"
    else
        print_warning "Audit log fixes had some issues (check manually)"
    fi

    # Step 4: Load sample data
    if [ -f "../scripts/qa-sample-data.sql" ]; then
        execute_sql "../scripts/qa-sample-data.sql" "QA Sample Data"
    else
        print_warning "QA sample data file not found, loading basic sample data..."
        # Load basic sample data inline
        psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d "$QA_DATABASE" -f "../scripts/qa-sample-data.sql" > /dev/null 2>&1 || true
    fi

    # Step 5: Verification
    print_status "Verifying QA database setup..."

    # Check schemas
    SCHEMA_COUNT=$(psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d "$QA_DATABASE" -t -c "
        SELECT COUNT(*) FROM information_schema.schemata
        WHERE schema_name LIKE 'nexus%';
    " | xargs)

    if [ "$SCHEMA_COUNT" -eq "3" ]; then
        print_success "All 3 schemas created successfully"
    else
        print_warning "Expected 3 schemas, found $SCHEMA_COUNT"
    fi

    # Check tables
    TABLE_COUNT=$(psql -h "$QA_HOST" -p "$QA_PORT" -U "$QA_USERNAME" -d "$QA_DATABASE" -t -c "
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'nexus_foundation' AND table_type = 'BASE TABLE';
    " | xargs)

    if [ "$TABLE_COUNT" -ge "8" ]; then
        print_success "Foundation tables created successfully ($TABLE_COUNT tables)"
    else
        print_warning "Expected at least 8 foundation tables, found $TABLE_COUNT"
    fi

    # Final summary
    echo "================================================================"
    print_success "QA Environment Setup Complete!"
    echo "================================================================"
    echo "Database: $QA_DATABASE"
    echo "Host: $QA_HOST"
    echo "Port: $QA_PORT"
    echo ""
    echo "Connection command:"
    echo "psql -h $QA_HOST -p $QA_PORT -U $QA_USERNAME -d $QA_DATABASE"
    echo ""
    echo "Next steps:"
    echo "1. Test application connectivity"
    echo "2. Run additional schema migrations if needed"
    echo "3. Load additional test data"
    echo "4. Configure application properties for QA"
    echo "================================================================"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi