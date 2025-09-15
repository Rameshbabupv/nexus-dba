# NEXUS HRMS Database Project - Claude Assistant Guide

## Project Overview

**NEXUS HRMS** is an enterprise-grade PostgreSQL database project that provides a comprehensive foundation for Human Resource Management Systems. This is the **database architecture component** of a larger HRMS system designed with performance, scalability, and security as primary concerns.

### Key Characteristics
- **Architecture**: Monolithic Modular Design with Spring Boot + GraphQL + PostgreSQL
- **Performance Target**: Sub-100ms query response times for 95% of operations
- **Scalability**: Support for 500+ concurrent users and 100K+ employee records per company
- **Security**: Multi-tenant with Row Level Security (RLS) and field-level encryption
- **Experience Base**: 20+ years of DBA and enterprise architecture experience

## Technology Stack

### Core Database Platform
- **PostgreSQL 15+** with extensions: pg_stat_statements, pg_trgm, btree_gin, pgcrypto
- **Multi-Schema Architecture** for module isolation
- **BIGINT Primary Keys** (not UUIDs) for performance optimization
- **Advanced Indexing**: Covering, partial, and GIN indexes

### Target Application Integration
- **Backend**: Spring Boot 3.x with modular architecture
- **API Layer**: GraphQL for flexible data access
- **Connection Pooling**: HikariCP (40 connections for 500 users)
- **Caching**: Redis for performance optimization
- **Security**: JWT-based authentication with RLS policies

### Schema Organization
```
nexus_foundation/     # Core company, location, user management
nexus_employee/       # Employee master and related data
nexus_attendance/     # Time tracking and shifts
nexus_leave/          # Leave management
nexus_payroll/        # Salary and benefits
nexus_performance/    # Appraisals and goals
nexus_recruitment/    # Hiring pipeline
nexus_audit/          # All audit logs
nexus_config/         # System configuration
nexus_lookup/         # Reference data
```

## File Structure

### SQL Schema Files (Numbered Migration Order)
```
01_nexus_foundation_schema.sql           # Core foundation with basic tables
01_nexus_monitoring_maintenance.sql      # Database monitoring setup
01_nexus_performance_indexes.sql         # Performance optimization indexes
01_nexus_security_framework.sql          # Security framework and RLS
01_spring_boot_database_guidelines.md    # Spring Boot integration guide
01_recommendations.md                    # Comprehensive architecture guide

02_organizational_structure_schema.sql   # Company structure and departments

03a_employee_supporting_masters_schema.sql  # Employee supporting master data
03b_employee_core_schema.sql               # Core employee master tables
03c_employee_sample_data.sql               # Sample employee data

04_attendance_management_schema.sql      # Attendance tracking system
04b_attendance_sample_data.sql          # Attendance sample data

05_leave_management_schema.sql          # Leave management system
05b_leave_sample_data.sql              # Leave sample data

06_payroll_management_schema.sql        # Payroll processing system
06b_payroll_sample_data.sql            # Payroll sample data

07_performance_management_schema.sql    # Performance appraisal system
07b_performance_sample_data.sql        # Performance sample data

08_recruitment_management_schema.sql    # Recruitment and hiring system
08b_recruitment_sample_data.sql        # Recruitment sample data

09_training_development_schema.sql      # Training and development system
09b_training_development_sample_data.sql # Training sample data

# Alternative schema versions
02_nexus_attendance_schema.sql         # Alternative attendance schema
03_nexus_leave_schema.sql              # Alternative leave schema
04_nexus_payroll_schema.sql            # Alternative payroll schema
05_nexus_performance_schema.sql        # Alternative performance schema
06_nexus_recruitment_schema.sql        # Alternative recruitment schema
```

### Development Tools
```
systech-dba/
├── scripts/
│   ├── common.sh                       # Common utility functions
│   ├── setup-plan.sh                   # Environment setup
│   ├── check-task-prerequisites.sh     # Prerequisite validation
│   ├── create-new-feature.sh           # Feature creation automation
│   └── get-feature-paths.sh            # Feature path utilities
├── templates/                          # Project templates
├── memory/                             # Project memory files
└── .claude/commands/                   # Claude-specific commands
```

## Code Style & Conventions

### Database Naming Standards
- **Schema Names**: snake_case with `nexus_` prefix
- **Table Names**: snake_case, descriptive (e.g., `employee_master`, `company_master`)
- **Column Names**: snake_case with clear, descriptive names
- **Primary Keys**: `id` BIGINT GENERATED ALWAYS AS IDENTITY
- **Foreign Keys**: `{referenced_table}_id` format

### Standard Table Pattern
```sql
CREATE TABLE schema_name.table_name (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,  -- Multi-tenant isolation
    -- Business columns here
    status status_enum NOT NULL DEFAULT 'active',
    -- Mandatory audit columns
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    version INTEGER NOT NULL DEFAULT 1  -- Optimistic locking
);
```

### Index Naming Conventions
- **Primary**: `pk_{table_name}` (automatic)
- **Foreign Key**: `idx_{table_name}_{column_name}`
- **Covering**: `idx_{table_name}_{purpose}_covering`
- **Partial**: `idx_{table_name}_{condition}`
- **GIN**: `idx_{table_name}_{column_name}_gin`

