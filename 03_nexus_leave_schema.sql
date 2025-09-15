-- =====================================================================================
-- NEXUS HRMS - Leave Management Schema
-- =====================================================================================
-- Version: 3.0
-- Date: 2025-01-14
-- Module: Leave Management System
-- Description: Comprehensive leave management with multi-level approvals, leave balances,
--              accruals, encashment, carry-forward policies, and integration with attendance
-- Dependencies: 01_nexus_foundation_schema.sql, 02_nexus_attendance_schema.sql
-- Author: PostgreSQL DBA (20+ Years Experience)
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create leave management schema
CREATE SCHEMA IF NOT EXISTS nexus_leave;

-- Set search path for this schema
SET search_path = nexus_leave, nexus_foundation, nexus_attendance, nexus_security, public;

-- =====================================================================================
-- LEAVE TYPE AND POLICY CONFIGURATION
-- =====================================================================================

-- Leave Type Master
-- Defines various types of leaves with rules and configurations
CREATE TABLE nexus_leave.leave_type_master (
    leave_type_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Leave Type Identification
    leave_type_code VARCHAR(20) NOT NULL,
    leave_type_name VARCHAR(100) NOT NULL,
    leave_type_description TEXT,
    leave_category VARCHAR(30) NOT NULL DEFAULT 'GENERAL',
    -- GENERAL, MEDICAL, MATERNITY, PATERNITY, EMERGENCY, COMPENSATORY, STUDY

    -- Leave Allocation Rules
    annual_allocation_days DECIMAL(5,2) DEFAULT 0.00,
    monthly_allocation_days DECIMAL(4,2) DEFAULT 0.00,
    quarterly_allocation_days DECIMAL(4,2) DEFAULT 0.00,
    allocation_frequency VARCHAR(20) DEFAULT 'ANNUAL', -- ANNUAL, MONTHLY, QUARTERLY, MANUAL

    -- Leave Balance Rules
    is_paid_leave BOOLEAN DEFAULT true,
    is_carry_forward_allowed BOOLEAN DEFAULT false,
    max_carry_forward_days DECIMAL(5,2) DEFAULT 0.00,
    carry_forward_expiry_months INTEGER DEFAULT 12,

    -- Leave Application Rules
    max_consecutive_days INTEGER DEFAULT 30,
    max_days_per_month DECIMAL(4,2) DEFAULT 31.00,
    max_applications_per_month INTEGER DEFAULT 10,
    min_advance_notice_days INTEGER DEFAULT 1,
    max_advance_application_days INTEGER DEFAULT 365,

    -- Approval Configuration
    requires_approval BOOLEAN DEFAULT true,
    approval_levels_required INTEGER DEFAULT 1,
    auto_approval_up_to_days DECIMAL(3,1) DEFAULT 0.0,

    -- Documentation Requirements
    requires_documentation BOOLEAN DEFAULT false,
    documentation_mandatory_after_days INTEGER DEFAULT 3,
    allowed_document_types TEXT[], -- Array of allowed document types

    -- Leave Calculation Rules
    is_sandwich_leave_applicable BOOLEAN DEFAULT false, -- Count weekends between leave days
    is_holiday_included BOOLEAN DEFAULT false, -- Count holidays as leave days
    leave_calculation_basis VARCHAR(20) DEFAULT 'CALENDAR_DAYS', -- CALENDAR_DAYS, WORKING_DAYS

    -- Encashment Rules
    is_encashment_allowed BOOLEAN DEFAULT false,
    encashment_eligibility_months INTEGER DEFAULT 12,
    max_encashment_days_per_year DECIMAL(5,2) DEFAULT 0.00,
    encashment_percentage DECIMAL(5,2) DEFAULT 100.00,

    -- Gender and Employee Type Restrictions
    applicable_gender VARCHAR(10) DEFAULT 'ALL', -- ALL, MALE, FEMALE, OTHER
    applicable_employee_types VARCHAR(50)[] DEFAULT ARRAY['PERMANENT'], -- PERMANENT, CONTRACT, INTERN, etc.
    applicable_after_months INTEGER DEFAULT 0, -- Eligibility after employment months

    -- Status and Effective Dates
    leave_type_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_leave_type_company_code UNIQUE (company_id, leave_type_code),
    CONSTRAINT chk_leave_type_status CHECK (leave_type_status IN ('ACTIVE', 'INACTIVE', 'DEPRECATED')),
    CONSTRAINT chk_allocation_frequency CHECK (allocation_frequency IN ('ANNUAL', 'MONTHLY', 'QUARTERLY', 'MANUAL')),
    CONSTRAINT chk_leave_category CHECK (leave_category IN (
        'GENERAL', 'MEDICAL', 'MATERNITY', 'PATERNITY', 'EMERGENCY', 'COMPENSATORY', 'STUDY', 'BEREAVEMENT'
    )),
    CONSTRAINT chk_carry_forward_logic CHECK (
        (is_carry_forward_allowed = false) OR
        (is_carry_forward_allowed = true AND max_carry_forward_days > 0)
    )
);

-- Leave Policy Assignment
-- Maps employees/groups to specific leave policies
CREATE TABLE nexus_leave.employee_leave_policy (
    policy_assignment_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    leave_type_id BIGINT NOT NULL REFERENCES nexus_leave.leave_type_master(leave_type_id),

    -- Assignment Target
    assignment_type VARCHAR(20) NOT NULL DEFAULT 'EMPLOYEE',
    -- EMPLOYEE, DEPARTMENT, DESIGNATION, GRADE, ALL_EMPLOYEES

    -- Specific Assignments
    employee_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    department_id BIGINT REFERENCES nexus_foundation.department_master(department_id),
    designation_id BIGINT REFERENCES nexus_foundation.designation_master(designation_id),
    employee_grade VARCHAR(20),

    -- Policy Customization (Override leave type defaults)
    custom_annual_allocation DECIMAL(5,2),
    custom_carry_forward_days DECIMAL(5,2),
    custom_max_consecutive_days INTEGER,
    custom_approval_levels INTEGER,

    -- Effective Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,
    policy_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_assignment_type CHECK (assignment_type IN (
        'EMPLOYEE', 'DEPARTMENT', 'DESIGNATION', 'GRADE', 'ALL_EMPLOYEES'
    )),
    CONSTRAINT chk_policy_status CHECK (policy_status IN ('ACTIVE', 'INACTIVE', 'EXPIRED')),
    CONSTRAINT chk_assignment_logic CHECK (
        (assignment_type = 'EMPLOYEE' AND employee_id IS NOT NULL) OR
        (assignment_type = 'DEPARTMENT' AND department_id IS NOT NULL) OR
        (assignment_type = 'DESIGNATION' AND designation_id IS NOT NULL) OR
        (assignment_type = 'GRADE' AND employee_grade IS NOT NULL) OR
        (assignment_type = 'ALL_EMPLOYEES')
    )
);

