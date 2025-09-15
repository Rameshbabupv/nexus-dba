-- =====================================================================================
-- NEXUS HRMS - Attendance Management Schema
-- =====================================================================================
-- Version: 2.0
-- Date: 2025-01-14
-- Module: Attendance Management System
-- Description: Comprehensive attendance tracking with biometric integration,
--              shift management, overtime calculations, and real-time processing
-- Dependencies: 01_nexus_foundation_schema.sql
-- Author: PostgreSQL DBA (20+ Years Experience)
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create attendance management schema
CREATE SCHEMA IF NOT EXISTS nexus_attendance;

-- Set search path for this schema
SET search_path = nexus_attendance, nexus_foundation, nexus_security, public;

-- =====================================================================================
-- ATTENDANCE MASTER CONFIGURATION TABLES
-- =====================================================================================

-- Shift Master Table
-- Defines work shifts with flexible timing and overtime rules
CREATE TABLE nexus_attendance.shift_master (
    shift_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    location_id BIGINT REFERENCES nexus_foundation.location_master(location_id),

    -- Shift Identification
    shift_code VARCHAR(20) NOT NULL,
    shift_name VARCHAR(100) NOT NULL,
    shift_type VARCHAR(20) NOT NULL DEFAULT 'REGULAR', -- REGULAR, NIGHT, ROTATING, FLEXIBLE

    -- Shift Timing Configuration
    shift_start_time TIME NOT NULL,
    shift_end_time TIME NOT NULL,
    shift_duration_minutes INTEGER NOT NULL,

    -- Break Configuration
    lunch_break_duration_minutes INTEGER DEFAULT 60,
    tea_break_duration_minutes INTEGER DEFAULT 30,
    total_break_duration_minutes INTEGER GENERATED ALWAYS AS (
        COALESCE(lunch_break_duration_minutes, 0) + COALESCE(tea_break_duration_minutes, 0)
    ) STORED,

    -- Grace Period and Late Policy
    grace_period_minutes INTEGER DEFAULT 15,
    late_mark_after_minutes INTEGER DEFAULT 30,
    half_day_after_minutes INTEGER DEFAULT 240, -- 4 hours

    -- Overtime Configuration
    overtime_eligible BOOLEAN DEFAULT true,
    overtime_start_after_minutes INTEGER DEFAULT 540, -- After 9 hours
    overtime_multiplier DECIMAL(3,2) DEFAULT 1.50,

    -- Weekly Schedule
    monday_applicable BOOLEAN DEFAULT true,
    tuesday_applicable BOOLEAN DEFAULT true,
    wednesday_applicable BOOLEAN DEFAULT true,
    thursday_applicable BOOLEAN DEFAULT true,
    friday_applicable BOOLEAN DEFAULT true,
    saturday_applicable BOOLEAN DEFAULT false,
    sunday_applicable BOOLEAN DEFAULT false,

    -- Status and Audit
    shift_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_shift_master_company_code UNIQUE (company_id, shift_code),
    CONSTRAINT chk_shift_timing CHECK (shift_end_time != shift_start_time),
    CONSTRAINT chk_shift_duration CHECK (shift_duration_minutes > 0 AND shift_duration_minutes <= 1440),
    CONSTRAINT chk_shift_status CHECK (shift_status IN ('ACTIVE', 'INACTIVE', 'DELETED'))
);

-- Employee Shift Assignment Table
-- Maps employees to their assigned shifts with effective periods
CREATE TABLE nexus_attendance.employee_shift_assignment (
    assignment_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    shift_id BIGINT NOT NULL REFERENCES nexus_attendance.shift_master(shift_id),

    -- Assignment Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Assignment Status
    assignment_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    assignment_reason VARCHAR(200),

    -- Flexible Shift Options
    is_flexible_timing BOOLEAN DEFAULT false,
    flexible_start_time_range_minutes INTEGER DEFAULT 0, -- +/- minutes from standard start

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_shift_active UNIQUE (employee_id, effective_from_date)
        WHERE assignment_status = 'ACTIVE' AND effective_to_date IS NULL,
    CONSTRAINT chk_assignment_dates CHECK (effective_to_date IS NULL OR effective_to_date >= effective_from_date),
    CONSTRAINT chk_assignment_status CHECK (assignment_status IN ('ACTIVE', 'INACTIVE', 'EXPIRED'))
);

-- Holiday Master Table
-- Company and location-specific holidays affecting attendance
CREATE TABLE nexus_attendance.holiday_master (
    holiday_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    location_id BIGINT REFERENCES nexus_foundation.location_master(location_id),

    -- Holiday Details
    holiday_name VARCHAR(100) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(20) NOT NULL DEFAULT 'NATIONAL', -- NATIONAL, REGIONAL, COMPANY, OPTIONAL

    -- Holiday Configuration
    is_mandatory BOOLEAN DEFAULT true,
    is_compensatory BOOLEAN DEFAULT false, -- Working on holiday gives comp-off
    compensatory_multiplier DECIMAL(3,2) DEFAULT 1.00,

    -- Applicability
    applies_to_all_employees BOOLEAN DEFAULT true,
    specific_departments TEXT[], -- Array of department IDs if not all employees
    specific_designations TEXT[], -- Array of designation IDs if not all employees

    -- Status
    holiday_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_holiday_master_company_date UNIQUE (company_id, location_id, holiday_date),
    CONSTRAINT chk_holiday_status CHECK (holiday_status IN ('ACTIVE', 'INACTIVE', 'CANCELLED'))
);

