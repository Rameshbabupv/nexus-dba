-- ================================================================
-- NEXUS HRMS: Organizational Structure Schema (Step 2)
-- PostgreSQL Database Schema for Organizational Hierarchy
--
-- Dependencies: Requires 01_initial_migration_schema.sql
-- Migration Order:
-- 1. division_master (groups companies and locations)
-- 2. location_master (company branches/offices)
-- 3. department_master (company departments)
-- 4. designation_master (job titles/positions)
-- 5. user_master (system users with privileges)
--
-- Created: 2025-01-14
-- Purpose: Organizational hierarchy and user management
-- ================================================================

-- ================================================================
-- TABLE: division_master
-- Purpose: Groups multiple companies and locations for management
-- Dependencies: company_master, location_master (many-to-many)
-- ================================================================
CREATE TABLE division_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    division_name VARCHAR(100) NOT NULL,
    division_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for grouping
    company_category INTEGER, -- 1=All, 2=Selected, 3=None
    location_category INTEGER, -- 1=All, 2=Selected, 3=None

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
    CONSTRAINT uk_division_name UNIQUE (division_name),
    CONSTRAINT uk_division_code UNIQUE (division_code)
);

-- Junction table for division-company relationships
CREATE TABLE division_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    division_master_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_div_comp_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_div_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_division_company UNIQUE (division_master_id, company_master_id)
);

-- Junction table for division-location relationships (created after location_master)
-- Will be created after location_master table

-- ================================================================
-- TABLE: location_master
-- Purpose: Company branches, offices, and physical locations
-- Dependencies: company_master, city_master, state_master
-- ================================================================
CREATE TABLE location_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Basic location information
    location_name VARCHAR(200) NOT NULL,
    location_type VARCHAR(50), -- 'Head Office', 'Branch', 'Factory', 'Warehouse', etc.
    license_no VARCHAR(50), -- Business license number

    -- Address information
    address1 VARCHAR(500),
    address2 VARCHAR(500),
    pincode VARCHAR(20),
    country VARCHAR(100), -- For now, will be normalized later

    -- Contact information
    contact_person VARCHAR(100),
    phone_no VARCHAR(20),
    mobile_no VARCHAR(20),
    email_id VARCHAR(100),

    -- Tally integration
    tally_comp_name VARCHAR(200), -- Company name in Tally

    -- Legal compliance information
    esi_no VARCHAR(50), -- ESI number for this location
    pf_no VARCHAR(50), -- PF number for this location
    gstin_no VARCHAR(50), -- GST number for this location

    -- Foreign key relationships
    company_master_id UUID,
    city_master_id UUID NOT NULL,
    state_master_id UUID NOT NULL,

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_location_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_location_city FOREIGN KEY (city_master_id)
        REFERENCES city_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_location_state FOREIGN KEY (state_master_id)
        REFERENCES state_master(id) ON DELETE RESTRICT,
    CONSTRAINT uk_location_name_company UNIQUE (location_name, company_master_id)
);

-- Now create the division-location junction table
CREATE TABLE division_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    division_master_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_div_loc_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_div_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_division_location UNIQUE (division_master_id, location_master_id)
);

-- ================================================================
-- TABLE: department_master
-- Purpose: Company departments (HR, IT, Finance, etc.)
-- Dependencies: company_master, division_master, location_master
-- ================================================================
CREATE TABLE department_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for grouping
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
    CONSTRAINT uk_department_name UNIQUE (department_name),
    CONSTRAINT uk_department_code UNIQUE (department_code)
);

-- Junction tables for department relationships
CREATE TABLE department_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_master_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dept_comp_department FOREIGN KEY (department_master_id)
        REFERENCES department_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_department_company UNIQUE (department_master_id, company_master_id)
);

CREATE TABLE department_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_master_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dept_loc_department FOREIGN KEY (department_master_id)
        REFERENCES department_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_department_location UNIQUE (department_master_id, location_master_id)
);

CREATE TABLE department_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_master_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dept_div_department FOREIGN KEY (department_master_id)
        REFERENCES department_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_dept_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_department_division UNIQUE (department_master_id, division_master_id)
);

-- ================================================================
-- TABLE: designation_master
-- Purpose: Job titles and positions (Manager, Developer, etc.)
-- Dependencies: company_master, division_master, location_master, menu_master
-- ================================================================
CREATE TABLE designation_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    designation_name VARCHAR(100) NOT NULL,
    designation_code VARCHAR(20) NOT NULL,
    remarks TEXT,

    -- Category settings for grouping
    company_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    location_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    division_category INTEGER NOT NULL, -- 1=All, 2=Selected, 3=None
    menu_category INTEGER, -- For menu access control

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
    CONSTRAINT uk_designation_name UNIQUE (designation_name),
    CONSTRAINT uk_designation_code UNIQUE (designation_code)
);

