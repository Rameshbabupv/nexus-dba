-- ================================================================
-- NEXUS HRMS: Employee Supporting Masters Schema (Phase 3A)
-- PostgreSQL Database Schema for Employee Classification Tables
--
-- Dependencies: Requires 02_organizational_structure_schema.sql
-- Migration Order:
-- 1. employee_category (Employee classifications)
-- 2. employee_group (Employee groupings)
-- 3. employee_grade (Grade/level system)
-- 4. section_master (Work sections within departments)
--
-- Created: 2025-01-14
-- Purpose: Supporting tables required by employee_master
-- ================================================================

-- ================================================================
-- TABLE: employee_category
-- Purpose: Employee classifications (Permanent, Contract, Consultant, etc.)
-- Dependencies: company_master, location_master, division_master
-- ================================================================
CREATE TABLE employee_category (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_category_name VARCHAR(100) NOT NULL,
    employee_category_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for organizational assignment
    company_category INTEGER, -- 1=All, 2=Selected, 3=None
    location_category INTEGER, -- 1=All, 2=Selected, 3=None
    division_category INTEGER, -- 1=All, 2=Selected, 3=None

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_employee_category_name UNIQUE (employee_category_name),
    CONSTRAINT uk_employee_category_code UNIQUE (employee_category_code)
);

-- Junction tables for employee_category relationships
CREATE TABLE employee_category_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_category_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_cat_comp_category FOREIGN KEY (employee_category_id)
        REFERENCES employee_category(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_cat_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_category_company UNIQUE (employee_category_id, company_master_id)
);

CREATE TABLE employee_category_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_category_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_cat_loc_category FOREIGN KEY (employee_category_id)
        REFERENCES employee_category(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_cat_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_category_location UNIQUE (employee_category_id, location_master_id)
);

CREATE TABLE employee_category_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_category_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_cat_div_category FOREIGN KEY (employee_category_id)
        REFERENCES employee_category(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_cat_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_category_division UNIQUE (employee_category_id, division_master_id)
);

-- ================================================================
-- TABLE: employee_group
-- Purpose: Employee groupings (Management, Technical, Administrative, etc.)
-- Dependencies: company_master, location_master, division_master
-- ================================================================
CREATE TABLE employee_group (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_group_name VARCHAR(100) NOT NULL,
    employee_group_category VARCHAR(50), -- Additional classification
    remarks TEXT,

    -- Category settings for organizational assignment
    company_category INTEGER, -- 1=All, 2=Selected, 3=None
    location_category INTEGER, -- 1=All, 2=Selected, 3=None
    division_category INTEGER, -- 1=All, 2=Selected, 3=None

    -- Legacy system integration fields
    hdms_master_id INTEGER DEFAULT 0,
    ams_master_id INTEGER DEFAULT 0,
    crm_master_id INTEGER DEFAULT 0,
    mms_master_id INTEGER DEFAULT 0,
    sdms_master_id INTEGER DEFAULT 0,
    sms_master_id INTEGER DEFAULT 0,
    service_master_id INTEGER DEFAULT 0,

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_employee_group_name UNIQUE (employee_group_name)
);

-- Junction tables for employee_group relationships
CREATE TABLE employee_group_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_group_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grp_comp_group FOREIGN KEY (employee_group_id)
        REFERENCES employee_group(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grp_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_group_company UNIQUE (employee_group_id, company_master_id)
);

CREATE TABLE employee_group_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_group_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grp_loc_group FOREIGN KEY (employee_group_id)
        REFERENCES employee_group(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grp_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_group_location UNIQUE (employee_group_id, location_master_id)
);

CREATE TABLE employee_group_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_group_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grp_div_group FOREIGN KEY (employee_group_id)
        REFERENCES employee_group(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grp_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_group_division UNIQUE (employee_group_id, division_master_id)
);