-- =====================================================================================
-- LEAVE BALANCE MANAGEMENT
-- =====================================================================================

-- Employee Leave Balance
-- Tracks current leave balances for each employee and leave type
CREATE TABLE nexus_leave.employee_leave_balance (
    balance_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    leave_type_id BIGINT NOT NULL REFERENCES nexus_leave.leave_type_master(leave_type_id),

    -- Balance Period
    balance_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    balance_period_start_date DATE NOT NULL,
    balance_period_end_date DATE NOT NULL,

    -- Leave Balance Components
    opening_balance DECIMAL(5,2) DEFAULT 0.00,
    annual_allocation DECIMAL(5,2) DEFAULT 0.00,
    carry_forward_balance DECIMAL(5,2) DEFAULT 0.00,
    additional_allocation DECIMAL(5,2) DEFAULT 0.00, -- Bonus/special allocations
    adjustment_balance DECIMAL(5,2) DEFAULT 0.00, -- Manual adjustments (+/-)

    -- Calculated Total Available
    total_available_balance DECIMAL(5,2) GENERATED ALWAYS AS (
        opening_balance + annual_allocation + carry_forward_balance +
        additional_allocation + adjustment_balance
    ) STORED,

    -- Leave Consumption
    consumed_balance DECIMAL(5,2) DEFAULT 0.00,
    pending_balance DECIMAL(5,2) DEFAULT 0.00, -- Approved but not yet taken
    encashed_balance DECIMAL(5,2) DEFAULT 0.00,

    -- Remaining Balance
    remaining_balance DECIMAL(5,2) GENERATED ALWAYS AS (
        total_available_balance - consumed_balance - pending_balance - encashed_balance
    ) STORED,

    -- Balance Status
    balance_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_carry_forward_processed BOOLEAN DEFAULT false,
    carry_forward_expiry_date DATE,

    -- Lapse Tracking
    lapsed_balance DECIMAL(5,2) DEFAULT 0.00,
    lapse_date DATE,
    lapse_reason VARCHAR(200),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_leave_balance_year UNIQUE (company_id, employee_id, leave_type_id, balance_year),
    CONSTRAINT chk_balance_status CHECK (balance_status IN ('ACTIVE', 'EXPIRED', 'PROCESSED')),
    CONSTRAINT chk_balance_periods CHECK (balance_period_end_date >= balance_period_start_date),
    CONSTRAINT chk_remaining_balance CHECK (remaining_balance >= 0.00)
);

-- Leave Balance Transactions
-- Audit trail for all balance changes
CREATE TABLE nexus_leave.leave_balance_transactions (
    transaction_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    balance_id BIGINT NOT NULL REFERENCES nexus_leave.employee_leave_balance(balance_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    leave_type_id BIGINT NOT NULL REFERENCES nexus_leave.leave_type_master(leave_type_id),

    -- Transaction Details
    transaction_type VARCHAR(30) NOT NULL,
    -- ALLOCATION, CONSUMPTION, ADJUSTMENT, CARRY_FORWARD, ENCASHMENT, LAPSE, REVERSAL
    transaction_amount DECIMAL(5,2) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Balance Snapshot (After Transaction)
    balance_before_transaction DECIMAL(5,2) NOT NULL,
    balance_after_transaction DECIMAL(5,2) NOT NULL,

    -- Reference Information
    reference_type VARCHAR(30), -- LEAVE_APPLICATION, MANUAL_ADJUSTMENT, POLICY_CHANGE, etc.
    reference_id BIGINT, -- ID of the referenced record
    reference_description TEXT,

    -- Transaction Processing
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    processed_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),

    -- Constraints
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN (
        'ALLOCATION', 'CONSUMPTION', 'ADJUSTMENT', 'CARRY_FORWARD',
        'ENCASHMENT', 'LAPSE', 'REVERSAL', 'RESTORATION'
    )),
    CONSTRAINT chk_transaction_status CHECK (transaction_status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    CONSTRAINT chk_balance_calculation CHECK (
        balance_after_transaction = balance_before_transaction +
        CASE WHEN transaction_type IN ('CONSUMPTION', 'ENCASHMENT', 'LAPSE')
             THEN -ABS(transaction_amount)
             ELSE ABS(transaction_amount)
        END
    )
);

-- =====================================================================================
-- LEAVE APPLICATION MANAGEMENT
-- =====================================================================================