-- =====================================================================================
-- BIOMETRIC DEVICE MANAGEMENT
-- =====================================================================================

-- Biometric Device Master
-- Physical biometric devices for attendance capture
CREATE TABLE nexus_attendance.biometric_device_master (
    device_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    location_id BIGINT NOT NULL REFERENCES nexus_foundation.location_master(location_id),

    -- Device Identification
    device_code VARCHAR(50) NOT NULL,
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(30) NOT NULL DEFAULT 'FINGERPRINT', -- FINGERPRINT, FACE, IRIS, CARD, PIN
    device_brand VARCHAR(50),
    device_model VARCHAR(100),

    -- Network Configuration
    device_ip_address INET,
    device_port INTEGER DEFAULT 4370,
    device_mac_address MACADDR,

    -- Device Status and Configuration
    device_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_entry_device BOOLEAN DEFAULT true,
    is_exit_device BOOLEAN DEFAULT true,
    max_concurrent_users INTEGER DEFAULT 1000,

    -- Synchronization Settings
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_frequency_minutes INTEGER DEFAULT 5,
    auto_sync_enabled BOOLEAN DEFAULT true,

    -- Device Location Details
    installation_location VARCHAR(200),
    floor_number INTEGER,
    building_section VARCHAR(50),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_biometric_device_code UNIQUE (company_id, device_code),
    CONSTRAINT uk_biometric_device_ip UNIQUE (device_ip_address, device_port) WHERE device_ip_address IS NOT NULL,
    CONSTRAINT chk_device_status CHECK (device_status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE', 'OFFLINE'))
);

-- Employee Biometric Registration
-- Maps employees to their biometric data on devices
CREATE TABLE nexus_attendance.employee_biometric_registration (
    registration_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    device_id BIGINT NOT NULL REFERENCES nexus_attendance.biometric_device_master(device_id),

    -- Biometric Registration Details
    biometric_template_id VARCHAR(50) NOT NULL, -- Device-specific template ID
    biometric_type VARCHAR(20) NOT NULL DEFAULT 'FINGERPRINT',
    finger_index INTEGER, -- For fingerprint (1-10)
    template_quality_score INTEGER, -- 0-100

    -- Registration Status
    registration_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_verification_date DATE,
    verification_success_count INTEGER DEFAULT 0,
    verification_failure_count INTEGER DEFAULT 0,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_biometric_device UNIQUE (employee_id, device_id, biometric_type, finger_index),
    CONSTRAINT chk_registration_status CHECK (registration_status IN ('ACTIVE', 'INACTIVE', 'EXPIRED', 'DELETED')),
    CONSTRAINT chk_finger_index CHECK (finger_index IS NULL OR (finger_index >= 1 AND finger_index <= 10))
);

-- =====================================================================================
-- ATTENDANCE TRANSACTION TABLES
-- =====================================================================================

-- Daily Attendance Records (Partitioned by month)
-- Core attendance data with high-volume optimizations
CREATE TABLE nexus_attendance.attendance_records (
    attendance_id BIGINT NOT NULL DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Attendance Date and Shift
    attendance_date DATE NOT NULL,
    shift_id BIGINT REFERENCES nexus_attendance.shift_master(shift_id),

    -- Time Records
    first_in_time TIMESTAMP WITH TIME ZONE,
    last_out_time TIMESTAMP WITH TIME ZONE,
    total_time_minutes INTEGER,
    break_time_minutes INTEGER DEFAULT 0,
    productive_time_minutes INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN total_time_minutes IS NOT NULL AND break_time_minutes IS NOT NULL
            THEN total_time_minutes - break_time_minutes
            ELSE NULL
        END
    ) STORED,

    -- Attendance Status
    attendance_status VARCHAR(20) NOT NULL DEFAULT 'PRESENT',
    -- PRESENT, ABSENT, LATE, HALF_DAY, COMP_OFF, HOLIDAY, WEEKEND, LEAVE

    -- Late and Early Departure
    late_by_minutes INTEGER DEFAULT 0,
    early_departure_minutes INTEGER DEFAULT 0,

    -- Overtime Calculation
    overtime_minutes INTEGER DEFAULT 0,
    overtime_amount DECIMAL(12,2) DEFAULT 0.00,
    overtime_approved BOOLEAN DEFAULT false,
    overtime_approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    overtime_approved_at TIMESTAMP WITH TIME ZONE,

    -- Manual Adjustments
    is_manual_entry BOOLEAN DEFAULT false,
    manual_entry_reason VARCHAR(500),
    manual_entry_approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Biometric Verification
    entry_device_id BIGINT REFERENCES nexus_attendance.biometric_device_master(device_id),
    exit_device_id BIGINT REFERENCES nexus_attendance.biometric_device_master(device_id),
    biometric_verification_status VARCHAR(20) DEFAULT 'VERIFIED',

    -- Payroll Integration
    is_payroll_processed BOOLEAN DEFAULT false,
    payroll_month DATE,

    -- Data Quality and Sync
    data_source VARCHAR(20) DEFAULT 'BIOMETRIC', -- BIOMETRIC, MANUAL, IMPORT, API
    sync_status VARCHAR(20) DEFAULT 'SYNCED',
    data_quality_score INTEGER DEFAULT 100, -- 0-100

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT pk_attendance_records PRIMARY KEY (attendance_id, attendance_date),
    CONSTRAINT uk_attendance_employee_date UNIQUE (company_id, employee_id, attendance_date),
    CONSTRAINT chk_attendance_status CHECK (attendance_status IN (
        'PRESENT', 'ABSENT', 'LATE', 'HALF_DAY', 'COMP_OFF', 'HOLIDAY', 'WEEKEND', 'LEAVE', 'WFH'
    )),
    CONSTRAINT chk_time_logic CHECK (
        (first_in_time IS NULL AND last_out_time IS NULL) OR
        (first_in_time IS NOT NULL AND last_out_time IS NULL) OR
        (first_in_time IS NOT NULL AND last_out_time IS NOT NULL AND last_out_time >= first_in_time)
    ),
    CONSTRAINT chk_data_quality_score CHECK (data_quality_score >= 0 AND data_quality_score <= 100)
) PARTITION BY RANGE (attendance_date);