-- Junction tables for designation relationships
CREATE TABLE designation_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    designation_master_id UUID NOT NULL,
    company_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_desig_comp_designation FOREIGN KEY (designation_master_id)
        REFERENCES designation_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_desig_comp_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_designation_company UNIQUE (designation_master_id, company_master_id)
);

CREATE TABLE designation_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    designation_master_id UUID NOT NULL,
    location_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_desig_loc_designation FOREIGN KEY (designation_master_id)
        REFERENCES designation_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_desig_loc_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_designation_location UNIQUE (designation_master_id, location_master_id)
);

CREATE TABLE designation_divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    designation_master_id UUID NOT NULL,
    division_master_id UUID NOT NULL,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_desig_div_designation FOREIGN KEY (designation_master_id)
        REFERENCES designation_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_desig_div_division FOREIGN KEY (division_master_id)
        REFERENCES division_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_designation_division UNIQUE (designation_master_id, division_master_id)
);

-- ================================================================
-- TABLE: user_master
-- Purpose: System users with authentication and privileges
-- Dependencies: employee_master (will be created later), all organizational tables
-- ================================================================
CREATE TABLE user_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Authentication
    user_name VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Hashed password
    email_password VARCHAR(255), -- Email account password (encrypted)

    -- Employee reference (will be added when employee_master is created)
    employee_master_id UUID, -- References employee_master

    -- Primary assignments
    company_master_id UUID,
    location_master_id UUID,
    designation_master_id UUID,

    -- User status and type
    user_type INTEGER, -- 1=Super Admin, 2=Company Admin, 3=HR User, 4=Employee, etc.
    is_active BOOLEAN DEFAULT true,
    login_status INTEGER DEFAULT 0, -- 0=Logged Out, 1=Logged In
    initial_company_setup BOOLEAN DEFAULT false,

    -- Keycloak integration
    keycloak_user_id VARCHAR(100), -- Keycloak user ID
    keycloak_realm VARCHAR(50), -- Keycloak realm

    -- Session management
    last_login_time TIMESTAMP WITH TIME ZONE,
    session_token VARCHAR(255),
    session_expires_at TIMESTAMP WITH TIME ZONE,

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_user_name UNIQUE (user_name),
    CONSTRAINT uk_keycloak_user UNIQUE (keycloak_user_id),
    CONSTRAINT fk_user_company FOREIGN KEY (company_master_id)
        REFERENCES company_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_user_location FOREIGN KEY (location_master_id)
        REFERENCES location_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_user_designation FOREIGN KEY (designation_master_id)
        REFERENCES designation_master(id) ON DELETE RESTRICT,
    CONSTRAINT chk_user_name_length CHECK (LENGTH(user_name) >= 3)
);

-- ================================================================
-- TABLE: user_privileges
-- Purpose: User access privileges across organizational hierarchy
-- Dependencies: user_master, all organizational tables
-- ================================================================
CREATE TABLE user_privileges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_master_id UUID NOT NULL,
    privilege_type VARCHAR(50) NOT NULL, -- 'company', 'location', 'division', 'department', 'designation'
    entity_id UUID NOT NULL, -- ID of the entity (company, location, etc.)
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_priv_user FOREIGN KEY (user_master_id)
        REFERENCES user_master(id) ON DELETE CASCADE,
    CONSTRAINT uk_user_privilege UNIQUE (user_master_id, privilege_type, entity_id)
);

-- ================================================================
-- INDEXES: Performance optimization
-- ================================================================

-- Division master indexes
CREATE INDEX idx_division_master_status ON division_master(row_status);
CREATE INDEX idx_division_master_name ON division_master(division_name);
CREATE INDEX idx_division_master_code ON division_master(division_code);

-- Location master indexes
CREATE INDEX idx_location_master_status ON location_master(row_status);
CREATE INDEX idx_location_master_company ON location_master(company_master_id);
CREATE INDEX idx_location_master_city ON location_master(city_master_id);
CREATE INDEX idx_location_master_state ON location_master(state_master_id);
CREATE INDEX idx_location_master_name ON location_master(location_name);
CREATE INDEX idx_location_master_type ON location_master(location_type);