-- Leave Applications
-- Core leave application records with comprehensive tracking
CREATE TABLE nexus_leave.leave_applications (
    application_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    leave_type_id BIGINT NOT NULL REFERENCES nexus_leave.leave_type_master(leave_type_id),

    -- Application Identification
    application_number VARCHAR(50) NOT NULL,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Leave Period
    leave_start_date DATE NOT NULL,
    leave_end_date DATE NOT NULL,
    leave_duration_days DECIMAL(4,1) NOT NULL,

    -- Leave Duration Breakdown
    total_calendar_days INTEGER GENERATED ALWAYS AS (
        (leave_end_date - leave_start_date + 1)
    ) STORED,
    working_days_count DECIMAL(4,1), -- Calculated excluding weekends/holidays
    weekend_days_count INTEGER DEFAULT 0,
    holiday_days_count INTEGER DEFAULT 0,

    -- Leave Session Details
    leave_session VARCHAR(20) DEFAULT 'FULL_DAY',
    -- FULL_DAY, FIRST_HALF, SECOND_HALF, CUSTOM_HOURS

    -- For partial day leaves
    session_start_time TIME,
    session_end_time TIME,
    session_hours DECIMAL(4,2),

    -- Application Details
    leave_reason TEXT NOT NULL,
    emergency_contact_name VARCHAR(100),
    emergency_contact_number VARCHAR(20),
    leave_address TEXT,

    -- Handover Information
    work_handover_to BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    handover_notes TEXT,
    handover_status VARCHAR(20) DEFAULT 'PENDING',

    -- Application Status
    application_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, PENDING_APPROVAL, APPROVED, REJECTED, CANCELLED, WITHDRAWN, COMPLETED

    -- Leave Balance Impact
    balance_consumed DECIMAL(5,2) DEFAULT 0.00,
    balance_available_at_application DECIMAL(5,2),
    is_loss_of_pay BOOLEAN DEFAULT false,
    lop_days DECIMAL(4,1) DEFAULT 0.0,

    -- Special Leave Handling
    is_sandwich_leave BOOLEAN DEFAULT false,
    sandwich_days_count INTEGER DEFAULT 0,
    is_compensatory_off BOOLEAN DEFAULT false,
    comp_off_reference_date DATE,

    -- Documentation
    supporting_documents JSONB, -- Array of document references
    medical_certificate_required BOOLEAN DEFAULT false,
    medical_certificate_submitted BOOLEAN DEFAULT false,

    -- Approval Workflow
    current_approval_level INTEGER DEFAULT 1,
    total_approval_levels INTEGER DEFAULT 1,
    approval_workflow_id BIGINT,

    -- Final Approval
    final_approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    final_approved_at TIMESTAMP WITH TIME ZONE,
    final_approval_comments TEXT,

    -- Rejection Details
    rejected_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,

    -- Leave Completion
    actual_leave_start_date DATE,
    actual_leave_end_date DATE,
    actual_leave_duration DECIMAL(4,1),
    leave_completion_status VARCHAR(20) DEFAULT 'PENDING',
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Integration with Attendance
    attendance_updated BOOLEAN DEFAULT false,
    attendance_update_status VARCHAR(20) DEFAULT 'PENDING',

    -- Payroll Integration
    payroll_processed BOOLEAN DEFAULT false,
    payroll_month DATE,
    payroll_impact_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_leave_application_number UNIQUE (company_id, application_number),
    CONSTRAINT chk_leave_dates CHECK (leave_end_date >= leave_start_date),
    CONSTRAINT chk_leave_duration CHECK (leave_duration_days > 0 AND leave_duration_days <= 365),
    CONSTRAINT chk_application_status CHECK (application_status IN (
        'DRAFT', 'SUBMITTED', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED',
        'CANCELLED', 'WITHDRAWN', 'COMPLETED', 'EXPIRED'
    )),
    CONSTRAINT chk_leave_session CHECK (leave_session IN (
        'FULL_DAY', 'FIRST_HALF', 'SECOND_HALF', 'CUSTOM_HOURS'
    )),
    CONSTRAINT chk_session_times CHECK (
        (leave_session != 'CUSTOM_HOURS') OR
        (session_start_time IS NOT NULL AND session_end_time IS NOT NULL AND session_end_time > session_start_time)
    ),
    CONSTRAINT chk_completion_status CHECK (leave_completion_status IN (
        'PENDING', 'COMPLETED', 'PARTIALLY_TAKEN', 'EXTENDED', 'SHORTENED', 'CANCELLED'
    ))
);

-- Leave Approval Workflow
-- Multi-level approval system for leave applications
CREATE TABLE nexus_leave.leave_approval_workflow (
    approval_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    application_id BIGINT NOT NULL REFERENCES nexus_leave.leave_applications(application_id),

    -- Approval Level Information
    approval_level INTEGER NOT NULL,
    approver_employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    approver_role VARCHAR(50), -- HR, MANAGER, ADMIN, etc.

    -- Approval Decision
    approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, DELEGATED, SKIPPED, EXPIRED

    approval_date TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,
    approval_conditions TEXT, -- Any conditions attached to approval

    -- Delegation Support
    delegated_to BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    delegation_reason TEXT,
    delegation_date TIMESTAMP WITH TIME ZONE,

    -- Time Limits
    approval_deadline TIMESTAMP WITH TIME ZONE,
    escalation_employee_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    escalated_at TIMESTAMP WITH TIME ZONE,
    escalation_reason TEXT,

    -- Approval Sequence
    is_parallel_approval BOOLEAN DEFAULT false, -- Can be approved in parallel with other levels
    is_mandatory_approval BOOLEAN DEFAULT true, -- Required for final approval
    sequence_order INTEGER DEFAULT 1,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_leave_approval_level UNIQUE (application_id, approval_level, approver_employee_id),
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'DELEGATED', 'SKIPPED', 'EXPIRED'
    )),
    CONSTRAINT chk_approval_level CHECK (approval_level > 0 AND approval_level <= 10),
    CONSTRAINT chk_approval_logic CHECK (
        (approval_status = 'PENDING') OR
        (approval_status != 'PENDING' AND approval_date IS NOT NULL)
    )
);

-- =====================================================================================
-- LEAVE ENCASHMENT MANAGEMENT
-- =====================================================================================

