# NEXUS HRMS - Suggested Commands

## Database Development Commands

### PostgreSQL Database Commands
```bash
# Connect to PostgreSQL database
psql -h localhost -U postgres -d nexus_hrms

# Run schema migration files in order
psql -h localhost -U postgres -d nexus_hrms -f 01_nexus_foundation_schema.sql
psql -h localhost -U postgres -d nexus_hrms -f 02_organizational_structure_schema.sql
psql -h localhost -U postgres -d nexus_hrms -f 03a_employee_supporting_masters_schema.sql

# Check database schema and tables
\dt nexus_foundation.*
\dt nexus_employee.*

# View table structure
\d nexus_foundation.company_master
\d nexus_foundation.employee_master

# Check indexes and performance
\di nexus_foundation.*
```

### Project Management Commands (systech-dba scripts)
```bash
# Navigate to scripts directory
cd systech-dba/scripts/

# Set up development environment
./setup-plan.sh

# Check feature branch prerequisites
./check-task-prerequisites.sh

# Create new feature branch structure
./create-new-feature.sh

# Get feature paths for current branch
./get-feature-paths.sh

# Update agent context
./update-agent-context.sh
```

### Git Workflow Commands
```bash
# Feature branch naming convention
git checkout -b 001-feature-name
git checkout -b 002-another-feature

# Standard git operations
git status
git add .
git commit -m "feat: descriptive commit message"
git push origin feature-branch-name
```

### Database Performance and Monitoring
```bash
# Check slow queries
SELECT query, calls, mean_time, total_time 
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC LIMIT 10;

# Check index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC;

# Monitor active connections
SELECT state, count(*) as connection_count
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state;
```

### Development Utilities
```bash
# Generate sample data (when files exist)
psql -h localhost -U postgres -d nexus_hrms -f 03c_employee_sample_data.sql
psql -h localhost -U postgres -d nexus_hrms -f 04b_attendance_sample_data.sql

# Backup database schema
pg_dump -h localhost -U postgres -s nexus_hrms > nexus_schema_backup.sql

# Restore from backup
psql -h localhost -U postgres -d nexus_hrms_new -f nexus_schema_backup.sql
```

## System-Specific Commands (Darwin/macOS)

### PostgreSQL Installation and Management
```bash
# Install PostgreSQL via Homebrew
brew install postgresql

# Start PostgreSQL service
brew services start postgresql

# Stop PostgreSQL service
brew services stop postgresql

# Check PostgreSQL status
brew services list | grep postgresql
```

### File Operations
```bash
# Find files (using macOS-compatible commands)
find . -name "*.sql" -type f
find . -name "*schema*" -type f

# Search content in files
grep -r "company_master" .
grep -r "CREATE TABLE" . --include="*.sql"

# Directory listing with details
ls -la
ls -la *.sql
```

### Text Processing
```bash
# View file contents
cat filename.sql
head -50 filename.sql
tail -20 filename.sql

# Search and filter
grep -i "create table" *.sql
grep -n "primary key" *.sql
```

## Task Completion Commands

### When Completing Database Tasks
1. **Test Schema**: Run the SQL files to ensure they execute without errors
2. **Validate Constraints**: Check that all foreign keys and constraints work properly
3. **Performance Check**: Ensure indexes are created and queries perform well
4. **Documentation Update**: Update any relevant documentation files
5. **Git Commit**: Commit changes with descriptive messages following the established patterns