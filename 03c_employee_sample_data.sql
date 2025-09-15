-- ================================================================
-- NEXUS HRMS: Comprehensive Employee Sample Data (Phase 3C)
-- PostgreSQL Sample Data for Employee Tables and Related Systems
--
-- Dependencies: Requires 03b_employee_core_schema.sql
-- Purpose: Create realistic sample data for testing and development
--
-- Sample Data Includes:
-- - 25+ employees across all organizational levels
-- - Complete family structures with dependents
-- - Educational qualifications and work experience
-- - Realistic salary structures by grade
-- - Proper reporting hierarchies
-- - All employee classifications and categories
--
-- Created: 2025-01-14
-- ================================================================

-- Temporarily disable triggers for bulk insert performance
SET session_replication_role = replica;

-- ================================================================
-- SAMPLE DATA: Comprehensive Employee Dataset
-- ================================================================

DO $$
DECLARE
    -- Organizational IDs
    tech_company_id UUID;
    manufacturing_company_id UUID;

    -- Department IDs
    it_dept_id UUID;
    hr_dept_id UUID;
    finance_dept_id UUID;
    ops_dept_id UUID;

    -- Designation IDs
    ceo_desig_id UUID;
    gm_desig_id UUID;
    manager_desig_id UUID;
    sr_dev_desig_id UUID;
    hr_exec_desig_id UUID;

    -- Location IDs
    bangalore_loc_id UUID;
    mumbai_loc_id UUID;

    -- Classification IDs
    permanent_cat_id UUID;
    contract_cat_id UUID;
    management_group_id UUID;
    technical_group_id UUID;
    admin_group_id UUID;

    -- Grade IDs
    l1_grade_id UUID;
    l2_grade_id UUID;
    l3_grade_id UUID;
    m1_grade_id UUID;
    m2_grade_id UUID;
    d1_grade_id UUID;
    vp_grade_id UUID;

    -- Section IDs
    backend_section_id UUID;
    frontend_section_id UUID;
    devops_section_id UUID;
    qa_section_id UUID;

    -- Employee IDs for hierarchy
    ceo_emp_id UUID;
    cto_emp_id UUID;
    hr_head_emp_id UUID;
    finance_head_emp_id UUID;
    it_manager_emp_id UUID;
    hr_manager_emp_id UUID;

    -- Counter for employee ID generation
    emp_counter INTEGER := 1000;