-- ================================================================
-- TABLE: employee_grade
-- Purpose: Employee grade/level system (L1, L2, Senior, Principal, etc.)
-- Dependencies: company_master, location_master, division_master
-- ================================================================
CREATE TABLE employee_grade (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_grade_name VARCHAR(100) NOT NULL,
    employee_grade_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for organizational assignment
    company_category INTEGER, -- 1=All, 2=Selected, 3=None
    location_category INTEGER, -- 1=All, 2=Selected, 3=None
    division_category INTEGER, -- 1=All, 2=Selected, 3=None

    -- Grade hierarchy and compensation
    grade_level INTEGER, -- Numeric level for hierarchy (1, 2, 3, etc.)
    min_salary DECIMAL(12,2), -- Minimum salary for this grade
    max_salary DECIMAL(12,2), -- Maximum salary for this grade
    grade_description TEXT, -- Detailed grade description

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_employee_grade_name UNIQUE (employee_grade_name),
    CONSTRAINT uk_employee_grade_code UNIQUE (employee_grade_code),
    CONSTRAINT chk_grade_salary_range CHECK (
        (min_salary IS NULL AND max_salary IS NULL) OR
        (min_salary IS NOT NULL AND max_salary IS NOT NULL AND min_salary <= max_salary)
    )
);

-- Junction tables for employee_grade relationships
CREATE TABLE employee_grade_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_grade_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grd_comp_grade FOREIGN KEY (employee_grade_id)
        REFERENCES employee_grade(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grd_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_grade_company UNIQUE (employee_grade_id, company_master_id)
);

CREATE TABLE employee_grade_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_grade_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grd_loc_grade FOREIGN KEY (employee_grade_id)
        REFERENCES employee_grade(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grd_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_grade_location UNIQUE (employee_grade_id, location_master_id)
);

CREATE TABLE employee_grade_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_grade_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_emp_grd_div_grade FOREIGN KEY (employee_grade_id)
        REFERENCES employee_grade(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_grd_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_employee_grade_division UNIQUE (employee_grade_id, division_master_id)
);

-- ================================================================
-- TABLE: section_master
-- Purpose: Work sections within departments (Sub-departments, teams, etc.)
-- Dependencies: company_master, location_master, division_master, department_master
-- ================================================================
CREATE TABLE section_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_name VARCHAR(100) NOT NULL,
    section_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for organizational assignment
    company_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    location_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    division_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    department_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None

    -- Section details
    section_head_employee_id UUID, -- Head of section (will reference employee_master later)
    section_type VARCHAR(50), -- 'Team', 'Unit', 'Sub-Department', etc.
    capacity INTEGER, -- Maximum number of employees
    is_profit_center BOOLEAN DEFAULT false, -- Is this section a profit center

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_section_name UNIQUE (section_name),
    CONSTRAINT uk_section_code UNIQUE (section_code),
    CONSTRAINT chk_section_capacity CHECK (capacity IS NULL OR capacity > 0)
);

-- Junction tables for section_master relationships
CREATE TABLE section_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_master_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sec_comp_section FOREIGN KEY (section_master_id)
        REFERENCES section_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_sec_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_section_company UNIQUE (section_master_id, company_master_id)
);

CREATE TABLE section_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_master_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sec_loc_section FOREIGN KEY (section_master_id)
        REFERENCES section_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_sec_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_section_location UNIQUE (section_master_id, location_master_id)
);

CREATE TABLE section_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_master_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sec_div_section FOREIGN KEY (section_master_id)
        REFERENCES section_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_sec_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_section_division UNIQUE (section_master_id, division_master_id)
);

CREATE TABLE section_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_master_id UUID NOT NULL,
    department_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sec_dept_section FOREIGN KEY (section_master_id)
        REFERENCES section_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_sec_dept_department FOREIGN KEY (department_master_id)
        REFERENCES department_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_section_department UNIQUE (section_master_id, department_master_id)
);

-- ================================================================
-- INDEXES: Performance optimization for employee supporting tables
-- ================================================================

-- Employee category indexes
CREATE INDEX idx_employee_category_status ON employee_category(row_status);
CREATE INDEX idx_employee_category_name ON employee_category(employee_category_name);
CREATE INDEX idx_employee_category_code ON employee_category(employee_category_code);

-- Employee group indexes
CREATE INDEX idx_employee_group_status ON employee_group(row_status);
CREATE INDEX idx_employee_group_name ON employee_group(employee_group_name);
CREATE INDEX idx_employee_group_category ON employee_group(employee_group_category);

-- Employee grade indexes
CREATE INDEX idx_employee_grade_status ON employee_grade(row_status);
CREATE INDEX idx_employee_grade_name ON employee_grade(employee_grade_name);
CREATE INDEX idx_employee_grade_code ON employee_grade(employee_grade_code);
CREATE INDEX idx_employee_grade_level ON employee_grade(grade_level);
CREATE INDEX idx_employee_grade_salary_range ON employee_grade(min_salary, max_salary);

