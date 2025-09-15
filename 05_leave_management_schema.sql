-- =====================================================================================
-- NEXUS HRMS - Leave Management Module
-- PostgreSQL Schema for Leave Types, Policies, Applications, and Balance Management
-- =====================================================================================
-- Migration from: MongoDB MEAN Stack to PostgreSQL NEXUS Architecture
-- Phase: 5 - Leave Management Core Tables
-- Dependencies: Employee Master, Attendance Management, Organizational Structure
-- =====================================================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- SECTION 1: ENUMS AND CUSTOM TYPES
-- =====================================================================================

-- Leave category types
CREATE TYPE leave_category_type AS ENUM (
    'earned_leave',      -- EL - Earned/Annual Leave
    'casual_leave',      -- CL - Casual Leave
    'sick_leave',        -- SL - Sick Leave
    'maternity_leave',   -- ML - Maternity Leave
    'paternity_leave',   -- PL - Paternity Leave
    'comp_off',          -- CO - Compensatory Off
    'loss_of_pay',       -- LOP - Loss of Pay
    'bereavement_leave', -- BL - Bereavement Leave
    'marriage_leave',    -- MAL - Marriage Leave
    'study_leave',       -- STL - Study Leave
    'sabbatical',        -- SAB - Sabbatical Leave
    'special_leave'      -- SPL - Special Leave
);

-- Leave application status
CREATE TYPE leave_application_status AS ENUM (
    'draft',
    'submitted',
    'pending_approval',
    'approved',
    'rejected',
    'cancelled',
    'withdrawn'
);

-- Leave accrual frequency
CREATE TYPE accrual_frequency_type AS ENUM (
    'monthly',
    'quarterly',
    'half_yearly',
    'yearly',
    'per_working_day'
);

-- Leave unit types
CREATE TYPE leave_unit_type AS ENUM (
    'days',
    'hours',
    'half_days'
);

-- Carry forward action
CREATE TYPE carry_forward_action AS ENUM (
    'carry_forward',
    'lapse',
    'encash'
);

-- Leave balance adjustment type
CREATE TYPE balance_adjustment_type AS ENUM (
    'credit',
    'debit',
    'opening_balance',
    'carry_forward',
    'encashment',
    'lapse',
    'manual_adjustment'
);

-- =====================================================================================
-- SECTION 2: LEAVE TYPES AND CATEGORIES
-- =====================================================================================

-- Master leave categories (system-defined)
CREATE TABLE leave_category_master (
    leave_category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(10) NOT NULL,
    category_type leave_category_type NOT NULL,
    description TEXT,
    is_paid BOOLEAN DEFAULT true,
    is_system_defined BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 1,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(category_code)
);

-- Leave types (company-specific implementations of categories)
CREATE TABLE leave_type_master (
    leave_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_category_id UUID NOT NULL REFERENCES leave_category_master(leave_category_id),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Basic information
    leave_type_name VARCHAR(100) NOT NULL,
    leave_type_code VARCHAR(20) NOT NULL,
    description TEXT,

    -- Configuration
    leave_unit_type leave_unit_type DEFAULT 'days',
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_to DATE,

    -- Display and ordering
    display_order INTEGER DEFAULT 1,
    color_code VARCHAR(7), -- Hex color for UI display

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, leave_type_code),
    UNIQUE(company_master_id, leave_type_name)
);

-- =====================================================================================
-- SECTION 3: LEAVE POLICIES AND RULES
-- =====================================================================================