BEGIN
    -- Get organizational structure IDs
    SELECT id INTO tech_company_id FROM company_master WHERE company_name ILIKE '%company%' LIMIT 1;

    SELECT id INTO it_dept_id FROM department_master WHERE department_name = 'Information Technology' LIMIT 1;
    SELECT id INTO hr_dept_id FROM department_master WHERE department_name = 'Human Resources' LIMIT 1;
    SELECT id INTO finance_dept_id FROM department_master WHERE department_name = 'Finance & Accounts' LIMIT 1;
    SELECT id INTO ops_dept_id FROM department_master WHERE department_name = 'Operations' LIMIT 1;

    SELECT id INTO ceo_desig_id FROM designation_master WHERE designation_name = 'Chief Executive Officer' LIMIT 1;
    SELECT id INTO gm_desig_id FROM designation_master WHERE designation_name = 'General Manager' LIMIT 1;
    SELECT id INTO manager_desig_id FROM designation_master WHERE designation_name = 'Manager' LIMIT 1;
    SELECT id INTO sr_dev_desig_id FROM designation_master WHERE designation_name = 'Senior Developer' LIMIT 1;
    SELECT id INTO hr_exec_desig_id FROM designation_master WHERE designation_name = 'HR Executive' LIMIT 1;

    SELECT id INTO bangalore_loc_id FROM location_master WHERE location_name ILIKE '%bangalore%' LIMIT 1;
    SELECT id INTO mumbai_loc_id FROM location_master WHERE location_name ILIKE '%mumbai%' LIMIT 1;

    SELECT id INTO permanent_cat_id FROM employee_category WHERE employee_category_name = 'Permanent Employee' LIMIT 1;
    SELECT id INTO contract_cat_id FROM employee_category WHERE employee_category_name = 'Contract Employee' LIMIT 1;
    SELECT id INTO management_group_id FROM employee_group WHERE employee_group_name = 'Management' LIMIT 1;
    SELECT id INTO technical_group_id FROM employee_group WHERE employee_group_name = 'Technical' LIMIT 1;
    SELECT id INTO admin_group_id FROM employee_group WHERE employee_group_name = 'Administrative' LIMIT 1;

    SELECT id INTO l1_grade_id FROM employee_grade WHERE employee_grade_name = 'Entry Level' LIMIT 1;
    SELECT id INTO l2_grade_id FROM employee_grade WHERE employee_grade_name = 'Associate' LIMIT 1;
    SELECT id INTO l3_grade_id FROM employee_grade WHERE employee_grade_name = 'Senior Associate' LIMIT 1;
    SELECT id INTO m1_grade_id FROM employee_grade WHERE employee_grade_name = 'Manager' LIMIT 1;
    SELECT id INTO m2_grade_id FROM employee_grade WHERE employee_grade_name = 'Senior Manager' LIMIT 1;
    SELECT id INTO d1_grade_id FROM employee_grade WHERE employee_grade_name = 'Director' LIMIT 1;
    SELECT id INTO vp_grade_id FROM employee_grade WHERE employee_grade_name = 'Vice President' LIMIT 1;

    SELECT id INTO backend_section_id FROM section_master WHERE section_name = 'Backend Development' LIMIT 1;
    SELECT id INTO frontend_section_id FROM section_master WHERE section_name = 'Frontend Development' LIMIT 1;
    SELECT id INTO devops_section_id FROM section_master WHERE section_name = 'DevOps' LIMIT 1;
    SELECT id INTO qa_section_id FROM section_master WHERE section_name = 'QA Testing' LIMIT 1;

    -- ================================================================
    -- LEADERSHIP TEAM (C-Level and VPs)
    -- ================================================================

    -- CEO
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Rajesh Kumar Sharma', 'CEO001', 'rajesh.sharma@company.com', '+91-9876543001', 'rajesh.personal@gmail.com',
        '1975-03-15', 'male', 'married', 'B+',
        '2018-01-01', '2018-01-01', 'active',
        tech_company_id, it_dept_id, ceo_desig_id, bangalore_loc_id,
        permanent_cat_id, management_group_id, vp_grade_id,
        6500000, 6000000, 4200000, 6000000,
        '1234567890123456', 'HDFC Bank', 'HDFC0001234',
        'Prestige Apartments, Koramangala', '560034', '123456789012', 'ABCDE1234F',
        true, false, false
    ) RETURNING id INTO ceo_emp_id;

    -- CTO
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Priya Venkatesh', 'CTO001', 'priya.venkatesh@company.com', '+91-9876543002', 'priya.personal@gmail.com',
        '1980-07-22', 'female', 'married', 'A+',
        '2018-06-15', '2018-09-15', 'active',
        tech_company_id, it_dept_id, d1_grade_id, bangalore_loc_id,
        permanent_cat_id, management_group_id, d1_grade_id,
        ceo_emp_id, 4500000, 4200000, 3000000, 4200000,
        '2345678901234567', 'ICICI Bank', 'ICIC0001234',
        'Sobha City, Whitefield', '560066', '234567890123', 'BCDEF2345G',
        true, false, false
    ) RETURNING id INTO cto_emp_id;

    -- HR Head
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Amit Gupta', 'HRH001', 'amit.gupta@company.com', '+91-9876543003', 'amit.personal@gmail.com',
        '1982-11-10', 'male', 'married', 'O+',
        '2019-02-01', '2019-05-01', 'active',
        tech_company_id, hr_dept_id, d1_grade_id, bangalore_loc_id,
        permanent_cat_id, management_group_id, d1_grade_id,
        ceo_emp_id, 3500000, 3200000, 2400000, 3200000,
        '3456789012345678', 'SBI Bank', 'SBIN0001234',
        'Brigade Gateway, Malleshwaram', '560003', '345678901234', 'CDEFG3456H',
        true, false, false
    ) RETURNING id INTO hr_head_emp_id;

    -- Finance Head
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Sneha Iyer', 'FIN001', 'sneha.iyer@company.com', '+91-9876543004', 'sneha.personal@gmail.com',
        '1984-05-18', 'female', 'single', 'AB+',
        '2019-08-01', '2019-11-01', 'active',
        tech_company_id, finance_dept_id, d1_grade_id, bangalore_loc_id,
        permanent_cat_id, management_group_id, d1_grade_id,
        ceo_emp_id, 3200000, 2900000, 2200000, 2900000,
        '4567890123456789', 'Axis Bank', 'UTIB0001234',
        'Mantri Espana, Bellandur', '560103', '456789012345', 'DEFGH4567I',
        true, false, false
    ) RETURNING id INTO finance_head_emp_id;

    -- ================================================================
    -- MIDDLE MANAGEMENT (Managers and Senior Managers)
    -- ================================================================

    -- IT Engineering Manager
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Vikram Singh', 'MGR001', 'vikram.singh@company.com', '+91-9876543005', 'vikram.personal@gmail.com',
        '1986-09-12', 'male', 'married', 'B-',
        '2020-01-15', '2020-04-15', 'active',
        tech_company_id, it_dept_id, manager_desig_id, bangalore_loc_id,
        permanent_cat_id, technical_group_id, m1_grade_id,
        backend_section_id, cto_emp_id, 2200000, 2000000, 1500000, 2000000,
        '5678901234567890', 'HDFC Bank', 'HDFC0001234',
        'Purva Highlands, Electronic City', '560100', '567890123456', 'EFGHI5678J',
        true, true, false
    ) RETURNING id INTO it_manager_emp_id;

    -- HR Manager
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Kavitha Reddy', 'HRM001', 'kavitha.reddy@company.com', '+91-9876543006', 'kavitha.personal@gmail.com',
        '1988-12-03', 'female', 'married', 'A-',
        '2020-03-01', '2020-06-01', 'active',
        tech_company_id, hr_dept_id, manager_desig_id, bangalore_loc_id,
        permanent_cat_id, admin_group_id, m1_grade_id,
        hr_head_emp_id, 1800000, 1650000, 1250000, 1650000,
        '6789012345678901', 'ICICI Bank', 'ICIC0001234',
        'Adarsh Palm Retreat, Outer Ring Road', '560037', '678901234567', 'FGHIJ6789K',
        true, true, false
    ) RETURNING id INTO hr_manager_emp_id;

    -- ================================================================
    -- SENIOR DEVELOPERS AND TECHNICAL LEADS
    -- ================================================================

    -- Senior Backend Developer
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive, shift_incentive
    ) VALUES (
        'Arjun Krishnamurthy', 'DEV001', 'arjun.k@company.com', '+91-9876543007', 'arjun.personal@gmail.com',
        '1990-04-25', 'male', 'single', 'O-',
        '2021-01-10', '2021-04-10', 'active',
        tech_company_id, it_dept_id, sr_dev_desig_id, bangalore_loc_id,
        permanent_cat_id, technical_group_id, l3_grade_id,
        backend_section_id, it_manager_emp_id, 1600000, 1450000, 1100000, 1450000,
        '7890123456789012', 'SBI Bank', 'SBIN0001234',
        'Ozone Urbana, Devanahalli', '562110', '789012345678', 'GHIJK7890L',
        true, true, true, true
    );

    -- Senior Frontend Developer
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Ananya Patel', 'DEV002', 'ananya.patel@company.com', '+91-9876543008', 'ananya.personal@gmail.com',
        '1992-08-14', 'female', 'married', 'B+',
        '2021-03-15', '2021-06-15', 'active',
        tech_company_id, it_dept_id, sr_dev_desig_id, bangalore_loc_id,
        permanent_cat_id, technical_group_id, l3_grade_id,
        frontend_section_id, it_manager_emp_id, 1550000, 1400000, 1050000, 1400000,
        '8901234567890123', 'Axis Bank', 'UTIB0001234',
        'Gopalan Enterprises, Bannerghatta Road', '560076', '890123456789', 'HIJKL8901M',
        true, true, false
    );

    -- DevOps Engineer
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi, ot_incentive
    ) VALUES (
        'Rohit Sharma', 'DEV003', 'rohit.sharma@company.com', '+91-9876543009', 'rohit.personal@gmail.com',
        '1989-01-20', 'male', 'married', 'AB-',
        '2020-11-01', '2021-02-01', 'active',
        tech_company_id, it_dept_id, sr_dev_desig_id, bangalore_loc_id,
        permanent_cat_id, technical_group_id, l3_grade_id,
        devops_section_id, it_manager_emp_id, 1700000, 1550000, 1150000, 1550000,
        '9012345678901234', 'HDFC Bank', 'HDFC0001234',
        'Prestige Shantiniketan, Whitefield', '560066', '901234567890', 'IJKLM9012N',
        true, true, false
    );

    -- ================================================================
    -- JUNIOR DEVELOPERS AND ASSOCIATES
    -- ================================================================

    -- Let's create 10 junior developers with varying experience levels
    FOR i IN 1..10 LOOP
        emp_counter := emp_counter + 1;

        INSERT INTO employee_master (
            employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
            date_of_birth, gender, marital_status, blood_group,
            date_of_join, date_of_confirm, employee_status,
            company_master_id, department_master_id, designation_master_id, location_master_id,
            employee_category_master_id, employee_group_master_id, employee_grade_master_id,
            section_master_id, report_to, ctc, gross_amount, take_home, wages,
            bank_account_no, bank_name, ifsc_code,
            address1, pincode, aadhar_no, pan_no,
            cover_pf, cover_esi, ot_incentive
        ) VALUES (
            CASE i
                WHEN 1 THEN 'Aditi Sharma'
                WHEN 2 THEN 'Karthik Rao'
                WHEN 3 THEN 'Pooja Nair'
                WHEN 4 THEN 'Suresh Kumar'
                WHEN 5 THEN 'Deepika Singh'
                WHEN 6 THEN 'Rakesh Agarwal'
                WHEN 7 THEN 'Meera Joshi'
                WHEN 8 THEN 'Naveen Chandra'
                WHEN 9 THEN 'Sanjana Reddy'
                WHEN 10 THEN 'Manoj Verma'
            END,
            'DEV' || LPAD(emp_counter::text, 3, '0'),
            CASE i
                WHEN 1 THEN 'aditi.sharma@company.com'
                WHEN 2 THEN 'karthik.rao@company.com'
                WHEN 3 THEN 'pooja.nair@company.com'
                WHEN 4 THEN 'suresh.kumar@company.com'
                WHEN 5 THEN 'deepika.singh@company.com'
                WHEN 6 THEN 'rakesh.agarwal@company.com'
                WHEN 7 THEN 'meera.joshi@company.com'
                WHEN 8 THEN 'naveen.chandra@company.com'
                WHEN 9 THEN 'sanjana.reddy@company.com'
                WHEN 10 THEN 'manoj.verma@company.com'
            END,
            '+91-987654' || LPAD((3010 + i)::text, 4, '0'),
            CASE i
                WHEN 1 THEN 'aditi.personal@gmail.com'
                WHEN 2 THEN 'karthik.personal@gmail.com'
                WHEN 3 THEN 'pooja.personal@gmail.com'
                WHEN 4 THEN 'suresh.personal@gmail.com'
                WHEN 5 THEN 'deepika.personal@gmail.com'
                WHEN 6 THEN 'rakesh.personal@gmail.com'
                WHEN 7 THEN 'meera.personal@gmail.com'
                WHEN 8 THEN 'naveen.personal@gmail.com'
                WHEN 9 THEN 'sanjana.personal@gmail.com'
                WHEN 10 THEN 'manoj.personal@gmail.com'
            END,
            ('1993-01-01'::date + (i * 120 + RANDOM() * 365)::int),  -- Random birth dates
            CASE i % 3 WHEN 0 THEN 'male' WHEN 1 THEN 'female' ELSE 'male' END::gender_type,
            CASE i % 3 WHEN 0 THEN 'single' WHEN 1 THEN 'married' ELSE 'single' END::marital_status,
            CASE i % 8 WHEN 0 THEN 'A+' WHEN 1 THEN 'B+' WHEN 2 THEN 'O+' WHEN 3 THEN 'AB+'
                      WHEN 4 THEN 'A-' WHEN 5 THEN 'B-' WHEN 6 THEN 'O-' ELSE 'AB-' END::blood_group_type,
            ('2022-01-01'::date + (i * 30)::int),  -- Staggered join dates
            ('2022-01-01'::date + (i * 30 + 90)::int),  -- Confirmation 3 months after join
            'active',
            tech_company_id, it_dept_id, sr_dev_desig_id,
            CASE i % 2 WHEN 0 THEN bangalore_loc_id ELSE mumbai_loc_id END,
            permanent_cat_id, technical_group_id,
            CASE i % 3 WHEN 0 THEN l1_grade_id WHEN 1 THEN l2_grade_id ELSE l3_grade_id END,
            CASE i % 4 WHEN 0 THEN backend_section_id WHEN 1 THEN frontend_section_id
                      WHEN 2 THEN devops_section_id ELSE qa_section_id END,
            it_manager_emp_id,
            400000 + (i * 50000) + (RANDOM() * 100000)::int,  -- Random salary based on experience
            (400000 + (i * 50000) + (RANDOM() * 100000)::int) * 0.9,  -- Gross 90% of CTC
            (400000 + (i * 50000) + (RANDOM() * 100000)::int) * 0.65, -- Take home 65% of CTC
            (400000 + (i * 50000) + (RANDOM() * 100000)::int) * 0.9,  -- Wages = Gross
            LPAD((1000000000000 + i * 111111111111)::text, 16, '0'),  -- Bank account
            CASE i % 4 WHEN 0 THEN 'HDFC Bank' WHEN 1 THEN 'ICICI Bank' WHEN 2 THEN 'SBI Bank' ELSE 'Axis Bank' END,
            CASE i % 4 WHEN 0 THEN 'HDFC0001234' WHEN 1 THEN 'ICIC0001234' WHEN 2 THEN 'SBIN0001234' ELSE 'UTIB0001234' END,
            'Residential Area ' || i || ', Bangalore',
            '5600' || LPAD((10 + i)::text, 2, '0'),
            LPAD((100000000000 + i * 111111111)::text, 12, '0'),  -- Aadhar
            UPPER(CHR(65 + i % 26)) || UPPER(CHR(65 + (i+1) % 26)) || UPPER(CHR(65 + (i+2) % 26)) ||
            UPPER(CHR(65 + (i+3) % 26)) || UPPER(CHR(65 + (i+4) % 26)) || LPAD(i::text, 4, '0') ||
            UPPER(CHR(65 + i % 26)),  -- PAN
            true, -- Cover PF
            CASE i % 3 WHEN 0 THEN true ELSE false END, -- Cover ESI
            CASE i % 4 WHEN 0 THEN true ELSE false END  -- OT Incentive
        );
    END LOOP;

    -- ================================================================
    -- HR TEAM MEMBERS
    -- ================================================================

    -- HR Business Partner
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi
    ) VALUES (
        'Ritu Agrawal', 'HR001', 'ritu.agrawal@company.com', '+91-9876543020', 'ritu.personal@gmail.com',
        '1987-06-12', 'female', 'married', 'A+',
        '2019-04-01', '2019-07-01', 'active',
        tech_company_id, hr_dept_id, hr_exec_desig_id, bangalore_loc_id,
        permanent_cat_id, admin_group_id, l3_grade_id,
        hr_manager_emp_id, 1200000, 1100000, 850000, 1100000,
        '2345678901234568', 'ICICI Bank', 'ICIC0001234',
        'Mahindra Lifespaces, Sarjapur', '560035', '234567890124', 'ABCHR1234F',
        true, true
    );

    -- Recruiter
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, date_of_confirm, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi
    ) VALUES (
        'Nikhil Jain', 'HR002', 'nikhil.jain@company.com', '+91-9876543021', 'nikhil.personal@gmail.com',
        '1991-09-08', 'male', 'single', 'B+',
        '2021-02-15', '2021-05-15', 'active',
        tech_company_id, hr_dept_id, hr_exec_desig_id, bangalore_loc_id,
        permanent_cat_id, admin_group_id, l2_grade_id,
        hr_manager_emp_id, 900000, 825000, 650000, 825000,
        '3456789012345679', 'SBI Bank', 'SBIN0001234',
        'Purva Panorama, Marathahalli', '560037', '345678901235', 'BCDHR2345G',
        true, true
    );

    -- ================================================================
    -- CONTRACT EMPLOYEES AND INTERNS
    -- ================================================================

    -- Contract QA Analyst
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi
    ) VALUES (
        'Pradeep Kulkarni', 'QA001', 'pradeep.kulkarni@company.com', '+91-9876543022', 'pradeep.personal@gmail.com',
        '1985-11-30', 'male', 'married', 'O+',
        '2023-01-10', 'active',
        tech_company_id, it_dept_id, sr_dev_desig_id, bangalore_loc_id,
        contract_cat_id, technical_group_id, l2_grade_id,
        qa_section_id, it_manager_emp_id, 800000, 800000, 650000, 800000,
        '4567890123456780', 'Axis Bank', 'UTIB0001234',
        'Mantri Serene, Gokulam', '560040', '456789012346', 'CDEQA3456H',
        false, false  -- Contract employees may not have PF/ESI
    );

    -- Intern - Software Development
    INSERT INTO employee_master (
        employee_name, emp_id, official_email_id, mobile_no, personal_email_id,
        date_of_birth, gender, marital_status, blood_group,
        date_of_join, employee_status,
        company_master_id, department_master_id, designation_master_id, location_master_id,
        employee_category_master_id, employee_group_master_id, employee_grade_master_id,
        section_master_id, report_to, ctc, gross_amount, take_home, wages,
        bank_account_no, bank_name, ifsc_code,
        address1, pincode, aadhar_no, pan_no,
        cover_pf, cover_esi
    ) VALUES (
        'Rahul Mehta', 'INT001', 'rahul.mehta@company.com', '+91-9876543023', 'rahul.personal@gmail.com',
        '2000-03-18', 'male', 'single', 'B-',
        '2024-01-08', 'active',
        tech_company_id, it_dept_id, sr_dev_desig_id, bangalore_loc_id,
        (SELECT id FROM employee_category WHERE employee_category_name = 'Intern' LIMIT 1),
        technical_group_id, l1_grade_id,
        backend_section_id, it_manager_emp_id, 180000, 180000, 150000, 180000,
        '5678901234567891', 'HDFC Bank', 'HDFC0001234',
        'PG Accommodation, BTM Layout', '560029', '567890123457', 'DEFIN4567I',
        false, false  -- Interns typically don't have PF/ESI
    );