-- Leave Encashment Requests
-- Employee requests for leave encashment
CREATE TABLE nexus_leave.leave_encashment_requests (
    encashment_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    leave_type_id BIGINT NOT NULL REFERENCES nexus_leave.leave_type_master(leave_type_id),

    -- Encashment Request Details
    encashment_request_number VARCHAR(50) NOT NULL,
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    encashment_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),

    -- Leave Balance Information
    available_balance DECIMAL(5,2) NOT NULL,
    requested_encashment_days DECIMAL(5,2) NOT NULL,
    eligible_encashment_days DECIMAL(5,2) NOT NULL,

    -- Financial Calculation
    per_day_salary DECIMAL(12,2) NOT NULL,
    encashment_percentage DECIMAL(5,2) DEFAULT 100.00,
    gross_encashment_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        eligible_encashment_days * per_day_salary * (encashment_percentage / 100)
    ) STORED,

    -- Tax and Deductions
    tax_applicable BOOLEAN DEFAULT true,
    tax_amount DECIMAL(12,2) DEFAULT 0.00,
    other_deductions DECIMAL(12,2) DEFAULT 0.00,
    net_encashment_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        gross_encashment_amount - COALESCE(tax_amount, 0) - COALESCE(other_deductions, 0)
    ) STORED,

    -- Request Status
    request_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, APPROVED, REJECTED, PROCESSED, PAID, CANCELLED

    -- Approval Information
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- Processing Information
    processed_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_month DATE,

    -- Payment Information
    payment_reference_number VARCHAR(100),
    payment_date DATE,
    payment_mode VARCHAR(20) DEFAULT 'BANK_TRANSFER',
    payment_status VARCHAR(20) DEFAULT 'PENDING',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_encashment_request_number UNIQUE (company_id, encashment_request_number),
    CONSTRAINT chk_encashment_request_status CHECK (request_status IN (
        'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'PROCESSED', 'PAID', 'CANCELLED'
    )),
    CONSTRAINT chk_encashment_days CHECK (
        requested_encashment_days > 0 AND
        eligible_encashment_days <= requested_encashment_days AND
        eligible_encashment_days <= available_balance
    ),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'
    ))
);

-- =====================================================================================
-- COMPENSATORY OFF MANAGEMENT
-- =====================================================================================

-- Compensatory Off Records
-- Tracks comp-off earned and utilized
CREATE TABLE nexus_leave.compensatory_off_records (
    comp_off_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Comp-off Earning Details
    earned_date DATE NOT NULL,
    earned_for_date DATE NOT NULL, -- Date for which comp-off was earned (holiday/weekend work)
    earned_reason VARCHAR(200) NOT NULL,

    -- Work Details
    work_start_time TIMESTAMP WITH TIME ZONE,
    work_end_time TIMESTAMP WITH TIME ZONE,
    total_work_hours DECIMAL(5,2),

    -- Comp-off Calculation
    comp_off_days_earned DECIMAL(4,1) NOT NULL DEFAULT 1.0,
    comp_off_type VARCHAR(20) DEFAULT 'FULL_DAY', -- FULL_DAY, HALF_DAY, HOURS
    comp_off_hours DECIMAL(5,2), -- For hourly comp-off

    -- Approval Status
    approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, AUTO_APPROVED
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,

    -- Utilization Tracking
    utilization_status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    -- AVAILABLE, PARTIALLY_USED, FULLY_USED, EXPIRED, CANCELLED
    utilized_days DECIMAL(4,1) DEFAULT 0.0,
    remaining_days DECIMAL(4,1) GENERATED ALWAYS AS (
        comp_off_days_earned - COALESCE(utilized_days, 0)
    ) STORED,

    -- Expiry Information
    expiry_date DATE NOT NULL,
    is_expired BOOLEAN GENERATED ALWAYS AS (
        CURRENT_DATE > expiry_date AND utilization_status = 'AVAILABLE'
    ) STORED,

    -- Reference Information
    reference_type VARCHAR(30), -- HOLIDAY_WORK, WEEKEND_WORK, OVERTIME_WORK
    reference_id BIGINT, -- Reference to attendance record, overtime request, etc.

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_comp_off_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'AUTO_APPROVED'
    )),
    CONSTRAINT chk_comp_off_utilization_status CHECK (utilization_status IN (
        'AVAILABLE', 'PARTIALLY_USED', 'FULLY_USED', 'EXPIRED', 'CANCELLED'
    )),
    CONSTRAINT chk_comp_off_days CHECK (
        comp_off_days_earned > 0 AND comp_off_days_earned <= 5 AND
        utilized_days >= 0 AND utilized_days <= comp_off_days_earned
    ),
    CONSTRAINT chk_work_times CHECK (
        (work_start_time IS NULL AND work_end_time IS NULL) OR
        (work_start_time IS NOT NULL AND work_end_time IS NOT NULL AND work_end_time > work_start_time)
    )
);

-- Comp-off Utilization Records
-- Tracks when and how comp-off is used
CREATE TABLE nexus_leave.comp_off_utilization (
    utilization_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    comp_off_id BIGINT NOT NULL REFERENCES nexus_leave.compensatory_off_records(comp_off_id),
    application_id BIGINT REFERENCES nexus_leave.leave_applications(application_id),

    -- Utilization Details
    utilized_date DATE NOT NULL,
    utilized_days DECIMAL(4,1) NOT NULL,
    utilization_type VARCHAR(20) DEFAULT 'LEAVE_APPLICATION',
    -- LEAVE_APPLICATION, DIRECT_UTILIZATION, EMERGENCY_USE

    -- Session Details
    utilized_session VARCHAR(20) DEFAULT 'FULL_DAY',
    session_start_time TIME,
    session_end_time TIME,

    -- Status
    utilization_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    -- ACTIVE, CANCELLED, REVERSED

    -- Cancellation/Reversal Information
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    cancellation_reason TEXT,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_utilization_status CHECK (utilization_status IN ('ACTIVE', 'CANCELLED', 'REVERSED')),
    CONSTRAINT chk_utilized_days CHECK (utilized_days > 0 AND utilized_days <= 5),
    CONSTRAINT chk_utilized_session CHECK (utilized_session IN ('FULL_DAY', 'FIRST_HALF', 'SECOND_HALF'))
);

-- =====================================================================================
-- LEAVE ANALYTICS AND REPORTING VIEWS
-- =====================================================================================