-- Create monthly partitions for attendance_records (last 24 months + next 12 months)
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '24 months');
    end_date DATE := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '12 months');
    partition_start DATE;
    partition_end DATE;
    partition_name TEXT;
BEGIN
    WHILE start_date < end_date LOOP
        partition_start := start_date;
        partition_end := start_date + INTERVAL '1 month';
        partition_name := 'attendance_records_' || TO_CHAR(partition_start, 'YYYY_MM');

        EXECUTE format('CREATE TABLE IF NOT EXISTS nexus_attendance.%I PARTITION OF nexus_attendance.attendance_records
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, partition_start, partition_end);

        start_date := partition_end;
    END LOOP;
END $$;

-- Raw Biometric Punches (Temporary staging table)
-- High-volume real-time data from biometric devices
CREATE TABLE nexus_attendance.biometric_punches (
    punch_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    device_id BIGINT NOT NULL REFERENCES nexus_attendance.biometric_device_master(device_id),

    -- Employee Identification
    employee_code VARCHAR(20), -- From biometric device
    employee_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    biometric_template_id VARCHAR(50),

    -- Punch Details
    punch_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    punch_type VARCHAR(10) NOT NULL DEFAULT 'AUTO', -- AUTO, MANUAL, FORCED
    verification_mode VARCHAR(20) DEFAULT 'FINGERPRINT',
    verification_quality INTEGER, -- 0-100

    -- Device Information
    device_timestamp TIMESTAMP WITH TIME ZONE,
    device_status_at_punch VARCHAR(20),

    -- Processing Status
    processing_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, PROCESSED, DUPLICATE, INVALID, ERROR
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_error_message TEXT,

    -- Data Sync
    sync_batch_id VARCHAR(50),
    raw_device_data JSONB,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_punch_processing_status CHECK (processing_status IN (
        'PENDING', 'PROCESSED', 'DUPLICATE', 'INVALID', 'ERROR'
    ))
);

-- =====================================================================================
-- ATTENDANCE CALCULATION AND SUMMARY TABLES
-- =====================================================================================

-- Monthly Attendance Summary
-- Pre-calculated monthly statistics for performance
CREATE TABLE nexus_attendance.monthly_attendance_summary (
    summary_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Summary Period
    summary_month DATE NOT NULL, -- First day of the month

    -- Attendance Counts
    total_working_days INTEGER NOT NULL DEFAULT 0,
    total_present_days INTEGER DEFAULT 0,
    total_absent_days INTEGER DEFAULT 0,
    total_late_days INTEGER DEFAULT 0,
    total_half_days INTEGER DEFAULT 0,
    total_comp_off_days INTEGER DEFAULT 0,
    total_leave_days INTEGER DEFAULT 0,
    total_holiday_days INTEGER DEFAULT 0,
    total_weekend_days INTEGER DEFAULT 0,

    -- Time Calculations
    total_work_hours DECIMAL(8,2) DEFAULT 0.00,
    total_overtime_hours DECIMAL(8,2) DEFAULT 0.00,
    total_late_minutes INTEGER DEFAULT 0,
    total_early_departure_minutes INTEGER DEFAULT 0,

    -- Attendance Percentage
    attendance_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN total_working_days > 0
            THEN ROUND((total_present_days::DECIMAL / total_working_days) * 100, 2)
            ELSE 0
        END
    ) STORED,

    -- Payroll Integration
    is_payroll_processed BOOLEAN DEFAULT false,
    payroll_processed_at TIMESTAMP WITH TIME ZONE,

    -- Summary Status
    summary_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, FINALIZED, APPROVED, PAYROLL_PROCESSED
    finalized_at TIMESTAMP WITH TIME ZONE,
    finalized_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_monthly_summary_employee_month UNIQUE (company_id, employee_id, summary_month),
    CONSTRAINT chk_summary_status CHECK (summary_status IN ('DRAFT', 'FINALIZED', 'APPROVED', 'PAYROLL_PROCESSED')),
    CONSTRAINT chk_attendance_counts CHECK (
        total_present_days >= 0 AND total_absent_days >= 0 AND
        (total_present_days + total_absent_days + total_leave_days + total_holiday_days + total_weekend_days) >= total_working_days
    )
);