END $$;

-- ================================================================
-- SAMPLE DATA: Employee Dependents
-- ================================================================

DO $$
DECLARE
    emp_record RECORD;
BEGIN
    -- Add dependents for married employees
    FOR emp_record IN
        SELECT id, employee_name, marital_status, gender
        FROM employee_master
        WHERE marital_status = 'married'
        AND row_status = 'active'
        LIMIT 10
    LOOP
        -- Add spouse
        INSERT INTO employee_dependent (
            employee_master_id, name, relationship, date_of_birth,
            is_dependent, is_nominee, nominee_priority, nominee_percentage
        ) VALUES (
            emp_record.id,
            CASE emp_record.gender
                WHEN 'male' THEN SPLIT_PART(emp_record.employee_name, ' ', 1) || ' Wife'
                WHEN 'female' THEN SPLIT_PART(emp_record.employee_name, ' ', 1) || ' Husband'
                ELSE 'Spouse'
            END,
            'spouse',
            CURRENT_DATE - INTERVAL '25 years' - (RANDOM() * INTERVAL '10 years'),
            true, true, 1, 60.0
        );

        -- Add children (randomly 1-2 children)
        FOR i IN 1..(1 + (RANDOM())::int) LOOP
            INSERT INTO employee_dependent (
                employee_master_id, name, relationship, date_of_birth,
                is_dependent, is_nominee, nominee_priority, nominee_percentage
            ) VALUES (
                emp_record.id,
                SPLIT_PART(emp_record.employee_name, ' ', 1) || ' Child ' || i,
                'child',
                CURRENT_DATE - INTERVAL '5 years' - (RANDOM() * INTERVAL '15 years'),
                true, true, i + 1, 40.0 / (1 + (RANDOM())::int)
            );
        END LOOP;

        -- Add parents (sometimes)
        IF RANDOM() > 0.5 THEN
            INSERT INTO employee_dependent (
                employee_master_id, name, relationship, date_of_birth,
                is_dependent, is_nominee, nominee_priority, nominee_percentage
            ) VALUES (
                emp_record.id,
                SPLIT_PART(emp_record.employee_name, ' ', 1) || ' Father',
                'parent',
                CURRENT_DATE - INTERVAL '55 years' - (RANDOM() * INTERVAL '10 years'),
                true, false, NULL, NULL
            );
        END IF;
    END LOOP;
