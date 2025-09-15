-- =====================================================================================
-- NEXUS HRMS - Attendance Management Sample Data
-- Comprehensive test data for attendance, shifts, and time tracking
-- =====================================================================================
-- Dependencies: Employee Master, Organizational Structure, Company Master
-- Purpose: Realistic attendance scenarios for testing and development
-- =====================================================================================

-- =====================================================================================
-- SECTION 1: CALENDAR AND HOLIDAY SETUP
-- =====================================================================================

-- Create 2024 calendar for our sample companies
INSERT INTO calendar_master (
    calendar_name, calendar_year, company_master_id, description, is_default, created_by
) VALUES
    ('Nexus Tech 2024 Calendar', 2024,
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Official company calendar for Nexus Technologies 2024', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('TechCorp 2024 Calendar', 2024,
     (SELECT company_master_id FROM company_master WHERE company_code = 'TC002'),
     'Official company calendar for TechCorp Industries 2024', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Insert comprehensive holiday data for 2024
WITH calendar_ids AS (
    SELECT calendar_id, calendar_name
    FROM calendar_master
    WHERE calendar_year = 2024
)
INSERT INTO holiday_master (
    holiday_name, holiday_date, holiday_type, calendar_master_id, description, is_optional, created_by
)
SELECT
    holiday_data.holiday_name,
    holiday_data.holiday_date,
    holiday_data.holiday_type::holiday_type,
    ci.calendar_id,
    holiday_data.description,
    holiday_data.is_optional,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM calendar_ids ci
CROSS JOIN (
    VALUES
        ('New Year Day', '2024-01-01', 'national', 'New Year celebration', false),
        ('Republic Day', '2024-01-26', 'national', 'Republic Day of India', false),
        ('Holi', '2024-03-25', 'religious', 'Festival of Colors', false),
        ('Good Friday', '2024-03-29', 'religious', 'Christian holy day', false),
        ('Eid ul-Fitr', '2024-04-11', 'religious', 'End of Ramadan', false),
        ('Labour Day', '2024-05-01', 'national', 'International Workers Day', false),
        ('Independence Day', '2024-08-15', 'national', 'Independence Day of India', false),
        ('Ganesh Chaturthi', '2024-09-07', 'regional', 'Lord Ganesha festival', true),
        ('Gandhi Jayanti', '2024-10-02', 'national', 'Birth anniversary of Mahatma Gandhi', false),
        ('Dussehra', '2024-10-12', 'religious', 'Victory of good over evil', false),
        ('Diwali', '2024-11-01', 'religious', 'Festival of Lights', false),
        ('Bhai Dooj', '2024-11-03', 'religious', 'Brother-sister festival', true),
        ('Christmas', '2024-12-25', 'religious', 'Birth of Jesus Christ', false),
        ('Company Foundation Day', '2024-06-15', 'company', 'Company anniversary celebration', false),
        ('Annual Day', '2024-12-20', 'company', 'Annual company celebration', false)
) AS holiday_data(holiday_name, holiday_date, holiday_type, description, is_optional);

-- =====================================================================================
-- SECTION 2: SHIFT MASTER SETUP
-- =====================================================================================

-- Create comprehensive shift patterns
INSERT INTO shift_master (
    shift_code, shift_name, shift_type, template_name, description,
    shift_start_time, shift_end_time, shift_end_day, standard_hours,
    is_break_included, total_break_time, grace_time_in, grace_time_out,
    late_coming_cutoff, early_going_cutoff, overtime_applicable,
    overtime_start_after, max_overtime_hours, overtime_calc_method,
    overtime_rate, minimum_hours_for_present, minimum_hours_for_half_day,
    effective_from, company_master_id, created_by
) VALUES
    -- General Day Shift
    ('GEN001', 'General Day Shift', 'general', 'Standard 9-6 Shift',
     'Standard office hours for corporate employees',
     '09:00:00', '18:00:00', 0, '09:00:00',
     true, '01:00:00', '00:15:00', '00:15:00',
     '00:30:00', '00:30:00', true,
     '01:00:00', '04:00:00', 'percentage',
     150.00, '07:00:00', '04:00:00',
     '2024-01-01',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Flexible Shift
    ('FLEX001', 'Flexible Hours', 'flexible', 'Flexible Working Hours',
     'Flexible working hours for senior employees',
     '09:00:00', '18:00:00', 0, '08:00:00',
     true, '01:00:00', '01:00:00', '01:00:00',
     '02:00:00', '02:00:00', true,
     '00:30:00', '06:00:00', 'percentage',
     150.00, '06:00:00', '03:00:00',
     '2024-01-01',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Night Shift
    ('NIGHT001', 'Night Shift', 'night', 'Night Operations',
     'Night shift for 24/7 operations',
     '22:00:00', '07:00:00', 1, '09:00:00',
     true, '01:00:00', '00:30:00', '00:30:00',
     '01:00:00', '01:00:00', true,
     '01:00:00', '04:00:00', 'percentage',
     175.00, '07:00:00', '04:00:00',
     '2024-01-01',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Early Morning Shift
    ('EARLY001', 'Early Morning Shift', 'general', 'Early Bird Shift',
     'Early morning shift for specific departments',
     '07:00:00', '16:00:00', 0, '09:00:00',
     true, '01:00:00', '00:15:00', '00:15:00',
     '00:30:00', '00:30:00', true,
     '01:00:00', '03:00:00', 'percentage',
     150.00, '07:00:00', '04:00:00',
     '2024-01-01',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Weekend Shift
    ('WKND001', 'Weekend Shift', 'general', 'Weekend Operations',
     'Weekend shift for continuous operations',
     '10:00:00', '19:00:00', 0, '09:00:00',
     true, '01:00:00', '00:30:00', '00:30:00',
     '01:00:00', '01:00:00', true,
     '01:00:00', '05:00:00', 'percentage',
     200.00, '07:00:00', '04:00:00',
     '2024-01-01',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Add break periods for shifts
INSERT INTO shift_break_periods (
    shift_master_id, break_name, break_start_time, break_end_time,
    break_duration, is_paid, break_order, created_by
)
SELECT
    sm.shift_master_id,
    break_data.break_name,
    break_data.break_start_time::TIME,
    break_data.break_end_time::TIME,
    break_data.break_duration::INTERVAL,
    break_data.is_paid,
    break_data.break_order,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM shift_master sm
CROSS JOIN (
    VALUES
        ('Tea Break', '10:30:00', '10:45:00', '00:15:00', true, 1),
        ('Lunch Break', '13:00:00', '14:00:00', '01:00:00', true, 2),
        ('Evening Tea', '16:30:00', '16:45:00', '00:15:00', true, 3)
) AS break_data(break_name, break_start_time, break_end_time, break_duration, is_paid, break_order)
WHERE sm.shift_code IN ('GEN001', 'FLEX001', 'EARLY001');

-- Add night shift breaks
INSERT INTO shift_break_periods (
    shift_master_id, break_name, break_start_time, break_end_time,
    break_duration, is_paid, break_order, created_by
)
SELECT
    sm.shift_master_id,
    break_data.break_name,
    break_data.break_start_time::TIME,
    break_data.break_end_time::TIME,
    break_data.break_duration::INTERVAL,
    break_data.is_paid,
    break_data.break_order,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM shift_master sm
CROSS JOIN (
    VALUES
        ('Night Tea Break', '00:30:00', '00:45:00', '00:15:00', true, 1),
        ('Night Meal Break', '03:00:00', '04:00:00', '01:00:00', true, 2),
        ('Early Morning Break', '06:00:00', '06:15:00', '00:15:00', true, 3)
) AS break_data(break_name, break_start_time, break_end_time, break_duration, is_paid, break_order)
WHERE sm.shift_code = 'NIGHT001';

-- =====================================================================================
-- SECTION 3: SHIFT ASSIGNMENT RULES
-- =====================================================================================

-- Create shift assignment rules based on organizational hierarchy
INSERT INTO shift_assignment_rules (
    shift_master_id, rule_name, applies_to_all, priority_order,
    effective_from, created_by
) VALUES
    -- Management and senior roles get flexible shifts
    ((SELECT shift_master_id FROM shift_master WHERE shift_code = 'FLEX001'),
     'Senior Management Flexible Hours', false, 1, '2024-01-01',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- IT Department gets general day shift
    ((SELECT shift_master_id FROM shift_master WHERE shift_code = 'GEN001'),
     'IT Department Standard Hours', false, 2, '2024-01-01',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Support team for night operations
    ((SELECT shift_master_id FROM shift_master WHERE shift_code = 'NIGHT001'),
     'Support Operations Night Shift', false, 3, '2024-01-01',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    -- Early shift for facilities and security
    ((SELECT shift_master_id FROM shift_master WHERE shift_code = 'EARLY001'),
     'Facilities Early Shift', false, 4, '2024-01-01',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Define assignment criteria for flexible shift (senior management)
INSERT INTO shift_assignment_criteria (
    shift_assignment_rule_id, designation_master_id, employee_grade_id,
    is_inclusion, created_by
)
SELECT
    sar.shift_assignment_rule_id,
    dm.designation_master_id,
    eg.employee_grade_id,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM shift_assignment_rules sar
CROSS JOIN designation_master dm
CROSS JOIN employee_grade eg
WHERE sar.rule_name = 'Senior Management Flexible Hours'
AND dm.designation_name IN ('Chief Executive Officer', 'Chief Technology Officer', 'VP Engineering', 'Director Finance')
AND eg.grade_name IN ('Executive', 'Senior Manager', 'Manager');

-- Define criteria for IT department standard hours
INSERT INTO shift_assignment_criteria (
    shift_assignment_rule_id, department_master_id, is_inclusion, created_by
)
SELECT
    sar.shift_assignment_rule_id,
    dept.department_master_id,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM shift_assignment_rules sar
CROSS JOIN department_master dept
WHERE sar.rule_name = 'IT Department Standard Hours'
AND dept.department_name IN ('Information Technology', 'Software Development', 'Quality Assurance');

-- =====================================================================================
-- SECTION 4: BIOMETRIC DEVICE SETUP
-- =====================================================================================

-- Setup biometric devices for different locations
INSERT INTO biometric_device_master (
    device_code, device_name, device_ip, device_port, device_type,
    device_model, location_master_id, is_active, sync_interval_minutes,
    supports_multiple_punch, max_punch_per_day, created_by
) VALUES
    ('BIO001', 'Main Entrance Device', '192.168.1.100', 4370, 'ZKTeco',
     'K40 Pro',
     (SELECT location_master_id FROM location_master WHERE location_name = 'Bangalore Corporate Office'),
     true, 15, true, 10,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('BIO002', 'IT Floor Device', '192.168.1.101', 4370, 'ZKTeco',
     'K40 Pro',
     (SELECT location_master_id FROM location_master WHERE location_name = 'Bangalore Corporate Office'),
     true, 15, true, 10,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('BIO003', 'Mumbai Office Main', '192.168.2.100', 4370, 'eSSL',
     'eSSL MB160',
     (SELECT location_master_id FROM location_master WHERE location_name = 'Mumbai Branch Office'),
     true, 10, true, 8,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('BIO004', 'Hyderabad Entrance', '192.168.3.100', 4370, 'Realtime',
     'RT T502',
     (SELECT location_master_id FROM location_master WHERE location_name = 'Hyderabad Development Center'),
     true, 20, true, 12,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Map employees to biometric devices
INSERT INTO employee_biometric_mapping (
    employee_master_id, biometric_device_id, device_employee_id,
    enrollment_date, is_active, created_by
)
SELECT
    em.employee_master_id,
    bdm.biometric_device_id,
    em.employee_code, -- Using employee code as device employee ID
    '2024-01-15'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
CROSS JOIN biometric_device_master bdm
JOIN location_master lm ON bdm.location_master_id = lm.location_master_id
WHERE em.location_master_id = lm.location_master_id
AND em.row_status = 1
AND bdm.is_active = true;

-- =====================================================================================
-- SECTION 5: EMPLOYEE SHIFT ASSIGNMENTS
-- =====================================================================================

-- Assign shifts to all employees based on their roles and departments
INSERT INTO employee_shift_assignment (
    employee_master_id, shift_master_id, assignment_date, effective_from,
    is_manual_assignment, assignment_reason, created_by
)
SELECT
    em.employee_master_id,
    CASE
        -- Senior management gets flexible shift
        WHEN dm.designation_name IN ('Chief Executive Officer', 'Chief Technology Officer', 'VP Engineering', 'Director Finance')
        THEN (SELECT shift_master_id FROM shift_master WHERE shift_code = 'FLEX001')

        -- IT departments get general shift
        WHEN dept.department_name IN ('Information Technology', 'Software Development', 'Quality Assurance')
        THEN (SELECT shift_master_id FROM shift_master WHERE shift_code = 'GEN001')

        -- Support and operations get general shift
        WHEN dept.department_name IN ('Human Resources', 'Finance', 'Administration')
        THEN (SELECT shift_master_id FROM shift_master WHERE shift_code = 'GEN001')

        -- Default to general shift
        ELSE (SELECT shift_master_id FROM shift_master WHERE shift_code = 'GEN001')
    END as shift_master_id,
    '2024-01-01'::DATE,
    '2024-01-01'::DATE,
    true,
    'Initial shift assignment based on role and department',
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
LEFT JOIN designation_master dm ON em.designation_master_id = dm.designation_master_id
LEFT JOIN department_master dept ON em.department_master_id = dept.department_master_id
WHERE em.row_status = 1
AND em.employment_status = 'active';

-- =====================================================================================
-- SECTION 6: OVERTIME POLICY SETUP
-- =====================================================================================

-- Create overtime policies for different employee categories
INSERT INTO overtime_policy (
    policy_name, company_master_id, minimum_overtime_hours,
    maximum_daily_overtime, maximum_monthly_overtime, overtime_calc_method,
    overtime_rate, requires_pre_approval, auto_approve_threshold,
    round_to_minutes, effective_from, is_active, created_by
) VALUES
    ('Standard Overtime Policy',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     '00:30:00', '04:00:00', '50:00:00', 'percentage', 150.00,
     false, '02:00:00', 15, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ('Senior Staff Overtime Policy',
     (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     '01:00:00', '06:00:00', '80:00:00', 'percentage', 175.00,
     true, '03:00:00', 30, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- =====================================================================================
-- SECTION 7: SAMPLE BIOMETRIC PUNCH DATA (MARCH 2024)
-- =====================================================================================

-- Generate realistic punch data for the first week of March 2024
-- This creates a comprehensive set of attendance scenarios

-- Helper function to generate punch times
DO $$
DECLARE
    v_employee RECORD;
    v_device RECORD;
    v_date DATE;
    v_punch_in_time TIMESTAMP;
    v_punch_out_time TIMESTAMP;
    v_lunch_out_time TIMESTAMP;
    v_lunch_in_time TIMESTAMP;
    v_shift RECORD;
    v_variation INTEGER;
BEGIN
    -- Loop through first 10 working days of March 2024
    FOR v_date IN
        SELECT generate_series('2024-03-01'::DATE, '2024-03-15'::DATE, '1 day'::INTERVAL)::DATE
        WHERE EXTRACT(DOW FROM generate_series('2024-03-01'::DATE, '2024-03-15'::DATE, '1 day'::INTERVAL)) NOT IN (0,6) -- Exclude weekends
    LOOP
        -- Generate punches for each employee
        FOR v_employee IN
            SELECT em.employee_master_id, em.employee_code, esa.shift_master_id
            FROM employee_master em
            JOIN employee_shift_assignment esa ON em.employee_master_id = esa.employee_master_id
            WHERE em.row_status = 1
            AND v_date BETWEEN esa.effective_from AND COALESCE(esa.effective_to, '2099-12-31')
            LIMIT 20 -- Limit to first 20 employees for sample data
        LOOP
            -- Get shift details
            SELECT shift_start_time, shift_end_time, shift_name
            INTO v_shift
            FROM shift_master
            WHERE shift_master_id = v_employee.shift_master_id;

            -- Get biometric device for employee
            SELECT bdm.biometric_device_id
            INTO v_device
            FROM employee_biometric_mapping ebm
            JOIN biometric_device_master bdm ON ebm.biometric_device_id = bdm.biometric_device_id
            WHERE ebm.employee_master_id = v_employee.employee_master_id
            AND ebm.is_active = true
            LIMIT 1;

            -- Skip if no device mapping
            CONTINUE WHEN v_device.biometric_device_id IS NULL;

            -- Generate realistic variations in punch times
            v_variation := (RANDOM() * 40 - 20)::INTEGER; -- -20 to +20 minutes variation

            -- Calculate punch times based on shift
            v_punch_in_time := v_date + v_shift.shift_start_time + (v_variation || ' minutes')::INTERVAL;
            v_punch_out_time := v_date + v_shift.shift_end_time + (v_variation || ' minutes')::INTERVAL;

            -- Add lunch break punches (out and in)
            v_lunch_out_time := v_date + '13:00:00'::TIME + ((RANDOM() * 20 - 10)::INTEGER || ' minutes')::INTERVAL;
            v_lunch_in_time := v_lunch_out_time + '01:00:00'::INTERVAL + ((RANDOM() * 20 - 10)::INTEGER || ' minutes')::INTERVAL;

            -- Insert morning punch in
            INSERT INTO biometric_punch_log (
                biometric_device_id, device_employee_id, device_log_id,
                punch_time, punch_date, is_processed, employee_master_id, punch_type
            ) VALUES (
                v_device.biometric_device_id, v_employee.employee_code,
                'LOG_' || v_employee.employee_code || '_' || v_date || '_IN1',
                v_punch_in_time, v_date, true, v_employee.employee_master_id, 'in'
            );

            -- Insert lunch out punch (70% probability)
            IF RANDOM() > 0.3 THEN
                INSERT INTO biometric_punch_log (
                    biometric_device_id, device_employee_id, device_log_id,
                    punch_time, punch_date, is_processed, employee_master_id, punch_type
                ) VALUES (
                    v_device.biometric_device_id, v_employee.employee_code,
                    'LOG_' || v_employee.employee_code || '_' || v_date || '_OUT_LUNCH',
                    v_lunch_out_time, v_date, true, v_employee.employee_master_id, 'break_out'
                );

                -- Insert lunch in punch
                INSERT INTO biometric_punch_log (
                    biometric_device_id, device_employee_id, device_log_id,
                    punch_time, punch_date, is_processed, employee_master_id, punch_type
                ) VALUES (
                    v_device.biometric_device_id, v_employee.employee_code,
                    'LOG_' || v_employee.employee_code || '_' || v_date || '_IN_LUNCH',
                    v_lunch_in_time, v_date, true, v_employee.employee_master_id, 'break_in'
                );
            END IF;

            -- Insert evening punch out (95% probability - some may forget to punch out)
            IF RANDOM() > 0.05 THEN
                INSERT INTO biometric_punch_log (
                    biometric_device_id, device_employee_id, device_log_id,
                    punch_time, punch_date, is_processed, employee_master_id, punch_type
                ) VALUES (
                    v_device.biometric_device_id, v_employee.employee_code,
                    'LOG_' || v_employee.employee_code || '_' || v_date || '_OUT1',
                    v_punch_out_time, v_date, true, v_employee.employee_master_id, 'out'
                );
            END IF;

            -- Add some overtime punches (20% probability)
            IF RANDOM() > 0.8 THEN
                INSERT INTO biometric_punch_log (
                    biometric_device_id, device_employee_id, device_log_id,
                    punch_time, punch_date, is_processed, employee_master_id, punch_type
                ) VALUES (
                    v_device.biometric_device_id, v_employee.employee_code,
                    'LOG_' || v_employee.employee_code || '_' || v_date || '_OT_OUT',
                    v_punch_out_time + '02:30:00'::INTERVAL, v_date, true, v_employee.employee_master_id, 'out'
                );
            END IF;

        END LOOP;
    END LOOP;
END $$;

-- =====================================================================================
-- SECTION 8: PROCESS ATTENDANCE ENTRIES
-- =====================================================================================

-- Create attendance entries based on biometric punches
INSERT INTO attendance_entry (
    employee_master_id, attendance_date, shift_master_id,
    first_punch_in, last_punch_out, total_punches,
    attendance_status, created_by
)
SELECT
    bpl.employee_master_id,
    bpl.punch_date,
    esa.shift_master_id,
    MIN(CASE WHEN bpl.punch_type = 'in' THEN bpl.punch_time END) as first_punch_in,
    MAX(CASE WHEN bpl.punch_type = 'out' THEN bpl.punch_time END) as last_punch_out,
    COUNT(*) as total_punches,
    CASE
        WHEN MIN(CASE WHEN bpl.punch_type = 'in' THEN bpl.punch_time END) IS NULL THEN 'absent'::attendance_status_type
        WHEN MAX(CASE WHEN bpl.punch_type = 'out' THEN bpl.punch_time END) IS NULL THEN 'present'::attendance_status_type
        ELSE 'present'::attendance_status_type
    END as attendance_status,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM biometric_punch_log bpl
JOIN employee_shift_assignment esa ON
    bpl.employee_master_id = esa.employee_master_id
    AND bpl.punch_date BETWEEN esa.effective_from AND COALESCE(esa.effective_to, '2099-12-31')
WHERE bpl.is_processed = true
GROUP BY bpl.employee_master_id, bpl.punch_date, esa.shift_master_id
ORDER BY bpl.punch_date, bpl.employee_master_id;

-- =====================================================================================
-- SECTION 9: CALCULATE WORKING HOURS AND ATTENDANCE STATUS
-- =====================================================================================

-- Update attendance entries with calculated hours and status
UPDATE attendance_entry ae
SET
    actual_hours_worked = CASE
        WHEN ae.first_punch_in IS NOT NULL AND ae.last_punch_out IS NOT NULL
        THEN ae.last_punch_out - ae.first_punch_in - COALESCE(break_calc.total_break_time, '01:00:00'::INTERVAL)
        ELSE '00:00:00'::INTERVAL
    END,
    net_hours_worked = CASE
        WHEN ae.first_punch_in IS NOT NULL AND ae.last_punch_out IS NOT NULL
        THEN GREATEST(
            ae.last_punch_out - ae.first_punch_in - COALESCE(break_calc.total_break_time, '01:00:00'::INTERVAL),
            '00:00:00'::INTERVAL
        )
        ELSE '00:00:00'::INTERVAL
    END,
    is_late = CASE
        WHEN ae.first_punch_in IS NOT NULL AND sm.shift_start_time IS NOT NULL
        THEN ae.first_punch_in::TIME > (sm.shift_start_time + sm.grace_time_in)
        ELSE false
    END,
    late_by = CASE
        WHEN ae.first_punch_in IS NOT NULL AND sm.shift_start_time IS NOT NULL
            AND ae.first_punch_in::TIME > (sm.shift_start_time + sm.grace_time_in)
        THEN ae.first_punch_in::TIME - sm.shift_start_time
        ELSE '00:00:00'::INTERVAL
    END,
    is_early_leaving = CASE
        WHEN ae.last_punch_out IS NOT NULL AND sm.shift_end_time IS NOT NULL
        THEN ae.last_punch_out::TIME < (sm.shift_end_time - sm.grace_time_out)
        ELSE false
    END,
    early_leaving_by = CASE
        WHEN ae.last_punch_out IS NOT NULL AND sm.shift_end_time IS NOT NULL
            AND ae.last_punch_out::TIME < (sm.shift_end_time - sm.grace_time_out)
        THEN sm.shift_end_time - ae.last_punch_out::TIME
        ELSE '00:00:00'::INTERVAL
    END,
    overtime_hours = CASE
        WHEN ae.first_punch_in IS NOT NULL AND ae.last_punch_out IS NOT NULL
            AND sm.overtime_applicable = true
        THEN GREATEST(
            (ae.last_punch_out - ae.first_punch_in - COALESCE(break_calc.total_break_time, '01:00:00'::INTERVAL))
            - sm.standard_hours,
            '00:00:00'::INTERVAL
        )
        ELSE '00:00:00'::INTERVAL
    END,
    is_calculated = true,
    calculation_date = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
FROM shift_master sm,
     LATERAL (
         SELECT COALESCE(SUM(sbp.break_duration), '01:00:00'::INTERVAL) as total_break_time
         FROM shift_break_periods sbp
         WHERE sbp.shift_master_id = ae.shift_master_id
     ) break_calc
WHERE ae.shift_master_id = sm.shift_master_id
AND ae.is_calculated = false;

-- =====================================================================================
-- SECTION 10: CREATE MONTHLY SUMMARY DATA
-- =====================================================================================

-- Generate monthly attendance summary for March 2024
INSERT INTO attendance_monthly_summary (
    employee_master_id, summary_year, summary_month,
    total_working_days, present_days, absent_days, half_days,
    total_hours_worked, regular_hours, overtime_hours,
    late_count, early_leaving_count, total_late_hours, total_early_hours,
    created_by
)
SELECT
    ae.employee_master_id,
    2024 as summary_year,
    3 as summary_month,
    COUNT(*) as total_working_days,
    COUNT(CASE WHEN ae.attendance_status IN ('present', 'late', 'early_leaving', 'overtime') THEN 1 END) as present_days,
    COUNT(CASE WHEN ae.attendance_status = 'absent' THEN 1 END) as absent_days,
    COUNT(CASE WHEN ae.attendance_status = 'half_day' THEN 1 END) as half_days,
    SUM(COALESCE(ae.actual_hours_worked, '00:00:00'::INTERVAL)) as total_hours_worked,
    SUM(COALESCE(ae.net_hours_worked, '00:00:00'::INTERVAL)) as regular_hours,
    SUM(COALESCE(ae.overtime_hours, '00:00:00'::INTERVAL)) as overtime_hours,
    COUNT(CASE WHEN ae.is_late = true THEN 1 END) as late_count,
    COUNT(CASE WHEN ae.is_early_leaving = true THEN 1 END) as early_leaving_count,
    SUM(COALESCE(ae.late_by, '00:00:00'::INTERVAL)) as total_late_hours,
    SUM(COALESCE(ae.early_leaving_by, '00:00:00'::INTERVAL)) as total_early_hours,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM attendance_entry ae
WHERE EXTRACT(YEAR FROM ae.attendance_date) = 2024
AND EXTRACT(MONTH FROM ae.attendance_date) = 3
GROUP BY ae.employee_master_id;

-- =====================================================================================
-- SECTION 11: SAMPLE OVERTIME REQUESTS
-- =====================================================================================

-- Create some overtime requests for employees who worked overtime
INSERT INTO overtime_request (
    employee_master_id, attendance_entry_id, request_date,
    requested_hours, actual_overtime_hours, reason, work_description,
    approval_status, approved_by, approval_date, created_by
)
SELECT
    ae.employee_master_id,
    ae.attendance_entry_id,
    ae.attendance_date,
    ae.overtime_hours,
    ae.overtime_hours,
    'Project deadline delivery',
    'Working on critical project deliverables for client presentation',
    CASE
        WHEN RANDOM() > 0.3 THEN 'approved'
        WHEN RANDOM() > 0.8 THEN 'rejected'
        ELSE 'pending'
    END as approval_status,
    CASE
        WHEN RANDOM() > 0.3 THEN (
            SELECT user_master_id FROM user_master
            WHERE email IN ('priya.sharma@nexustech.com', 'amit.kumar@nexustech.com')
            ORDER BY RANDOM() LIMIT 1
        )
        ELSE NULL
    END as approved_by,
    CASE
        WHEN RANDOM() > 0.3 THEN ae.attendance_date + '1 day'::INTERVAL
        ELSE NULL
    END as approval_date,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM attendance_entry ae
WHERE ae.overtime_hours > '00:30:00'::INTERVAL
AND RANDOM() > 0.5; -- Only create requests for 50% of overtime cases

-- =====================================================================================
-- SECTION 12: SAMPLE ATTENDANCE EXCEPTIONS
-- =====================================================================================

-- Create attendance exceptions for missing punches and other issues
INSERT INTO attendance_exception (
    attendance_entry_id, employee_master_id, exception_date,
    exception_type, exception_description, regularization_requested,
    regularization_reason, proposed_in_time, proposed_out_time,
    approval_status, created_by
)
SELECT
    ae.attendance_entry_id,
    ae.employee_master_id,
    ae.attendance_date,
    CASE
        WHEN ae.first_punch_in IS NULL THEN 'missing_punch'
        WHEN ae.last_punch_out IS NULL THEN 'missing_punch'
        WHEN ae.is_late = true THEN 'late_entry'
        WHEN ae.is_early_leaving = true THEN 'early_exit'
        ELSE 'no_show'
    END as exception_type,
    CASE
        WHEN ae.first_punch_in IS NULL THEN 'Missing punch in record'
        WHEN ae.last_punch_out IS NULL THEN 'Missing punch out record'
        WHEN ae.is_late = true THEN 'Late arrival due to traffic'
        WHEN ae.is_early_leaving = true THEN 'Early leaving for personal work'
        ELSE 'No show without prior information'
    END as exception_description,
    true as regularization_requested,
    CASE
        WHEN ae.first_punch_in IS NULL THEN 'Biometric device was not working properly'
        WHEN ae.last_punch_out IS NULL THEN 'Forgot to punch out, worked till usual time'
        WHEN ae.is_late = true THEN 'Traffic jam due to road construction'
        WHEN ae.is_early_leaving = true THEN 'Medical appointment for family member'
        ELSE 'Emergency situation at home'
    END as regularization_reason,
    CASE
        WHEN ae.first_punch_in IS NULL THEN ae.attendance_date + '09:15:00'::TIME
        ELSE ae.first_punch_in
    END as proposed_in_time,
    CASE
        WHEN ae.last_punch_out IS NULL THEN ae.attendance_date + '18:00:00'::TIME
        ELSE ae.last_punch_out
    END as proposed_out_time,
    CASE
        WHEN RANDOM() > 0.4 THEN 'approved'
        WHEN RANDOM() > 0.8 THEN 'rejected'
        ELSE 'pending'
    END as approval_status,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM attendance_entry ae
WHERE (
    ae.first_punch_in IS NULL
    OR ae.last_punch_out IS NULL
    OR ae.is_late = true
    OR ae.is_early_leaving = true
)
AND RANDOM() > 0.7; -- Create exceptions for 30% of problematic cases

-- =====================================================================================
-- SECTION 13: VERIFICATION QUERIES
-- =====================================================================================

-- Summary statistics for verification
SELECT
    'Total Employees with Shift Assignments' as metric,
    COUNT(DISTINCT employee_master_id) as count
FROM employee_shift_assignment
WHERE row_status = 1

UNION ALL

SELECT
    'Total Biometric Devices' as metric,
    COUNT(*) as count
FROM biometric_device_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Biometric Punch Records' as metric,
    COUNT(*) as count
FROM biometric_punch_log

UNION ALL

SELECT
    'Total Attendance Entries (March 2024)' as metric,
    COUNT(*) as count
FROM attendance_entry
WHERE EXTRACT(YEAR FROM attendance_date) = 2024
AND EXTRACT(MONTH FROM attendance_date) = 3

UNION ALL

SELECT
    'Total Overtime Requests' as metric,
    COUNT(*) as count
FROM overtime_request

UNION ALL

SELECT
    'Total Attendance Exceptions' as metric,
    COUNT(*) as count
FROM attendance_exception

UNION ALL

SELECT
    'Monthly Summaries Generated' as metric,
    COUNT(*) as count
FROM attendance_monthly_summary;

-- Attendance status distribution
SELECT
    'Attendance Status Distribution' as category,
    attendance_status,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) as percentage
FROM attendance_entry
WHERE EXTRACT(YEAR FROM attendance_date) = 2024
AND EXTRACT(MONTH FROM attendance_date) = 3
GROUP BY attendance_status
ORDER BY count DESC;

-- Top employees by overtime hours
SELECT
    'Top Overtime Workers' as category,
    em.employee_code,
    em.full_name,
    SUM(ae.overtime_hours) as total_overtime,
    COUNT(CASE WHEN ae.overtime_hours > '00:00:00' THEN 1 END) as overtime_days
FROM attendance_entry ae
JOIN employee_master em ON ae.employee_master_id = em.employee_master_id
WHERE EXTRACT(YEAR FROM ae.attendance_date) = 2024
AND EXTRACT(MONTH FROM ae.attendance_date) = 3
GROUP BY em.employee_master_id, em.employee_code, em.full_name
HAVING SUM(ae.overtime_hours) > '00:00:00'
ORDER BY SUM(ae.overtime_hours) DESC
LIMIT 10;

-- Shift-wise attendance summary
SELECT
    'Shift Performance' as category,
    sm.shift_name,
    COUNT(DISTINCT ae.employee_master_id) as total_employees,
    AVG(EXTRACT(EPOCH FROM ae.net_hours_worked)/3600) as avg_hours_per_day,
    COUNT(CASE WHEN ae.is_late THEN 1 END) as total_late_instances,
    COUNT(CASE WHEN ae.overtime_hours > '00:00:00' THEN 1 END) as total_overtime_instances
FROM attendance_entry ae
JOIN shift_master sm ON ae.shift_master_id = sm.shift_master_id
WHERE EXTRACT(YEAR FROM ae.attendance_date) = 2024
AND EXTRACT(MONTH FROM ae.attendance_date) = 3
GROUP BY sm.shift_master_id, sm.shift_name
ORDER BY total_employees DESC;

-- =====================================================================================
-- END OF ATTENDANCE SAMPLE DATA
-- =====================================================================================