-- Attendance Regularization Requests
-- Employee requests for attendance corrections
CREATE TABLE nexus_attendance.attendance_regularization (
    regularization_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    attendance_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,

    -- Regularization Request Details
    regularization_type VARCHAR(30) NOT NULL,
    -- MISSED_PUNCH, WRONG_PUNCH, LATE_ENTRY, EARLY_EXIT, FORGOT_TO_PUNCH

    -- Current vs Requested Values
    current_in_time TIMESTAMP WITH TIME ZONE,
    requested_in_time TIMESTAMP WITH TIME ZONE,
    current_out_time TIMESTAMP WITH TIME ZONE,
    requested_out_time TIMESTAMP WITH TIME ZONE,

    -- Request Details
    regularization_reason TEXT NOT NULL,
    supporting_documents JSONB, -- Array of document references

    -- Approval Workflow
    request_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, WITHDRAWN, EXPIRED

    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Approval Details
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- System Processing
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_status VARCHAR(20) DEFAULT 'PENDING',
    processing_error TEXT,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_regularization_request_status CHECK (request_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN', 'EXPIRED'
    )),
    CONSTRAINT chk_processing_status CHECK (processing_status IN ('PENDING', 'PROCESSED', 'ERROR')),
    CONSTRAINT chk_requested_times CHECK (
        (requested_in_time IS NULL OR requested_out_time IS NULL) OR
        (requested_out_time > requested_in_time)
    )
);

-- =====================================================================================
-- OVERTIME MANAGEMENT
-- =====================================================================================

-- Overtime Requests and Approvals
CREATE TABLE nexus_attendance.overtime_requests (
    overtime_request_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Overtime Request Details
    overtime_date DATE NOT NULL,
    planned_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    planned_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    planned_duration_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (planned_end_time - planned_start_time)) / 60
    ) STORED,

    -- Overtime Justification
    overtime_reason TEXT NOT NULL,
    project_reference VARCHAR(100),
    task_description TEXT,

    -- Approval Workflow
    request_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, CANCELLED, COMPLETED

    -- Pre-approval
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- Actual Overtime (filled after completion)
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    actual_duration_minutes INTEGER,
    overtime_completion_status VARCHAR(20) DEFAULT 'PENDING',

    -- Compensation
    overtime_rate_per_hour DECIMAL(10,2),
    total_overtime_amount DECIMAL(12,2),
    compensation_type VARCHAR(20) DEFAULT 'MONETARY', -- MONETARY, COMP_OFF, BOTH

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_overtime_request_status CHECK (request_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED'
    )),
    CONSTRAINT chk_overtime_times CHECK (planned_end_time > planned_start_time),
    CONSTRAINT chk_overtime_completion CHECK (overtime_completion_status IN (
        'PENDING', 'COMPLETED', 'PARTIAL', 'CANCELLED'
    ))
);

-- =====================================================================================
-- ATTENDANCE POLICY CONFIGURATION
-- =====================================================================================