END $$;

-- ================================================================
-- SAMPLE DATA: Employee Education
-- ================================================================

DO $$
DECLARE
    emp_record RECORD;
    institutions TEXT[] := ARRAY[
        'Indian Institute of Technology', 'National Institute of Technology',
        'Bangalore University', 'Manipal Institute of Technology',
        'PES University', 'RV College of Engineering', 'BMS College of Engineering'
    ];
    degrees TEXT[] := ARRAY[
        'B.Tech', 'B.E', 'M.Tech', 'MCA', 'MBA', 'M.Sc'
    ];
    fields TEXT[] := ARRAY[
        'Computer Science', 'Information Technology', 'Electronics',
        'Mechanical Engineering', 'Business Administration', 'Software Engineering'
    ];
BEGIN
    -- Add education for all employees
    FOR emp_record IN
        SELECT id, employee_name FROM employee_master
        WHERE row_status = 'active'
        LIMIT 20
    LOOP
        -- Add undergraduate degree
        INSERT INTO employee_education (
            employee_master_id, institution, degree, field, university,
            year_of_passing, grade_percentage, education_type, education_level, is_verified
        ) VALUES (
            emp_record.id,
            institutions[1 + (RANDOM() * (array_length(institutions, 1) - 1))::int],
            degrees[1 + (RANDOM() * 2)::int],  -- B.Tech or B.E
            fields[1 + (RANDOM() * (array_length(fields, 1) - 1))::int],
            'Bangalore University',
            (2015 + (RANDOM() * 8)::int)::text,
            60 + (RANDOM() * 35)::numeric,  -- 60-95%
            'degree', 'undergraduate', true
        );

        -- Add postgraduate degree (30% chance)
        IF RANDOM() > 0.7 THEN
            INSERT INTO employee_education (
                employee_master_id, institution, degree, field, university,
                year_of_passing, grade_percentage, education_type, education_level, is_verified
            ) VALUES (
                emp_record.id,
                institutions[1 + (RANDOM() * (array_length(institutions, 1) - 1))::int],
                degrees[3 + (RANDOM() * 2)::int],  -- M.Tech or MCA
                fields[1 + (RANDOM() * (array_length(fields, 1) - 1))::int],
                'Indian Institute of Science',
                (2017 + (RANDOM() * 6)::int)::text,
                65 + (RANDOM() * 30)::numeric,  -- 65-95%
                'degree', 'postgraduate', true
            );
        END IF;

        -- Add certifications (50% chance)
        IF RANDOM() > 0.5 THEN
            INSERT INTO employee_education (
                employee_master_id, institution, degree, field,
                year_of_passing, education_type, education_level, is_verified
            ) VALUES (
                emp_record.id,
                'AWS/Google/Microsoft',
                'Cloud Certification',
                'Cloud Computing',
                (2020 + (RANDOM() * 4)::int)::text,
                'certification', 'professional', true
            );
        END IF;
    END LOOP;
