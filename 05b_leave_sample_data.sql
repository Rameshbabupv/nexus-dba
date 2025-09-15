-- =====================================================================================
-- NEXUS HRMS - Leave Management Sample Data
-- Comprehensive test data for leave types, policies, applications, and balances
-- =====================================================================================
-- Dependencies: Employee Master, Attendance Management, Organizational Structure
-- Purpose: Realistic leave scenarios for testing and development
-- =====================================================================================

-- =====================================================================================
-- SECTION 1: LEAVE CATEGORIES AND TYPES SETUP
-- =====================================================================================

-- Insert standard leave categories
INSERT INTO leave_category_master (
    category_name, category_code, category_type, description, is_paid, is_system_defined, display_order, created_by
) VALUES
    ('Earned Leave', 'EL', 'earned_leave', 'Annual earned leave entitlement based on service period', true, true, 1,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Casual Leave', 'CL', 'casual_leave', 'Short-term casual leave for personal work', true, true, 2,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Sick Leave', 'SL', 'sick_leave', 'Medical leave for health-related issues', true, true, 3,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Maternity Leave', 'ML', 'maternity_leave', 'Maternity leave for female employees', true, true, 4,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Paternity Leave', 'PL', 'paternity_leave', 'Paternity leave for male employees', true, true, 5,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Compensatory Off', 'CO', 'comp_off', 'Compensatory off for overtime and holiday work', true, true, 6,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Loss of Pay', 'LOP', 'loss_of_pay', 'Unpaid leave when other leave balances are exhausted', false, true, 7,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Bereavement Leave', 'BL', 'bereavement_leave', 'Leave for family bereavement', true, true, 8,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Marriage Leave', 'MAL', 'marriage_leave', 'Leave for marriage ceremonies', true, true, 9,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Study Leave', 'STL', 'study_leave', 'Leave for educational purposes and examinations', true, true, 10,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create company-specific leave types for Nexus Technologies
INSERT INTO leave_type_master (
    leave_category_id, company_master_id, leave_type_name, leave_type_code,
    description, leave_unit_type, is_active, effective_from, display_order, color_code, created_by
)
SELECT
    lcm.leave_category_id,
    cm.company_master_id,
    leave_data.leave_type_name,
    leave_data.leave_type_code,
    leave_data.description,
    leave_data.leave_unit_type::leave_unit_type,
    true,
    '2024-01-01'::DATE,
    leave_data.display_order,
    leave_data.color_code,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM leave_category_master lcm
CROSS JOIN company_master cm
CROSS JOIN (
    VALUES
        ('EL', 'Earned Leave', 'EL_001', 'Annual earned leave with carry forward and encashment', 'days', 1, '#2E8B57'),
        ('CL', 'Casual Leave', 'CL_001', 'Casual leave for personal work and emergencies', 'days', 2, '#4169E1'),
        ('SL', 'Sick Leave', 'SL_001', 'Medical leave with certificate requirements', 'days', 3, '#DC143C'),
        ('ML', 'Maternity Leave', 'ML_001', 'Maternity leave as per government regulations', 'days', 4, '#FF69B4'),
        ('PL', 'Paternity Leave', 'PL_001', 'Paternity leave for new fathers', 'days', 5, '#1E90FF'),
        ('CO', 'Compensatory Off', 'CO_001', 'Comp-off earned from overtime and holiday work', 'days', 6, '#FFD700'),
        ('LOP', 'Loss of Pay', 'LOP_001', 'Unpaid leave when paid leave balance is insufficient', 'days', 7, '#808080'),
        ('BL', 'Bereavement Leave', 'BL_001', 'Leave for death in immediate family', 'days', 8, '#2F4F4F'),
        ('MAL', 'Marriage Leave', 'MAL_001', 'Leave for employee marriage and family weddings', 'days', 9, '#DA70D6'),
        ('STL', 'Study Leave', 'STL_001', 'Leave for educational and professional development', 'days', 10, '#20B2AA')
) AS leave_data(category_code, leave_type_name, leave_type_code, description, leave_unit_type, display_order, color_code)
WHERE lcm.category_code = leave_data.category_code
AND cm.company_code = 'NXT001'; -- Nexus Technologies

-- =====================================================================================
-- SECTION 2: LEAVE POLICIES CONFIGURATION
-- =====================================================================================

-- Create comprehensive leave policies for different leave types
INSERT INTO leave_policy_master (
    leave_type_id, company_master_id, policy_name, policy_code, description,
    annual_entitlement, accrual_frequency, accrual_amount,
    applicable_during_probation, probation_accrual_rate,
    minimum_days_per_application, maximum_days_per_application, maximum_consecutive_days,
    allow_negative_balance, maximum_negative_balance,
    attachment_required_after_days, medical_certificate_required_after_days,
    minimum_advance_notice_days, maximum_advance_application_days,
    allow_carry_forward, maximum_carry_forward, carry_forward_expiry_months,
    allow_encashment, minimum_balance_for_encashment, maximum_encashment_days, encashment_rate,
    include_weekends, include_holidays, prorate_on_joining, prorate_on_leaving,
    effective_from, is_active, created_by
)
SELECT
    ltm.leave_type_id,
    ltm.company_master_id,
    policy_data.policy_name,
    policy_data.policy_code,
    policy_data.description,
    policy_data.annual_entitlement,
    policy_data.accrual_frequency::accrual_frequency_type,
    policy_data.accrual_amount,
    policy_data.applicable_during_probation,
    policy_data.probation_accrual_rate,
    policy_data.minimum_days_per_application,
    policy_data.maximum_days_per_application,
    policy_data.maximum_consecutive_days,
    policy_data.allow_negative_balance,
    policy_data.maximum_negative_balance,
    policy_data.attachment_required_after_days,
    policy_data.medical_certificate_required_after_days,
    policy_data.minimum_advance_notice_days,
    policy_data.maximum_advance_application_days,
    policy_data.allow_carry_forward,
    policy_data.maximum_carry_forward,
    policy_data.carry_forward_expiry_months,
    policy_data.allow_encashment,
    policy_data.minimum_balance_for_encashment,
    policy_data.maximum_encashment_days,
    policy_data.encashment_rate,
    policy_data.include_weekends,
    policy_data.include_holidays,
    policy_data.prorate_on_joining,
    policy_data.prorate_on_leaving,
    '2024-01-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM leave_type_master ltm
CROSS JOIN (
    VALUES
        -- Earned Leave Policy
        ('EL_001', 'Standard Earned Leave Policy', 'POL_EL_001',
         'Standard earned leave policy with monthly accrual and encashment',
         21.0, 'monthly', 1.75, false, 50.0, 0.5, 21.0, 15.0, false, 0.0,
         0, 0, 1, 365, true, 15.0, 12, true, 10.0, 15.0, 100.0,
         false, false, true, true),

        -- Casual Leave Policy
        ('CL_001', 'Standard Casual Leave Policy', 'POL_CL_001',
         'Casual leave policy with annual allocation',
         12.0, 'yearly', 12.0, true, 100.0, 0.5, 5.0, 3.0, false, 0.0,
         0, 0, 1, 365, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         false, false, true, true),

        -- Sick Leave Policy
        ('SL_001', 'Standard Sick Leave Policy', 'POL_SL_001',
         'Sick leave policy with medical certificate requirements',
         12.0, 'yearly', 12.0, true, 100.0, 0.5, 12.0, 7.0, true, 5.0,
         3, 2, 0, 30, true, 6.0, 12, false, 0.0, 0.0, 0.0,
         false, false, true, true),

        -- Maternity Leave Policy
        ('ML_001', 'Maternity Leave Policy', 'POL_ML_001',
         'Maternity leave as per Maternity Benefit Act',
         182.0, 'yearly', 182.0, false, 0.0, 7.0, 182.0, 182.0, false, 0.0,
         0, 0, 30, 90, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         true, true, false, false),

        -- Paternity Leave Policy
        ('PL_001', 'Paternity Leave Policy', 'POL_PL_001',
         'Paternity leave for new fathers',
         15.0, 'yearly', 15.0, true, 100.0, 1.0, 15.0, 15.0, false, 0.0,
         0, 0, 7, 90, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         true, true, false, false),

        -- Compensatory Off Policy
        ('CO_001', 'Compensatory Off Policy', 'POL_CO_001',
         'Comp-off policy for overtime and holiday work',
         30.0, 'monthly', 2.5, true, 100.0, 0.5, 5.0, 3.0, false, 0.0,
         0, 0, 1, 90, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         false, false, false, false),

        -- Loss of Pay Policy
        ('LOP_001', 'Loss of Pay Policy', 'POL_LOP_001',
         'Unpaid leave when other leave balances are exhausted',
         365.0, 'yearly', 365.0, true, 100.0, 0.5, 365.0, 30.0, false, 0.0,
         0, 0, 1, 30, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         true, true, false, false),

        -- Bereavement Leave Policy
        ('BL_001', 'Bereavement Leave Policy', 'POL_BL_001',
         'Leave for death in immediate family',
         5.0, 'yearly', 5.0, true, 100.0, 1.0, 5.0, 5.0, false, 0.0,
         0, 0, 0, 7, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         true, true, false, false),

        -- Marriage Leave Policy
        ('MAL_001', 'Marriage Leave Policy', 'POL_MAL_001',
         'Leave for marriage - employee and family',
         5.0, 'yearly', 5.0, true, 100.0, 1.0, 5.0, 5.0, false, 0.0,
         0, 0, 15, 90, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         true, true, false, false),

        -- Study Leave Policy
        ('STL_001', 'Study Leave Policy', 'POL_STL_001',
         'Leave for educational and professional development',
         10.0, 'yearly', 10.0, false, 0.0, 1.0, 10.0, 5.0, false, 0.0,
         0, 0, 30, 180, false, 0.0, 0, false, 0.0, 0.0, 0.0,
         false, false, true, true)
) AS policy_data(
    leave_type_code, policy_name, policy_code, description,
    annual_entitlement, accrual_frequency, accrual_amount,
    applicable_during_probation, probation_accrual_rate,
    minimum_days_per_application, maximum_days_per_application, maximum_consecutive_days,
    allow_negative_balance, maximum_negative_balance,
    attachment_required_after_days, medical_certificate_required_after_days,
    minimum_advance_notice_days, maximum_advance_application_days,
    allow_carry_forward, maximum_carry_forward, carry_forward_expiry_months,
    allow_encashment, minimum_balance_for_encashment, maximum_encashment_days, encashment_rate,
    include_weekends, include_holidays, prorate_on_joining, prorate_on_leaving
)
WHERE ltm.leave_type_code = policy_data.leave_type_code;

-- Create policy applicability rules - Apply all policies to all employees initially
INSERT INTO leave_policy_applicability (
    leave_policy_id, applies_to_all, is_inclusion, priority_order, created_by
)
SELECT
    lpm.leave_policy_id,
    true,
    true,
    1,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM leave_policy_master lpm
WHERE lpm.is_active = true;

-- Create specific policy applicability for maternity leave (only female employees)
UPDATE leave_policy_applicability SET
    applies_to_all = false
WHERE leave_policy_id IN (
    SELECT lpm.leave_policy_id
    FROM leave_policy_master lpm
    JOIN leave_type_master ltm ON lpm.leave_type_id = ltm.leave_type_id
    WHERE ltm.leave_type_code = 'ML_001'
);

-- =====================================================================================
-- SECTION 3: EMPLOYEE LEAVE ENTITLEMENTS SETUP
-- =====================================================================================

-- Assign leave policies to all active employees for 2024
INSERT INTO employee_leave_entitlement (
    employee_master_id, leave_policy_id, leave_type_id,
    entitlement_year, effective_from, effective_to,
    annual_entitlement, opening_balance, accrued_balance,
    used_balance, available_balance, carry_forward_balance,
    is_calculated, last_accrual_date, created_by
)
SELECT
    em.employee_master_id,
    lpm.leave_policy_id,
    lpm.leave_type_id,
    2024,
    '2024-01-01'::DATE,
    '2024-12-31'::DATE,
    CASE
        -- Prorate for employees who joined during the year
        WHEN em.date_of_joining > '2024-01-01' THEN
            ROUND(lpm.annual_entitlement *
                  (365 - (em.date_of_joining - '2024-01-01'::DATE)) / 365.0, 2)
        ELSE lpm.annual_entitlement
    END as annual_entitlement,
    CASE
        -- Set opening balance same as annual entitlement for most leave types
        WHEN ltm.leave_type_code IN ('CL_001', 'SL_001', 'BL_001', 'MAL_001', 'STL_001') THEN
            CASE
                WHEN em.date_of_joining > '2024-01-01' THEN
                    ROUND(lpm.annual_entitlement *
                          (365 - (em.date_of_joining - '2024-01-01'::DATE)) / 365.0, 2)
                ELSE lpm.annual_entitlement
            END
        -- Earned leave starts with 0 and accrues monthly
        WHEN ltm.leave_type_code = 'EL_001' THEN 0
        -- Special leaves start with 0
        ELSE 0
    END as opening_balance,
    CASE
        -- Calculate accrued balance for EL based on months completed
        WHEN ltm.leave_type_code = 'EL_001' THEN
            CASE
                WHEN em.date_of_joining <= '2024-01-01' THEN
                    ROUND(lpm.accrual_amount * 3, 2) -- 3 months accrued (Jan-Mar)
                ELSE
                    GREATEST(0, ROUND(lpm.accrual_amount *
                             (3 - EXTRACT(MONTHS FROM AGE('2024-03-01', em.date_of_joining))), 2))
            END
        ELSE 0
    END as accrued_balance,
    0 as used_balance, -- No leave used yet in sample data
    0 as available_balance, -- Will be calculated by trigger
    CASE
        -- Add some carry forward balance for senior employees
        WHEN ltm.leave_type_code = 'EL_001' AND em.date_of_joining < '2023-01-01' THEN
            ROUND(RANDOM() * 10 + 5, 1) -- 5-15 days carry forward
        ELSE 0
    END as carry_forward_balance,
    true,
    CASE
        WHEN ltm.leave_type_code = 'EL_001' THEN '2024-03-01'::DATE
        ELSE NULL
    END as last_accrual_date,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
CROSS JOIN leave_policy_master lpm
JOIN leave_type_master ltm ON lpm.leave_type_id = ltm.leave_type_id
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND lpm.is_active = true
-- Exclude maternity leave for male employees
AND NOT (ltm.leave_type_code = 'ML_001' AND em.gender = 'male')
-- Exclude paternity leave for female employees
AND NOT (ltm.leave_type_code = 'PL_001' AND em.gender = 'female')
-- Only include first 20 employees for sample data
AND em.employee_master_id IN (
    SELECT employee_master_id FROM employee_master
    WHERE row_status = 1 ORDER BY created_at LIMIT 20
);

-- =====================================================================================
-- SECTION 4: LEAVE BALANCE ADJUSTMENTS (ACCRUAL HISTORY)
-- =====================================================================================

-- Create accrual history for earned leave (January to March 2024)
INSERT INTO leave_balance_adjustment (
    employee_leave_entitlement_id, employee_master_id, leave_type_id,
    adjustment_date, adjustment_type, adjustment_amount,
    balance_before_adjustment, balance_after_adjustment,
    adjustment_reason, is_system_generated, created_by
)
SELECT
    ele.employee_leave_entitlement_id,
    ele.employee_master_id,
    ele.leave_type_id,
    accrual_data.adjustment_date,
    'credit'::balance_adjustment_type,
    lpm.accrual_amount,
    CASE accrual_data.month_num
        WHEN 1 THEN ele.carry_forward_balance
        WHEN 2 THEN ele.carry_forward_balance + lpm.accrual_amount
        WHEN 3 THEN ele.carry_forward_balance + (lpm.accrual_amount * 2)
    END as balance_before_adjustment,
    CASE accrual_data.month_num
        WHEN 1 THEN ele.carry_forward_balance + lpm.accrual_amount
        WHEN 2 THEN ele.carry_forward_balance + (lpm.accrual_amount * 2)
        WHEN 3 THEN ele.carry_forward_balance + (lpm.accrual_amount * 3)
    END as balance_after_adjustment,
    'Monthly earned leave accrual for ' || accrual_data.month_name,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_leave_entitlement ele
JOIN leave_policy_master lpm ON ele.leave_policy_id = lpm.leave_policy_id
JOIN leave_type_master ltm ON ele.leave_type_id = ltm.leave_type_id
CROSS JOIN (
    VALUES
        ('2024-01-01'::DATE, 'January 2024', 1),
        ('2024-02-01'::DATE, 'February 2024', 2),
        ('2024-03-01'::DATE, 'March 2024', 3)
) AS accrual_data(adjustment_date, month_name, month_num)
WHERE ltm.leave_type_code = 'EL_001'
AND lpm.accrual_frequency = 'monthly';

-- Add carry forward adjustments for employees with previous year balance
INSERT INTO leave_balance_adjustment (
    employee_leave_entitlement_id, employee_master_id, leave_type_id,
    adjustment_date, adjustment_type, adjustment_amount,
    balance_before_adjustment, balance_after_adjustment,
    adjustment_reason, is_system_generated, created_by
)
SELECT
    ele.employee_leave_entitlement_id,
    ele.employee_master_id,
    ele.leave_type_id,
    '2024-01-01'::DATE,
    'carry_forward'::balance_adjustment_type,
    ele.carry_forward_balance,
    0,
    ele.carry_forward_balance,
    'Carry forward from previous year 2023',
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_leave_entitlement ele
JOIN leave_type_master ltm ON ele.leave_type_id = ltm.leave_type_id
WHERE ltm.leave_type_code = 'EL_001'
AND ele.carry_forward_balance > 0;

-- =====================================================================================
-- SECTION 5: COMPENSATORY OFF CREDITS
-- =====================================================================================

-- Create some comp-off credits from overtime work
INSERT INTO comp_off_credit (
    employee_master_id, source_date, source_type, source_reference_id,
    credit_days, reason, credited_date, expiry_date,
    used_days, available_days, approved_by, approval_date, approval_status, created_by
)
SELECT
    em.employee_master_id,
    comp_data.source_date,
    comp_data.source_type,
    NULL, -- No specific reference for sample data
    comp_data.credit_days,
    comp_data.reason,
    comp_data.source_date,
    comp_data.source_date + INTERVAL '90 days', -- 90 days validity
    0,
    comp_data.credit_days,
    (SELECT user_master_id FROM user_master WHERE email = 'priya.sharma@nexustech.com'),
    comp_data.source_date + INTERVAL '1 day',
    'approved',
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
CROSS JOIN (
    VALUES
        ('2024-01-15'::DATE, 'overtime', 1.0, 'Worked overtime for project delivery'),
        ('2024-02-10'::DATE, 'weekend_work', 1.0, 'Weekend work for system maintenance'),
        ('2024-02-26'::DATE, 'holiday_work', 1.0, 'Worked on Republic Day holiday'),
        ('2024-03-05'::DATE, 'overtime', 0.5, 'Extended work for bug fixes'),
        ('2024-03-10'::DATE, 'holiday_work', 1.0, 'Worked on Holi holiday')
) AS comp_data(source_date, source_type, credit_days, reason)
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND RANDOM() > 0.7 -- Only 30% of employees get comp-off
LIMIT 15; -- Limit to 15 records for sample data

-- =====================================================================================
-- SECTION 6: LEAVE APPLICATIONS
-- =====================================================================================

-- Create diverse leave applications with different statuses
DO $$
DECLARE
    v_employee RECORD;
    v_leave_type RECORD;
    v_app_count INTEGER := 0;
    v_from_date DATE;
    v_to_date DATE;
    v_days DECIMAL(4,2);
    v_reason TEXT;
    v_status leave_application_status;
    v_approver_id UUID;
BEGIN
    -- Loop through employees and create realistic leave applications
    FOR v_employee IN
        SELECT em.employee_master_id, em.employee_code, em.full_name
        FROM employee_master em
        WHERE em.row_status = 1
        AND em.employment_status = 'active'
        ORDER BY em.created_at
        LIMIT 15
    LOOP
        -- Create 2-4 leave applications per employee
        FOR i IN 1..(2 + (RANDOM() * 3)::INTEGER) LOOP
            -- Select random leave type (avoid special leaves like maternity/paternity)
            SELECT ltm.leave_type_id, ltm.leave_type_name, ltm.leave_type_code
            INTO v_leave_type
            FROM leave_type_master ltm
            WHERE ltm.leave_type_code IN ('EL_001', 'CL_001', 'SL_001', 'CO_001', 'BL_001')
            ORDER BY RANDOM()
            LIMIT 1;

            -- Generate random leave dates (Jan-Mar 2024)
            v_from_date := '2024-01-01'::DATE + (RANDOM() * 80)::INTEGER;

            -- Generate leave duration based on leave type
            v_days := CASE v_leave_type.leave_type_code
                WHEN 'EL_001' THEN 1 + (RANDOM() * 8)::INTEGER -- 1-9 days
                WHEN 'CL_001' THEN 1 + (RANDOM() * 2)::INTEGER -- 1-3 days
                WHEN 'SL_001' THEN 1 + (RANDOM() * 4)::INTEGER -- 1-5 days
                WHEN 'CO_001' THEN 1 + (RANDOM() * 1)::INTEGER -- 1-2 days
                WHEN 'BL_001' THEN 2 + (RANDOM() * 2)::INTEGER -- 2-4 days
                ELSE 1
            END;

            v_to_date := v_from_date + (v_days - 1)::INTEGER;

            -- Generate appropriate reason
            v_reason := CASE v_leave_type.leave_type_code
                WHEN 'EL_001' THEN CASE (RANDOM() * 4)::INTEGER
                    WHEN 0 THEN 'Family vacation and personal time'
                    WHEN 1 THEN 'Wedding function in family'
                    WHEN 2 THEN 'Personal work and relaxation'
                    ELSE 'Annual vacation with family'
                END
                WHEN 'CL_001' THEN CASE (RANDOM() * 4)::INTEGER
                    WHEN 0 THEN 'Personal work and bank visits'
                    WHEN 1 THEN 'House shifting and relocation'
                    WHEN 2 THEN 'Family function attendance'
                    ELSE 'Emergency personal work'
                END
                WHEN 'SL_001' THEN CASE (RANDOM() * 3)::INTEGER
                    WHEN 0 THEN 'Fever and viral infection'
                    WHEN 1 THEN 'Medical checkup and treatment'
                    ELSE 'Health issues and rest'
                END
                WHEN 'CO_001' THEN 'Using compensatory off for personal time'
                WHEN 'BL_001' THEN 'Death in family and funeral arrangements'
                ELSE 'General leave request'
            END;

            -- Determine application status (realistic distribution)
            v_status := CASE (RANDOM() * 10)::INTEGER
                WHEN 0, 1 THEN 'pending_approval'::leave_application_status
                WHEN 2 THEN 'rejected'::leave_application_status
                WHEN 3 THEN 'submitted'::leave_application_status
                ELSE 'approved'::leave_application_status
            END;

            -- Select random approver
            SELECT user_master_id INTO v_approver_id
            FROM user_master
            WHERE email IN ('priya.sharma@nexustech.com', 'amit.kumar@nexustech.com',
                           'rajesh.singh@nexustech.com', 'sneha.patel@nexustech.com')
            ORDER BY RANDOM()
            LIMIT 1;

            -- Insert leave application
            INSERT INTO leave_application (
                employee_master_id, leave_type_id, leave_policy_id,
                application_date, leave_from_date, leave_to_date, leave_days,
                reason, application_status, current_approver_id,
                submitted_date, approved_date,
                balance_before_application, balance_after_application,
                created_by
            ) SELECT
                v_employee.employee_master_id,
                v_leave_type.leave_type_id,
                lpm.leave_policy_id,
                v_from_date - INTERVAL '2 days', -- Applied 2 days before
                v_from_date,
                v_to_date,
                v_days,
                v_reason,
                v_status,
                CASE WHEN v_status != 'draft' THEN v_approver_id ELSE NULL END,
                CASE WHEN v_status != 'draft' THEN v_from_date - INTERVAL '2 days' ELSE NULL END,
                CASE WHEN v_status = 'approved' THEN v_from_date ELSE NULL END,
                ele.available_balance,
                CASE WHEN v_status = 'approved' THEN ele.available_balance - v_days ELSE ele.available_balance END,
                (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
            FROM leave_policy_master lpm
            JOIN employee_leave_entitlement ele ON
                lpm.leave_policy_id = ele.leave_policy_id
                AND ele.employee_master_id = v_employee.employee_master_id
            WHERE lpm.leave_type_id = v_leave_type.leave_type_id
            LIMIT 1;

            v_app_count := v_app_count + 1;

            -- Don't create too many applications
            EXIT WHEN v_app_count >= 40;
        END LOOP;

        EXIT WHEN v_app_count >= 40;
    END LOOP;
END $$;

-- =====================================================================================
-- SECTION 7: LEAVE APPLICATION APPROVALS
-- =====================================================================================

-- Create approval records for submitted and processed applications
INSERT INTO leave_application_approval (
    leave_application_id, approver_id, approval_level, approval_order,
    approval_status, approval_date, comments, is_current_approver, created_by
)
SELECT
    la.leave_application_id,
    la.current_approver_id,
    1,
    1,
    CASE la.application_status
        WHEN 'approved' THEN 'approved'
        WHEN 'rejected' THEN 'rejected'
        WHEN 'pending_approval' THEN 'pending'
        ELSE 'pending'
    END,
    CASE
        WHEN la.application_status IN ('approved', 'rejected') THEN la.approved_date
        ELSE NULL
    END,
    CASE la.application_status
        WHEN 'approved' THEN 'Leave approved. Please ensure work handover.'
        WHEN 'rejected' THEN CASE (RANDOM() * 3)::INTEGER
            WHEN 0 THEN 'Leave rejected due to project deadlines'
            WHEN 1 THEN 'Insufficient leave balance available'
            ELSE 'Leave dates conflict with critical business activity'
        END
        ELSE NULL
    END,
    CASE WHEN la.application_status = 'pending_approval' THEN true ELSE false END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM leave_application la
WHERE la.current_approver_id IS NOT NULL;

-- =====================================================================================
-- SECTION 8: UPDATE LEAVE BALANCES FOR APPROVED APPLICATIONS
-- =====================================================================================

-- Update leave entitlements for approved applications
UPDATE employee_leave_entitlement SET
    used_balance = used_balance + approved_usage.total_days_used,
    updated_at = CURRENT_TIMESTAMP
FROM (
    SELECT
        la.employee_master_id,
        la.leave_type_id,
        SUM(la.leave_days) as total_days_used
    FROM leave_application la
    WHERE la.application_status = 'approved'
    GROUP BY la.employee_master_id, la.leave_type_id
) AS approved_usage
WHERE employee_leave_entitlement.employee_master_id = approved_usage.employee_master_id
AND employee_leave_entitlement.leave_type_id = approved_usage.leave_type_id;

-- Create balance adjustment records for approved leave applications
INSERT INTO leave_balance_adjustment (
    employee_leave_entitlement_id, employee_master_id, leave_type_id,
    adjustment_date, adjustment_type, adjustment_amount,
    balance_before_adjustment, balance_after_adjustment,
    adjustment_reason, reference_id, reference_type, created_by
)
SELECT
    ele.employee_leave_entitlement_id,
    la.employee_master_id,
    la.leave_type_id,
    la.leave_from_date,
    'debit'::balance_adjustment_type,
    la.leave_days,
    la.balance_before_application,
    la.balance_after_application,
    'Leave application: ' || la.application_number || ' - ' || LEFT(la.reason, 50),
    la.leave_application_id,
    'leave_application',
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM leave_application la
JOIN employee_leave_entitlement ele ON
    la.employee_master_id = ele.employee_master_id
    AND la.leave_type_id = ele.leave_type_id
WHERE la.application_status = 'approved';

-- =====================================================================================
-- SECTION 9: LEAVE ENCASHMENT REQUESTS
-- =====================================================================================

-- Create some leave encashment requests for senior employees
INSERT INTO leave_encashment (
    employee_master_id, leave_type_id, encashment_date,
    encashment_days, daily_wage, encashment_amount,
    encashment_year, available_balance, balance_after_encashment,
    approval_status, approved_by, approval_date,
    employee_comments, created_by
)
SELECT
    em.employee_master_id,
    ele.leave_type_id,
    '2024-03-15'::DATE,
    CASE
        WHEN ele.available_balance >= 20 THEN 15.0
        WHEN ele.available_balance >= 15 THEN 10.0
        WHEN ele.available_balance >= 10 THEN 5.0
        ELSE 0
    END as encashment_days,
    ROUND(em.basic_salary / 30, 2) as daily_wage,
    ROUND((em.basic_salary / 30) *
          CASE
              WHEN ele.available_balance >= 20 THEN 15.0
              WHEN ele.available_balance >= 15 THEN 10.0
              WHEN ele.available_balance >= 10 THEN 5.0
              ELSE 0
          END, 2) as encashment_amount,
    2024,
    ele.available_balance,
    ele.available_balance -
    CASE
        WHEN ele.available_balance >= 20 THEN 15.0
        WHEN ele.available_balance >= 15 THEN 10.0
        WHEN ele.available_balance >= 10 THEN 5.0
        ELSE 0
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'approved'
        ELSE 'approved'
    END,
    (SELECT user_master_id FROM user_master WHERE email = 'priya.sharma@nexustech.com'),
    '2024-03-16'::DATE,
    'Request for leave encashment as per company policy',
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
JOIN employee_leave_entitlement ele ON em.employee_master_id = ele.employee_master_id
JOIN leave_type_master ltm ON ele.leave_type_id = ltm.leave_type_id
WHERE ltm.leave_type_code = 'EL_001'
AND ele.available_balance >= 10
AND em.date_of_joining < '2023-01-01' -- Only senior employees
AND RANDOM() > 0.7 -- Only 30% of eligible employees
LIMIT 8;

-- =====================================================================================
-- SECTION 10: VERIFICATION QUERIES AND STATISTICS
-- =====================================================================================

-- Summary statistics for verification
SELECT
    'Total Leave Types Configured' as metric,
    COUNT(*) as count
FROM leave_type_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Leave Policies Active' as metric,
    COUNT(*) as count
FROM leave_policy_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Employee Leave Entitlements' as metric,
    COUNT(*) as count
FROM employee_leave_entitlement

UNION ALL

SELECT
    'Total Leave Applications' as metric,
    COUNT(*) as count
FROM leave_application

UNION ALL

SELECT
    'Total Comp-off Credits' as metric,
    COUNT(*) as count
FROM comp_off_credit

UNION ALL

SELECT
    'Total Encashment Requests' as metric,
    COUNT(*) as count
FROM leave_encashment;

-- Leave application status distribution
SELECT
    'Application Status Distribution' as category,
    application_status,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) as percentage
FROM leave_application
GROUP BY application_status
ORDER BY count DESC;

-- Leave type usage analysis
SELECT
    'Leave Type Usage' as category,
    ltm.leave_type_name,
    COUNT(la.leave_application_id) as total_applications,
    COUNT(CASE WHEN la.application_status = 'approved' THEN 1 END) as approved_applications,
    SUM(CASE WHEN la.application_status = 'approved' THEN la.leave_days ELSE 0 END) as total_days_approved,
    ROUND(AVG(CASE WHEN la.application_status = 'approved' THEN la.leave_days END), 2) as avg_days_per_application
FROM leave_type_master ltm
LEFT JOIN leave_application la ON ltm.leave_type_id = la.leave_type_id
GROUP BY ltm.leave_type_id, ltm.leave_type_name
ORDER BY total_applications DESC;

-- Employee leave balance summary
SELECT
    'Employee Leave Balance Summary' as category,
    em.employee_code,
    em.full_name,
    ltm.leave_type_name,
    ele.annual_entitlement,
    ele.available_balance,
    ele.used_balance,
    ROUND((ele.used_balance / NULLIF(ele.annual_entitlement, 0)) * 100, 2) as utilization_percentage
FROM employee_leave_entitlement ele
JOIN employee_master em ON ele.employee_master_id = em.employee_master_id
JOIN leave_type_master ltm ON ele.leave_type_id = ltm.leave_type_id
WHERE ltm.leave_type_code = 'EL_001' -- Focus on earned leave
ORDER BY em.employee_code;

-- Monthly leave application trends
SELECT
    'Monthly Application Trends' as category,
    TO_CHAR(application_date, 'YYYY-MM') as application_month,
    COUNT(*) as total_applications,
    COUNT(CASE WHEN application_status = 'approved' THEN 1 END) as approved_applications,
    SUM(CASE WHEN application_status = 'approved' THEN leave_days ELSE 0 END) as total_approved_days
FROM leave_application
GROUP BY TO_CHAR(application_date, 'YYYY-MM')
ORDER BY application_month;

-- =====================================================================================
-- END OF LEAVE MANAGEMENT SAMPLE DATA
-- =====================================================================================