# NEXUS HRMS - QA Environment Deployment Guide

## 🎯 Overview

This guide provides **multiple approaches** for setting up the complete NEXUS HRMS database in your QA environment. Choose the approach that best fits your infrastructure and requirements.

## 📋 Prerequisites

### Common Requirements
- PostgreSQL 15+ installed on QA server
- Network connectivity to QA server
- Appropriate database user privileges
- Git access to the repository

### For Docker Approach
- Docker installed and running
- Docker Compose (optional)
- 2GB+ available disk space

### For Traditional Approach
- Direct PostgreSQL access
- psql client tools
- SSH access (if remote)

---

## 🚀 **Method 1: Database Backup & Restore (Fastest)**

### **Option A: Complete Database Restore from Backup**

This is the **fastest and most reliable** method using pre-created database dumps.

```bash
# 1. Download/transfer the backup files to your QA server
scp nexus_hrms_complete.backup qa-user@qa-server:/tmp/
# OR
scp nexus_hrms_complete.sql qa-user@qa-server:/tmp/

# 2. Restore using custom format (Recommended)
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists \
  --verbose /tmp/nexus_hrms_complete.backup

# 3. For different database name, use SQL format
sed 's/nexus_hrms/nexus_hrms_qa/g' /tmp/nexus_hrms_complete.sql > /tmp/nexus_hrms_qa.sql
psql -h qa-host -U qa-username -d postgres -f /tmp/nexus_hrms_qa.sql
```

**What this method provides:**
- ✅ Complete database with all schemas, data, and configurations
- ✅ All extensions and functions pre-configured
- ✅ Sample data with 3 companies and 14+ test users
- ✅ Audit logging fully functional
- ✅ Row Level Security policies enabled
- ✅ All indexes and performance optimizations
- ✅ Takes only 2-5 minutes to complete

### **Option B: Create Fresh Backup from Development**

```bash
# 1. Create backup from development environment
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --clean --create --if-exists \
  --verbose --format=custom \
  --file=nexus_hrms_dev_backup.backup

# 2. Transfer to QA server
scp nexus_hrms_dev_backup.backup qa-user@qa-server:/tmp/

# 3. Restore on QA server
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists \
  --verbose /tmp/nexus_hrms_dev_backup.backup
```

### **Option C: SQL Format with Custom Database Name**

```bash
# 1. Create SQL backup from development
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --clean --create --if-exists \
  --verbose --format=plain \
  --file=nexus_hrms_dev.sql

# 2. Customize for QA environment
sed -i 's/nexus_hrms/nexus_hrms_qa/g' nexus_hrms_dev.sql

# 3. Restore on QA server
psql -h qa-host -U qa-username -d postgres -f nexus_hrms_dev.sql
```

---

## 🔧 **Method 2: Automated Script Deployment**

### **Option A: Direct Database Deployment**

```bash
# 1. Navigate to scripts directory
cd scripts/

# 2. Run the automated setup script
./qa-setup.sh [qa-host] [qa-username] [qa-database-name]

# Example: Local setup
./qa-setup.sh localhost postgres nexus_hrms_qa

# Example: Remote QA server
./qa-setup.sh qa-server.company.com nexus_user nexus_hrms_qa 5432
```

**What this script does:**
- ✅ Tests database connectivity
- ✅ Creates QA database
- ✅ Loads foundation schema with fixes
- ✅ Applies audit log partitioning fixes
- ✅ Loads comprehensive QA sample data
- ✅ Verifies setup completion
- ✅ Provides connection information

### **Option B: Docker Container Deployment**

```bash
# 1. Navigate to scripts directory
cd scripts/

# 2. Run Docker-based setup
./docker-qa-setup.sh qa

# For different environments
./docker-qa-setup.sh staging
./docker-qa-setup.sh dev
```

**Docker setup provides:**
- ✅ Isolated PostgreSQL container
- ✅ Persistent data volumes
- ✅ Easy start/stop/restart
- ✅ No conflicts with existing databases
- ✅ Consistent environment across teams

---

## 🔧 **Method 3: Manual Step-by-Step Setup**

