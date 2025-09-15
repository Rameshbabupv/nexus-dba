# NEXUS HRMS - Codebase Structure

## Root Directory Structure
```
nexus-dba/
├── SQL Schema Files (numbered sequentially)
├── Documentation Files (*.md)
├── systech-dba/ (Development tools and templates)
├── .serena/ (Serena MCP configuration)
└── .claude/ (Claude Code configuration)
```

## SQL Schema Files Organization

### Foundation and Core (01-03)
- `01_nexus_foundation_schema.sql` - Core foundation schema with basic tables
- `01_nexus_monitoring_maintenance.sql` - Database monitoring and maintenance
- `01_nexus_performance_indexes.sql` - Performance optimization indexes
- `01_nexus_security_framework.sql` - Security framework and RLS policies
- `02_organizational_structure_schema.sql` - Company structure and departments
- `03a_employee_supporting_masters_schema.sql` - Employee supporting master data
- `03b_employee_core_schema.sql` - Core employee master tables
- `03c_employee_sample_data.sql` - Sample employee data

### Module-Specific Schemas (04-09)
- `04_attendance_management_schema.sql` - Attendance tracking system
- `04b_attendance_sample_data.sql` - Attendance sample data
- `05_leave_management_schema.sql` - Leave management system
- `05b_leave_sample_data.sql` - Leave sample data
- `06_payroll_management_schema.sql` - Payroll processing system
- `06b_payroll_sample_data.sql` - Payroll sample data
- `07_performance_management_schema.sql` - Performance appraisal system
- `07b_performance_sample_data.sql` - Performance sample data
- `08_recruitment_management_schema.sql` - Recruitment and hiring system
- `08b_recruitment_sample_data.sql` - Recruitment sample data
- `09_training_development_schema.sql` - Training and development system
- `09b_training_development_sample_data.sql` - Training sample data

### Alternate Schema Versions
- `02_nexus_attendance_schema.sql` - Alternative attendance schema
- `03_nexus_leave_schema.sql` - Alternative leave schema
- `04_nexus_payroll_schema.sql` - Alternative payroll schema
- `05_nexus_performance_schema.sql` - Alternative performance schema
- `06_nexus_recruitment_schema.sql` - Alternative recruitment schema

## Documentation Files
- `01_recommendations.md` - Comprehensive architecture recommendations
- `01_spring_boot_database_guidelines.md` - Spring Boot integration guidelines

## Development Tools (systech-dba/)
```
systech-dba/
├── scripts/
│   ├── common.sh - Common utility functions
│   ├── setup-plan.sh - Environment setup
│   ├── check-task-prerequisites.sh - Prerequisite validation
│   ├── update-agent-context.sh - Context management
│   ├── get-feature-paths.sh - Feature path utilities
│   └── create-new-feature.sh - Feature creation automation
├── templates/
│   ├── agent-file-template.md - Agent file template
│   ├── tasks-template.md - Task template
│   ├── spec-template.md - Specification template
│   └── plan-template.md - Plan template
├── memory/ - Project memory files
└── .claude/commands/ - Claude-specific commands
```

## Schema Dependencies and Migration Order

### Recommended Migration Sequence
1. **Foundation**: `01_nexus_foundation_schema.sql`
2. **Security**: `01_nexus_security_framework.sql`
3. **Performance**: `01_nexus_performance_indexes.sql`
4. **Organization**: `02_organizational_structure_schema.sql`
5. **Employee Supporting**: `03a_employee_supporting_masters_schema.sql`
6. **Employee Core**: `03b_employee_core_schema.sql`
7. **Module Schemas**: `04_attendance_*`, `05_leave_*`, etc.
8. **Sample Data**: `*_sample_data.sql` files (development only)

## Key Design Patterns

### Multi-Schema Architecture
- **nexus_foundation**: Core company and user management
- **nexus_employee**: Employee-related tables
- **nexus_attendance**: Attendance tracking
- **nexus_leave**: Leave management
- **nexus_payroll**: Payroll processing
- **nexus_performance**: Performance management
- **nexus_recruitment**: Recruitment system
- **nexus_audit**: Audit and compliance
- **nexus_config**: Configuration management

### File Naming Conventions
- **Schema Files**: `{number}_{module_name}_schema.sql`
- **Sample Data**: `{number}b_{module_name}_sample_data.sql`
- **Alternative Versions**: `{number}_{nexus_module_name}_schema.sql`

### Feature Branch Structure
- **Branch Naming**: `{number}-{feature-name}` (e.g., `001-employee-management`)
- **Feature Directory**: `specs/{branch-name}/`
- **Required Files**: `spec.md`, `plan.md`, `tasks.md`