-- Core leave policies
CREATE TABLE leave_policy_master (
    leave_policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_type_id UUID NOT NULL REFERENCES leave_type_master(leave_type_id),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Policy identification
    policy_name VARCHAR(100) NOT NULL,
    policy_code VARCHAR(20) NOT NULL,
    description TEXT,

    -- Accrual configuration
    annual_entitlement DECIMAL(8,2) DEFAULT 0, -- Annual leave entitlement
    accrual_frequency accrual_frequency_type DEFAULT 'monthly',
    accrual_amount DECIMAL(8,2) DEFAULT 0, -- Amount accrued per frequency
    accrual_starts_from DATE, -- When accrual begins

    -- Probation rules
    applicable_during_probation BOOLEAN DEFAULT false,
    probation_accrual_rate DECIMAL(5,2) DEFAULT 100.00, -- Percentage of normal accrual

    -- Usage rules
    minimum_days_per_application DECIMAL(4,2) DEFAULT 0.5,
    maximum_days_per_application DECIMAL(8,2) DEFAULT 999,
    maximum_consecutive_days DECIMAL(8,2) DEFAULT 999,

    -- Advance/negative balance
    allow_negative_balance BOOLEAN DEFAULT false,
    maximum_negative_balance DECIMAL(8,2) DEFAULT 0,

    -- Documentation requirements
    attachment_required_after_days INTEGER DEFAULT 0,
    medical_certificate_required_after_days INTEGER DEFAULT 0,

    -- Advance notice requirements
    minimum_advance_notice_days INTEGER DEFAULT 1,
    maximum_advance_application_days INTEGER DEFAULT 365,

    -- Carry forward rules
    allow_carry_forward BOOLEAN DEFAULT true,
    maximum_carry_forward DECIMAL(8,2) DEFAULT 0,
    carry_forward_expiry_months INTEGER DEFAULT 12,

    -- Encashment rules
    allow_encashment BOOLEAN DEFAULT false,
    minimum_balance_for_encashment DECIMAL(8,2) DEFAULT 0,
    maximum_encashment_days DECIMAL(8,2) DEFAULT 0,
    encashment_rate DECIMAL(5,2) DEFAULT 100.00, -- Percentage of daily salary

    -- Weekend and holiday handling
    include_weekends BOOLEAN DEFAULT false,
    include_holidays BOOLEAN DEFAULT false,

    -- Pro-rata calculation for joiners/leavers
    prorate_on_joining BOOLEAN DEFAULT true,
    prorate_on_leaving BOOLEAN DEFAULT true,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, policy_code)
);

-- Leave policy applicability rules
CREATE TABLE leave_policy_applicability (
    leave_policy_applicability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_policy_id UUID NOT NULL REFERENCES leave_policy_master(leave_policy_id),

    -- Applicability criteria
    applies_to_all BOOLEAN DEFAULT true,

    -- Organizational filters
    division_master_id UUID REFERENCES division_master(division_master_id),
    department_master_id UUID REFERENCES department_master(department_master_id),
    designation_master_id UUID REFERENCES designation_master(designation_master_id),
    employee_category_id UUID REFERENCES employee_category(employee_category_id),
    employee_group_id UUID REFERENCES employee_group(employee_group_id),
    employee_grade_id UUID REFERENCES employee_grade(employee_grade_id),
    location_master_id UUID REFERENCES location_master(location_master_id),

    -- Specific employee assignment
    employee_master_id UUID REFERENCES employee_master(employee_master_id),

    -- Include/exclude flag
    is_inclusion BOOLEAN DEFAULT true,

    -- Priority for conflicting rules
    priority_order INTEGER DEFAULT 1,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Leave earned calendar (for earned leave calculations)
CREATE TABLE leave_earned_calendar (
    leave_earned_calendar_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_policy_id UUID NOT NULL REFERENCES leave_policy_master(leave_policy_id),
    calendar_year INTEGER NOT NULL,

    -- Earned leave calculation periods
    el_calculation_start_date DATE NOT NULL,
    el_calculation_end_date DATE NOT NULL,

    -- Working days criteria
    minimum_working_days_for_el INTEGER DEFAULT 240,
    working_days_calculation_method VARCHAR(50) DEFAULT 'attendance_based', -- attendance_based, calendar_based

    -- Accrual rates by service period
    accrual_rate_0_to_5_years DECIMAL(4,2) DEFAULT 1.0, -- Days per month
    accrual_rate_5_to_10_years DECIMAL(4,2) DEFAULT 1.0,
    accrual_rate_above_10_years DECIMAL(4,2) DEFAULT 1.0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(leave_policy_id, calendar_year)
);

-- =====================================================================================
-- SECTION 4: LEAVE BALANCE MANAGEMENT
-- =====================================================================================

-- Employee leave entitlements (annual allocations)
CREATE TABLE employee_leave_entitlement (
    employee_leave_entitlement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    leave_policy_id UUID NOT NULL REFERENCES leave_policy_master(leave_policy_id),
    leave_type_id UUID NOT NULL REFERENCES leave_type_master(leave_type_id),

    -- Entitlement period
    entitlement_year INTEGER NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,

    -- Entitlement amounts
    annual_entitlement DECIMAL(8,2) NOT NULL DEFAULT 0,
    opening_balance DECIMAL(8,2) DEFAULT 0,
    accrued_balance DECIMAL(8,2) DEFAULT 0,
    used_balance DECIMAL(8,2) DEFAULT 0,
    available_balance DECIMAL(8,2) DEFAULT 0,
    carry_forward_balance DECIMAL(8,2) DEFAULT 0,

    -- Calculation flags
    is_calculated BOOLEAN DEFAULT false,
    calculation_date TIMESTAMP,
    last_accrual_date DATE,

    -- Manual override
    is_manually_overridden BOOLEAN DEFAULT false,
    override_reason TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, leave_policy_id, entitlement_year)
);

