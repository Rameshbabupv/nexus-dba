-- ================================================================
-- NEXUS HRMS: Initial Migration Schema (Step 1)
-- PostgreSQL Database Schema for Company Master and Dependencies
--
-- Migration Order:
-- 1. countryMaster (no dependencies)
-- 2. stateMaster (depends on countryMaster)
-- 3. cityMaster (depends on stateMaster)
-- 4. companyMaster (depends on countryMaster, stateMaster, cityMaster)
--
-- Created: 2025-01-14
-- Purpose: Foundation tables for NEXUS HRMS system
-- ================================================================

-- Enable UUID extension for ID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enums for common status values
CREATE TYPE row_status AS ENUM ('active', 'inactive', 'deleted');

-- ================================================================
-- TABLE: country_master
-- Purpose: Master table for countries
-- Dependencies: None
-- ================================================================
CREATE TABLE country_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(10), -- ISO country code
    currency_type VARCHAR(10), -- Currency code (USD, INR, etc.)
    remarks TEXT,

    -- Region reference (for future expansion)
    region_master_id UUID, -- Reference to region_master when created

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
    created_user UUID, -- Reference to user_master when created
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID, -- Reference to user_master when created
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uk_country_name UNIQUE (country_name),
    CONSTRAINT uk_country_code UNIQUE (country_code)
);

-- Create indexes for country_master
CREATE INDEX idx_country_master_status ON country_master(row_status);
CREATE INDEX idx_country_master_name ON country_master(country_name);
CREATE INDEX idx_country_master_code ON country_master(country_code);

-- ================================================================
-- TABLE: state_master
-- Purpose: Master table for states/provinces
-- Dependencies: country_master
-- ================================================================
CREATE TABLE state_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state_name VARCHAR(100) NOT NULL,
    state_code VARCHAR(10), -- State/province code
    remarks TEXT,

    -- Foreign keys
    country_master_id UUID NOT NULL,

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
    CONSTRAINT fk_state_country FOREIGN KEY (country_master_id)
        REFERENCES country_master(id) ON DELETE RESTRICT,
    CONSTRAINT uk_state_name_country UNIQUE (state_name, country_master_id),
    CONSTRAINT uk_state_code_country UNIQUE (state_code, country_master_id)
);

-- Create indexes for state_master
CREATE INDEX idx_state_master_status ON state_master(row_status);
CREATE INDEX idx_state_master_country ON state_master(country_master_id);
CREATE INDEX idx_state_master_name ON state_master(state_name);
CREATE INDEX idx_state_master_code ON state_master(state_code);

-- ================================================================
-- TABLE: city_master
-- Purpose: Master table for cities
-- Dependencies: state_master, country_master (indirect)
-- ================================================================
CREATE TABLE city_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_name VARCHAR(100) NOT NULL,
    city_code VARCHAR(10), -- City code
    remarks TEXT,

    -- Foreign keys
    state_master_id UUID NOT NULL,

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
    CONSTRAINT fk_city_state FOREIGN KEY (state_master_id)
        REFERENCES state_master(id) ON DELETE RESTRICT,
    CONSTRAINT uk_city_name_state UNIQUE (city_name, state_master_id)
);

-- Create indexes for city_master
CREATE INDEX idx_city_master_status ON city_master(row_status);
CREATE INDEX idx_city_master_state ON city_master(state_master_id);
CREATE INDEX idx_city_master_name ON city_master(city_name);
CREATE INDEX idx_city_master_code ON city_master(city_code);

