-- =====================================================================================
-- NEXUS HRMS - Attendance Management Module
-- PostgreSQL Schema for Attendance, Shift Management, and Time Tracking
-- =====================================================================================
-- Migration from: MongoDB MEAN Stack to PostgreSQL NEXUS Architecture
-- Phase: 4 - Attendance Management Core Tables
-- Dependencies: Employee Master, Organizational Structure, Company Master
-- =====================================================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- SECTION 1: ENUMS AND CUSTOM TYPES
-- =====================================================================================

-- Attendance status enumeration
CREATE TYPE attendance_status_type AS ENUM (
    'present',
    'absent',
    'half_day',
    'late',
    'early_leaving',
    'overtime',
    'on_leave',
    'on_duty',
    'comp_off',
    'holiday',
    'weekend'
);

-- Punch type enumeration
CREATE TYPE punch_type AS ENUM (
    'in',
    'out',
    'break_out',
    'break_in'
);

-- Shift type enumeration
CREATE TYPE shift_type AS ENUM (
    'general',
    'night',
    'flexible',
    'rotational'
);

-- Holiday type enumeration
CREATE TYPE holiday_type AS ENUM (
    'national',
    'regional',
    'company',
    'religious',
    'optional'
);

-- Overtime calculation method
CREATE TYPE overtime_calc_method AS ENUM (
    'hourly_rate',
    'percentage',
    'fixed_amount',
    'slab_based'
);

-- =====================================================================================
-- SECTION 2: CALENDAR AND HOLIDAY MANAGEMENT
-- =====================================================================================

-- Calendar master for company-specific calendars
CREATE TABLE calendar_master (
    calendar_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_name VARCHAR(100) NOT NULL,
    calendar_year INTEGER NOT NULL,
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),
    location_master_id UUID REFERENCES location_master(location_master_id),
    description TEXT,
    is_default BOOLEAN DEFAULT false,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, calendar_year, calendar_name)
);