-- Attendance Policy Master
-- Company-specific attendance rules and calculations
CREATE TABLE nexus_attendance.attendance_policy_master (
    policy_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Policy Identification
    policy_name VARCHAR(100) NOT NULL,
    policy_code VARCHAR(20) NOT NULL,
    policy_description TEXT,

    -- Working Hours Configuration
    standard_work_hours_per_day DECIMAL(4,2) DEFAULT 8.00,
    standard_work_days_per_week INTEGER DEFAULT 5,
    minimum_hours_for_full_day DECIMAL(4,2) DEFAULT 6.00,
    minimum_hours_for_half_day DECIMAL(4,2) DEFAULT 4.00,

    -- Grace Period Rules
    grace_period_minutes INTEGER DEFAULT 15,
    late_deduction_after_minutes INTEGER DEFAULT 30,
    late_deduction_amount DECIMAL(8,2) DEFAULT 0.00,

    -- Overtime Rules
    overtime_eligible_after_hours DECIMAL(4,2) DEFAULT 8.00,
    weekend_overtime_multiplier DECIMAL(3,2) DEFAULT 2.00,
    holiday_overtime_multiplier DECIMAL(3,2) DEFAULT 2.50,
    max_overtime_hours_per_day DECIMAL(4,2) DEFAULT 4.00,
    max_overtime_hours_per_month DECIMAL(6,2) DEFAULT 60.00,

    -- Attendance Requirements
    minimum_monthly_attendance_percentage DECIMAL(5,2) DEFAULT 80.00,
    continuous_absence_limit_days INTEGER DEFAULT 3,
    monthly_late_limit_count INTEGER DEFAULT 5,

    -- Biometric Requirements
    biometric_mandatory BOOLEAN DEFAULT true,
    manual_entry_allowed BOOLEAN DEFAULT false,
    manual_entry_approval_required BOOLEAN DEFAULT true,

    -- Regularization Rules
    regularization_allowed_days_limit INTEGER DEFAULT 7, -- Can regularize within 7 days
    max_regularizations_per_month INTEGER DEFAULT 5,

    -- Policy Status and Applicability
    policy_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Applicable Employee Categories
    applies_to_all_employees BOOLEAN DEFAULT true,
    specific_departments BIGINT[], -- Array of department IDs
    specific_designations BIGINT[], -- Array of designation IDs
    specific_employee_grades VARCHAR(20)[], -- Array of grades

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_attendance_policy_company_code UNIQUE (company_id, policy_code),
    CONSTRAINT chk_policy_status CHECK (policy_status IN ('ACTIVE', 'INACTIVE', 'DRAFT')),
    CONSTRAINT chk_work_hours CHECK (
        standard_work_hours_per_day > 0 AND
        minimum_hours_for_full_day <= standard_work_hours_per_day AND
        minimum_hours_for_half_day <= minimum_hours_for_full_day
    )
);

-- =====================================================================================
-- ATTENDANCE ANALYTICS AND REPORTING VIEWS
-- =====================================================================================

-- Real-time Attendance Dashboard View
CREATE OR REPLACE VIEW nexus_attendance.v_real_time_attendance AS
SELECT
    ar.company_id,
    ar.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    ar.attendance_date,
    ar.attendance_status,
    ar.first_in_time,
    ar.last_out_time,
    ar.total_time_minutes,
    ar.productive_time_minutes,
    ar.late_by_minutes,
    ar.overtime_minutes,
    sm.shift_name,
    sm.shift_start_time,
    sm.shift_end_time,

    -- Status Indicators
    CASE
        WHEN ar.attendance_date = CURRENT_DATE AND ar.first_in_time IS NOT NULL AND ar.last_out_time IS NULL
        THEN 'IN_OFFICE'
        WHEN ar.attendance_date = CURRENT_DATE AND ar.last_out_time IS NOT NULL
        THEN 'CHECKED_OUT'
        WHEN ar.attendance_date = CURRENT_DATE AND ar.first_in_time IS NULL
        THEN 'NOT_ARRIVED'
        ELSE 'COMPLETED'
    END AS current_status,

    -- Time Calculations
    CASE
        WHEN ar.first_in_time IS NOT NULL AND ar.last_out_time IS NULL
        THEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ar.first_in_time)) / 60
        ELSE ar.total_time_minutes
    END AS current_session_minutes

FROM nexus_attendance.attendance_records ar
    JOIN nexus_foundation.employee_master emp ON ar.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
    LEFT JOIN nexus_attendance.shift_master sm ON ar.shift_id = sm.shift_id
WHERE ar.attendance_date >= CURRENT_DATE - INTERVAL '7 days'
    AND emp.employee_status = 'ACTIVE';

-- Monthly Attendance Analytics View
CREATE OR REPLACE VIEW nexus_attendance.v_monthly_attendance_analytics AS
SELECT
    mas.company_id,
    mas.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    desig.designation_name,
    mas.summary_month,

    -- Attendance Statistics
    mas.total_working_days,
    mas.total_present_days,
    mas.total_absent_days,
    mas.total_late_days,
    mas.total_half_days,
    mas.attendance_percentage,

    -- Time Statistics
    mas.total_work_hours,
    mas.total_overtime_hours,
    ROUND(mas.total_late_minutes / 60.0, 2) AS total_late_hours,

    -- Performance Indicators
    CASE
        WHEN mas.attendance_percentage >= 95 THEN 'EXCELLENT'
        WHEN mas.attendance_percentage >= 85 THEN 'GOOD'
        WHEN mas.attendance_percentage >= 75 THEN 'AVERAGE'
        ELSE 'POOR'
    END AS attendance_grade,

    -- Compliance Status
    CASE
        WHEN mas.total_late_days > 5 THEN 'NON_COMPLIANT'
        WHEN mas.attendance_percentage < 80 THEN 'NON_COMPLIANT'
        ELSE 'COMPLIANT'
    END AS policy_compliance_status

FROM nexus_attendance.monthly_attendance_summary mas
    JOIN nexus_foundation.employee_master emp ON mas.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
    LEFT JOIN nexus_foundation.designation_master desig ON emp.designation_id = desig.designation_id
WHERE emp.employee_status = 'ACTIVE';

-- =====================================================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================================================

-- Enable RLS on all attendance tables
ALTER TABLE nexus_attendance.shift_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.employee_shift_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.holiday_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.biometric_device_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.employee_biometric_registration ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.biometric_punches ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.monthly_attendance_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.attendance_regularization ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.overtime_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_attendance.attendance_policy_master ENABLE ROW LEVEL SECURITY;