-- ================================================================
-- TABLE: company_master
-- Purpose: Master table for companies - Core business entity
-- Dependencies: country_master, state_master, city_master
-- ================================================================
CREATE TABLE company_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Basic company information
    company_name VARCHAR(200) NOT NULL,
    company_prefix VARCHAR(10), -- Company code prefix for employee IDs
    address1 VARCHAR(500),
    address2 VARCHAR(500),
    pincode VARCHAR(20),
    email_id VARCHAR(100),
    website VARCHAR(200),

    -- Contact information
    contact_person VARCHAR(100),
    designation VARCHAR(100),
    mobile_no VARCHAR(20),
    office_mobile VARCHAR(20),
    fax_no VARCHAR(20),

    -- Location references
    country_master_id UUID,
    state_master_id UUID,
    city_master_id UUID,

    -- Financial and currency
    currency_master VARCHAR(10), -- Currency code

    -- Legal and compliance information
    cin_no VARCHAR(50), -- Corporate Identification Number
    lin_no VARCHAR(50), -- Labor Identification Number
    gstin_no VARCHAR(50), -- GST Identification Number
    tan_no VARCHAR(50), -- Tax Deduction Account Number
    pan_no VARCHAR(50), -- Permanent Account Number
    pf_no VARCHAR(50), -- Provident Fund number
    esi_no VARCHAR(50), -- Employee State Insurance number
    iso_no VARCHAR(50), -- ISO certification number
    api_certification VARCHAR(100), -- API certification details

    -- PF (Provident Fund) configuration
    enable_pf BOOLEAN DEFAULT false,
    pf_amount DECIMAL(10,2),
    pf_employee DECIMAL(5,2), -- Employee PF contribution percentage
    pf_employer DECIMAL(5,2), -- Employer PF contribution percentage
    employee_pension DECIMAL(5,2), -- Employee pension contribution percentage
    pf_effective_from DATE,

    -- ESI (Employee State Insurance) configuration
    enable_esi BOOLEAN DEFAULT false,
    esi_amount DECIMAL(10,2),
    esi_employee DECIMAL(5,2), -- Employee ESI contribution percentage
    esi_employer DECIMAL(5,2), -- Employer ESI contribution percentage
    esi_effective_from DATE,

    -- Financial year configuration
    starts_from DATE, -- Financial year start date
    ends_by DATE, -- Financial year end date

    -- Payroll configuration
    salary_days INTEGER NOT NULL DEFAULT 30, -- Standard salary calculation days
    calendar_days BOOLEAN DEFAULT false, -- Use calendar days for calculations
    service_age INTEGER, -- Service age configuration
    emp_year INTEGER, -- Employee year configuration

    -- Feature flags
    ot_incentives BOOLEAN DEFAULT false, -- Enable overtime incentives
    bonus BOOLEAN DEFAULT false, -- Enable bonus calculations
    gratuity BOOLEAN DEFAULT false, -- Enable gratuity calculations
    factories_act BOOLEAN DEFAULT false, -- Factories Act compliance
    capture_location BOOLEAN DEFAULT false, -- Enable location capture
    multi_copy BOOLEAN DEFAULT false, -- Enable multiple copies
    select_copy VARCHAR(50), -- Copy selection configuration

    -- Additional configuration
    remarks TEXT,
    print_table_dls JSONB, -- Print table configurations as JSON

    -- Audit fields
    row_status row_status DEFAULT 'active',
    created_user UUID,
    created_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_user UUID,
    updated_date_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_company_country FOREIGN KEY (country_master_id)
        REFERENCES country_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_company_state FOREIGN KEY (state_master_id)
        REFERENCES state_master(id) ON DELETE RESTRICT,
    CONSTRAINT fk_company_city FOREIGN KEY (city_master_id)
        REFERENCES city_master(id) ON DELETE RESTRICT,
    CONSTRAINT uk_company_name UNIQUE (company_name),
    CONSTRAINT uk_company_prefix UNIQUE (company_prefix),
    CONSTRAINT uk_company_cin UNIQUE (cin_no),
    CONSTRAINT uk_company_gstin UNIQUE (gstin_no),
    CONSTRAINT uk_company_pan UNIQUE (pan_no),

    -- Check constraints
    CONSTRAINT chk_salary_days CHECK (salary_days > 0 AND salary_days <= 31),
    CONSTRAINT chk_pf_percentages CHECK (
        (pf_employee IS NULL OR pf_employee >= 0) AND
        (pf_employer IS NULL OR pf_employer >= 0) AND
        (employee_pension IS NULL OR employee_pension >= 0)
    ),
    CONSTRAINT chk_esi_percentages CHECK (
        (esi_employee IS NULL OR esi_employee >= 0) AND
        (esi_employer IS NULL OR esi_employer >= 0)
    ),
    CONSTRAINT chk_financial_year CHECK (
        (starts_from IS NULL AND ends_by IS NULL) OR
        (starts_from IS NOT NULL AND ends_by IS NOT NULL AND starts_from < ends_by)
    )
);

-- Create indexes for company_master
CREATE INDEX idx_company_master_status ON company_master(row_status);
CREATE INDEX idx_company_master_name ON company_master(company_name);
CREATE INDEX idx_company_master_prefix ON company_master(company_prefix);
CREATE INDEX idx_company_master_country ON company_master(country_master_id);
CREATE INDEX idx_company_master_state ON company_master(state_master_id);
CREATE INDEX idx_company_master_city ON company_master(city_master_id);
CREATE INDEX idx_company_master_cin ON company_master(cin_no);
CREATE INDEX idx_company_master_gstin ON company_master(gstin_no);
CREATE INDEX idx_company_master_pan ON company_master(pan_no);

-- ================================================================
-- TRIGGERS: Auto-update timestamps
-- ================================================================