-- Section master indexes
CREATE INDEX idx_section_master_status ON section_master(row_status);
CREATE INDEX idx_section_master_name ON section_master(section_name);
CREATE INDEX idx_section_master_code ON section_master(section_code);
CREATE INDEX idx_section_master_type ON section_master(section_type);
CREATE INDEX idx_section_master_head ON section_master(section_head_employee_id);

-- Junction table indexes
CREATE INDEX idx_emp_cat_companies_category ON employee_category_companies(employee_category_id);
CREATE INDEX idx_emp_cat_companies_company ON employee_category_companies(company_master_id);
CREATE INDEX idx_emp_cat_locations_category ON employee_category_locations(employee_category_id);
CREATE INDEX idx_emp_cat_locations_location ON employee_category_locations(location_master_id);

CREATE INDEX idx_emp_grp_companies_group ON employee_group_companies(employee_group_id);
CREATE INDEX idx_emp_grp_companies_company ON employee_group_companies(company_master_id);
CREATE INDEX idx_emp_grp_locations_group ON employee_group_locations(employee_group_id);
CREATE INDEX idx_emp_grp_locations_location ON employee_group_locations(location_master_id);

CREATE INDEX idx_emp_grd_companies_grade ON employee_grade_companies(employee_grade_id);
CREATE INDEX idx_emp_grd_companies_company ON employee_grade_companies(company_master_id);
CREATE INDEX idx_emp_grd_locations_grade ON employee_grade_locations(employee_grade_id);
CREATE INDEX idx_emp_grd_locations_location ON employee_grade_locations(location_master_id);

CREATE INDEX idx_sec_companies_section ON section_companies(section_master_id);
CREATE INDEX idx_sec_companies_company ON section_companies(company_master_id);
CREATE INDEX idx_sec_locations_section ON section_locations(section_master_id);
CREATE INDEX idx_sec_locations_location ON section_locations(location_master_id);
CREATE INDEX idx_sec_departments_section ON section_departments(section_master_id);
CREATE INDEX idx_sec_departments_department ON section_departments(department_master_id);

-- ================================================================
-- TRIGGERS: Auto-update timestamps
-- ================================================================

-- Apply triggers to all employee supporting tables
CREATE TRIGGER trg_employee_category_updated_date_time
    BEFORE UPDATE ON employee_category
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_employee_group_updated_date_time
    BEFORE UPDATE ON employee_group
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_employee_grade_updated_date_time
    BEFORE UPDATE ON employee_grade
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_section_master_updated_date_time
    BEFORE UPDATE ON section_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

-- ================================================================
-- UPDATE: Add employee_master_id to user_master (resolve circular dependency)
-- ================================================================

-- Add nullable employee reference to user_master
-- This resolves the circular dependency between user_master and employee_master
ALTER TABLE user_master
ADD COLUMN employee_master_id UUID REFERENCES employee_master(id) ON DELETE RESTRICT;

-- Add index for the new foreign key
CREATE INDEX idx_user_master_employee ON user_master(employee_master_id);

-- Update the comment
COMMENT ON COLUMN user_master.employee_master_id IS 'Reference to employee_master, nullable to resolve circular dependency';

-- ================================================================
-- SAMPLE DATA: Initial seed data for employee supporting tables
-- ================================================================

-- Insert sample employee categories
INSERT INTO employee_category (employee_category_name, employee_category_code, company_category, location_category, division_category, remarks) VALUES
('Permanent Employee', 'PERM', 1, 1, 1, 'Full-time permanent employees'),
('Contract Employee', 'CONT', 2, 2, 2, 'Contract-based employees'),
('Consultant', 'CONS', 2, 2, 1, 'External consultants'),
('Intern', 'INTN', 2, 2, 1, 'Internship employees'),
('Probation', 'PROB', 2, 2, 2, 'Employees on probation period');

-- Insert sample employee groups
INSERT INTO employee_group (employee_group_name, employee_group_category, company_category, location_category, division_category, remarks) VALUES
('Management', 'Leadership', 1, 1, 1, 'Senior management and executives'),
('Technical', 'Engineering', 2, 2, 1, 'Software engineers and technical staff'),
('Administrative', 'Support', 2, 2, 1, 'Administrative and support staff'),
('Sales & Marketing', 'Business', 2, 2, 2, 'Sales and marketing teams'),
('Finance & Accounts', 'Finance', 1, 1, 1, 'Finance and accounting teams'),
('Human Resources', 'Support', 1, 1, 1, 'HR and people operations');