## Essential Commands

### PostgreSQL Database Commands
```bash
# Connect to database
psql -h localhost -U postgres -d nexus_hrms

# Run schema migrations in order
psql -h localhost -U postgres -d nexus_hrms -f 01_nexus_foundation_schema.sql
psql -h localhost -U postgres -d nexus_hrms -f 02_organizational_structure_schema.sql

# Check schema structure
\dt nexus_foundation.*
\d nexus_foundation.company_master

# Performance monitoring
SELECT query, calls, mean_time FROM pg_stat_statements
WHERE mean_time > 1000 ORDER BY mean_time DESC LIMIT 10;
```

### Project Management (systech-dba scripts)
```bash
cd systech-dba/scripts/

# Environment setup
./setup-plan.sh

# Feature development workflow
./create-new-feature.sh
./check-task-prerequisites.sh
./get-feature-paths.sh
```

### Git Workflow
```bash
# Feature branch naming: {number}-{feature-name}
git checkout -b 001-employee-management
git checkout -b 002-attendance-system

# Commit patterns
git commit -m "feat(schema): add employee master table with audit fields"
git commit -m "fix(payroll): correct foreign key constraint"
git commit -m "perf(indexes): add covering index for dashboard queries"
```

## Key Design Principles

### Performance Optimization
- **Primary Keys**: BIGINT sequences instead of UUIDs (40-50% index size reduction)
- **Partitioning**: Date-based partitioning for large transactional tables
- **Indexing Strategy**: Covering indexes, partial indexes, GIN for full-text search
- **Connection Pooling**: HikariCP optimized for 40 connections, 500 concurrent users

### Security Framework
- **Multi-Tenancy**: Row Level Security (RLS) policies for company isolation
- **Field Encryption**: AES encryption for sensitive PII data
- **Audit Trail**: Comprehensive audit logging for compliance (GDPR-ready)
- **Access Control**: Role-based security with hierarchical permissions

### Data Integrity
- **Referential Integrity**: Comprehensive foreign key constraints
- **Check Constraints**: Business rule enforcement at database level
- **Optimistic Locking**: Version fields for concurrent update handling
- **Audit Columns**: Mandatory created_at, created_by, updated_at, updated_by fields

## Development Workflow

### Schema Migration Process
1. **Foundation First**: Start with `01_nexus_foundation_schema.sql`
2. **Security Setup**: Apply `01_nexus_security_framework.sql`
3. **Performance Indexes**: Run `01_nexus_performance_indexes.sql`
4. **Module Schemas**: Apply in dependency order (02, 03a, 03b, 04, etc.)
5. **Sample Data**: Load `*_sample_data.sql` files for development

### Task Completion Checklist
- [ ] SQL files execute without syntax errors
- [ ] All required indexes are created and optimized
- [ ] RLS policies are active and tested
- [ ] Audit logging is functional
- [ ] Sample data loads successfully
- [ ] Performance benchmarks meet requirements (<100ms for 95% queries)
- [ ] Documentation is updated
- [ ] Changes committed with descriptive messages

## Performance Targets

### Response Time Requirements
- **Simple Queries**: <50ms (employee lookup, basic CRUD)
- **Complex Queries**: <200ms (dashboard aggregations, reports)
- **Batch Operations**: <1s per 1000 records
- **Reports**: <30s for complex payroll/performance reports

### Scalability Targets
- **Concurrent Users**: 500+ per company instance
- **Data Volume**: 100K+ employees per company
- **Transaction Rate**: 1000+ transactions per second
- **Storage**: Efficient handling of 10TB+ data volumes

## Security & Compliance

### Data Protection
- **Encryption at Rest**: Sensitive fields (SSN, bank accounts, salary)
- **Encryption in Transit**: SSL/TLS for all connections
- **Data Masking**: Sensitive data masked in logs and non-production environments
- **Access Logging**: Complete audit trail for all data access

### Compliance Features
- **GDPR Ready**: Right to deletion, data anonymization capabilities
- **SOX Compliance**: Comprehensive audit trails and data integrity
- **HIPAA Compatible**: Healthcare data protection (if applicable)
- **Multi-Tenant Isolation**: Complete data separation between companies

## Troubleshooting

### Common Issues
- **Slow Queries**: Check `pg_stat_statements` for optimization opportunities
- **Lock Contention**: Monitor `pg_locks` for blocking queries
- **Connection Pool**: Monitor HikariCP metrics for pool exhaustion
- **RLS Issues**: Verify security context is properly set

### Performance Monitoring
```sql
-- Monitor slow queries
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
WHERE mean_time > 1000
ORDER BY mean_time DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC;

-- Monitor connections
SELECT state, count(*) FROM pg_stat_activity
WHERE datname = current_database() GROUP BY state;
```

## Documentation References

- **`01_recommendations.md`**: Comprehensive architecture recommendations (857 lines)
- **`01_spring_boot_database_guidelines.md`**: Spring Boot integration guide (1738 lines)
- **Memory Files**: Detailed project information in `systech-dba/memory/`
- **Templates**: Development templates in `systech-dba/templates/`

---

**Project Status**: Database foundation complete, ready for Spring Boot application integration
**Last Updated**: 2025-01-14
**Version**: Foundation Schema v1.0