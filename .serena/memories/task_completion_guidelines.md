# NEXUS HRMS - Task Completion Guidelines

## When a Task is Completed

### Database Schema Development Tasks

#### 1. SQL Schema Validation
- **Syntax Check**: Ensure SQL files execute without syntax errors
- **Dependency Validation**: Verify all referenced tables and schemas exist
- **Constraint Testing**: Test foreign key constraints and check constraints
- **Index Verification**: Confirm all required indexes are created

#### 2. Performance Validation
- **Query Testing**: Test critical queries for performance
- **Index Usage**: Verify queries use appropriate indexes with EXPLAIN PLAN
- **Connection Testing**: Test with realistic connection pool settings
- **Data Volume Testing**: Test with representative data volumes

#### 3. Security Compliance
- **RLS Policies**: Verify Row Level Security policies are active
- **Encryption**: Confirm sensitive fields are properly encrypted
- **Audit Trail**: Test audit logging for all CRUD operations
- **Access Control**: Validate role-based access controls

### Development Process Tasks

#### 1. Code Quality Checks
```bash
# Check SQL syntax
psql -h localhost -U postgres -d nexus_hrms --single-transaction -f schema_file.sql

# Validate schema structure
\dt nexus_foundation.*
\d table_name

# Check constraints
\d+ table_name
```

#### 2. Documentation Updates
- **Schema Comments**: Ensure all tables and important columns have comments
- **README Updates**: Update relevant documentation files
- **Migration Notes**: Document any special migration requirements
- **Dependency Documentation**: Update dependency information

#### 3. Version Control
```bash
# Standard commit process
git add .
git status  # Review changes
git commit -m "feat(schema): descriptive commit message"

# For database schema changes
git commit -m "feat(employee): add employee master table with audit fields"
git commit -m "fix(payroll): correct foreign key constraint in payroll_transaction"
git commit -m "perf(indexes): add covering index for employee dashboard queries"
```

### Testing Requirements

#### 1. Schema Testing
- **Migration Testing**: Test complete schema migration from scratch
- **Rollback Testing**: Verify rollback procedures work
- **Data Integrity**: Test referential integrity with sample data
- **Performance Testing**: Benchmark critical queries

#### 2. Integration Testing
- **Multi-Tenant Testing**: Verify RLS works correctly across companies
- **Concurrent Access**: Test with multiple simultaneous connections
- **Large Dataset Testing**: Test with realistic data volumes
- **Backup/Restore**: Verify backup and restore procedures

### Deployment Preparation

#### 1. Production Readiness
- **Environment Configuration**: Verify all environment-specific settings
- **Security Hardening**: Confirm security measures are in place
- **Monitoring Setup**: Ensure monitoring and alerting are configured
- **Backup Strategy**: Validate backup and recovery procedures

#### 2. Documentation Completion
- **Deployment Guide**: Create or update deployment documentation
- **Operations Manual**: Document ongoing maintenance procedures
- **Troubleshooting Guide**: Document common issues and solutions
- **Performance Tuning**: Document optimization procedures

### Quality Gates

#### Must-Have Before Task Completion
- [ ] All SQL files execute without errors
- [ ] Required indexes are created and optimized
- [ ] RLS policies are active and tested
- [ ] Audit logging is functional
- [ ] Sample data loads successfully
- [ ] Performance benchmarks meet requirements
- [ ] Documentation is updated
- [ ] Code is committed with descriptive messages

#### Nice-to-Have
- [ ] Performance testing with realistic load
- [ ] Security penetration testing
- [ ] Comprehensive integration testing
- [ ] Load testing with concurrent users
- [ ] Disaster recovery testing

### Command Sequence for Task Completion

#### 1. Final Validation
```bash
# Test schema migration
psql -h localhost -U postgres -d nexus_hrms_test -f complete_schema.sql

# Performance validation
EXPLAIN ANALYZE SELECT * FROM employee_master WHERE company_id = 1;

# Security testing
SET ROLE hr_user;
SELECT * FROM employee_master; -- Should only see authorized records
```

#### 2. Documentation and Commit
```bash
# Update documentation
# Edit relevant .md files

# Commit changes
git add .
git commit -m "feat: complete [task description]"
git push origin feature-branch
```

#### 3. Cleanup
```bash
# Clean up temporary files
rm -f *.tmp *.log

# Verify clean state
git status
```

## Failure Recovery

### If Task Cannot Be Completed
1. **Document Blockers**: Clearly document what prevented completion
2. **Rollback Changes**: Revert any partial changes that might cause issues
3. **Create Follow-up Tasks**: Break down remaining work into smaller tasks
4. **Update Status**: Communicate current status and next steps
5. **Preserve Work**: Commit work-in-progress to a branch for future reference