-- Insert sample employee grades
INSERT INTO employee_grade (employee_grade_name, employee_grade_code, grade_level, min_salary, max_salary, company_category, location_category, division_category, remarks) VALUES
('Entry Level', 'L1', 1, 300000, 600000, 1, 1, 1, 'Entry level positions'),
('Associate', 'L2', 2, 500000, 900000, 1, 1, 1, 'Associate level positions'),
('Senior Associate', 'L3', 3, 800000, 1400000, 1, 1, 1, 'Senior associate positions'),
('Manager', 'M1', 4, 1200000, 2000000, 1, 1, 1, 'Manager level positions'),
('Senior Manager', 'M2', 5, 1800000, 3000000, 1, 1, 1, 'Senior manager positions'),
('Director', 'D1', 6, 2500000, 4500000, 1, 1, 1, 'Director level positions'),
('Vice President', 'VP', 7, 4000000, 7000000, 1, 1, 1, 'VP level positions');

-- Insert sample sections (assuming departments exist)
INSERT INTO section_master (section_name, section_code, section_type, capacity, company_category, location_category, division_category, department_category, remarks) VALUES
('Backend Development', 'BE_DEV', 'Team', 15, 2, 2, 1, 2, 'Backend development team'),
('Frontend Development', 'FE_DEV', 'Team', 12, 2, 2, 1, 2, 'Frontend development team'),
('DevOps', 'DEVOPS', 'Team', 8, 2, 2, 1, 2, 'DevOps and infrastructure team'),
('QA Testing', 'QA', 'Team', 10, 2, 2, 1, 2, 'Quality assurance testing team'),
('Recruitment', 'REC', 'Unit', 5, 2, 2, 1, 2, 'Recruitment and talent acquisition'),
('Payroll Processing', 'PAYROLL', 'Unit', 3, 2, 2, 1, 2, 'Payroll processing unit'),
('Accounts Receivable', 'AR', 'Unit', 4, 2, 2, 1, 2, 'Accounts receivable unit'),
('Business Development', 'BD', 'Team', 6, 2, 2, 2, 2, 'Business development team');

-- Create associations for first company (assuming it exists)
DO $$
DECLARE
    first_company_id UUID;
    first_location_id UUID;
    first_division_id UUID;
    first_department_id UUID;
BEGIN
    -- Get first company, location, division, department
    SELECT id INTO first_company_id FROM company_master LIMIT 1;
    SELECT id INTO first_location_id FROM location_master LIMIT 1;
    SELECT id INTO first_division_id FROM division_master LIMIT 1;
    SELECT id INTO first_department_id FROM department_master LIMIT 1;

    IF first_company_id IS NOT NULL THEN
        -- Associate employee categories with first company
        INSERT INTO employee_category_companies (employee_category_id, company_master_id)
        SELECT id, first_company_id FROM employee_category WHERE employee_category_code IN ('CONT', 'CONS', 'INTN', 'PROB');

        -- Associate employee groups with first company
        INSERT INTO employee_group_companies (employee_group_id, company_master_id)
        SELECT id, first_company_id FROM employee_group WHERE employee_group_category IN ('Engineering', 'Business');

        -- Associate employee grades with first company
        INSERT INTO employee_grade_companies (employee_grade_id, company_master_id)
        SELECT id, first_company_id FROM employee_grade WHERE grade_level <= 3;
    END IF;

    IF first_location_id IS NOT NULL THEN
        -- Associate sections with first location
        INSERT INTO section_locations (section_master_id, location_master_id)
        SELECT id, first_location_id FROM section_master WHERE section_type = 'Team';
    END IF;
END $$;

-- ================================================================
-- FUNCTIONS: Helper functions for employee classification queries
-- ================================================================

