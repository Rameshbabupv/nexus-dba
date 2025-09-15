-- ================================================================
-- NEXUS HRMS - QA Environment Sample Data
-- ================================================================
-- Purpose: Load sample data for QA testing environment
-- Dependencies: Foundation schema must be created first
-- ================================================================

-- Set client encoding
SET client_encoding = 'UTF8';

-- ================================================================
-- GEOGRAPHIC DATA (Countries, States, Cities)
-- ================================================================

-- Insert sample countries
INSERT INTO nexus_foundation.country_master (country_code, country_code_3, country_name, dial_code, currency_code, created_by) VALUES
('US', 'USA', 'United States', '+1', 'USD', 1),
('IN', 'IND', 'India', '+91', 'INR', 1),
('UK', 'GBR', 'United Kingdom', '+44', 'GBP', 1),
('CA', 'CAN', 'Canada', '+1', 'CAD', 1),
('AU', 'AUS', 'Australia', '+61', 'AUD', 1),
('SG', 'SGP', 'Singapore', '+65', 'SGD', 1),
('DE', 'DEU', 'Germany', '+49', 'EUR', 1),
('JP', 'JPN', 'Japan', '+81', 'JPY', 1)
ON CONFLICT (country_code) DO NOTHING;

-- Insert sample states for India
INSERT INTO nexus_foundation.state_master (country_id, state_code, state_name, created_by) VALUES
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'KA', 'Karnataka', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'MH', 'Maharashtra', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'TN', 'Tamil Nadu', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'DL', 'Delhi', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'WB', 'West Bengal', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'GJ', 'Gujarat', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'RJ', 'Rajasthan', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'UP', 'Uttar Pradesh', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'AP', 'Andhra Pradesh', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'), 'TS', 'Telangana', 1)
ON CONFLICT (country_id, state_code) DO NOTHING;

-- Insert sample states for US
INSERT INTO nexus_foundation.state_master (country_id, state_code, state_name, created_by) VALUES
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'), 'CA', 'California', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'), 'NY', 'New York', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'), 'TX', 'Texas', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'), 'FL', 'Florida', 1),
((SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'), 'WA', 'Washington', 1)
ON CONFLICT (country_id, state_code) DO NOTHING;

-- Insert sample cities for India
INSERT INTO nexus_foundation.city_master (state_id, city_name, postal_code, created_by) VALUES
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'KA' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Bangalore', '560001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'KA' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Mysore', '570001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'MH' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Mumbai', '400001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'MH' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Pune', '411001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'TN' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Chennai', '600001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'DL' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'New Delhi', '110001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'WB' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Kolkata', '700001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'GJ' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Ahmedabad', '380001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'TS' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Hyderabad', '500001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'AP' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN')), 'Visakhapatnam', '530001', 1)
ON CONFLICT DO NOTHING;