### **Step 1: Create Database**

```bash
# Connect to PostgreSQL
psql -h [qa-host] -U [qa-username] -d postgres

# Create database
CREATE DATABASE nexus_hrms_qa
OWNER [qa-username]
ENCODING 'UTF8'
LC_COLLATE='en_US.UTF-8'
LC_CTYPE='en_US.UTF-8'
TEMPLATE=template0;

# Exit and connect to new database
\q
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa
```

### **Step 2: Load Foundation Schema**

```bash
# Run foundation schema
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 01_nexus_foundation_schema.sql

# Fix audit log partitioning (if errors occur)
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -c "
-- Fix audit_log table
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
"
```

### **Step 3: Load Sample Data**

```bash
# Load QA sample data
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f scripts/qa-sample-data.sql
```

---

## 🔄 **Method 4: Advanced Backup & Restore Options**

### **Option A: Schema-Only Backup (Structure Without Data)**

```bash
# 1. Create schema-only backup
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --schema-only --clean --create --if-exists \
  --verbose --format=custom \
  --file=nexus_hrms_schema_only.backup

# 2. Restore schema and then load QA sample data
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists \
  --verbose nexus_hrms_schema_only.backup

# 3. Load QA-specific sample data
psql -h qa-host -U qa-username -d nexus_hrms -f scripts/qa-sample-data.sql
```

### **Option B: Data-Only Backup (for Data Migration)**

```bash
# 1. Create data-only backup (assumes schema exists)
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --data-only --verbose --format=custom \
  --file=nexus_hrms_data_only.backup

# 2. Restore data (requires existing schema)
pg_restore -h qa-host -U qa-username -d nexus_hrms_qa \
  --data-only --verbose nexus_hrms_data_only.backup
```

### **Option C: Selective Table Backup**

```bash
# 1. Backup specific tables only
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --table=nexus_foundation.company_master \
  --table=nexus_foundation.user_master \
  --table=nexus_foundation.location_master \
  --verbose --format=custom \
  --file=nexus_hrms_core_tables.backup

# 2. Restore selective tables
pg_restore -h qa-host -U qa-username -d nexus_hrms_qa \
  --verbose nexus_hrms_core_tables.backup
```

### **Option D: Compressed Backup for Large Databases**

```bash
# 1. Create compressed backup
pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --clean --create --if-exists \
  --verbose --format=custom --compress=9 \
  --file=nexus_hrms_compressed.backup

# 2. Restore compressed backup
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists \
  --verbose nexus_hrms_compressed.backup
```

---

## 📁 **Backup File Management**

### **Available Backup Files**

The repository includes pre-created backup files for quick QA deployment:

| File | Size | Format | Best For |
|------|------|--------|----------|
| `nexus_hrms_complete.backup` | ~78KB | Custom (compressed) | Production QA setup |
| `nexus_hrms_complete.sql` | ~73KB | Plain SQL | Manual inspection/editing |

### **Backup File Locations**

```bash
# After running pg_dump, files are created in current directory
ls -lh nexus_hrms_complete.*
-rw-r--r-- 1 user staff 78K nexus_hrms_complete.backup
-rw-r--r-- 1 user staff 73K nexus_hrms_complete.sql

# Transfer to QA server
scp nexus_hrms_complete.backup qa-user@qa-server:/tmp/
scp nexus_hrms_complete.sql qa-user@qa-server:/tmp/
```

### **Backup Validation**

```bash
# Verify backup file integrity
pg_restore --list nexus_hrms_complete.backup | head -20

# Check backup file size and content
pg_restore --schema-only nexus_hrms_complete.backup | wc -l
```

---

## 🔍 **QA Environment Configuration**

### **QA-Specific Data Loaded**

| Data Type | Count | Description |
|-----------|-------|-------------|
| **Companies** | 3 | SysTech QA, Global Tech QA, US Tech QA |
| **Locations** | 7 | Multiple offices across India and US |
| **Users** | 14+ | Complete role hierarchy for testing |
| **Roles** | 15+ | From Super Admin to Employee levels |
| **Countries** | 8 | US, India, UK, Canada, Australia, etc. |
| **States** | 15+ | Indian states and US states |
| **Cities** | 15+ | Major cities for location testing |