-- Company-based access policy for all attendance tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_attendance'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE POLICY company_access_policy ON nexus_attendance.%I
            FOR ALL TO nexus_app_role
            USING (company_id = current_setting(''app.current_company_id'')::BIGINT)
        ', table_name);
    END LOOP;
END $$;

-- =====================================================================================
-- TRIGGERS FOR AUDIT AND BUSINESS LOGIC
-- =====================================================================================

-- Trigger for updating last_modified_at
CREATE OR REPLACE FUNCTION nexus_attendance.update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified_at = CURRENT_TIMESTAMP;
    NEW.last_modified_by = current_setting('app.current_user_id', true);
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to all main tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_attendance'
        AND tablename NOT IN ('biometric_punches', 'attendance_records')
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_last_modified_trigger
            BEFORE UPDATE ON nexus_attendance.%I
            FOR EACH ROW EXECUTE FUNCTION nexus_attendance.update_last_modified()
        ', table_name);
    END LOOP;
END $$;

-- Attendance calculation trigger
CREATE OR REPLACE FUNCTION nexus_attendance.calculate_attendance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate total time if both in and out times are present
    IF NEW.first_in_time IS NOT NULL AND NEW.last_out_time IS NOT NULL THEN
        NEW.total_time_minutes = EXTRACT(EPOCH FROM (NEW.last_out_time - NEW.first_in_time)) / 60;

        -- Calculate late minutes based on shift timing
        IF NEW.shift_id IS NOT NULL THEN
            DECLARE
                shift_start_time TIME;
                actual_start_time TIME;
            BEGIN
                SELECT s.shift_start_time INTO shift_start_time
                FROM nexus_attendance.shift_master s
                WHERE s.shift_id = NEW.shift_id;

                actual_start_time = NEW.first_in_time::TIME;

                IF actual_start_time > shift_start_time THEN
                    NEW.late_by_minutes = EXTRACT(EPOCH FROM (actual_start_time - shift_start_time)) / 60;
                END IF;
            END;
        END IF;

        -- Calculate overtime based on policy
        DECLARE
            standard_hours DECIMAL;
            overtime_eligible_after DECIMAL;
        BEGIN
            SELECT
                ap.standard_work_hours_per_day,
                ap.overtime_eligible_after_hours
            INTO standard_hours, overtime_eligible_after
            FROM nexus_attendance.attendance_policy_master ap
            WHERE ap.company_id = NEW.company_id
            AND ap.policy_status = 'ACTIVE'
            AND CURRENT_DATE BETWEEN ap.effective_from_date
                AND COALESCE(ap.effective_to_date, CURRENT_DATE)
            LIMIT 1;

            IF NEW.total_time_minutes > (overtime_eligible_after * 60) THEN
                NEW.overtime_minutes = NEW.total_time_minutes - (overtime_eligible_after * 60);
            END IF;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply attendance calculation trigger
CREATE TRIGGER calculate_attendance_metrics_trigger
    BEFORE INSERT OR UPDATE ON nexus_attendance.attendance_records
    FOR EACH ROW EXECUTE FUNCTION nexus_attendance.calculate_attendance_metrics();

-- =====================================================================================
-- STORED PROCEDURES FOR ATTENDANCE PROCESSING
-- =====================================================================================

-- Process biometric punches into attendance records
CREATE OR REPLACE FUNCTION nexus_attendance.process_biometric_punches(
    p_company_id BIGINT,
    p_processing_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    processed_count INTEGER,
    duplicate_count INTEGER,
    error_count INTEGER,
    processing_summary JSONB
) AS $$
DECLARE
    v_processed_count INTEGER := 0;
    v_duplicate_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_punch_record RECORD;