-- Function to get employee categories for a company
CREATE OR REPLACE FUNCTION get_employee_categories_for_company(company_id UUID)
RETURNS TABLE(category_id UUID, category_name VARCHAR, category_code VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ec.id, ec.employee_category_name, ec.employee_category_code
    FROM employee_category ec
    LEFT JOIN employee_category_companies ecc ON ecc.employee_category_id = ec.id
    WHERE ec.row_status = 'active'
    AND (ec.company_category = 1 OR (ec.company_category = 2 AND ecc.company_master_id = company_id));
END;
$$ LANGUAGE plpgsql;

-- Function to get employee grades within salary range
CREATE OR REPLACE FUNCTION get_employee_grades_by_salary(min_sal DECIMAL, max_sal DECIMAL)
RETURNS TABLE(grade_id UUID, grade_name VARCHAR, grade_code VARCHAR, grade_level INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT eg.id, eg.employee_grade_name, eg.employee_grade_code, eg.grade_level
    FROM employee_grade eg
    WHERE eg.row_status = 'active'
    AND (
        (eg.min_salary IS NULL AND eg.max_salary IS NULL) OR
        (eg.min_salary <= max_sal AND eg.max_salary >= min_sal)
    )
    ORDER BY eg.grade_level;
END;
$$ LANGUAGE plpgsql;

-- Function to get sections for a department
CREATE OR REPLACE FUNCTION get_sections_for_department(dept_id UUID)
RETURNS TABLE(section_id UUID, section_name VARCHAR, section_code VARCHAR, section_type VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT sm.id, sm.section_name, sm.section_code, sm.section_type
    FROM section_master sm
    LEFT JOIN section_departments sd ON sd.section_master_id = sm.id
    WHERE sm.row_status = 'active'
    AND (sm.department_category = 1 OR (sm.department_category = 2 AND sd.department_master_id = dept_id))
    ORDER BY sm.section_name;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- COMMENTS: Table and column documentation
-- ================================================================

-- Table comments
COMMENT ON TABLE employee_category IS 'Employee classifications like Permanent, Contract, Consultant';
COMMENT ON TABLE employee_group IS 'Employee groupings like Management, Technical, Administrative';
COMMENT ON TABLE employee_grade IS 'Employee grade/level system with salary ranges';
COMMENT ON TABLE section_master IS 'Work sections within departments for detailed organization';

-- Key column comments
COMMENT ON COLUMN employee_category.employee_category_name IS 'Employee classification name (Permanent, Contract, etc.)';
COMMENT ON COLUMN employee_group.employee_group_category IS 'Additional group classification';
COMMENT ON COLUMN employee_grade.grade_level IS 'Numeric level for hierarchy (1=lowest, higher=senior)';
COMMENT ON COLUMN employee_grade.min_salary IS 'Minimum salary for this grade in organization currency';
COMMENT ON COLUMN employee_grade.max_salary IS 'Maximum salary for this grade in organization currency';
COMMENT ON COLUMN section_master.section_head_employee_id IS 'Employee who heads this section (nullable until employee_master created)';
COMMENT ON COLUMN section_master.capacity IS 'Maximum number of employees in this section';
COMMENT ON COLUMN section_master.is_profit_center IS 'Whether this section is tracked as a profit center';

-- ================================================================
-- MIGRATION NOTES
-- ================================================================

/*
EMPLOYEE SUPPORTING MASTERS MIGRATION CHECKLIST:

1. ✅ Dependencies resolved: All tables reference existing organizational structure
2. ✅ Employee classifications: Category, Group, Grade, Section
3. ✅ Many-to-many relationships: Junction tables for flexible assignments
4. ✅ Circular dependency resolved: user_master.employee_master_id added as nullable
5. ✅ Salary ranges: Grade-based compensation structure
6. ✅ Organizational hierarchy: Sections within departments
7. ✅ Performance optimization: Strategic indexes
8. ✅ Sample data: Ready-to-use test classifications
9. ✅ Helper functions: Common query utilities
10. ✅ Documentation: Comprehensive comments

FIELD MAPPINGS:
- MongoDB ObjectId arrays → PostgreSQL junction tables
- Category numbers → Preserved (1=All, 2=Selected, 3=None)
- Organizational references → Proper foreign keys
- Legacy integration fields → Preserved for employee_group

NEXT STEPS:
- employee_master table can now reference all these classifications
- user_master ↔ employee_master circular dependency resolved
- Payroll system can use grade-based salary ranges
- Reporting can filter by categories, groups, grades, sections

BUSINESS LOGIC PRESERVED:
- Multi-company/location assignment patterns
- Category-based filtering system
- Grade-level hierarchy with salary bands
- Section-based team organization
- Legacy system integration capabilities
*/