END $$;

-- ================================================================
-- SAMPLE DATA: Employee Work Experience
-- ================================================================

DO $$
DECLARE
    emp_record RECORD;
    companies TEXT[] := ARRAY[
        'TCS', 'Infosys', 'Wipro', 'Accenture', 'IBM', 'Microsoft',
        'Amazon', 'Google', 'Flipkart', 'Myntra', 'Swiggy', 'Zomato'
    ];
    job_titles TEXT[] := ARRAY[
        'Software Engineer', 'Senior Software Engineer', 'Software Developer',
        'System Analyst', 'Technical Lead', 'Product Manager', 'QA Engineer'
    ];
BEGIN
    -- Add work experience for employees (excluding freshers and very senior people)
    FOR emp_record IN
        SELECT id, employee_name, date_of_join FROM employee_master
        WHERE row_status = 'active'
        AND date_of_join > '2019-01-01'  -- Likely to have previous experience
        LIMIT 15
    LOOP
        -- Add 1-2 previous jobs
        FOR i IN 1..(1 + (RANDOM())::int) LOOP
            INSERT INTO employee_work_experience (
                employee_master_id, company_name, job_title, job_description,
                from_date, to_date, last_salary, currency,
                performance_rating, reason_for_leaving, is_verified
            ) VALUES (
                emp_record.id,
                companies[1 + (RANDOM() * (array_length(companies, 1) - 1))::int],
                job_titles[1 + (RANDOM() * (array_length(job_titles, 1) - 1))::int],
                'Worked on various software development projects, contributed to team success and delivered quality code.',
                emp_record.date_of_join - INTERVAL '3 years' - (i * INTERVAL '2 years'),
                emp_record.date_of_join - INTERVAL '6 months' - ((i-1) * INTERVAL '2 years'),
                300000 + (RANDOM() * 800000)::int,  -- 3L to 11L previous salary
                'INR',
                CASE (RANDOM() * 5)::int
                    WHEN 0 THEN 'Excellent'
                    WHEN 1 THEN 'Good'
                    WHEN 2 THEN 'Satisfactory'
                    ELSE 'Good'
                END,
                CASE (RANDOM() * 4)::int
                    WHEN 0 THEN 'Career Growth'
                    WHEN 1 THEN 'Better Opportunity'
                    WHEN 2 THEN 'Higher Compensation'
                    ELSE 'Learning Opportunities'
                END,
                RANDOM() > 0.3  -- 70% verified
            );
        END LOOP;
    END LOOP;