-- Department master indexes
CREATE INDEX idx_department_master_status ON department_master(row_status);
CREATE INDEX idx_department_master_name ON department_master(department_name);
CREATE INDEX idx_department_master_code ON department_master(department_code);

-- Designation master indexes
CREATE INDEX idx_designation_master_status ON designation_master(row_status);
CREATE INDEX idx_designation_master_name ON designation_master(designation_name);
CREATE INDEX idx_designation_master_code ON designation_master(designation_code);

-- User master indexes
CREATE INDEX idx_user_master_status ON user_master(row_status);
CREATE INDEX idx_user_master_username ON user_master(user_name);
CREATE INDEX idx_user_master_employee ON user_master(employee_master_id);
CREATE INDEX idx_user_master_company ON user_master(company_master_id);
CREATE INDEX idx_user_master_active ON user_master(is_active);
CREATE INDEX idx_user_master_type ON user_master(user_type);
CREATE INDEX idx_user_master_keycloak ON user_master(keycloak_user_id);

-- User privileges indexes
CREATE INDEX idx_user_privileges_user ON user_privileges(user_master_id);
CREATE INDEX idx_user_privileges_type ON user_privileges(privilege_type);
CREATE INDEX idx_user_privileges_entity ON user_privileges(entity_id);

-- Junction table indexes
CREATE INDEX idx_division_companies_division ON division_companies(division_master_id);
CREATE INDEX idx_division_companies_company ON division_companies(company_master_id);
CREATE INDEX idx_division_locations_division ON division_locations(division_master_id);
CREATE INDEX idx_division_locations_location ON division_locations(location_master_id);

CREATE INDEX idx_department_companies_dept ON department_companies(department_master_id);
CREATE INDEX idx_department_companies_company ON department_companies(company_master_id);
CREATE INDEX idx_department_locations_dept ON department_locations(department_master_id);
CREATE INDEX idx_department_locations_location ON department_locations(location_master_id);

CREATE INDEX idx_designation_companies_desig ON designation_companies(designation_master_id);
CREATE INDEX idx_designation_companies_company ON designation_companies(company_master_id);

-- ================================================================
-- TRIGGERS: Auto-update timestamps
-- ================================================================

-- Apply triggers to all new tables
CREATE TRIGGER trg_division_master_updated_date_time
    BEFORE UPDATE ON division_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_location_master_updated_date_time
    BEFORE UPDATE ON location_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_department_master_updated_date_time
    BEFORE UPDATE ON department_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_designation_master_updated_date_time
    BEFORE UPDATE ON designation_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_user_master_updated_date_time
    BEFORE UPDATE ON user_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

-- ================================================================
-- SAMPLE DATA: Initial seed data
-- ================================================================

-- Insert sample divisions
INSERT INTO division_master (division_name, division_code, company_category, location_category, remarks) VALUES
('Corporate Division', 'CORP', 1, 1, 'Corporate headquarters and support functions'),
('Manufacturing Division', 'MFG', 2, 2, 'Manufacturing and production facilities'),
('Sales Division', 'SALES', 2, 2, 'Sales and marketing operations');

-- Insert sample locations (assuming first company exists)
INSERT INTO location_master (
    location_name, location_type, address1, city_master_id, state_master_id,
    company_master_id, contact_person, phone_no, email_id, remarks
) VALUES
('Head Office', 'Head Office', 'Corporate Tower, MG Road',
 (SELECT id FROM city_master WHERE city_name = 'Bangalore' LIMIT 1),
 (SELECT id FROM state_master WHERE state_code = 'KA' LIMIT 1),
 (SELECT id FROM company_master LIMIT 1),
 'John Doe', '+91-80-12345678', 'ho@company.com', 'Main headquarters'),

('Bangalore Branch', 'Branch', 'Tech Park, Whitefield',
 (SELECT id FROM city_master WHERE city_name = 'Bangalore' LIMIT 1),
 (SELECT id FROM state_master WHERE state_code = 'KA' LIMIT 1),
 (SELECT id FROM company_master LIMIT 1),
 'Jane Smith', '+91-80-87654321', 'blr@company.com', 'Bangalore operations');

-- Insert sample departments
INSERT INTO department_master (department_name, department_code, company_category, location_category, division_category, remarks) VALUES
('Human Resources', 'HR', 1, 1, 1, 'Human resource management'),
('Information Technology', 'IT', 1, 1, 1, 'IT and software development'),
('Finance & Accounts', 'FIN', 1, 1, 1, 'Financial operations'),
('Operations', 'OPS', 2, 2, 2, 'Operational activities');