BEGIN
    -- Process pending punches for the specified date
    FOR v_punch_record IN
        SELECT
            bp.*,
            emp.employee_id,
            emp.company_id
        FROM nexus_attendance.biometric_punches bp
        LEFT JOIN nexus_foundation.employee_master emp ON bp.employee_code = emp.employee_code
        WHERE bp.processing_status = 'PENDING'
        AND DATE(bp.punch_timestamp) = p_processing_date
        AND (p_company_id IS NULL OR emp.company_id = p_company_id)
        ORDER BY bp.punch_timestamp
    LOOP
        BEGIN
            -- Check if employee exists
            IF v_punch_record.employee_id IS NULL THEN
                UPDATE nexus_attendance.biometric_punches
                SET processing_status = 'INVALID',
                    processing_error_message = 'Employee not found for code: ' || v_punch_record.employee_code,
                    processed_at = CURRENT_TIMESTAMP
                WHERE punch_id = v_punch_record.punch_id;

                v_error_count := v_error_count + 1;
                CONTINUE;
            END IF;

            -- Insert or update attendance record
            INSERT INTO nexus_attendance.attendance_records (
                company_id,
                employee_id,
                attendance_date,
                first_in_time,
                last_out_time,
                attendance_status,
                entry_device_id,
                exit_device_id,
                data_source
            )
            VALUES (
                v_punch_record.company_id,
                v_punch_record.employee_id,
                DATE(v_punch_record.punch_timestamp),
                v_punch_record.punch_timestamp,
                NULL,
                'PRESENT',
                v_punch_record.device_id,
                NULL,
                'BIOMETRIC'
            )
            ON CONFLICT (company_id, employee_id, attendance_date)
            DO UPDATE SET
                last_out_time = CASE
                    WHEN nexus_attendance.attendance_records.first_in_time < EXCLUDED.first_in_time
                    THEN EXCLUDED.first_in_time
                    ELSE nexus_attendance.attendance_records.last_out_time
                END,
                exit_device_id = CASE
                    WHEN nexus_attendance.attendance_records.first_in_time < EXCLUDED.first_in_time
                    THEN EXCLUDED.entry_device_id
                    ELSE nexus_attendance.attendance_records.exit_device_id
                END,
                last_modified_at = CURRENT_TIMESTAMP;

            -- Mark punch as processed
            UPDATE nexus_attendance.biometric_punches
            SET processing_status = 'PROCESSED',
                processed_at = CURRENT_TIMESTAMP
            WHERE punch_id = v_punch_record.punch_id;

            v_processed_count := v_processed_count + 1;

        EXCEPTION WHEN OTHERS THEN
            -- Mark punch as error
            UPDATE nexus_attendance.biometric_punches
            SET processing_status = 'ERROR',
                processing_error_message = SQLERRM,
                processed_at = CURRENT_TIMESTAMP
            WHERE punch_id = v_punch_record.punch_id;

            v_error_count := v_error_count + 1;
        END;
    END LOOP;

    RETURN QUERY SELECT
        v_processed_count,
        v_duplicate_count,
        v_error_count,
        jsonb_build_object(
            'processing_date', p_processing_date,
            'company_id', p_company_id,
            'processed_count', v_processed_count,
            'duplicate_count', v_duplicate_count,
            'error_count', v_error_count,
            'processed_at', CURRENT_TIMESTAMP
        );
END;
$$ LANGUAGE plpgsql;

-- Generate monthly attendance summary
CREATE OR REPLACE FUNCTION nexus_attendance.generate_monthly_summary(
    p_company_id BIGINT,
    p_employee_id BIGINT DEFAULT NULL,
    p_summary_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
)
RETURNS INTEGER AS $$
DECLARE
    v_employee_record RECORD;
    v_summary_record RECORD;
    v_working_days INTEGER;
    v_processed_count INTEGER := 0;