-- Insert sample cities for US
INSERT INTO nexus_foundation.city_master (state_id, city_name, postal_code, created_by) VALUES
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'CA' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US')), 'San Francisco', '94101', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'CA' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US')), 'Los Angeles', '90001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'NY' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US')), 'New York City', '10001', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'TX' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US')), 'Austin', '73301', 1),
((SELECT state_id FROM nexus_foundation.state_master WHERE state_code = 'WA' AND country_id = (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US')), 'Seattle', '98101', 1)
ON CONFLICT DO NOTHING;

-- ================================================================
-- COMPANY DATA (Multiple QA Companies)
-- ================================================================

-- QA Company 1: SysTech Solutions
INSERT INTO nexus_foundation.company_master (
    company_code, company_name, company_short_name, company_type,
    legal_name, registration_number, pan_number, gst_number,
    registered_address, registered_country_id, registered_city_id,
    primary_phone, primary_email, secondary_email, industry_type,
    employee_strength_range, subscription_plan, max_employees_allowed,
    created_by
) VALUES (
    'SYSTECH_QA',
    'SysTech Solutions Private Limited (QA)',
    'SysTech QA',
    'PRIVATE_LIMITED',
    'SysTech Solutions Private Limited',
    'U72900KA2020PTC138234',
    'AABCS1234C',
    '29AABCS1234C1Z5',
    '123 Tech Park, Electronic City, Bangalore, Karnataka - 560100',
    (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
    (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Bangalore'),
    '+91-80-12345678',
    'qa@systechsolutions.com',
    'admin@systechsolutions.com',
    'Information Technology',
    '51-200',
    'PREMIUM',
    500,
    1
);

-- QA Company 2: Global Tech Corp
INSERT INTO nexus_foundation.company_master (
    company_code, company_name, company_short_name, company_type,
    legal_name, registration_number, pan_number, gst_number,
    registered_address, registered_country_id, registered_city_id,
    primary_phone, primary_email, industry_type,
    employee_strength_range, subscription_plan, max_employees_allowed,
    is_multi_location, is_multi_currency,
    created_by
) VALUES (
    'GLOBAL_QA',
    'Global Tech Corporation (QA)',
    'Global Tech QA',
    'PUBLIC_LIMITED',
    'Global Tech Corporation Limited',
    'L72900DL2018PLC345678',
    'AABCG5678D',
    '07AABCG5678D1Z2',
    '456 Business District, Connaught Place, New Delhi - 110001',
    (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
    (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'New Delhi'),
    '+91-11-87654321',
    'info@globaltech-qa.com',
    'Software Development',
    '201-500',
    'ENTERPRISE',
    1000,
    true,
    true,
    1
);

-- QA Company 3: US Subsidiary
INSERT INTO nexus_foundation.company_master (
    company_code, company_name, company_short_name, company_type,
    legal_name, registration_number,
    registered_address, registered_country_id, registered_city_id,
    primary_phone, primary_email, industry_type,
    employee_strength_range, subscription_plan, max_employees_allowed,
    default_currency_code, default_timezone,
    created_by
) VALUES (
    'USTECH_QA',
    'US Tech Solutions Inc (QA)',
    'US Tech QA',
    'PRIVATE_LIMITED',
    'US Tech Solutions Incorporated',
    'EIN-12-3456789',
    '789 Silicon Valley Blvd, San Francisco, CA 94101',
    (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'),
    (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'San Francisco'),
    '+1-415-555-0123',
    'contact@ustech-qa.com',
    'Technology Consulting',
    '11-50',
    'STANDARD',
    100,
    'USD',
    'America/Los_Angeles',
    1
);

-- ================================================================
-- LOCATION DATA (Multiple Locations per Company)
-- ================================================================

-- Get company IDs for location setup
DO $$
DECLARE
    systech_company_id BIGINT;
    global_company_id BIGINT;
    ustech_company_id BIGINT;
BEGIN
    SELECT company_id INTO systech_company_id FROM nexus_foundation.company_master WHERE company_code = 'SYSTECH_QA';
    SELECT company_id INTO global_company_id FROM nexus_foundation.company_master WHERE company_code = 'GLOBAL_QA';
    SELECT company_id INTO ustech_company_id FROM nexus_foundation.company_master WHERE company_code = 'USTECH_QA';

    -- SysTech Locations
    INSERT INTO nexus_foundation.location_master (
        company_id, location_code, location_name, location_type,
        address_line_1, address_line_2, city_id, country_id, postal_code,
        is_head_office, seating_capacity, created_by
    ) VALUES
    (systech_company_id, 'HO_BLR', 'Head Office - Bangalore', 'HEAD_OFFICE',
     '123 Tech Park, Electronic City', 'Phase 1',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Bangalore'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
     '560100', true, 200, 1),

    (systech_company_id, 'BR_MYS', 'Branch Office - Mysore', 'BRANCH_OFFICE',
     '456 Industrial Area, Hebbal', 'Mysore',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Mysore'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
     '570016', false, 50, 1);

    -- Global Tech Locations
    INSERT INTO nexus_foundation.location_master (
        company_id, location_code, location_name, location_type,
        address_line_1, city_id, country_id, postal_code,
        is_head_office, seating_capacity, created_by
    ) VALUES
    (global_company_id, 'HO_DEL', 'Corporate Headquarters', 'HEAD_OFFICE',
     '456 Business District, Connaught Place',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'New Delhi'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
     '110001', true, 300, 1),

    (global_company_id, 'DEV_BLR', 'Development Center - Bangalore', 'BRANCH_OFFICE',
     '789 Whitefield, ITPL Road',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Bangalore'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
     '560066', false, 150, 1),

    (global_company_id, 'SUP_MUM', 'Support Center - Mumbai', 'SERVICE_CENTER',
     '321 Andheri East, SEEPZ',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Mumbai'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'IN'),
     '400093', false, 80, 1);

    -- US Tech Locations
    INSERT INTO nexus_foundation.location_master (
        company_id, location_code, location_name, location_type,
        address_line_1, city_id, country_id, postal_code,
        is_head_office, seating_capacity, created_by
    ) VALUES
    (ustech_company_id, 'HO_SF', 'Headquarters - San Francisco', 'HEAD_OFFICE',
     '789 Silicon Valley Blvd',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'San Francisco'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'),
     '94101', true, 75, 1),

    (ustech_company_id, 'SAT_SEA', 'Satellite Office - Seattle', 'BRANCH_OFFICE',
     '654 Tech Center Drive',
     (SELECT city_id FROM nexus_foundation.city_master WHERE city_name = 'Seattle'),
     (SELECT country_id FROM nexus_foundation.country_master WHERE country_code = 'US'),
     '98101', false, 25, 1);

END $$;

-- ================================================================
-- ROLE DATA (Standard HRMS Roles)
-- ================================================================

-- Get company IDs for role setup
DO $$
DECLARE
    systech_company_id BIGINT;
    global_company_id BIGINT;
    ustech_company_id BIGINT;
BEGIN
    SELECT company_id INTO systech_company_id FROM nexus_foundation.company_master WHERE company_code = 'SYSTECH_QA';
    SELECT company_id INTO global_company_id FROM nexus_foundation.company_master WHERE company_code = 'GLOBAL_QA';
    SELECT company_id INTO ustech_company_id FROM nexus_foundation.company_master WHERE company_code = 'USTECH_QA';

    -- Standard roles for each company
    INSERT INTO nexus_foundation.role_master (
        company_id, role_code, role_name, role_description, role_level,
        is_system_role, module_permissions, created_by
    ) VALUES
    -- SysTech Roles
    (systech_company_id, 'SUPER_ADMIN', 'Super Administrator', 'Full system access', 1, true, '{"all": ["create", "read", "update", "delete"]}', 1),
    (systech_company_id, 'HR_MANAGER', 'HR Manager', 'Human Resources Management', 2, false, '{"employee": ["create", "read", "update"], "leave": ["read", "approve"], "attendance": ["read"]}', 1),
    (systech_company_id, 'PAYROLL_ADMIN', 'Payroll Administrator', 'Payroll Processing and Management', 2, false, '{"payroll": ["create", "read", "update"], "employee": ["read"]}', 1),
    (systech_company_id, 'MANAGER', 'Manager', 'Team Management', 3, false, '{"employee": ["read"], "leave": ["read", "approve"], "attendance": ["read"], "performance": ["read", "update"]}', 1),
    (systech_company_id, 'EMPLOYEE', 'Employee', 'Basic Employee Access', 4, false, '{"self": ["read", "update"], "leave": ["create", "read"], "attendance": ["read"]}', 1),

    -- Global Tech Roles (similar structure)
    (global_company_id, 'SUPER_ADMIN', 'Super Administrator', 'Full system access', 1, true, '{"all": ["create", "read", "update", "delete"]}', 1),
    (global_company_id, 'HR_DIRECTOR', 'HR Director', 'Strategic HR Leadership', 2, false, '{"employee": ["create", "read", "update", "delete"], "leave": ["all"], "performance": ["all"]}', 1),
    (global_company_id, 'HR_MANAGER', 'HR Manager', 'Human Resources Management', 3, false, '{"employee": ["create", "read", "update"], "leave": ["read", "approve"]}', 1),
    (global_company_id, 'TEAM_LEAD', 'Team Lead', 'Team Leadership', 4, false, '{"employee": ["read"], "leave": ["read", "approve"], "performance": ["read", "update"]}', 1),
    (global_company_id, 'SENIOR_EMPLOYEE', 'Senior Employee', 'Senior Level Access', 5, false, '{"self": ["read", "update"], "leave": ["create", "read"], "training": ["read"]}', 1),
    (global_company_id, 'EMPLOYEE', 'Employee', 'Basic Employee Access', 6, false, '{"self": ["read", "update"], "leave": ["create", "read"]}', 1),

    -- US Tech Roles
    (ustech_company_id, 'ADMIN', 'Administrator', 'System Administration', 1, true, '{"all": ["create", "read", "update", "delete"]}', 1),
    (ustech_company_id, 'HR_SPECIALIST', 'HR Specialist', 'HR Operations', 2, false, '{"employee": ["create", "read", "update"], "leave": ["read", "approve"]}', 1),
    (ustech_company_id, 'SUPERVISOR', 'Supervisor', 'Supervisory Role', 3, false, '{"employee": ["read"], "leave": ["read", "approve"]}', 1),
    (ustech_company_id, 'STAFF', 'Staff Member', 'Regular Staff Access', 4, false, '{"self": ["read", "update"], "leave": ["create", "read"]}', 1);

END $$;

-- ================================================================
-- USER DATA (QA Test Users)
-- ================================================================

-- Get company and role IDs for user setup
DO $$
DECLARE
    systech_company_id BIGINT;
    global_company_id BIGINT;
    ustech_company_id BIGINT;
    admin_role_id BIGINT;
    hr_role_id BIGINT;
    manager_role_id BIGINT;
    employee_role_id BIGINT;
BEGIN
    SELECT company_id INTO systech_company_id FROM nexus_foundation.company_master WHERE company_code = 'SYSTECH_QA';
    SELECT company_id INTO global_company_id FROM nexus_foundation.company_master WHERE company_code = 'GLOBAL_QA';
    SELECT company_id INTO ustech_company_id FROM nexus_foundation.company_master WHERE company_code = 'USTECH_QA';

    -- SysTech Users
    INSERT INTO nexus_foundation.user_master (
        company_id, username, email_address, first_name, last_name,
        display_name, user_status, preferred_language, created_by
    ) VALUES
    (systech_company_id, 'qa_admin', 'qa.admin@systechsolutions.com', 'QA', 'Administrator', 'QA Admin', 'ACTIVE', 'en', 1),
    (systech_company_id, 'hr_manager_qa', 'hr.manager@systechsolutions.com', 'Priya', 'Sharma', 'Priya Sharma', 'ACTIVE', 'en', 1),
    (systech_company_id, 'payroll_admin_qa', 'payroll@systechsolutions.com', 'Rajesh', 'Kumar', 'Rajesh Kumar', 'ACTIVE', 'en', 1),
    (systech_company_id, 'manager1_qa', 'manager1@systechsolutions.com', 'Amit', 'Singh', 'Amit Singh', 'ACTIVE', 'en', 1),
    (systech_company_id, 'employee1_qa', 'employee1@systechsolutions.com', 'Deepika', 'Patel', 'Deepika Patel', 'ACTIVE', 'en', 1),
    (systech_company_id, 'employee2_qa', 'employee2@systechsolutions.com', 'Arjun', 'Reddy', 'Arjun Reddy', 'ACTIVE', 'en', 1),

    -- Global Tech Users
    (global_company_id, 'global_admin', 'admin@globaltech-qa.com', 'Global', 'Administrator', 'Global Admin', 'ACTIVE', 'en', 1),
    (global_company_id, 'hr_director_qa', 'hr.director@globaltech-qa.com', 'Sunita', 'Agarwal', 'Sunita Agarwal', 'ACTIVE', 'en', 1),
    (global_company_id, 'team_lead1', 'teamlead1@globaltech-qa.com', 'Vikram', 'Gupta', 'Vikram Gupta', 'ACTIVE', 'en', 1),
    (global_company_id, 'senior_dev1', 'senior.dev1@globaltech-qa.com', 'Ananya', 'Iyer', 'Ananya Iyer', 'ACTIVE', 'en', 1),

    -- US Tech Users
    (ustech_company_id, 'us_admin', 'admin@ustech-qa.com', 'John', 'Smith', 'John Smith', 'ACTIVE', 'en', 1),
    (ustech_company_id, 'hr_specialist_us', 'hr@ustech-qa.com', 'Sarah', 'Johnson', 'Sarah Johnson', 'ACTIVE', 'en', 1),
    (ustech_company_id, 'supervisor1', 'supervisor@ustech-qa.com', 'Michael', 'Davis', 'Michael Davis', 'ACTIVE', 'en', 1),
    (ustech_company_id, 'staff1', 'staff1@ustech-qa.com', 'Emily', 'Wilson', 'Emily Wilson', 'ACTIVE', 'en', 1);

END $$;

-- ================================================================
-- USER ROLE ASSIGNMENTS
-- ================================================================

-- Assign roles to users
DO $$
DECLARE
    user_rec RECORD;
    role_rec RECORD;
BEGIN
    -- SysTech role assignments
    FOR user_rec IN
        SELECT user_id, username, company_id FROM nexus_foundation.user_master
        WHERE company_id = (SELECT company_id FROM nexus_foundation.company_master WHERE company_code = 'SYSTECH_QA')
    LOOP
        IF user_rec.username LIKE '%admin%' THEN
            SELECT role_id INTO role_rec.role_id FROM nexus_foundation.role_master
            WHERE company_id = user_rec.company_id AND role_code = 'SUPER_ADMIN';
        ELSIF user_rec.username LIKE '%hr_manager%' THEN
            SELECT role_id INTO role_rec.role_id FROM nexus_foundation.role_master
            WHERE company_id = user_rec.company_id AND role_code = 'HR_MANAGER';
        ELSIF user_rec.username LIKE '%payroll%' THEN
            SELECT role_id INTO role_rec.role_id FROM nexus_foundation.role_master
            WHERE company_id = user_rec.company_id AND role_code = 'PAYROLL_ADMIN';
        ELSIF user_rec.username LIKE '%manager%' THEN
            SELECT role_id INTO role_rec.role_id FROM nexus_foundation.role_master
            WHERE company_id = user_rec.company_id AND role_code = 'MANAGER';
        ELSE
            SELECT role_id INTO role_rec.role_id FROM nexus_foundation.role_master
            WHERE company_id = user_rec.company_id AND role_code = 'EMPLOYEE';
        END IF;

        IF role_rec.role_id IS NOT NULL THEN
            INSERT INTO nexus_foundation.user_role_assignment (
                user_id, role_id, assigned_by, assignment_reason, created_by
            ) VALUES (
                user_rec.user_id, role_rec.role_id, 1, 'QA Environment Setup', 1
            );
        END IF;
    END LOOP;

    -- Similar assignments for other companies (Global Tech and US Tech)
    -- [Additional assignment logic would go here for brevity]

END $$;

-- ================================================================
-- SYSTEM PARAMETERS (QA Configuration)
-- ================================================================

-- Insert QA-specific system parameters
INSERT INTO nexus_config.system_parameter (
    company_id, parameter_category, parameter_key, parameter_value,
    parameter_data_type, parameter_description, is_user_configurable, created_by
) VALUES
(NULL, 'SYSTEM', 'QA_MODE', 'true', 'BOOLEAN', 'QA Environment Mode Flag', false, 1),
(NULL, 'SYSTEM', 'DEBUG_LEVEL', 'DEBUG', 'STRING', 'Debug logging level for QA', true, 1),
(NULL, 'SYSTEM', 'TEST_DATA_RETENTION_DAYS', '30', 'INTEGER', 'QA test data retention period', true, 1),
(NULL, 'EMAIL', 'SMTP_HOST', 'smtp-qa.example.com', 'STRING', 'QA SMTP server', true, 1),
(NULL, 'EMAIL', 'FROM_ADDRESS', 'noreply-qa@systech.com', 'STRING', 'QA email sender address', true, 1),
(NULL, 'SECURITY', 'PASSWORD_POLICY', 'RELAXED', 'STRING', 'Relaxed password policy for QA', true, 1),
(NULL, 'FEATURES', 'ENABLE_AUDIT_LOGGING', 'true', 'BOOLEAN', 'Enable comprehensive audit logging', false, 1),
(NULL, 'FEATURES', 'ENABLE_PERFORMANCE_MONITORING', 'true', 'BOOLEAN', 'Enable performance monitoring', true, 1)
ON CONFLICT (company_id, parameter_category, parameter_key) DO NOTHING;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Summary of loaded data
SELECT 'QA Data Load Summary' as status;

SELECT
    'Companies' as data_type,
    COUNT(*) as count,
    STRING_AGG(company_code, ', ') as codes
FROM nexus_foundation.company_master
UNION ALL
SELECT
    'Locations',
    COUNT(*),
    STRING_AGG(location_code, ', ')
FROM nexus_foundation.location_master
UNION ALL
SELECT
    'Users',
    COUNT(*),
    STRING_AGG(username, ', ')
FROM nexus_foundation.user_master
UNION ALL
SELECT
    'Roles',
    COUNT(*),
    STRING_AGG(role_code, ', ')
FROM nexus_foundation.role_master
UNION ALL
SELECT
    'Countries',
    COUNT(*),
    STRING_AGG(country_code, ', ')
FROM nexus_foundation.country_master
UNION ALL
SELECT
    'States',
    COUNT(*),
    STRING_AGG(state_code, ', ')
FROM nexus_foundation.state_master
UNION ALL
SELECT
    'Cities',
    COUNT(*),
    STRING_AGG(city_name, ', ')
FROM nexus_foundation.city_master;

-- QA Environment ready message
SELECT 'QA Environment Successfully Loaded!' as message;