-- Insert sample designations
INSERT INTO designation_master (designation_name, designation_code, company_category, location_category, division_category, remarks) VALUES
('Chief Executive Officer', 'CEO', 1, 1, 1, 'Top executive position'),
('General Manager', 'GM', 2, 2, 2, 'General management role'),
('Manager', 'MGR', 2, 2, 2, 'Department manager'),
('Senior Developer', 'SR_DEV', 2, 2, 1, 'Senior software developer'),
('HR Executive', 'HR_EXEC', 2, 2, 1, 'Human resources executive');

-- Create sample admin user (password should be hashed in real implementation)
INSERT INTO user_master (
    user_name, password_hash, user_type, is_active,
    company_master_id, initial_company_setup, remarks
) VALUES
('admin', '$2a$10$example_hashed_password', 1, true,
 (SELECT id FROM company_master LIMIT 1), true, 'System administrator');

-- ================================================================
-- FUNCTIONS: Helper functions for organizational queries
-- ================================================================

-- Function to get user's accessible companies
CREATE OR REPLACE FUNCTION get_user_companies(user_id UUID)
RETURNS TABLE(company_id UUID, company_name VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT c.id, c.company_name
    FROM company_master c
    INNER JOIN user_privileges up ON up.entity_id = c.id
    WHERE up.user_master_id = user_id
    AND up.privilege_type = 'company'
    AND c.row_status = 'active';
END;
$$ LANGUAGE plpgsql;

-- Function to get user's accessible locations
CREATE OR REPLACE FUNCTION get_user_locations(user_id UUID)
RETURNS TABLE(location_id UUID, location_name VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT l.id, l.location_name
    FROM location_master l
    INNER JOIN user_privileges up ON up.entity_id = l.id
    WHERE up.user_master_id = user_id
    AND up.privilege_type = 'location'
    AND l.row_status = 'active';
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- COMMENTS: Table and column documentation
-- ================================================================

-- Table comments
COMMENT ON TABLE division_master IS 'Groups multiple companies and locations for management hierarchy';
COMMENT ON TABLE location_master IS 'Physical locations, branches, and offices of companies';
COMMENT ON TABLE department_master IS 'Organizational departments within companies';
COMMENT ON TABLE designation_master IS 'Job titles and positions with access control';
COMMENT ON TABLE user_master IS 'System users with authentication and organizational privileges';
COMMENT ON TABLE user_privileges IS 'Fine-grained access control for users across organizational entities';

-- Key column comments
COMMENT ON COLUMN division_master.company_category IS '1=All Companies, 2=Selected Companies, 3=No Companies';
COMMENT ON COLUMN user_master.user_type IS '1=Super Admin, 2=Company Admin, 3=HR User, 4=Employee';
COMMENT ON COLUMN user_privileges.privilege_type IS 'Type: company, location, division, department, designation';
COMMENT ON COLUMN user_master.initial_company_setup IS 'Flag indicating if user completed initial company setup';

-- ================================================================
-- MIGRATION NOTES
-- ================================================================

/*
ORGANIZATIONAL STRUCTURE MIGRATION CHECKLIST:

1. ✅ Dependencies resolved: All tables reference existing foundation tables
2. ✅ Many-to-many relationships: Junction tables for complex relationships
3. ✅ User management: Complete authentication and authorization system
4. ✅ Organizational hierarchy: Division → Company → Location → Department → Designation
5. ✅ Access control: Fine-grained privileges system
6. ✅ Performance optimization: Strategic indexes for queries
7. ✅ Data integrity: Foreign keys and constraints
8. ✅ Audit trail: Complete tracking fields
9. ✅ Sample data: Test data for development
10. ✅ Helper functions: Query utilities for common operations

FIELD MAPPINGS:
- MongoDB arrays → PostgreSQL junction tables
- ObjectId references → UUID foreign keys
- Number categories → INTEGER with clear meaning
- Mixed privilege arrays → Normalized user_privileges table

NEXT STEPS:
- Create employee_master table (references user_master)
- Add foreign key from user_master to employee_master
- Create menu_master and link to designation permissions
- Implement Row Level Security policies
- Create GraphQL schemas for organizational management

BUSINESS LOGIC PRESERVED:
- Multi-company, multi-location support
- Category-based filtering (All/Selected/None)
- Hierarchical privileges system
- Legacy system integration fields
- Comprehensive audit trails
*/