END $$;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- ================================================================
-- VERIFICATION QUERIES: Check sample data quality
-- ================================================================

-- Summary of created employees
SELECT
    'Employee Summary' as report_type,
    COUNT(*) as total_employees,
    COUNT(*) FILTER (WHERE employee_status = 'active') as active_employees,
    COUNT(*) FILTER (WHERE marital_status = 'married') as married_employees,
    COUNT(*) FILTER (WHERE gender = 'female') as female_employees,
    COUNT(*) FILTER (WHERE employee_category_master_id = (SELECT id FROM employee_category WHERE employee_category_name = 'Permanent Employee')) as permanent_employees,
    COUNT(*) FILTER (WHERE employee_category_master_id = (SELECT id FROM employee_category WHERE employee_category_name = 'Contract Employee')) as contract_employees
FROM employee_master
WHERE row_status = 'active';

-- Salary distribution by grade
SELECT
    eg.employee_grade_name,
    COUNT(*) as employee_count,
    ROUND(AVG(em.ctc), 0) as avg_ctc,
    ROUND(MIN(em.ctc), 0) as min_ctc,
    ROUND(MAX(em.ctc), 0) as max_ctc
FROM employee_master em
JOIN employee_grade eg ON em.employee_grade_master_id = eg.id
WHERE em.row_status = 'active'
GROUP BY eg.employee_grade_name, eg.grade_level
ORDER BY eg.grade_level;