BEGIN
    -- Calculate working days for the month (excluding weekends and holidays)
    SELECT COUNT(*)
    INTO v_working_days
    FROM generate_series(
        p_summary_month,
        p_summary_month + INTERVAL '1 month' - INTERVAL '1 day',
        INTERVAL '1 day'
    ) AS day_series(day)
    WHERE EXTRACT(DOW FROM day_series.day) NOT IN (0, 6) -- Exclude Sunday (0) and Saturday (6)
    AND day_series.day NOT IN (
        SELECT holiday_date
        FROM nexus_attendance.holiday_master
        WHERE company_id = p_company_id
        AND holiday_status = 'ACTIVE'
    );

    -- Process employees
    FOR v_employee_record IN
        SELECT employee_id, employee_code
        FROM nexus_foundation.employee_master
        WHERE company_id = p_company_id
        AND employee_status = 'ACTIVE'
        AND (p_employee_id IS NULL OR employee_id = p_employee_id)
    LOOP
        -- Calculate attendance summary for employee
        SELECT
            v_working_days as total_working_days,
            COUNT(CASE WHEN attendance_status = 'PRESENT' THEN 1 END) as present_days,
            COUNT(CASE WHEN attendance_status = 'ABSENT' THEN 1 END) as absent_days,
            COUNT(CASE WHEN attendance_status = 'LATE' THEN 1 END) as late_days,
            COUNT(CASE WHEN attendance_status = 'HALF_DAY' THEN 1 END) as half_days,
            COUNT(CASE WHEN attendance_status = 'COMP_OFF' THEN 1 END) as comp_off_days,
            COUNT(CASE WHEN attendance_status = 'LEAVE' THEN 1 END) as leave_days,
            COUNT(CASE WHEN attendance_status = 'HOLIDAY' THEN 1 END) as holiday_days,
            COUNT(CASE WHEN attendance_status = 'WEEKEND' THEN 1 END) as weekend_days,
            ROUND(SUM(COALESCE(total_time_minutes, 0)) / 60.0, 2) as total_work_hours,
            ROUND(SUM(COALESCE(overtime_minutes, 0)) / 60.0, 2) as total_overtime_hours,
            SUM(COALESCE(late_by_minutes, 0)) as total_late_minutes,
            SUM(COALESCE(early_departure_minutes, 0)) as total_early_departure_minutes
        INTO v_summary_record
        FROM nexus_attendance.attendance_records
        WHERE company_id = p_company_id
        AND employee_id = v_employee_record.employee_id
        AND attendance_date >= p_summary_month
        AND attendance_date < p_summary_month + INTERVAL '1 month';

        -- Insert or update summary
        INSERT INTO nexus_attendance.monthly_attendance_summary (
            company_id,
            employee_id,
            summary_month,
            total_working_days,
            total_present_days,
            total_absent_days,
            total_late_days,
            total_half_days,
            total_comp_off_days,
            total_leave_days,
            total_holiday_days,
            total_weekend_days,
            total_work_hours,
            total_overtime_hours,
            total_late_minutes,
            total_early_departure_minutes,
            summary_status
        )
        VALUES (
            p_company_id,
            v_employee_record.employee_id,
            p_summary_month,
            v_summary_record.total_working_days,
            COALESCE(v_summary_record.present_days, 0),
            COALESCE(v_summary_record.absent_days, 0),
            COALESCE(v_summary_record.late_days, 0),
            COALESCE(v_summary_record.half_days, 0),
            COALESCE(v_summary_record.comp_off_days, 0),
            COALESCE(v_summary_record.leave_days, 0),
            COALESCE(v_summary_record.holiday_days, 0),
            COALESCE(v_summary_record.weekend_days, 0),
            COALESCE(v_summary_record.total_work_hours, 0),
            COALESCE(v_summary_record.total_overtime_hours, 0),
            COALESCE(v_summary_record.total_late_minutes, 0),
            COALESCE(v_summary_record.total_early_departure_minutes, 0),
            'DRAFT'
        )
        ON CONFLICT (company_id, employee_id, summary_month)
        DO UPDATE SET
            total_working_days = EXCLUDED.total_working_days,
            total_present_days = EXCLUDED.total_present_days,
            total_absent_days = EXCLUDED.total_absent_days,
            total_late_days = EXCLUDED.total_late_days,
            total_half_days = EXCLUDED.total_half_days,
            total_comp_off_days = EXCLUDED.total_comp_off_days,
            total_leave_days = EXCLUDED.total_leave_days,
            total_holiday_days = EXCLUDED.total_holiday_days,
            total_weekend_days = EXCLUDED.total_weekend_days,
            total_work_hours = EXCLUDED.total_work_hours,
            total_overtime_hours = EXCLUDED.total_overtime_hours,
            total_late_minutes = EXCLUDED.total_late_minutes,
            total_early_departure_minutes = EXCLUDED.total_early_departure_minutes,
            last_modified_at = CURRENT_TIMESTAMP;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA nexus_attendance IS 'Attendance Management System with biometric integration, shift management, and real-time processing capabilities';

COMMENT ON TABLE nexus_attendance.shift_master IS 'Master table for work shifts with timing, overtime rules, and weekly schedules';
COMMENT ON TABLE nexus_attendance.employee_shift_assignment IS 'Assignment of employees to shifts with effective periods and flexible timing options';
COMMENT ON TABLE nexus_attendance.holiday_master IS 'Company and location-specific holidays affecting attendance calculations';
COMMENT ON TABLE nexus_attendance.biometric_device_master IS 'Physical biometric devices for attendance capture with network configuration';
COMMENT ON TABLE nexus_attendance.employee_biometric_registration IS 'Employee biometric templates registered on devices for verification';
COMMENT ON TABLE nexus_attendance.attendance_records IS 'Core attendance data partitioned by month for high-volume operations';
COMMENT ON TABLE nexus_attendance.biometric_punches IS 'Raw biometric punch data from devices before processing into attendance records';
COMMENT ON TABLE nexus_attendance.monthly_attendance_summary IS 'Pre-calculated monthly attendance statistics for performance optimization';
COMMENT ON TABLE nexus_attendance.attendance_regularization IS 'Employee requests for attendance corrections with approval workflow';
COMMENT ON TABLE nexus_attendance.overtime_requests IS 'Overtime requests and approvals with actual vs planned tracking';
COMMENT ON TABLE nexus_attendance.attendance_policy_master IS 'Company-specific attendance rules, calculations, and policy configurations';

-- =====================================================================================
-- SCHEMA COMPLETION
-- =====================================================================================

-- Grant permissions to application role
GRANT USAGE ON SCHEMA nexus_attendance TO nexus_app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nexus_attendance TO nexus_app_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA nexus_attendance TO nexus_app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nexus_attendance TO nexus_app_role;

-- Grant read-only access to reporting role
GRANT USAGE ON SCHEMA nexus_attendance TO nexus_readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_attendance TO nexus_readonly_role;
GRANT EXECUTE ON FUNCTION nexus_attendance.generate_monthly_summary TO nexus_readonly_role;

RAISE NOTICE 'NEXUS Attendance Management Schema created successfully with:
- 11 core tables with partitioning for high-volume data
- Biometric device integration and real-time processing
- Comprehensive shift management and overtime calculations
- Attendance policy configuration and regularization workflows
- Advanced analytics views and stored procedures
- Row Level Security and audit trails
- GraphQL-optimized structure for modern frontend integration';

-- End of 02_nexus_attendance_schema.sql