# NEXUS HRMS - Code Style & Conventions

## Database Schema Conventions

### Naming Conventions
- **Schema Names**: snake_case with `nexus_` prefix (e.g., `nexus_foundation`, `nexus_employee`)
- **Table Names**: snake_case, descriptive names (e.g., `employee_master`, `company_master`)
- **Column Names**: snake_case with clear, descriptive names
- **Primary Keys**: Use `id` as primary key column name, BIGINT type
- **Foreign Keys**: Named as `{referenced_table}_id` (e.g., `company_id`, `employee_id`)

### Data Types and Constraints
- **Primary Keys**: BIGINT with GENERATED ALWAYS AS IDENTITY (not UUIDs for performance)
- **Timestamps**: Use TIMESTAMP WITH TIME ZONE, default to UTC
- **Enums**: Use PostgreSQL ENUM types for fixed value sets
- **Text Fields**: VARCHAR with appropriate length limits, not unlimited TEXT
- **Status Fields**: ENUM types (e.g., 'active', 'inactive', 'terminated')

### Table Structure Standards
```sql
-- Standard table pattern
CREATE TABLE schema_name.table_name (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,  -- Multi-tenant isolation
    -- Business columns
    status status_enum NOT NULL DEFAULT 'active',
    -- Audit columns (mandatory)
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    version INTEGER NOT NULL DEFAULT 1  -- Optimistic locking
);
```

### Index Naming Conventions
- **Primary Indexes**: `pk_{table_name}` (automatic)
- **Foreign Key Indexes**: `idx_{table_name}_{column_name}`
- **Covering Indexes**: `idx_{table_name}_{purpose}_covering`
- **Partial Indexes**: `idx_{table_name}_{condition}`
- **GIN Indexes**: `idx_{table_name}_{column_name}_gin`

### Security and Audit Standards
- **Row Level Security**: All multi-tenant tables must have RLS policies
- **Audit Trails**: All business tables require audit columns (created_at, created_by, etc.)
- **Sensitive Data**: Use encryption for PII fields (SSN, bank accounts, etc.)
- **Comments**: All tables, important columns, and complex constraints must have comments

### SQL Formatting
- **Keywords**: UPPERCASE (CREATE, TABLE, PRIMARY KEY, etc.)
- **Identifiers**: lowercase with underscores
- **Indentation**: 4 spaces for nested elements
- **Line Length**: Max 120 characters
- **Comments**: Use `--` for single line, `/* */` for block comments

## File Organization
- **Schema Files**: Numbered sequentially (01_, 02_, 03_, etc.)
- **Migration Order**: Dependencies clearly documented in file headers
- **Sample Data**: Separate files with `_sample_data.sql` suffix
- **Documentation**: Comprehensive headers with purpose, dependencies, and creation date