-- Employee Leave Summary View
CREATE OR REPLACE VIEW nexus_leave.v_employee_leave_summary AS
SELECT
    elb.company_id,
    elb.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    elb.balance_year,
    ltm.leave_type_code,
    ltm.leave_type_name,
    ltm.leave_category,

    -- Balance Information
    elb.annual_allocation,
    elb.carry_forward_balance,
    elb.total_available_balance,
    elb.consumed_balance,
    elb.pending_balance,
    elb.remaining_balance,
    elb.encashed_balance,
    elb.lapsed_balance,

    -- Utilization Percentage
    CASE
        WHEN elb.total_available_balance > 0
        THEN ROUND((elb.consumed_balance / elb.total_available_balance) * 100, 2)
        ELSE 0
    END AS utilization_percentage,

    -- Status Indicators
    CASE
        WHEN elb.remaining_balance < 0 THEN 'OVERUTILIZED'
        WHEN elb.remaining_balance = 0 THEN 'FULLY_UTILIZED'
        WHEN elb.remaining_balance < (elb.total_available_balance * 0.2) THEN 'LOW_BALANCE'
        ELSE 'SUFFICIENT'
    END AS balance_status,

    -- Carry Forward Eligibility
    CASE
        WHEN ltm.is_carry_forward_allowed AND elb.remaining_balance > 0
        THEN LEAST(elb.remaining_balance, ltm.max_carry_forward_days)
        ELSE 0
    END AS eligible_carry_forward,

    -- Encashment Eligibility
    CASE
        WHEN ltm.is_encashment_allowed AND elb.remaining_balance > 0
        THEN LEAST(elb.remaining_balance, ltm.max_encashment_days_per_year)
        ELSE 0
    END AS eligible_encashment

FROM nexus_leave.employee_leave_balance elb
    JOIN nexus_foundation.employee_master emp ON elb.employee_id = emp.employee_id
    JOIN nexus_leave.leave_type_master ltm ON elb.leave_type_id = ltm.leave_type_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
WHERE emp.employee_status = 'ACTIVE'
    AND elb.balance_status = 'ACTIVE';

-- Leave Application Analytics View
CREATE OR REPLACE VIEW nexus_leave.v_leave_application_analytics AS
SELECT
    la.company_id,
    la.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    ltm.leave_type_name,
    ltm.leave_category,
    la.application_number,
    la.application_date,
    la.leave_start_date,
    la.leave_end_date,
    la.leave_duration_days,
    la.application_status,

    -- Approval Information
    CASE
        WHEN la.application_status = 'APPROVED' THEN la.final_approved_by
        WHEN la.application_status = 'REJECTED' THEN la.rejected_by
        ELSE NULL
    END AS decision_maker_id,

    CASE
        WHEN la.application_status = 'APPROVED' THEN la.final_approved_at
        WHEN la.application_status = 'REJECTED' THEN la.rejected_at
        ELSE NULL
    END AS decision_date,

    -- Processing Time Analysis
    CASE
        WHEN la.application_status IN ('APPROVED', 'REJECTED')
        THEN EXTRACT(DAY FROM (
            COALESCE(la.final_approved_at, la.rejected_at) -
            la.created_at
        ))
        ELSE NULL
    END AS processing_days,

    -- Leave Period Analysis
    EXTRACT(MONTH FROM la.leave_start_date) AS leave_month,
    EXTRACT(YEAR FROM la.leave_start_date) AS leave_year,
    EXTRACT(DOW FROM la.leave_start_date) AS leave_start_day_of_week,

    -- Financial Impact
    la.is_loss_of_pay,
    la.lop_days,
    la.payroll_impact_amount,

    -- Approval Workflow Status
    la.current_approval_level,
    la.total_approval_levels,
    ROUND(
        (la.current_approval_level::DECIMAL / la.total_approval_levels) * 100, 2
    ) AS approval_progress_percentage

FROM nexus_leave.leave_applications la
    JOIN nexus_foundation.employee_master emp ON la.employee_id = emp.employee_id
    JOIN nexus_leave.leave_type_master ltm ON la.leave_type_id = ltm.leave_type_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id;

-- Monthly Leave Statistics View
CREATE OR REPLACE VIEW nexus_leave.v_monthly_leave_statistics AS
SELECT
    company_id,
    DATE_TRUNC('month', leave_start_date) AS leave_month,
    leave_type_id,
    ltm.leave_type_name,
    ltm.leave_category,

    -- Application Statistics
    COUNT(*) AS total_applications,
    COUNT(CASE WHEN application_status = 'APPROVED' THEN 1 END) AS approved_applications,
    COUNT(CASE WHEN application_status = 'REJECTED' THEN 1 END) AS rejected_applications,
    COUNT(CASE WHEN application_status = 'PENDING_APPROVAL' THEN 1 END) AS pending_applications,

    -- Duration Statistics
    SUM(leave_duration_days) AS total_leave_days,
    AVG(leave_duration_days) AS average_leave_duration,
    MAX(leave_duration_days) AS max_leave_duration,
    MIN(leave_duration_days) AS min_leave_duration,

    -- Approval Rate
    ROUND(
        (COUNT(CASE WHEN application_status = 'APPROVED' THEN 1 END)::DECIMAL /
         NULLIF(COUNT(CASE WHEN application_status IN ('APPROVED', 'REJECTED') THEN 1 END), 0)) * 100, 2
    ) AS approval_rate_percentage,

    -- Processing Time
    AVG(
        CASE
            WHEN application_status IN ('APPROVED', 'REJECTED')
            THEN EXTRACT(DAY FROM (
                COALESCE(final_approved_at, rejected_at) - created_at
            ))
            ELSE NULL
        END
    ) AS average_processing_days

FROM nexus_leave.leave_applications la
    JOIN nexus_leave.leave_type_master ltm ON la.leave_type_id = ltm.leave_type_id
WHERE leave_start_date >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY company_id, DATE_TRUNC('month', leave_start_date), leave_type_id, ltm.leave_type_name, ltm.leave_category
ORDER BY leave_month DESC, leave_type_name;

-- =====================================================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================================================

-- Enable RLS on all leave tables
ALTER TABLE nexus_leave.leave_type_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.employee_leave_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.employee_leave_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.leave_balance_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.leave_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.leave_approval_workflow ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.leave_encashment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.compensatory_off_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_leave.comp_off_utilization ENABLE ROW LEVEL SECURITY;