-- Holiday master
CREATE TABLE holiday_master (
    holiday_master_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_name VARCHAR(100) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type holiday_type NOT NULL,
    calendar_master_id UUID NOT NULL REFERENCES calendar_master(calendar_id),
    description TEXT,
    is_optional BOOLEAN DEFAULT false,
    is_half_day BOOLEAN DEFAULT false,

    -- Applicability
    applies_to_all BOOLEAN DEFAULT true,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Holiday applicability (for non-universal holidays)
CREATE TABLE holiday_applicability (
    holiday_applicability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_master_id UUID NOT NULL REFERENCES holiday_master(holiday_master_id),

    -- Can apply to divisions, departments, designations, or specific employees
    division_master_id UUID REFERENCES division_master(division_master_id),
    department_master_id UUID REFERENCES department_master(department_master_id),
    designation_master_id UUID REFERENCES designation_master(designation_master_id),
    employee_master_id UUID REFERENCES employee_master(employee_master_id),

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 3: SHIFT MANAGEMENT
-- =====================================================================================

-- Shift master - Core shift definitions
CREATE TABLE shift_master (
    shift_master_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_code VARCHAR(20) NOT NULL,
    shift_name VARCHAR(100) NOT NULL,
    shift_type shift_type DEFAULT 'general',
    template_name VARCHAR(100),
    description TEXT,

    -- Basic timing
    shift_start_time TIME NOT NULL,
    shift_end_time TIME NOT NULL,
    shift_end_day INTEGER DEFAULT 0, -- 0=same day, 1=next day
    standard_hours INTERVAL NOT NULL,

    -- Break configuration
    is_break_included BOOLEAN DEFAULT false,
    total_break_time INTERVAL DEFAULT '00:00:00',
    net_working_hours INTERVAL,

    -- Grace time and cut-off
    grace_time_in INTERVAL DEFAULT '00:00:00',
    grace_time_out INTERVAL DEFAULT '00:00:00',
    late_coming_cutoff INTERVAL DEFAULT '00:00:00',
    early_going_cutoff INTERVAL DEFAULT '00:00:00',

    -- Overtime configuration
    overtime_applicable BOOLEAN DEFAULT false,
    overtime_start_after INTERVAL,
    max_overtime_hours INTERVAL,
    overtime_calc_method overtime_calc_method,
    overtime_rate DECIMAL(10,2),

    -- Attendance rules
    minimum_hours_for_present INTERVAL,
    minimum_hours_for_half_day INTERVAL,
    auto_punch_out_time TIME,

    -- Weekend configuration
    include_weekends BOOLEAN DEFAULT false,
    weekend_saturday BOOLEAN DEFAULT true,
    weekend_sunday BOOLEAN DEFAULT true,

    -- Applicability
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    -- Company/Location context
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, shift_code)
);

-- Break periods within shifts
CREATE TABLE shift_break_periods (
    shift_break_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_master_id UUID NOT NULL REFERENCES shift_master(shift_master_id),
    break_name VARCHAR(50) NOT NULL,
    break_start_time TIME NOT NULL,
    break_end_time TIME NOT NULL,
    break_duration INTERVAL NOT NULL,
    is_paid BOOLEAN DEFAULT true,
    break_order INTEGER NOT NULL,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Shift assignment rules - Who gets which shift
CREATE TABLE shift_assignment_rules (
    shift_assignment_rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_master_id UUID NOT NULL REFERENCES shift_master(shift_master_id),
    rule_name VARCHAR(100) NOT NULL,

    -- Assignment criteria
    applies_to_all BOOLEAN DEFAULT false,

    -- Priority for conflicting rules
    priority_order INTEGER DEFAULT 1,

    -- Date range
    effective_from DATE NOT NULL,
    effective_to DATE,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Shift assignment criteria (organizational filters)
CREATE TABLE shift_assignment_criteria (
    shift_assignment_criteria_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_assignment_rule_id UUID NOT NULL REFERENCES shift_assignment_rules(shift_assignment_rule_id),

    -- Organizational criteria
    division_master_id UUID REFERENCES division_master(division_master_id),
    department_master_id UUID REFERENCES department_master(department_master_id),
    designation_master_id UUID REFERENCES designation_master(designation_master_id),
    employee_category_id UUID REFERENCES employee_category(employee_category_id),
    employee_group_id UUID REFERENCES employee_group(employee_group_id),
    employee_grade_id UUID REFERENCES employee_grade(employee_grade_id),

    -- Include/Exclude flag
    is_inclusion BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Employee shift assignments (actual assignments)
CREATE TABLE employee_shift_assignment (
    employee_shift_assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    shift_master_id UUID NOT NULL REFERENCES shift_master(shift_master_id),

    -- Assignment period
    assignment_date DATE NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,

    -- Assignment source
    assigned_by_rule_id UUID REFERENCES shift_assignment_rules(shift_assignment_rule_id),
    is_manual_assignment BOOLEAN DEFAULT false,
    assignment_reason TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 4: BIOMETRIC DEVICE MANAGEMENT
-- =====================================================================================

-- Biometric device master
CREATE TABLE biometric_device_master (
    biometric_device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_code VARCHAR(20) NOT NULL,
    device_name VARCHAR(100) NOT NULL,
    device_ip VARCHAR(15),
    device_port INTEGER,
    device_type VARCHAR(50), -- eSSL, ZKTeco, Realtime, etc.
    device_model VARCHAR(100),
    location_master_id UUID NOT NULL REFERENCES location_master(location_master_id),

    -- Connection settings
    is_active BOOLEAN DEFAULT true,
    last_sync_time TIMESTAMP,
    sync_interval_minutes INTEGER DEFAULT 15,

    -- Device configuration
    supports_multiple_punch BOOLEAN DEFAULT true,
    max_punch_per_day INTEGER DEFAULT 10,
    auto_clear_logs BOOLEAN DEFAULT false,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(device_code),
    UNIQUE(device_ip, device_port)
);

-- Employee biometric mapping
CREATE TABLE employee_biometric_mapping (
    employee_biometric_mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    biometric_device_id UUID NOT NULL REFERENCES biometric_device_master(biometric_device_id),
    device_employee_id VARCHAR(20) NOT NULL, -- Employee ID in biometric device

    enrollment_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(biometric_device_id, device_employee_id)
);

-- =====================================================================================
-- SECTION 5: ATTENDANCE TRACKING CORE
-- =====================================================================================

-- Raw biometric punches from devices
CREATE TABLE biometric_punch_log (
    biometric_punch_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    biometric_device_id UUID NOT NULL REFERENCES biometric_device_master(biometric_device_id),
    device_employee_id VARCHAR(20) NOT NULL,
    device_log_id VARCHAR(50), -- Original log ID from device
    punch_time TIMESTAMP NOT NULL,
    punch_date DATE NOT NULL,

    -- Processing status
    is_processed BOOLEAN DEFAULT false,
    employee_master_id UUID REFERENCES employee_master(employee_master_id),
    punch_type punch_type,

    -- Data sync info
    sync_batch_id UUID,
    sync_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Processed attendance entries
CREATE TABLE attendance_entry (
    attendance_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    attendance_date DATE NOT NULL,

    -- Shift information
    shift_master_id UUID REFERENCES shift_master(shift_master_id),
    expected_shift_start TIME,
    expected_shift_end TIME,

    -- Actual punch times
    first_punch_in TIMESTAMP,
    last_punch_out TIMESTAMP,
    total_punches INTEGER DEFAULT 0,

    -- Calculated times
    actual_hours_worked INTERVAL,
    break_hours INTERVAL DEFAULT '00:00:00',
    net_hours_worked INTERVAL,
    overtime_hours INTERVAL DEFAULT '00:00:00',

    -- Status determination
    attendance_status attendance_status_type,
    is_late BOOLEAN DEFAULT false,
    late_by INTERVAL DEFAULT '00:00:00',
    is_early_leaving BOOLEAN DEFAULT false,
    early_leaving_by INTERVAL DEFAULT '00:00:00',

    -- Manual adjustments
    is_manually_adjusted BOOLEAN DEFAULT false,
    manual_in_time TIMESTAMP,
    manual_out_time TIMESTAMP,
    adjustment_reason TEXT,
    adjusted_by UUID REFERENCES user_master(user_master_id),
    adjustment_date TIMESTAMP,

    -- Calculation flags
    is_calculated BOOLEAN DEFAULT false,
    calculation_date TIMESTAMP,
    calculation_errors TEXT,

    created_by UUID REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, attendance_date)
);

-- Individual punch details
CREATE TABLE attendance_punch_detail (
    attendance_punch_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_entry_id UUID NOT NULL REFERENCES attendance_entry(attendance_entry_id),
    biometric_punch_log_id UUID REFERENCES biometric_punch_log(biometric_punch_log_id),

    punch_time TIMESTAMP NOT NULL,
    punch_type punch_type NOT NULL,
    is_valid_punch BOOLEAN DEFAULT true,

    -- Manual punch information
    is_manual_punch BOOLEAN DEFAULT false,
    manual_punch_reason TEXT,

    created_by UUID REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 6: OVERTIME AND EXCEPTION MANAGEMENT
-- =====================================================================================

-- Overtime configuration
CREATE TABLE overtime_policy (
    overtime_policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL,
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Basic overtime rules
    minimum_overtime_hours INTERVAL DEFAULT '00:30:00',
    maximum_daily_overtime INTERVAL DEFAULT '04:00:00',
    maximum_monthly_overtime INTERVAL DEFAULT '50:00:00',

    -- Rate calculation
    overtime_calc_method overtime_calc_method DEFAULT 'percentage',
    overtime_rate DECIMAL(10,2) DEFAULT 150.00, -- 150% of hourly rate

    -- Approval requirements
    requires_pre_approval BOOLEAN DEFAULT false,
    auto_approve_threshold INTERVAL DEFAULT '02:00:00',

    -- Rounding rules
    round_to_minutes INTEGER DEFAULT 15,

    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Overtime requests and approvals
CREATE TABLE overtime_request (
    overtime_request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    attendance_entry_id UUID REFERENCES attendance_entry(attendance_entry_id),

    request_date DATE NOT NULL,
    requested_hours INTERVAL NOT NULL,
    actual_overtime_hours INTERVAL,

    -- Request details
    reason TEXT NOT NULL,
    work_description TEXT,

    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,
    approval_comments TEXT,

    -- Processing
    is_processed BOOLEAN DEFAULT false,
    processed_date TIMESTAMP,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Attendance exceptions and regularization
CREATE TABLE attendance_exception (
    attendance_exception_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_entry_id UUID NOT NULL REFERENCES attendance_entry(attendance_entry_id),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    exception_date DATE NOT NULL,

    -- Exception type
    exception_type VARCHAR(50) NOT NULL, -- missing_punch, late_entry, early_exit, no_show
    exception_description TEXT,

    -- Regularization request
    regularization_requested BOOLEAN DEFAULT false,
    regularization_reason TEXT,
    proposed_in_time TIMESTAMP,
    proposed_out_time TIMESTAMP,

    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'pending',
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,
    approval_comments TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 7: ATTENDANCE SUMMARY AND CALCULATION TABLES
-- =====================================================================================

-- Monthly attendance summary
CREATE TABLE attendance_monthly_summary (
    attendance_monthly_summary_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    summary_year INTEGER NOT NULL,
    summary_month INTEGER NOT NULL,

    -- Basic counts
    total_working_days INTEGER DEFAULT 0,
    present_days INTEGER DEFAULT 0,
    absent_days INTEGER DEFAULT 0,
    half_days INTEGER DEFAULT 0,
    leave_days INTEGER DEFAULT 0,
    holiday_days INTEGER DEFAULT 0,
    weekend_days INTEGER DEFAULT 0,

    -- Time calculations
    total_hours_worked INTERVAL DEFAULT '00:00:00',
    regular_hours INTERVAL DEFAULT '00:00:00',
    overtime_hours INTERVAL DEFAULT '00:00:00',
    break_hours INTERVAL DEFAULT '00:00:00',

    -- Attendance metrics
    late_count INTEGER DEFAULT 0,
    early_leaving_count INTEGER DEFAULT 0,
    total_late_hours INTERVAL DEFAULT '00:00:00',
    total_early_hours INTERVAL DEFAULT '00:00:00',

    -- Calculation status
    is_finalized BOOLEAN DEFAULT false,
    finalized_by UUID REFERENCES user_master(user_master_id),
    finalized_date TIMESTAMP,

    created_by UUID REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, summary_year, summary_month)
);

-- Shift-wise attendance summary
CREATE TABLE shift_attendance_summary (
    shift_attendance_summary_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_master_id UUID NOT NULL REFERENCES shift_master(shift_master_id),
    summary_date DATE NOT NULL,

    -- Employee counts
    total_assigned_employees INTEGER DEFAULT 0,
    present_employees INTEGER DEFAULT 0,
    absent_employees INTEGER DEFAULT 0,
    late_employees INTEGER DEFAULT 0,

    -- Time summaries
    total_hours_worked INTERVAL DEFAULT '00:00:00',
    total_overtime_hours INTERVAL DEFAULT '00:00:00',
    average_hours_per_employee INTERVAL DEFAULT '00:00:00',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(shift_master_id, summary_date)
);

-- =====================================================================================
-- SECTION 8: INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Calendar and Holiday indexes
CREATE INDEX idx_calendar_master_company_year ON calendar_master(company_master_id, calendar_year);
CREATE INDEX idx_holiday_master_date ON holiday_master(holiday_date);
CREATE INDEX idx_holiday_master_calendar ON holiday_master(calendar_master_id);

-- Shift management indexes
CREATE INDEX idx_shift_master_company ON shift_master(company_master_id);
CREATE INDEX idx_shift_master_active ON shift_master(is_active, effective_from, effective_to);
CREATE INDEX idx_employee_shift_assignment_employee ON employee_shift_assignment(employee_master_id);
CREATE INDEX idx_employee_shift_assignment_date ON employee_shift_assignment(assignment_date);
CREATE INDEX idx_employee_shift_assignment_effective ON employee_shift_assignment(effective_from, effective_to);

-- Attendance tracking indexes
CREATE INDEX idx_biometric_punch_log_device_time ON biometric_punch_log(biometric_device_id, punch_time);
CREATE INDEX idx_biometric_punch_log_date ON biometric_punch_log(punch_date);
CREATE INDEX idx_biometric_punch_log_processed ON biometric_punch_log(is_processed);
CREATE INDEX idx_attendance_entry_employee_date ON attendance_entry(employee_master_id, attendance_date);
CREATE INDEX idx_attendance_entry_date ON attendance_entry(attendance_date);
CREATE INDEX idx_attendance_entry_status ON attendance_entry(attendance_status);
CREATE INDEX idx_attendance_punch_detail_entry ON attendance_punch_detail(attendance_entry_id);

-- Summary table indexes
CREATE INDEX idx_attendance_monthly_summary_employee ON attendance_monthly_summary(employee_master_id);
CREATE INDEX idx_attendance_monthly_summary_period ON attendance_monthly_summary(summary_year, summary_month);
CREATE INDEX idx_shift_attendance_summary_shift_date ON shift_attendance_summary(shift_master_id, summary_date);

-- =====================================================================================
-- SECTION 9: TRIGGERS AND BUSINESS LOGIC
-- =====================================================================================

-- Function to calculate net working hours for shift
CREATE OR REPLACE FUNCTION calculate_net_working_hours()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate net working hours = standard hours - total break time
    NEW.net_working_hours := NEW.standard_hours - COALESCE(NEW.total_break_time, '00:00:00'::INTERVAL);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for shift master net hours calculation
CREATE TRIGGER trigger_calculate_net_working_hours
    BEFORE INSERT OR UPDATE ON shift_master
    FOR EACH ROW
    EXECUTE FUNCTION calculate_net_working_hours();

-- Function to auto-assign shifts based on rules
CREATE OR REPLACE FUNCTION auto_assign_employee_shift(
    p_employee_id UUID,
    p_assignment_date DATE
) RETURNS UUID AS $$
DECLARE
    v_shift_id UUID;
    v_rule_record RECORD;
BEGIN
    -- Find applicable shift assignment rule with highest priority
    FOR v_rule_record IN
        SELECT DISTINCT sar.shift_master_id, sar.shift_assignment_rule_id
        FROM shift_assignment_rules sar
        WHERE sar.effective_from <= p_assignment_date
        AND (sar.effective_to IS NULL OR sar.effective_to >= p_assignment_date)
        AND sar.row_status = 1
        AND (
            sar.applies_to_all = true
            OR EXISTS (
                SELECT 1 FROM shift_assignment_criteria sac
                JOIN employee_master em ON em.employee_master_id = p_employee_id
                WHERE sac.shift_assignment_rule_id = sar.shift_assignment_rule_id
                AND sac.is_inclusion = true
                AND sac.row_status = 1
                AND (
                    sac.division_master_id = em.division_master_id
                    OR sac.department_master_id = em.department_master_id
                    OR sac.designation_master_id = em.designation_master_id
                    OR sac.employee_category_id = em.employee_category_id
                    OR sac.employee_group_id = em.employee_group_id
                    OR sac.employee_grade_id = em.employee_grade_id
                )
            )
        )
        ORDER BY sar.priority_order ASC
        LIMIT 1
    LOOP
        v_shift_id := v_rule_record.shift_master_id;

        -- Insert assignment record
        INSERT INTO employee_shift_assignment (
            employee_master_id,
            shift_master_id,
            assignment_date,
            effective_from,
            assigned_by_rule_id,
            is_manual_assignment,
            created_by
        ) VALUES (
            p_employee_id,
            v_shift_id,
            p_assignment_date,
            p_assignment_date,
            v_rule_record.shift_assignment_rule_id,
            false,
            (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
        );

        EXIT; -- Exit after first match
    END LOOP;

    RETURN v_shift_id;
END;
$$ LANGUAGE plpgsql;

-- Function to process biometric punch logs
CREATE OR REPLACE FUNCTION process_biometric_punches()
RETURNS INTEGER AS $$
DECLARE
    v_punch_record RECORD;
    v_attendance_entry_id UUID;
    v_processed_count INTEGER := 0;
BEGIN
    -- Process unprocessed punch logs
    FOR v_punch_record IN
        SELECT bpl.*, ebm.employee_master_id
        FROM biometric_punch_log bpl
        JOIN employee_biometric_mapping ebm ON
            bpl.biometric_device_id = ebm.biometric_device_id
            AND bpl.device_employee_id = ebm.device_employee_id
        WHERE bpl.is_processed = false
        AND ebm.is_active = true
        ORDER BY bpl.punch_time
    LOOP
        -- Get or create attendance entry for the date
        SELECT attendance_entry_id INTO v_attendance_entry_id
        FROM attendance_entry
        WHERE employee_master_id = v_punch_record.employee_master_id
        AND attendance_date = v_punch_record.punch_date;

        IF v_attendance_entry_id IS NULL THEN
            -- Create new attendance entry
            INSERT INTO attendance_entry (
                employee_master_id,
                attendance_date,
                shift_master_id,
                total_punches
            ) VALUES (
                v_punch_record.employee_master_id,
                v_punch_record.punch_date,
                (SELECT shift_master_id FROM employee_shift_assignment
                 WHERE employee_master_id = v_punch_record.employee_master_id
                 AND v_punch_record.punch_date BETWEEN effective_from AND COALESCE(effective_to, '2099-12-31')
                 ORDER BY created_at DESC LIMIT 1),
                0
            ) RETURNING attendance_entry_id INTO v_attendance_entry_id;
        END IF;

        -- Determine punch type based on sequence
        UPDATE biometric_punch_log SET
            punch_type = CASE
                WHEN (SELECT COUNT(*) FROM attendance_punch_detail
                      WHERE attendance_entry_id = v_attendance_entry_id) % 2 = 0
                THEN 'in'::punch_type
                ELSE 'out'::punch_type
            END,
            employee_master_id = v_punch_record.employee_master_id,
            is_processed = true
        WHERE biometric_punch_log_id = v_punch_record.biometric_punch_log_id;

        -- Insert punch detail
        INSERT INTO attendance_punch_detail (
            attendance_entry_id,
            biometric_punch_log_id,
            punch_time,
            punch_type
        ) VALUES (
            v_attendance_entry_id,
            v_punch_record.biometric_punch_log_id,
            v_punch_record.punch_time,
            CASE
                WHEN (SELECT COUNT(*) FROM attendance_punch_detail
                      WHERE attendance_entry_id = v_attendance_entry_id) % 2 = 0
                THEN 'in'::punch_type
                ELSE 'out'::punch_type
            END
        );

        -- Update attendance entry punch count and times
        UPDATE attendance_entry SET
            total_punches = (SELECT COUNT(*) FROM attendance_punch_detail WHERE attendance_entry_id = v_attendance_entry_id),
            first_punch_in = CASE
                WHEN first_punch_in IS NULL OR v_punch_record.punch_time < first_punch_in
                THEN v_punch_record.punch_time
                ELSE first_punch_in
            END,
            last_punch_out = CASE
                WHEN last_punch_out IS NULL OR v_punch_record.punch_time > last_punch_out
                THEN v_punch_record.punch_time
                ELSE last_punch_out
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE attendance_entry_id = v_attendance_entry_id;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SECTION 10: UTILITY VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- View for current shift assignments
CREATE VIEW current_employee_shifts AS
SELECT
    esa.employee_master_id,
    em.employee_code,
    em.full_name,
    esa.shift_master_id,
    sm.shift_name,
    sm.shift_start_time,
    sm.shift_end_time,
    sm.standard_hours,
    esa.effective_from,
    esa.effective_to
FROM employee_shift_assignment esa
JOIN employee_master em ON esa.employee_master_id = em.employee_master_id
JOIN shift_master sm ON esa.shift_master_id = sm.shift_master_id
WHERE CURRENT_DATE BETWEEN esa.effective_from AND COALESCE(esa.effective_to, '2099-12-31')
AND esa.row_status = 1
AND em.row_status = 1
AND sm.row_status = 1;

-- View for daily attendance summary
CREATE VIEW daily_attendance_summary AS
SELECT
    ae.attendance_date,
    ae.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    sm.shift_name,
    ae.attendance_status,
    ae.first_punch_in,
    ae.last_punch_out,
    ae.net_hours_worked,
    ae.overtime_hours,
    ae.is_late,
    ae.late_by,
    ae.is_early_leaving,
    ae.early_leaving_by
FROM attendance_entry ae
JOIN employee_master em ON ae.employee_master_id = em.employee_master_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN shift_master sm ON ae.shift_master_id = sm.shift_master_id
WHERE ae.row_status = 1;

-- View for employee attendance analytics
CREATE VIEW employee_attendance_analytics AS
SELECT
    ams.employee_master_id,
    em.employee_code,
    em.full_name,
    ams.summary_year,
    ams.summary_month,
    ams.total_working_days,
    ams.present_days,
    ams.absent_days,
    ams.leave_days,
    ROUND((ams.present_days::DECIMAL / NULLIF(ams.total_working_days, 0)) * 100, 2) as attendance_percentage,
    ams.total_hours_worked,
    ams.overtime_hours,
    ams.late_count,
    ams.early_leaving_count
FROM attendance_monthly_summary ams
JOIN employee_master em ON ams.employee_master_id = em.employee_master_id
WHERE ams.row_status = 1
AND em.row_status = 1;

-- =====================================================================================
-- SECTION 11: COMMENTS AND DOCUMENTATION
-- =====================================================================================

-- Table documentation
COMMENT ON TABLE calendar_master IS 'Company-specific calendar definitions for attendance calculation';
COMMENT ON TABLE holiday_master IS 'Holiday definitions with type classification and applicability rules';
COMMENT ON TABLE shift_master IS 'Core shift definitions with timing, breaks, overtime rules and attendance policies';
COMMENT ON TABLE biometric_device_master IS 'Biometric device configuration and connectivity settings';
COMMENT ON TABLE biometric_punch_log IS 'Raw punch data from biometric devices before processing';
COMMENT ON TABLE attendance_entry IS 'Processed daily attendance records with calculated hours and status';
COMMENT ON TABLE attendance_monthly_summary IS 'Monthly aggregated attendance metrics for payroll integration';
COMMENT ON TABLE overtime_request IS 'Overtime pre-approval and post-approval workflow management';
COMMENT ON TABLE attendance_exception IS 'Attendance exceptions and regularization requests';

-- Function documentation
COMMENT ON FUNCTION auto_assign_employee_shift(UUID, DATE) IS 'Automatically assigns shift to employee based on configured rules and organizational hierarchy';
COMMENT ON FUNCTION process_biometric_punches() IS 'Processes raw biometric punch logs into structured attendance entries with punch type determination';

-- =====================================================================================
-- END OF ATTENDANCE MANAGEMENT SCHEMA
-- =====================================================================================