-- Function to update the updated_date_time column
CREATE OR REPLACE FUNCTION update_updated_date_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_date_time = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER trg_country_master_updated_date_time
    BEFORE UPDATE ON country_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_state_master_updated_date_time
    BEFORE UPDATE ON state_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_city_master_updated_date_time
    BEFORE UPDATE ON city_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

CREATE TRIGGER trg_company_master_updated_date_time
    BEFORE UPDATE ON company_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_date_time();

-- ================================================================
-- SAMPLE DATA: Initial seed data
-- ================================================================

-- Insert sample countries
INSERT INTO country_master (country_name, country_code, currency_type, remarks) VALUES
('India', 'IN', 'INR', 'Republic of India'),
('United States', 'US', 'USD', 'United States of America'),
('United Kingdom', 'GB', 'GBP', 'United Kingdom');

-- Insert sample states for India
INSERT INTO state_master (state_name, state_code, country_master_id, remarks) VALUES
('Karnataka', 'KA', (SELECT id FROM country_master WHERE country_code = 'IN'), 'State in South India'),
('Tamil Nadu', 'TN', (SELECT id FROM country_master WHERE country_code = 'IN'), 'State in South India'),
('Maharashtra', 'MH', (SELECT id FROM country_master WHERE country_code = 'IN'), 'State in West India'),
('Delhi', 'DL', (SELECT id FROM country_master WHERE country_code = 'IN'), 'National Capital Territory');

-- Insert sample cities
INSERT INTO city_master (city_name, state_master_id, remarks) VALUES
('Bangalore', (SELECT id FROM state_master WHERE state_code = 'KA'), 'Silicon Valley of India'),
('Chennai', (SELECT id FROM state_master WHERE state_code = 'TN'), 'Detroit of India'),
('Mumbai', (SELECT id FROM state_master WHERE state_code = 'MH'), 'Financial Capital of India'),
('New Delhi', (SELECT id FROM state_master WHERE state_code = 'DL'), 'Capital of India');

-- ================================================================
-- COMMENTS: Table and column documentation
-- ================================================================

-- Table comments
COMMENT ON TABLE country_master IS 'Master table for countries with currency and regional information';
COMMENT ON TABLE state_master IS 'Master table for states/provinces within countries';
COMMENT ON TABLE city_master IS 'Master table for cities within states';
COMMENT ON TABLE company_master IS 'Core company master table with complete business configuration';

-- Key column comments for company_master
COMMENT ON COLUMN company_master.company_name IS 'Official registered company name';
COMMENT ON COLUMN company_master.company_prefix IS 'Prefix used for employee ID generation';
COMMENT ON COLUMN company_master.cin_no IS 'Corporate Identification Number for Indian companies';
COMMENT ON COLUMN company_master.gstin_no IS 'Goods and Services Tax Identification Number';
COMMENT ON COLUMN company_master.salary_days IS 'Standard number of days used for salary calculations';
COMMENT ON COLUMN company_master.enable_pf IS 'Flag to enable Provident Fund deductions';
COMMENT ON COLUMN company_master.enable_esi IS 'Flag to enable Employee State Insurance deductions';
COMMENT ON COLUMN company_master.starts_from IS 'Financial year start date for the company';
COMMENT ON COLUMN company_master.ends_by IS 'Financial year end date for the company';

-- ================================================================
-- SECURITY: Row Level Security (RLS) preparation
-- ================================================================

-- Enable RLS on company_master for multi-tenant security
-- ALTER TABLE company_master ENABLE ROW LEVEL SECURITY;

-- Note: RLS policies will be added when user management is implemented
-- This ensures data isolation between different companies

-- ================================================================
-- MIGRATION NOTES
-- ================================================================

/*
MIGRATION CHECKLIST:

1. ✅ Dependencies resolved: country -> state -> city -> company
2. ✅ All MongoDB fields mapped to PostgreSQL equivalents
3. ✅ UUID primary keys for better performance and security
4. ✅ Proper foreign key relationships established
5. ✅ Indexes created for performance optimization
6. ✅ Constraints added for data integrity
7. ✅ Audit trail fields included
8. ✅ Auto-update timestamps implemented
9. ✅ Sample data provided for testing
10. ✅ Documentation and comments added

NEXT STEPS:
- Create division_master table (groups companies)
- Create user_master and authentication tables
- Implement Row Level Security policies
- Create GraphQL schemas for these tables
- Build React components for company management

LEGACY FIELD MAPPINGS:
- MongoDB ObjectId -> PostgreSQL UUID
- Mixed case fields -> snake_case convention
- Date fields -> TIMESTAMP WITH TIME ZONE
- Boolean fields -> PostgreSQL BOOLEAN
- Text fields -> VARCHAR with appropriate limits
- Arrays -> JSONB or separate junction tables
*/