-- Company-based access policy for all leave tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_leave'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE POLICY company_access_policy ON nexus_leave.%I
            FOR ALL TO nexus_app_role
            USING (company_id = current_setting(''app.current_company_id'')::BIGINT)
        ', table_name);
    END LOOP;
END $$;

-- Employee-specific data access policy for sensitive tables
CREATE POLICY employee_data_access_policy ON nexus_leave.leave_applications
    FOR ALL TO nexus_app_role
    USING (
        company_id = current_setting('app.current_company_id')::BIGINT AND
        (
            employee_id = current_setting('app.current_user_id')::BIGINT OR
            -- Allow HR and managers to access based on role
            EXISTS (
                SELECT 1 FROM nexus_foundation.user_master um
                WHERE um.user_id = current_setting('app.current_user_id')::BIGINT
                AND um.user_role IN ('HR_ADMIN', 'HR_MANAGER', 'ADMIN')
            )
        )
    );

-- =====================================================================================
-- TRIGGERS FOR BUSINESS LOGIC AND AUDIT
-- =====================================================================================

-- Trigger for updating last_modified_at
CREATE OR REPLACE FUNCTION nexus_leave.update_last_modified()
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
        WHERE schemaname = 'nexus_leave'
        AND tablename NOT IN ('leave_balance_transactions')
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_last_modified_trigger
            BEFORE UPDATE ON nexus_leave.%I
            FOR EACH ROW EXECUTE FUNCTION nexus_leave.update_last_modified()
        ', table_name);
    END LOOP;
END $$;

-- Leave application number generation trigger
CREATE OR REPLACE FUNCTION nexus_leave.generate_application_number()
RETURNS TRIGGER AS $$
DECLARE
    v_sequence_number INTEGER;
    v_year_suffix VARCHAR(4);
    v_company_code VARCHAR(10);