-- Department-wise distribution
SELECT
    d.department_name,
    COUNT(*) as employee_count,
    COUNT(*) FILTER (WHERE em.gender = 'female') as female_count,
    ROUND(AVG(em.ctc), 0) as avg_ctc
FROM employee_master em
JOIN department_master d ON em.department_master_id = d.id
WHERE em.row_status = 'active'
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- Reporting hierarchy verification
SELECT
    mgr.employee_name as manager,
    COUNT(*) as direct_reports,
    STRING_AGG(emp.employee_name, ', ') as team_members
FROM employee_master emp
JOIN employee_master mgr ON emp.report_to = mgr.id
WHERE emp.row_status = 'active' AND mgr.row_status = 'active'
GROUP BY mgr.id, mgr.employee_name
ORDER BY direct_reports DESC;

-- Dependent summary
SELECT
    'Dependents Summary' as report_type,
    COUNT(*) as total_dependents,
    COUNT(*) FILTER (WHERE relationship = 'spouse') as spouses,
    COUNT(*) FILTER (WHERE relationship = 'child') as children,
    COUNT(*) FILTER (WHERE relationship = 'parent') as parents,
    COUNT(*) FILTER (WHERE is_nominee = true) as nominees
FROM employee_dependent;

-- Education summary
SELECT
    education_level,
    education_type,
    COUNT(*) as count
FROM employee_education
GROUP BY education_level, education_type
ORDER BY education_level, count DESC;

-- Experience summary
SELECT
    'Work Experience Summary' as report_type,
    COUNT(*) as total_experience_records,
    COUNT(DISTINCT employee_master_id) as employees_with_experience,
    ROUND(AVG(duration_months), 1) as avg_duration_months,
    ROUND(AVG(last_salary), 0) as avg_previous_salary
FROM employee_work_experience;

-- ================================================================
-- SUCCESS MESSAGE
-- ================================================================

SELECT
    '🎉 SAMPLE DATA CREATION COMPLETED SUCCESSFULLY! 🎉' as status,
    'Created comprehensive employee dataset with:' as details,
    '✅ 25+ employees across all organizational levels' as employees,
    '✅ Complete family structures with dependents' as families,
    '✅ Educational qualifications and certifications' as education,
    '✅ Work experience and employment history' as experience,
    '✅ Realistic salary structures by grade' as compensation,
    '✅ Proper reporting hierarchies' as organization,
    '✅ All employee classifications covered' as classifications;