### **QA Test Users**

| Company | Username | Role | Email |
|---------|----------|------|-------|
| SysTech QA | `qa_admin` | Super Admin | qa.admin@systechsolutions.com |
| SysTech QA | `hr_manager_qa` | HR Manager | hr.manager@systechsolutions.com |
| SysTech QA | `payroll_admin_qa` | Payroll Admin | payroll@systechsolutions.com |
| SysTech QA | `manager1_qa` | Manager | manager1@systechsolutions.com |
| SysTech QA | `employee1_qa` | Employee | employee1@systechsolutions.com |
| Global Tech QA | `global_admin` | Super Admin | admin@globaltech-qa.com |
| Global Tech QA | `hr_director_qa` | HR Director | hr.director@globaltech-qa.com |
| US Tech QA | `us_admin` | Administrator | admin@ustech-qa.com |
| US Tech QA | `hr_specialist_us` | HR Specialist | hr@ustech-qa.com |

### **System Parameters for QA**

- **QA_MODE**: `true` - Enables QA-specific features
- **DEBUG_LEVEL**: `DEBUG` - Enhanced logging for testing
- **PASSWORD_POLICY**: `RELAXED` - Easier testing
- **AUDIT_LOGGING**: `ENABLED` - Full audit trail
- **TEST_DATA_RETENTION**: `30 days` - Auto-cleanup

---

## ✅ **Verification Steps**

### **1. Basic Connectivity Test**

```bash
# Test database connection
psql -h [qa-host] -p [port] -U [username] -d [database] -c "SELECT version();"
```

### **2. Schema Verification**

```sql
-- Check schemas
SELECT schema_name FROM information_schema.schemata
WHERE schema_name LIKE 'nexus%'
ORDER BY schema_name;
-- Expected: nexus_audit, nexus_config, nexus_foundation

-- Check tables
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'nexus_foundation'
ORDER BY table_name;
-- Expected: 8+ base tables, 2 views
```

### **3. Data Verification**

```sql
-- Check data counts
SELECT 'Companies' as type, COUNT(*) as count FROM nexus_foundation.company_master
UNION ALL
SELECT 'Users', COUNT(*) FROM nexus_foundation.user_master
UNION ALL
SELECT 'Locations', COUNT(*) FROM nexus_foundation.location_master
UNION ALL
SELECT 'Roles', COUNT(*) FROM nexus_foundation.role_master;
```

### **4. Performance Test**

```sql
-- Test complex query performance
EXPLAIN ANALYZE
SELECT
    c.company_name,
    l.location_name,
    u.username,
    u.email_address
FROM nexus_foundation.company_master c
JOIN nexus_foundation.location_master l ON c.company_id = l.company_id
JOIN nexus_foundation.user_master u ON c.company_id = u.company_id
WHERE c.company_status = 'ACTIVE';
-- Should execute in < 10ms
```

### **5. Audit Log Test**

```sql
-- Verify audit logging works
INSERT INTO nexus_foundation.company_master (
    company_code, company_name, company_short_name,
    registered_address, registered_country_id, primary_email, created_by
) VALUES (
    'TEST001', 'Test Company', 'Test Co',
    'Test Address', 1, 'test@test.com', 1
);

-- Check audit record was created
SELECT table_name, operation_type, COUNT(*)
FROM nexus_audit.audit_log
WHERE table_name = 'company_master'
GROUP BY table_name, operation_type;

-- Clean up test data
DELETE FROM nexus_foundation.company_master WHERE company_code = 'TEST001';
```

---

## 🐛 **Troubleshooting**

### **Common Issues & Solutions**

#### **Issue: Connection Refused**
```bash
# Check PostgreSQL is running
brew services list | grep postgresql
# or
systemctl status postgresql

# Check port and host
telnet [qa-host] [port]
```

#### **Issue: Authentication Failed**
```bash
# Check pg_hba.conf allows connections
# Add line for QA access:
# host    all    all    [qa-ip]/32    md5
```