-- Leave balance adjustments (all transactions)
CREATE TABLE leave_balance_adjustment (
    leave_balance_adjustment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_leave_entitlement_id UUID NOT NULL REFERENCES employee_leave_entitlement(employee_leave_entitlement_id),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    leave_type_id UUID NOT NULL REFERENCES leave_type_master(leave_type_id),

    -- Adjustment details
    adjustment_date DATE NOT NULL,
    adjustment_type balance_adjustment_type NOT NULL,
    adjustment_amount DECIMAL(8,2) NOT NULL,
    balance_before_adjustment DECIMAL(8,2) NOT NULL,
    balance_after_adjustment DECIMAL(8,2) NOT NULL,

    -- Reference information
    leave_application_id UUID, -- References leave_application table (created later)
    reference_id UUID, -- Generic reference for other transactions
    reference_type VARCHAR(50), -- Type of reference (application, encashment, etc.)

    -- Description and reason
    adjustment_reason TEXT,
    description TEXT,

    -- Processing information
    is_system_generated BOOLEAN DEFAULT false,
    processing_batch_id UUID,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 5: LEAVE APPLICATION AND APPROVAL WORKFLOW
-- =====================================================================================

-- Leave applications
CREATE TABLE leave_application (
    leave_application_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    leave_type_id UUID NOT NULL REFERENCES leave_type_master(leave_type_id),
    leave_policy_id UUID NOT NULL REFERENCES leave_policy_master(leave_policy_id),

    -- Application identification
    application_number VARCHAR(50) NOT NULL,
    application_date DATE NOT NULL,

    -- Leave period
    leave_from_date DATE NOT NULL,
    leave_to_date DATE NOT NULL,
    leave_days DECIMAL(4,2) NOT NULL,
    leave_unit leave_unit_type DEFAULT 'days',

    -- Application details
    reason TEXT NOT NULL,
    contact_address TEXT,
    contact_phone VARCHAR(20),
    emergency_contact VARCHAR(100),

    -- Half day details (if applicable)
    is_half_day BOOLEAN DEFAULT false,
    half_day_session VARCHAR(20), -- morning, afternoon

    -- Status and workflow
    application_status leave_application_status DEFAULT 'draft',
    workflow_status VARCHAR(50), -- For complex approval workflows
    current_approver_id UUID REFERENCES user_master(user_master_id),

    -- Dates for tracking
    submitted_date TIMESTAMP,
    approved_date TIMESTAMP,
    rejected_date TIMESTAMP,

    -- Comments and feedback
    approver_comments TEXT,
    hr_comments TEXT,

    -- Balance impact
    balance_before_application DECIMAL(8,2),
    balance_after_application DECIMAL(8,2),

    -- Integration flags
    is_processed_in_attendance BOOLEAN DEFAULT false,
    attendance_integration_date TIMESTAMP,

    -- Attachment support
    has_attachments BOOLEAN DEFAULT false,
    attachment_count INTEGER DEFAULT 0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(application_number)
);

-- Leave application approval workflow
CREATE TABLE leave_application_approval (
    leave_application_approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_application_id UUID NOT NULL REFERENCES leave_application(leave_application_id),

    -- Approver information
    approver_id UUID NOT NULL REFERENCES user_master(user_master_id),
    approval_level INTEGER NOT NULL DEFAULT 1,
    approval_order INTEGER NOT NULL DEFAULT 1,

    -- Approval details
    approval_status VARCHAR(20) NOT NULL, -- pending, approved, rejected, delegated
    approval_date TIMESTAMP,
    comments TEXT,

    -- Delegation support
    delegated_to_id UUID REFERENCES user_master(user_master_id),
    delegation_reason TEXT,

    -- System tracking
    is_current_approver BOOLEAN DEFAULT false,
    notification_sent BOOLEAN DEFAULT false,
    reminder_count INTEGER DEFAULT 0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Leave application attachments
CREATE TABLE leave_application_attachment (
    leave_application_attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_application_id UUID NOT NULL REFERENCES leave_application(leave_application_id),

    -- File information
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    file_type VARCHAR(100),
    mime_type VARCHAR(100),

    -- Attachment details
    attachment_type VARCHAR(50), -- medical_certificate, supporting_document, etc.
    description TEXT,

    -- Verification
    is_verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES user_master(user_master_id),
    verification_date TIMESTAMP,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 6: COMPENSATORY OFF (COMP-OFF) MANAGEMENT
-- =====================================================================================

-- Comp-off credits (earned from overtime/holiday work)
CREATE TABLE comp_off_credit (
    comp_off_credit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),

    -- Source of comp-off
    source_date DATE NOT NULL,
    source_type VARCHAR(50) NOT NULL, -- overtime, holiday_work, weekend_work
    source_reference_id UUID, -- Reference to attendance_entry or overtime_request

    -- Credit details
    credit_days DECIMAL(4,2) NOT NULL,
    credit_hours INTERVAL, -- For hour-based tracking
    reason TEXT,

    -- Validity
    credited_date DATE NOT NULL,
    expiry_date DATE NOT NULL,

    -- Usage tracking
    used_days DECIMAL(4,2) DEFAULT 0,
    available_days DECIMAL(4,2) NOT NULL,
    is_expired BOOLEAN DEFAULT false,

    -- Approval
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,
    approval_status VARCHAR(20) DEFAULT 'pending',

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Comp-off usage (when comp-off is used for leave)
CREATE TABLE comp_off_usage (
    comp_off_usage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comp_off_credit_id UUID NOT NULL REFERENCES comp_off_credit(comp_off_credit_id),
    leave_application_id UUID REFERENCES leave_application(leave_application_id),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),

    -- Usage details
    usage_date DATE NOT NULL,
    used_days DECIMAL(4,2) NOT NULL,
    remaining_days DECIMAL(4,2) NOT NULL,

    -- Reference
    usage_reason TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 7: LEAVE ENCASHMENT
-- =====================================================================================

-- Leave encashment requests
CREATE TABLE leave_encashment (
    leave_encashment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    leave_type_id UUID NOT NULL REFERENCES leave_type_master(leave_type_id),

    -- Encashment details
    encashment_number VARCHAR(50) NOT NULL,
    encashment_date DATE NOT NULL,
    encashment_days DECIMAL(8,2) NOT NULL,
    daily_wage DECIMAL(12,2) NOT NULL,
    encashment_amount DECIMAL(12,2) NOT NULL,

    -- Period and balance
    encashment_year INTEGER NOT NULL,
    available_balance DECIMAL(8,2) NOT NULL,
    balance_after_encashment DECIMAL(8,2) NOT NULL,

    -- Processing
    approval_status VARCHAR(20) DEFAULT 'pending',
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,

    -- Payroll integration
    is_processed_in_payroll BOOLEAN DEFAULT false,
    payroll_period VARCHAR(20),
    payroll_integration_date TIMESTAMP,

    -- Comments
    employee_comments TEXT,
    approver_comments TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(encashment_number)
);

-- =====================================================================================
-- SECTION 8: INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Leave type and policy indexes
CREATE INDEX idx_leave_type_master_company ON leave_type_master(company_master_id);
CREATE INDEX idx_leave_type_master_category ON leave_type_master(leave_category_id);
CREATE INDEX idx_leave_policy_master_company ON leave_policy_master(company_master_id);
CREATE INDEX idx_leave_policy_master_type ON leave_policy_master(leave_type_id);
CREATE INDEX idx_leave_policy_applicability_policy ON leave_policy_applicability(leave_policy_id);

-- Leave entitlement and balance indexes
CREATE INDEX idx_employee_leave_entitlement_employee ON employee_leave_entitlement(employee_master_id);
CREATE INDEX idx_employee_leave_entitlement_year ON employee_leave_entitlement(entitlement_year);
CREATE INDEX idx_employee_leave_entitlement_policy ON employee_leave_entitlement(leave_policy_id);
CREATE INDEX idx_leave_balance_adjustment_entitlement ON leave_balance_adjustment(employee_leave_entitlement_id);
CREATE INDEX idx_leave_balance_adjustment_date ON leave_balance_adjustment(adjustment_date);
CREATE INDEX idx_leave_balance_adjustment_type ON leave_balance_adjustment(adjustment_type);

-- Leave application indexes
CREATE INDEX idx_leave_application_employee ON leave_application(employee_master_id);
CREATE INDEX idx_leave_application_type ON leave_application(leave_type_id);
CREATE INDEX idx_leave_application_status ON leave_application(application_status);
CREATE INDEX idx_leave_application_dates ON leave_application(leave_from_date, leave_to_date);
CREATE INDEX idx_leave_application_approval_application ON leave_application_approval(leave_application_id);
CREATE INDEX idx_leave_application_approval_approver ON leave_application_approval(approver_id);

-- Comp-off indexes
CREATE INDEX idx_comp_off_credit_employee ON comp_off_credit(employee_master_id);
CREATE INDEX idx_comp_off_credit_source_date ON comp_off_credit(source_date);
CREATE INDEX idx_comp_off_credit_expiry ON comp_off_credit(expiry_date);
CREATE INDEX idx_comp_off_usage_credit ON comp_off_usage(comp_off_credit_id);
CREATE INDEX idx_comp_off_usage_application ON comp_off_usage(leave_application_id);

-- Encashment indexes
CREATE INDEX idx_leave_encashment_employee ON leave_encashment(employee_master_id);
CREATE INDEX idx_leave_encashment_type ON leave_encashment(leave_type_id);
CREATE INDEX idx_leave_encashment_year ON leave_encashment(encashment_year);

-- =====================================================================================
-- SECTION 9: TRIGGERS AND BUSINESS LOGIC FUNCTIONS
-- =====================================================================================

-- Function to calculate available leave balance
CREATE OR REPLACE FUNCTION calculate_available_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate available balance = opening + accrued + carry_forward - used
    NEW.available_balance := COALESCE(NEW.opening_balance, 0)
                           + COALESCE(NEW.accrued_balance, 0)
                           + COALESCE(NEW.carry_forward_balance, 0)
                           - COALESCE(NEW.used_balance, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for leave entitlement balance calculation
CREATE TRIGGER trigger_calculate_available_balance
    BEFORE INSERT OR UPDATE ON employee_leave_entitlement
    FOR EACH ROW
    EXECUTE FUNCTION calculate_available_balance();

-- Function to generate leave application number
CREATE OR REPLACE FUNCTION generate_leave_application_number()
RETURNS TRIGGER AS $$
DECLARE
    v_year TEXT;
    v_sequence INTEGER;
    v_company_code VARCHAR(10);
BEGIN
    -- Get current year
    v_year := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;

    -- Get company code
    SELECT cm.company_code INTO v_company_code
    FROM employee_master em
    JOIN company_master cm ON em.company_master_id = cm.company_master_id
    WHERE em.employee_master_id = NEW.employee_master_id;

    -- Get next sequence number for the year and company
    SELECT COALESCE(MAX(CAST(SUBSTRING(application_number FROM 'LA' || v_year || '-' || v_company_code || '-([0-9]+)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM leave_application la
    JOIN employee_master em ON la.employee_master_id = em.employee_master_id
    JOIN company_master cm ON em.company_master_id = cm.company_master_id
    WHERE cm.company_code = v_company_code
    AND EXTRACT(YEAR FROM la.application_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate application number: LA2024-NXT001-0001
    NEW.application_number := 'LA' || v_year || '-' || v_company_code || '-' || LPAD(v_sequence::TEXT, 4, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate application number
CREATE TRIGGER trigger_generate_leave_application_number
    BEFORE INSERT ON leave_application
    FOR EACH ROW
    WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
    EXECUTE FUNCTION generate_leave_application_number();

-- Function to auto-assign leave policies to employees
CREATE OR REPLACE FUNCTION assign_leave_policies_to_employee(
    p_employee_id UUID,
    p_effective_date DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
    v_policy_record RECORD;
    v_assigned_count INTEGER := 0;
    v_entitlement_year INTEGER;
BEGIN
    v_entitlement_year := EXTRACT(YEAR FROM p_effective_date);

    -- Find all applicable leave policies for the employee
    FOR v_policy_record IN
        SELECT DISTINCT lpm.leave_policy_id, lpm.leave_type_id, lpm.annual_entitlement
        FROM leave_policy_master lpm
        WHERE lpm.is_active = true
        AND p_effective_date BETWEEN lpm.effective_from AND COALESCE(lpm.effective_to, '2099-12-31')
        AND lpm.row_status = 1
        AND EXISTS (
            SELECT 1 FROM leave_policy_applicability lpa
            JOIN employee_master em ON em.employee_master_id = p_employee_id
            WHERE lpa.leave_policy_id = lpm.leave_policy_id
            AND lpa.is_inclusion = true
            AND lpa.row_status = 1
            AND (
                lpa.applies_to_all = true
                OR lpa.employee_master_id = p_employee_id
                OR lpa.division_master_id = em.division_master_id
                OR lpa.department_master_id = em.department_master_id
                OR lpa.designation_master_id = em.designation_master_id
                OR lpa.employee_category_id = em.employee_category_id
                OR lpa.employee_group_id = em.employee_group_id
                OR lpa.employee_grade_id = em.employee_grade_id
                OR lpa.location_master_id = em.location_master_id
            )
        )
    LOOP
        -- Check if entitlement already exists
        IF NOT EXISTS (
            SELECT 1 FROM employee_leave_entitlement
            WHERE employee_master_id = p_employee_id
            AND leave_policy_id = v_policy_record.leave_policy_id
            AND entitlement_year = v_entitlement_year
        ) THEN
            -- Create new entitlement
            INSERT INTO employee_leave_entitlement (
                employee_master_id,
                leave_policy_id,
                leave_type_id,
                entitlement_year,
                effective_from,
                effective_to,
                annual_entitlement,
                opening_balance,
                created_by
            ) VALUES (
                p_employee_id,
                v_policy_record.leave_policy_id,
                v_policy_record.leave_type_id,
                v_entitlement_year,
                DATE_TRUNC('year', p_effective_date)::DATE,
                (DATE_TRUNC('year', p_effective_date) + INTERVAL '1 year - 1 day')::DATE,
                v_policy_record.annual_entitlement,
                v_policy_record.annual_entitlement,
                (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
            );

            v_assigned_count := v_assigned_count + 1;
        END IF;
    END LOOP;

    RETURN v_assigned_count;
END;
$$ LANGUAGE plpgsql;

-- Function to process leave accruals
CREATE OR REPLACE FUNCTION process_monthly_leave_accruals(
    p_accrual_date DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
    v_entitlement_record RECORD;
    v_accrual_amount DECIMAL(8,2);
    v_processed_count INTEGER := 0;
BEGIN
    -- Process monthly accruals for all active entitlements
    FOR v_entitlement_record IN
        SELECT
            ele.employee_leave_entitlement_id,
            ele.employee_master_id,
            ele.leave_type_id,
            lpm.accrual_frequency,
            lpm.accrual_amount,
            lpm.annual_entitlement,
            ele.last_accrual_date
        FROM employee_leave_entitlement ele
        JOIN leave_policy_master lpm ON ele.leave_policy_id = lpm.leave_policy_id
        WHERE ele.row_status = 1
        AND lpm.is_active = true
        AND lpm.accrual_frequency = 'monthly'
        AND (
            ele.last_accrual_date IS NULL
            OR ele.last_accrual_date < DATE_TRUNC('month', p_accrual_date)
        )
        AND p_accrual_date BETWEEN ele.effective_from AND ele.effective_to
    LOOP
        -- Calculate accrual amount
        v_accrual_amount := v_entitlement_record.accrual_amount;

        -- Create balance adjustment record
        INSERT INTO leave_balance_adjustment (
            employee_leave_entitlement_id,
            employee_master_id,
            leave_type_id,
            adjustment_date,
            adjustment_type,
            adjustment_amount,
            balance_before_adjustment,
            balance_after_adjustment,
            adjustment_reason,
            is_system_generated,
            created_by
        ) SELECT
            v_entitlement_record.employee_leave_entitlement_id,
            v_entitlement_record.employee_master_id,
            v_entitlement_record.leave_type_id,
            p_accrual_date,
            'credit'::balance_adjustment_type,
            v_accrual_amount,
            ele.available_balance,
            ele.available_balance + v_accrual_amount,
            'Monthly accrual for ' || TO_CHAR(p_accrual_date, 'Month YYYY'),
            true,
            (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
        FROM employee_leave_entitlement ele
        WHERE ele.employee_leave_entitlement_id = v_entitlement_record.employee_leave_entitlement_id;

        -- Update entitlement record
        UPDATE employee_leave_entitlement SET
            accrued_balance = accrued_balance + v_accrual_amount,
            last_accrual_date = p_accrual_date,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_leave_entitlement_id = v_entitlement_record.employee_leave_entitlement_id;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SECTION 10: UTILITY VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- View for current employee leave balances
CREATE VIEW current_employee_leave_balances AS
SELECT
    ele.employee_master_id,
    em.employee_code,
    em.full_name,
    ltm.leave_type_name,
    ltm.leave_type_code,
    ele.entitlement_year,
    ele.annual_entitlement,
    ele.opening_balance,
    ele.accrued_balance,
    ele.used_balance,
    ele.available_balance,
    ele.carry_forward_balance,
    lpm.allow_carry_forward,
    lpm.allow_encashment,
    lpm.maximum_encashment_days
FROM employee_leave_entitlement ele
JOIN employee_master em ON ele.employee_master_id = em.employee_master_id
JOIN leave_type_master ltm ON ele.leave_type_id = ltm.leave_type_id
JOIN leave_policy_master lpm ON ele.leave_policy_id = lpm.leave_policy_id
WHERE ele.entitlement_year = EXTRACT(YEAR FROM CURRENT_DATE)
AND ele.row_status = 1
AND em.row_status = 1
AND ltm.is_active = true
ORDER BY em.employee_code, ltm.display_order;

-- View for pending leave applications
CREATE VIEW pending_leave_applications AS
SELECT
    la.leave_application_id,
    la.application_number,
    la.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    ltm.leave_type_name,
    la.leave_from_date,
    la.leave_to_date,
    la.leave_days,
    la.reason,
    la.application_status,
    la.current_approver_id,
    ua.full_name as approver_name,
    la.submitted_date,
    EXTRACT(DAYS FROM CURRENT_DATE - la.submitted_date::DATE) as days_pending
FROM leave_application la
JOIN employee_master em ON la.employee_master_id = em.employee_master_id
JOIN leave_type_master ltm ON la.leave_type_id = ltm.leave_type_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN user_master ua ON la.current_approver_id = ua.user_master_id
WHERE la.application_status IN ('submitted', 'pending_approval')
AND la.row_status = 1
ORDER BY la.submitted_date ASC;

-- View for leave analytics and reporting
CREATE VIEW leave_analytics_summary AS
SELECT
    em.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    dg.designation_name,
    COUNT(la.leave_application_id) as total_applications,
    COUNT(CASE WHEN la.application_status = 'approved' THEN 1 END) as approved_applications,
    COUNT(CASE WHEN la.application_status = 'rejected' THEN 1 END) as rejected_applications,
    SUM(CASE WHEN la.application_status = 'approved' THEN la.leave_days ELSE 0 END) as total_leave_days_taken,
    AVG(CASE WHEN la.application_status = 'approved' THEN la.leave_days END) as avg_leave_days_per_application,
    MIN(la.leave_from_date) as first_leave_date,
    MAX(la.leave_to_date) as last_leave_date
FROM employee_master em
LEFT JOIN leave_application la ON em.employee_master_id = la.employee_master_id
    AND EXTRACT(YEAR FROM la.application_date) = EXTRACT(YEAR FROM CURRENT_DATE)
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
WHERE em.row_status = 1
GROUP BY em.employee_master_id, em.employee_code, em.full_name, dm.department_name, dg.designation_name
ORDER BY em.employee_code;

-- =====================================================================================
-- SECTION 11: COMMENTS AND DOCUMENTATION
-- =====================================================================================

-- Table documentation
COMMENT ON TABLE leave_category_master IS 'System-defined leave categories with standard types and configurations';
COMMENT ON TABLE leave_type_master IS 'Company-specific leave types based on standard categories';
COMMENT ON TABLE leave_policy_master IS 'Comprehensive leave policies with accrual, usage, and carry-forward rules';
COMMENT ON TABLE employee_leave_entitlement IS 'Annual leave entitlements and balance tracking for employees';
COMMENT ON TABLE leave_application IS 'Leave applications with approval workflow and status tracking';
COMMENT ON TABLE comp_off_credit IS 'Compensatory off credits earned from overtime and holiday work';
COMMENT ON TABLE leave_encashment IS 'Leave encashment requests and processing for eligible leave types';

-- Function documentation
COMMENT ON FUNCTION assign_leave_policies_to_employee(UUID, DATE) IS 'Automatically assigns applicable leave policies to employee based on organizational rules';
COMMENT ON FUNCTION process_monthly_leave_accruals(DATE) IS 'Processes monthly leave accruals for all eligible employees with balance updates';

-- =====================================================================================
-- END OF LEAVE MANAGEMENT SCHEMA
-- =====================================================================================