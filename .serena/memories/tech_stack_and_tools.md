# NEXUS HRMS - Technology Stack & Tools

## Core Technology Stack

### Database Platform
- **PostgreSQL 15+**: Primary database with advanced features
- **Extensions**: pg_stat_statements, pg_trgm, btree_gin, pgcrypto
- **Architecture**: Multi-schema organization with performance optimization

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

### Application Stack (Target Integration)
- **Backend Framework**: Spring Boot 3.x
- **API Layer**: GraphQL for flexible data access
- **Connection Pooling**: HikariCP (optimized for 40 connections, 500 users)
- **Caching**: Redis for performance
- **Security**: JWT-based with Row Level Security (RLS)

### Development Tools
- **Version Control**: Git with feature branch workflow (001-feature-name pattern)
- **Scripts**: Bash scripts for project management in systech-dba/scripts/
- **Documentation**: Markdown-based with templates in systech-dba/templates/

### Performance Optimization Features
- **Indexing Strategy**: Covering indexes, partial indexes, GIN indexes for full-text search
- **Partitioning**: Date-based partitioning for large transactional tables
- **Primary Keys**: BIGINT sequences (not UUIDs) for better performance
- **Connection Management**: Optimized HikariCP configuration

### Security Features
- **Multi-Tenancy**: Row Level Security (RLS) policies
- **Encryption**: Field-level encryption for sensitive data (PII)
- **Audit Trail**: Comprehensive audit logging for compliance
- **Access Control**: Role-based security with hierarchical permissions