BEGIN
    -- Get company code
    SELECT company_code INTO v_company_code
    FROM nexus_foundation.company_master
    WHERE company_id = NEW.company_id;

    -- Get year suffix
    v_year_suffix := RIGHT(EXTRACT(YEAR FROM CURRENT_DATE)::TEXT, 2);

    -- Get next sequence number for this company and year
    SELECT COALESCE(MAX(
        CASE
            WHEN application_number ~ ('^' || v_company_code || '/LEV/' || v_year_suffix || '/[0-9]+$')
            THEN SUBSTRING(application_number FROM '[0-9]+$')::INTEGER
            ELSE 0
        END
    ), 0) + 1
    INTO v_sequence_number
    FROM nexus_leave.leave_applications
    WHERE company_id = NEW.company_id
    AND EXTRACT(YEAR FROM application_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate application number: COMPCODE/LEV/YY/NNNN
    NEW.application_number := v_company_code || '/LEV/' || v_year_suffix || '/' ||
                             LPAD(v_sequence_number::TEXT, 4, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply application number generation trigger
CREATE TRIGGER generate_application_number_trigger
    BEFORE INSERT ON nexus_leave.leave_applications
    FOR EACH ROW
    WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
    EXECUTE FUNCTION nexus_leave.generate_application_number();

-- Leave balance update trigger
CREATE OR REPLACE FUNCTION nexus_leave.update_leave_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_balance_record nexus_leave.employee_leave_balance%ROWTYPE;
BEGIN
    -- Get current balance
    SELECT * INTO v_balance_record
    FROM nexus_leave.employee_leave_balance
    WHERE company_id = NEW.company_id
    AND employee_id = NEW.employee_id
    AND leave_type_id = NEW.leave_type_id
    AND balance_year = EXTRACT(YEAR FROM NEW.leave_start_date);

    -- Update balance based on application status
    IF NEW.application_status = 'APPROVED' AND
       (OLD.application_status IS NULL OR OLD.application_status != 'APPROVED') THEN

        -- Consume leave balance
        UPDATE nexus_leave.employee_leave_balance
        SET consumed_balance = consumed_balance + NEW.balance_consumed,
            last_modified_at = CURRENT_TIMESTAMP
        WHERE balance_id = v_balance_record.balance_id;

        -- Create balance transaction
        INSERT INTO nexus_leave.leave_balance_transactions (
            company_id, balance_id, employee_id, leave_type_id,
            transaction_type, transaction_amount, transaction_date,
            balance_before_transaction, balance_after_transaction,
            reference_type, reference_id, reference_description
        ) VALUES (
            NEW.company_id, v_balance_record.balance_id, NEW.employee_id, NEW.leave_type_id,
            'CONSUMPTION', NEW.balance_consumed, NEW.leave_start_date,
            v_balance_record.remaining_balance,
            v_balance_record.remaining_balance - NEW.balance_consumed,
            'LEAVE_APPLICATION', NEW.application_id,
            'Leave consumed for application: ' || NEW.application_number
        );

    ELSIF NEW.application_status IN ('REJECTED', 'CANCELLED') AND
          OLD.application_status = 'APPROVED' THEN

        -- Restore leave balance
        UPDATE nexus_leave.employee_leave_balance
        SET consumed_balance = consumed_balance - NEW.balance_consumed,
            last_modified_at = CURRENT_TIMESTAMP
        WHERE balance_id = v_balance_record.balance_id;

        -- Create reversal transaction
        INSERT INTO nexus_leave.leave_balance_transactions (
            company_id, balance_id, employee_id, leave_type_id,
            transaction_type, transaction_amount, transaction_date,
            balance_before_transaction, balance_after_transaction,
            reference_type, reference_id, reference_description
        ) VALUES (
            NEW.company_id, v_balance_record.balance_id, NEW.employee_id, NEW.leave_type_id,
            'REVERSAL', NEW.balance_consumed, CURRENT_DATE,
            v_balance_record.remaining_balance,
            v_balance_record.remaining_balance + NEW.balance_consumed,
            'LEAVE_APPLICATION', NEW.application_id,
            'Leave balance restored due to ' || NEW.application_status || ': ' || NEW.application_number
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply leave balance update trigger
CREATE TRIGGER update_leave_balance_trigger
    AFTER UPDATE ON nexus_leave.leave_applications
    FOR EACH ROW EXECUTE FUNCTION nexus_leave.update_leave_balance();

-- =====================================================================================
-- STORED PROCEDURES FOR LEAVE PROCESSING
-- =====================================================================================

-- Generate annual leave allocation
CREATE OR REPLACE FUNCTION nexus_leave.generate_annual_leave_allocation(
    p_company_id BIGINT,
    p_allocation_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_employee_id BIGINT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_employee_record RECORD;
    v_policy_record RECORD;
    v_carry_forward_days DECIMAL(5,2);
    v_processed_count INTEGER := 0;
BEGIN
    -- Process employees
    FOR v_employee_record IN
        SELECT employee_id, employee_code, joining_date
        FROM nexus_foundation.employee_master
        WHERE company_id = p_company_id
        AND employee_status = 'ACTIVE'
        AND (p_employee_id IS NULL OR employee_id = p_employee_id)
    LOOP
        -- Process each leave type policy for the employee
        FOR v_policy_record IN
            SELECT
                elp.leave_type_id,
                ltm.leave_type_code,
                ltm.leave_type_name,
                COALESCE(elp.custom_annual_allocation, ltm.annual_allocation_days) as annual_allocation,
                COALESCE(elp.custom_carry_forward_days, ltm.max_carry_forward_days) as max_carry_forward,
                ltm.is_carry_forward_allowed,
                ltm.carry_forward_expiry_months
            FROM nexus_leave.employee_leave_policy elp
            JOIN nexus_leave.leave_type_master ltm ON elp.leave_type_id = ltm.leave_type_id
            WHERE elp.company_id = p_company_id
            AND elp.policy_status = 'ACTIVE'
            AND (
                (elp.assignment_type = 'EMPLOYEE' AND elp.employee_id = v_employee_record.employee_id) OR
                (elp.assignment_type = 'ALL_EMPLOYEES') OR
                (elp.assignment_type = 'DEPARTMENT' AND elp.department_id IN (
                    SELECT department_id FROM nexus_foundation.employee_master
                    WHERE employee_id = v_employee_record.employee_id
                ))
            )
        LOOP
            -- Calculate carry forward balance from previous year
            v_carry_forward_days := 0;
            IF v_policy_record.is_carry_forward_allowed THEN
                SELECT LEAST(remaining_balance, v_policy_record.max_carry_forward)
                INTO v_carry_forward_days
                FROM nexus_leave.employee_leave_balance
                WHERE company_id = p_company_id
                AND employee_id = v_employee_record.employee_id
                AND leave_type_id = v_policy_record.leave_type_id
                AND balance_year = p_allocation_year - 1
                AND balance_status = 'ACTIVE';

                v_carry_forward_days := COALESCE(v_carry_forward_days, 0);
            END IF;

            -- Insert or update annual allocation
            INSERT INTO nexus_leave.employee_leave_balance (
                company_id,
                employee_id,
                leave_type_id,
                balance_year,
                balance_period_start_date,
                balance_period_end_date,
                annual_allocation,
                carry_forward_balance,
                carry_forward_expiry_date,
                balance_status
            )
            VALUES (
                p_company_id,
                v_employee_record.employee_id,
                v_policy_record.leave_type_id,
                p_allocation_year,
                DATE(p_allocation_year || '-01-01'),
                DATE(p_allocation_year || '-12-31'),
                v_policy_record.annual_allocation,
                v_carry_forward_days,
                CASE
                    WHEN v_carry_forward_days > 0 AND v_policy_record.carry_forward_expiry_months > 0
                    THEN DATE(p_allocation_year || '-01-01') +
                         (v_policy_record.carry_forward_expiry_months || ' months')::INTERVAL
                    ELSE NULL
                END,
                'ACTIVE'
            )
            ON CONFLICT (company_id, employee_id, leave_type_id, balance_year)
            DO UPDATE SET
                annual_allocation = EXCLUDED.annual_allocation,
                carry_forward_balance = EXCLUDED.carry_forward_balance,
                carry_forward_expiry_date = EXCLUDED.carry_forward_expiry_date,
                last_modified_at = CURRENT_TIMESTAMP;

            -- Create allocation transaction
            INSERT INTO nexus_leave.leave_balance_transactions (
                company_id,
                balance_id,
                employee_id,
                leave_type_id,
                transaction_type,
                transaction_amount,
                transaction_date,
                balance_before_transaction,
                balance_after_transaction,
                reference_type,
                reference_description
            )
            SELECT
                p_company_id,
                elb.balance_id,
                v_employee_record.employee_id,
                v_policy_record.leave_type_id,
                'ALLOCATION',
                v_policy_record.annual_allocation,
                CURRENT_DATE,
                0,
                v_policy_record.annual_allocation,
                'ANNUAL_ALLOCATION',
                'Annual leave allocation for year ' || p_allocation_year
            FROM nexus_leave.employee_leave_balance elb
            WHERE elb.company_id = p_company_id
            AND elb.employee_id = v_employee_record.employee_id
            AND elb.leave_type_id = v_policy_record.leave_type_id
            AND elb.balance_year = p_allocation_year;

            v_processed_count := v_processed_count + 1;
        END LOOP;
    END LOOP;

    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- Process leave application approval
CREATE OR REPLACE FUNCTION nexus_leave.process_leave_approval(
    p_application_id BIGINT,
    p_approver_employee_id BIGINT,
    p_approval_action VARCHAR(20), -- APPROVE, REJECT, DELEGATE
    p_comments TEXT DEFAULT NULL,
    p_delegate_to BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_application_record nexus_leave.leave_applications%ROWTYPE;
    v_approval_record nexus_leave.leave_approval_workflow%ROWTYPE;
    v_next_level INTEGER;
    v_result JSONB;
BEGIN
    -- Get application details
    SELECT * INTO v_application_record
    FROM nexus_leave.leave_applications
    WHERE application_id = p_application_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Leave application not found'
        );
    END IF;

    -- Get current approval level
    SELECT * INTO v_approval_record
    FROM nexus_leave.leave_approval_workflow
    WHERE application_id = p_application_id
    AND approver_employee_id = p_approver_employee_id
    AND approval_level = v_application_record.current_approval_level
    AND approval_status = 'PENDING';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'No pending approval found for this user'
        );
    END IF;

    -- Process the approval action
    CASE p_approval_action
        WHEN 'APPROVE' THEN
            -- Update approval record
            UPDATE nexus_leave.leave_approval_workflow
            SET approval_status = 'APPROVED',
                approval_date = CURRENT_TIMESTAMP,
                approval_comments = p_comments
            WHERE approval_id = v_approval_record.approval_id;

            -- Check if this is the final approval level
            IF v_application_record.current_approval_level >= v_application_record.total_approval_levels THEN
                -- Final approval - update application status
                UPDATE nexus_leave.leave_applications
                SET application_status = 'APPROVED',
                    final_approved_by = p_approver_employee_id,
                    final_approved_at = CURRENT_TIMESTAMP,
                    final_approval_comments = p_comments
                WHERE application_id = p_application_id;

                v_result := jsonb_build_object(
                    'success', true,
                    'message', 'Leave application finally approved',
                    'application_status', 'APPROVED'
                );
            ELSE
                -- Move to next approval level
                v_next_level := v_application_record.current_approval_level + 1;

                UPDATE nexus_leave.leave_applications
                SET current_approval_level = v_next_level
                WHERE application_id = p_application_id;

                v_result := jsonb_build_object(
                    'success', true,
                    'message', 'Approval completed, moved to next level',
                    'current_approval_level', v_next_level,
                    'application_status', 'PENDING_APPROVAL'
                );
            END IF;

        WHEN 'REJECT' THEN
            -- Update approval record
            UPDATE nexus_leave.leave_approval_workflow
            SET approval_status = 'REJECTED',
                approval_date = CURRENT_TIMESTAMP,
                approval_comments = p_comments
            WHERE approval_id = v_approval_record.approval_id;

            -- Update application status
            UPDATE nexus_leave.leave_applications
            SET application_status = 'REJECTED',
                rejected_by = p_approver_employee_id,
                rejected_at = CURRENT_TIMESTAMP,
                rejection_reason = p_comments
            WHERE application_id = p_application_id;

            v_result := jsonb_build_object(
                'success', true,
                'message', 'Leave application rejected',
                'application_status', 'REJECTED'
            );

        WHEN 'DELEGATE' THEN
            IF p_delegate_to IS NULL THEN
                RETURN jsonb_build_object(
                    'success', false,
                    'error', 'Delegate target employee ID is required'
                );
            END IF;

            -- Update current approval record
            UPDATE nexus_leave.leave_approval_workflow
            SET approval_status = 'DELEGATED',
                approval_date = CURRENT_TIMESTAMP,
                approval_comments = p_comments,
                delegated_to = p_delegate_to,
                delegation_date = CURRENT_TIMESTAMP,
                delegation_reason = p_comments
            WHERE approval_id = v_approval_record.approval_id;

            -- Create new approval record for delegate
            INSERT INTO nexus_leave.leave_approval_workflow (
                company_id, application_id, approval_level,
                approver_employee_id, approver_role, approval_status
            ) VALUES (
                v_application_record.company_id,
                p_application_id,
                v_application_record.current_approval_level,
                p_delegate_to,
                'DELEGATED_APPROVER',
                'PENDING'
            );

            v_result := jsonb_build_object(
                'success', true,
                'message', 'Approval delegated successfully',
                'delegated_to', p_delegate_to,
                'application_status', 'PENDING_APPROVAL'
            );

        ELSE
            RETURN jsonb_build_object(
                'success', false,
                'error', 'Invalid approval action: ' || p_approval_action
            );
    END CASE;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA nexus_leave IS 'Comprehensive leave management system with multi-level approvals, balance tracking, encashment, and compensatory off management';

COMMENT ON TABLE nexus_leave.leave_type_master IS 'Master configuration for different types of leaves with rules, allocations, and business logic';
COMMENT ON TABLE nexus_leave.employee_leave_policy IS 'Assignment of leave policies to employees, departments, or designations with customization options';
COMMENT ON TABLE nexus_leave.employee_leave_balance IS 'Current leave balances for employees with carry-forward, allocation, and consumption tracking';
COMMENT ON TABLE nexus_leave.leave_balance_transactions IS 'Comprehensive audit trail for all leave balance changes with reference tracking';
COMMENT ON TABLE nexus_leave.leave_applications IS 'Core leave application records with approval workflow and comprehensive tracking';
COMMENT ON TABLE nexus_leave.leave_approval_workflow IS 'Multi-level approval system with delegation, escalation, and parallel approval support';
COMMENT ON TABLE nexus_leave.leave_encashment_requests IS 'Leave encashment requests with financial calculations and payment tracking';
COMMENT ON TABLE nexus_leave.compensatory_off_records IS 'Compensatory off earned from holiday/weekend work with expiry tracking';
COMMENT ON TABLE nexus_leave.comp_off_utilization IS 'Tracking of compensatory off utilization with session-level details';

-- =====================================================================================
-- SCHEMA COMPLETION
-- =====================================================================================

-- Grant permissions to application role
GRANT USAGE ON SCHEMA nexus_leave TO nexus_app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nexus_leave TO nexus_app_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA nexus_leave TO nexus_app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nexus_leave TO nexus_app_role;

-- Grant read-only access to reporting role
GRANT USAGE ON SCHEMA nexus_leave TO nexus_readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_leave TO nexus_readonly_role;
GRANT EXECUTE ON FUNCTION nexus_leave.generate_annual_leave_allocation TO nexus_readonly_role;

RAISE NOTICE 'NEXUS Leave Management Schema created successfully with:
- 9 core tables with comprehensive leave lifecycle management
- Multi-level approval workflow with delegation and escalation
- Advanced leave balance tracking with carry-forward and encashment
- Compensatory off management with expiry and utilization tracking
- Leave policy configuration with flexible assignment rules
- Comprehensive analytics views for reporting and insights
- Row Level Security and audit trails for data protection
- Stored procedures for automated leave processing and approvals
- GraphQL-optimized structure for modern frontend integration';

-- End of 03_nexus_leave_schema.sql