#### **Issue: Audit Log Partition Errors**
```sql
-- Create missing partitions manually
CREATE TABLE nexus_audit.audit_log_YYYY_MM PARTITION OF nexus_audit.audit_log
    FOR VALUES FROM ('YYYY-MM-01') TO ('YYYY-MM+1-01');
```

#### **Issue: Permission Denied**
```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE nexus_hrms_qa TO [qa-username];
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA nexus_foundation TO [qa-username];
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA nexus_foundation TO [qa-username];
```

#### **Issue: Backup/Restore Errors**
```bash
# Check backup file integrity
pg_restore --list nexus_hrms_complete.backup | grep ERROR

# Restore with verbose output for debugging
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists --verbose \
  nexus_hrms_complete.backup 2>&1 | tee restore.log

# Skip problematic objects (if needed)
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists --single-transaction \
  nexus_hrms_complete.backup
```

#### **Issue: Database Already Exists**
```bash
# Force drop and recreate
pg_restore -h qa-host -U qa-username -d postgres \
  --clean --create --if-exists \
  nexus_hrms_complete.backup

# Or manually drop first
psql -h qa-host -U qa-username -d postgres -c "DROP DATABASE IF EXISTS nexus_hrms_qa;"
```

#### **Issue: Version Compatibility**
```bash
# Check PostgreSQL versions
psql -h dev-host -U dev-username -c "SELECT version();"
psql -h qa-host -U qa-username -c "SELECT version();"

# Use compatible pg_dump version
/usr/pgsql-15/bin/pg_dump -h dev-host -U dev-username -d nexus_hrms \
  --clean --create --if-exists --format=custom \
  --file=nexus_hrms_v15.backup
```

### **Log Locations**

- **PostgreSQL Logs**: `/var/log/postgresql/` or check `SHOW log_directory;`
- **Docker Logs**: `docker logs nexus-postgres-qa`
- **Script Logs**: Output to console (redirect to file if needed)

---

## 📝 **Next Steps After QA Setup**

### **1. Application Configuration**

Update your Spring Boot application properties for QA:

```yaml
# application-qa.yml
spring:
  datasource:
    url: jdbc:postgresql://[qa-host]:[port]/nexus_hrms_qa
    username: [qa-username]
    password: [qa-password]
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
```

### **2. Additional Schema Modules**

```bash
# Load additional modules as needed
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 02_organizational_structure_schema.sql
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 03a_employee_supporting_masters_schema.sql
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 03b_employee_core_schema.sql
```

### **3. Load Test Data**

```bash
# Load specific sample data
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 03c_employee_sample_data.sql
psql -h [qa-host] -U [qa-username] -d nexus_hrms_qa -f 04b_attendance_sample_data.sql
```

### **4. Performance Monitoring**

```sql
-- Enable query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Monitor query performance
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

---

## 🎯 **Success Criteria**

Your QA environment is ready when:

- ✅ All 3 schemas created (`nexus_foundation`, `nexus_audit`, `nexus_config`)
- ✅ 8+ tables in foundation schema
- ✅ 3 QA companies with realistic data
- ✅ 14+ test users with proper role assignments
- ✅ Audit logging functional with partitioned tables
- ✅ Row Level Security policies enabled
- ✅ All extensions loaded (pgcrypto, pg_trgm, etc.)
- ✅ Performance queries execute in < 100ms
- ✅ Application can connect and authenticate
- ✅ Sample CRUD operations work correctly
- ✅ Backup and restore operations tested

**Setup Time by Method:**
- **Method 1 (Backup/Restore)**: 2-5 minutes ⚡
- **Method 2 (Automated Scripts)**: 5-10 minutes
- **Method 3 (Manual Setup)**: 10-15 minutes
- **Method 4 (Advanced Options)**: 5-20 minutes

---

## 📞 **Support**

For issues with QA setup:

1. **Check logs** for specific error messages
2. **Verify prerequisites** are met
3. **Test connectivity** step by step
4. **Review troubleshooting section** above
5. **Consult database administrator** for infrastructure issues

**Happy Testing!** 🚀