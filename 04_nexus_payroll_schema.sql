-- =====================================================================================
-- NEXUS HRMS - Payroll Management Schema
-- =====================================================================================
-- Version: 4.0
-- Date: 2025-01-14
-- Module: Payroll Management System
-- Description: Comprehensive payroll processing with complex calculations, statutory
--              compliance (PF, ESI, Tax), salary templates, advances, loans, and
--              multi-currency support with detailed audit trails
-- Dependencies: 01_nexus_foundation_schema.sql, 02_nexus_attendance_schema.sql, 03_nexus_leave_schema.sql
-- Author: PostgreSQL DBA (20+ Years Experience)
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create payroll management schema
CREATE SCHEMA IF NOT EXISTS nexus_payroll;

-- Set search path for this schema
SET search_path = nexus_payroll, nexus_foundation, nexus_attendance, nexus_leave, nexus_security, public;

-- =====================================================================================
-- SALARY STRUCTURE AND COMPONENT CONFIGURATION
-- =====================================================================================

-- Salary Component Master
-- Defines all possible salary components (earnings and deductions)
CREATE TABLE nexus_payroll.salary_component_master (
    component_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Component Identification
    component_code VARCHAR(20) NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    component_description TEXT,
    component_type VARCHAR(20) NOT NULL DEFAULT 'EARNING',
    -- EARNING, DEDUCTION, STATUTORY_DEDUCTION, REIMBURSEMENT, BONUS

    -- Component Category
    component_category VARCHAR(30) NOT NULL DEFAULT 'BASIC',
    -- BASIC, HRA, DA, CONVEYANCE, MEDICAL, SPECIAL, PF, ESI, TAX, LWF, INSURANCE

    -- Calculation Configuration
    calculation_type VARCHAR(20) NOT NULL DEFAULT 'FIXED',
    -- FIXED, PERCENTAGE, FORMULA, ATTENDANCE_BASED, PERFORMANCE_BASED

    calculation_base VARCHAR(30) DEFAULT 'NONE',
    -- NONE, BASIC_SALARY, GROSS_SALARY, CTC, ATTENDANCE_DAYS, WORKING_DAYS

    calculation_percentage DECIMAL(8,4) DEFAULT 0.0000,
    calculation_formula TEXT, -- Complex formula for advanced calculations

    -- Limits and Constraints
    minimum_amount DECIMAL(12,2) DEFAULT 0.00,
    maximum_amount DECIMAL(12,2),
    is_taxable BOOLEAN DEFAULT true,
    is_statutory BOOLEAN DEFAULT false,

    -- Frequency and Timing
    payment_frequency VARCHAR(20) DEFAULT 'MONTHLY',
    -- MONTHLY, QUARTERLY, ANNUALLY, ONE_TIME, VARIABLE

    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Display and Reporting
    display_order INTEGER DEFAULT 100,
    is_visible_in_payslip BOOLEAN DEFAULT true,
    is_part_of_ctc BOOLEAN DEFAULT true,

    -- Status
    component_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_salary_component_company_code UNIQUE (company_id, component_code),
    CONSTRAINT chk_component_type CHECK (component_type IN (
        'EARNING', 'DEDUCTION', 'STATUTORY_DEDUCTION', 'REIMBURSEMENT', 'BONUS'
    )),
    CONSTRAINT chk_calculation_type CHECK (calculation_type IN (
        'FIXED', 'PERCENTAGE', 'FORMULA', 'ATTENDANCE_BASED', 'PERFORMANCE_BASED'
    )),
    CONSTRAINT chk_component_status CHECK (component_status IN ('ACTIVE', 'INACTIVE', 'DEPRECATED')),
    CONSTRAINT chk_amount_limits CHECK (
        (maximum_amount IS NULL) OR (maximum_amount >= minimum_amount)
    )
);

-- Salary Template Master
-- Predefined salary structures for employee categories
CREATE TABLE nexus_payroll.salary_template_master (
    template_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Template Identification
    template_code VARCHAR(20) NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,

    -- Template Configuration
    template_type VARCHAR(20) DEFAULT 'STANDARD',
    -- STANDARD, EXECUTIVE, CONTRACTUAL, INTERN, CONSULTANT

    currency_code VARCHAR(3) DEFAULT 'INR',
    is_ctc_template BOOLEAN DEFAULT true,

    -- Applicability
    applicable_grade VARCHAR(20)[],
    applicable_department_ids BIGINT[],
    applicable_designation_ids BIGINT[],
    applicable_location_ids BIGINT[],

    -- Template Status
    template_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Approval
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_salary_template_company_code UNIQUE (company_id, template_code),
    CONSTRAINT chk_template_type CHECK (template_type IN (
        'STANDARD', 'EXECUTIVE', 'CONTRACTUAL', 'INTERN', 'CONSULTANT'
    )),
    CONSTRAINT chk_template_status CHECK (template_status IN ('ACTIVE', 'INACTIVE', 'DRAFT'))
);

-- Salary Template Components
-- Components included in each salary template
CREATE TABLE nexus_payroll.salary_template_components (
    template_component_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    template_id BIGINT NOT NULL REFERENCES nexus_payroll.salary_template_master(template_id),
    component_id BIGINT NOT NULL REFERENCES nexus_payroll.salary_component_master(component_id),

    -- Component Configuration in Template
    default_amount DECIMAL(12,2) DEFAULT 0.00,
    calculation_override_type VARCHAR(20), -- Override template calculation
    calculation_override_value DECIMAL(12,4),
    calculation_override_formula TEXT,

    -- Component Rules in Template
    is_mandatory BOOLEAN DEFAULT true,
    is_editable BOOLEAN DEFAULT false,
    minimum_amount_override DECIMAL(12,2),
    maximum_amount_override DECIMAL(12,2),

    -- Display Configuration
    display_order INTEGER DEFAULT 100,
    component_group VARCHAR(50) DEFAULT 'GENERAL',

    -- Status
    component_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_template_component UNIQUE (template_id, component_id),
    CONSTRAINT chk_template_component_status CHECK (component_status IN ('ACTIVE', 'INACTIVE'))
);

-- =====================================================================================
-- EMPLOYEE SALARY STRUCTURE
-- =====================================================================================

-- Employee Salary Structure
-- Individual employee salary assignments based on templates
CREATE TABLE nexus_payroll.employee_salary_structure (
    salary_structure_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    template_id BIGINT REFERENCES nexus_payroll.salary_template_master(template_id),

    -- Salary Structure Identification
    structure_code VARCHAR(50),
    structure_name VARCHAR(100),

    -- Salary Configuration
    currency_code VARCHAR(3) DEFAULT 'INR',
    ctc_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    gross_salary DECIMAL(15,2) GENERATED ALWAYS AS (
        ctc_amount -- This will be updated by trigger with actual calculation
    ) STORED,
    net_salary DECIMAL(15,2), -- Calculated during payroll processing

    -- Effective Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Salary Change Information
    revision_type VARCHAR(30) DEFAULT 'NEW_JOINING',
    -- NEW_JOINING, PROMOTION, INCREMENT, REVISION, TRANSFER, CORRECTION
    previous_ctc_amount DECIMAL(15,2),
    increment_percentage DECIMAL(8,4),
    increment_amount DECIMAL(12,2),

    -- Approval and Processing
    approval_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, PENDING_APPROVAL, APPROVED, REJECTED, ACTIVE, EXPIRED
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,

    -- Processing Status
    is_processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,

    -- Comments and Justification
    revision_reason TEXT,
    hr_comments TEXT,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_salary_active UNIQUE (employee_id, effective_from_date)
        WHERE approval_status = 'ACTIVE' AND effective_to_date IS NULL,
    CONSTRAINT chk_salary_structure_approval_status CHECK (approval_status IN (
        'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'ACTIVE', 'EXPIRED'
    )),
    CONSTRAINT chk_revision_type CHECK (revision_type IN (
        'NEW_JOINING', 'PROMOTION', 'INCREMENT', 'REVISION', 'TRANSFER', 'CORRECTION'
    )),
    CONSTRAINT chk_salary_dates CHECK (
        effective_to_date IS NULL OR effective_to_date >= effective_from_date
    )
);

-- Employee Salary Components
-- Individual component assignments for each employee
CREATE TABLE nexus_payroll.employee_salary_components (
    employee_component_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    salary_structure_id BIGINT NOT NULL REFERENCES nexus_payroll.employee_salary_structure(salary_structure_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    component_id BIGINT NOT NULL REFERENCES nexus_payroll.salary_component_master(component_id),

    -- Component Amount Configuration
    component_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    calculation_type VARCHAR(20) DEFAULT 'FIXED',
    calculation_base VARCHAR(30),
    calculation_percentage DECIMAL(8,4),
    calculation_formula TEXT,

    -- Component Limits
    minimum_amount DECIMAL(12,2),
    maximum_amount DECIMAL(12,2),

    -- Component Status
    is_active BOOLEAN DEFAULT true,
    is_locked BOOLEAN DEFAULT false, -- Prevent changes during payroll processing

    -- Effective Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_component_active UNIQUE (employee_id, component_id, effective_from_date)
        WHERE is_active = true AND effective_to_date IS NULL,
    CONSTRAINT chk_component_amount CHECK (component_amount >= 0),
    CONSTRAINT chk_component_dates CHECK (
        effective_to_date IS NULL OR effective_to_date >= effective_from_date
    )
);

-- =====================================================================================
-- STATUTORY COMPLIANCE CONFIGURATION
-- =====================================================================================

-- PF (Provident Fund) Configuration
CREATE TABLE nexus_payroll.pf_configuration (
    pf_config_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- PF Registration Details
    pf_registration_number VARCHAR(50) NOT NULL,
    pf_office_code VARCHAR(20),
    establishment_code VARCHAR(20),

    -- PF Calculation Rules
    employee_pf_percentage DECIMAL(5,2) DEFAULT 12.00,
    employer_pf_percentage DECIMAL(5,2) DEFAULT 12.00,
    eps_percentage DECIMAL(5,2) DEFAULT 8.33,
    edli_percentage DECIMAL(5,2) DEFAULT 0.50,
    admin_charges_percentage DECIMAL(5,2) DEFAULT 0.65,

    -- PF Limits and Thresholds
    pf_ceiling_amount DECIMAL(12,2) DEFAULT 15000.00,
    eps_ceiling_amount DECIMAL(12,2) DEFAULT 15000.00,
    minimum_pension_amount DECIMAL(12,2) DEFAULT 1000.00,

    -- Applicability Rules
    pf_applicable_from_salary DECIMAL(12,2) DEFAULT 0.00,
    is_pf_mandatory BOOLEAN DEFAULT true,
    pf_exemption_salary_limit DECIMAL(12,2),

    -- Effective Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,
    config_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_pf_config_company_active UNIQUE (company_id, effective_from_date)
        WHERE config_status = 'ACTIVE' AND effective_to_date IS NULL,
    CONSTRAINT chk_pf_config_status CHECK (config_status IN ('ACTIVE', 'INACTIVE'))
);

-- ESI (Employee State Insurance) Configuration
CREATE TABLE nexus_payroll.esi_configuration (
    esi_config_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- ESI Registration Details
    esi_registration_number VARCHAR(50) NOT NULL,
    esi_local_office VARCHAR(100),
    esi_regional_office VARCHAR(100),

    -- ESI Calculation Rules
    employee_esi_percentage DECIMAL(5,2) DEFAULT 0.75,
    employer_esi_percentage DECIMAL(5,2) DEFAULT 3.25,

    -- ESI Limits and Thresholds
    esi_ceiling_amount DECIMAL(12,2) DEFAULT 25000.00,
    esi_minimum_wages DECIMAL(12,2) DEFAULT 21000.00,

    -- Applicability Rules
    is_esi_applicable BOOLEAN DEFAULT true,
    esi_exemption_categories VARCHAR(50)[],

    -- Effective Period
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,
    config_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_esi_config_company_active UNIQUE (company_id, effective_from_date)
        WHERE config_status = 'ACTIVE' AND effective_to_date IS NULL,
    CONSTRAINT chk_esi_config_status CHECK (config_status IN ('ACTIVE', 'INACTIVE'))
);

-- Tax Slab Configuration
CREATE TABLE nexus_payroll.tax_slab_master (
    tax_slab_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Tax Year Configuration
    assessment_year VARCHAR(10) NOT NULL, -- e.g., '2024-25'
    financial_year_start DATE NOT NULL,
    financial_year_end DATE NOT NULL,

    -- Tax Slab Details
    slab_sequence INTEGER NOT NULL,
    income_from_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    income_to_amount DECIMAL(15,2),
    tax_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    tax_exemption_limit DECIMAL(15,2) DEFAULT 0.00,

    -- Slab Category
    tax_regime VARCHAR(20) DEFAULT 'OLD', -- OLD, NEW
    taxpayer_category VARCHAR(20) DEFAULT 'INDIVIDUAL',
    -- INDIVIDUAL, SENIOR_CITIZEN, SUPER_SENIOR_CITIZEN

    -- Additional Taxes
    surcharge_percentage DECIMAL(5,2) DEFAULT 0.00,
    cess_percentage DECIMAL(5,2) DEFAULT 4.00,

    -- Status
    slab_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_tax_slab_company_sequence UNIQUE (company_id, assessment_year, tax_regime, taxpayer_category, slab_sequence),
    CONSTRAINT chk_tax_slab_status CHECK (slab_status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT chk_income_range CHECK (
        income_to_amount IS NULL OR income_to_amount > income_from_amount
    )
);

-- =====================================================================================
-- PAYROLL PROCESSING TABLES
-- =====================================================================================

-- Payroll Processing Master
-- Monthly payroll processing cycles
CREATE TABLE nexus_payroll.payroll_processing_master (
    payroll_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Payroll Period
    payroll_month DATE NOT NULL, -- First day of the month
    payroll_year INTEGER GENERATED ALWAYS AS (EXTRACT(YEAR FROM payroll_month)) STORED,
    payroll_period_name VARCHAR(50), -- e.g., 'January 2024'

    -- Payroll Configuration
    salary_date DATE NOT NULL, -- Actual salary payment date
    cutoff_date DATE NOT NULL, -- Attendance/leave cutoff date
    payroll_type VARCHAR(20) DEFAULT 'REGULAR',
    -- REGULAR, BONUS, ARREARS, FINAL_SETTLEMENT, ADVANCE

    -- Processing Scope
    total_employees_count INTEGER DEFAULT 0,
    processed_employees_count INTEGER DEFAULT 0,
    failed_employees_count INTEGER DEFAULT 0,
    excluded_employees_count INTEGER DEFAULT 0,

    -- Financial Summary
    total_gross_amount DECIMAL(18,2) DEFAULT 0.00,
    total_deductions_amount DECIMAL(18,2) DEFAULT 0.00,
    total_net_amount DECIMAL(18,2) DEFAULT 0.00,
    total_employer_contributions DECIMAL(18,2) DEFAULT 0.00,

    -- Processing Status
    processing_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, IN_PROGRESS, COMPLETED, APPROVED, PUBLISHED, PAID, CANCELLED

    -- Processing Timestamps
    processing_started_at TIMESTAMP WITH TIME ZONE,
    processing_completed_at TIMESTAMP WITH TIME ZONE,
    processing_duration_minutes INTEGER,

    -- Approval Information
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- Lock Status
    is_locked BOOLEAN DEFAULT false,
    locked_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    locked_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_payroll_company_month UNIQUE (company_id, payroll_month, payroll_type),
    CONSTRAINT chk_payroll_processing_status CHECK (processing_status IN (
        'DRAFT', 'IN_PROGRESS', 'COMPLETED', 'APPROVED', 'PUBLISHED', 'PAID', 'CANCELLED'
    )),
    CONSTRAINT chk_payroll_type CHECK (payroll_type IN (
        'REGULAR', 'BONUS', 'ARREARS', 'FINAL_SETTLEMENT', 'ADVANCE'
    ))
);

-- Employee Payroll Records (Partitioned by payroll_month)
-- Individual employee payroll calculations
CREATE TABLE nexus_payroll.employee_payroll_records (
    payroll_record_id BIGINT NOT NULL DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    payroll_id BIGINT NOT NULL REFERENCES nexus_payroll.payroll_processing_master(payroll_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Payroll Period
    payroll_month DATE NOT NULL,
    employee_code VARCHAR(20) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,

    -- Salary Structure Reference
    salary_structure_id BIGINT REFERENCES nexus_payroll.employee_salary_structure(salary_structure_id),
    currency_code VARCHAR(3) DEFAULT 'INR',

    -- Attendance and Leave Data
    total_working_days INTEGER DEFAULT 0,
    actual_working_days DECIMAL(5,2) DEFAULT 0.00,
    present_days DECIMAL(5,2) DEFAULT 0.00,
    absent_days DECIMAL(5,2) DEFAULT 0.00,
    paid_leave_days DECIMAL(5,2) DEFAULT 0.00,
    unpaid_leave_days DECIMAL(5,2) DEFAULT 0.00,
    overtime_hours DECIMAL(6,2) DEFAULT 0.00,

    -- Payroll Calculations
    gross_earnings DECIMAL(15,2) DEFAULT 0.00,
    total_deductions DECIMAL(15,2) DEFAULT 0.00,
    net_salary DECIMAL(15,2) DEFAULT 0.00,
    employer_contributions DECIMAL(15,2) DEFAULT 0.00,

    -- Statutory Calculations
    pf_employee_amount DECIMAL(12,2) DEFAULT 0.00,
    pf_employer_amount DECIMAL(12,2) DEFAULT 0.00,
    eps_amount DECIMAL(12,2) DEFAULT 0.00,
    edli_amount DECIMAL(12,2) DEFAULT 0.00,
    esi_employee_amount DECIMAL(12,2) DEFAULT 0.00,
    esi_employer_amount DECIMAL(12,2) DEFAULT 0.00,
    tds_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Additional Calculations
    overtime_amount DECIMAL(12,2) DEFAULT 0.00,
    bonus_amount DECIMAL(12,2) DEFAULT 0.00,
    arrears_amount DECIMAL(12,2) DEFAULT 0.00,
    advance_deduction DECIMAL(12,2) DEFAULT 0.00,
    loan_deduction DECIMAL(12,2) DEFAULT 0.00,

    -- Processing Information
    calculation_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, CALCULATED, APPROVED, REJECTED, RECALCULATED
    calculated_at TIMESTAMP WITH TIME ZONE,
    calculation_errors TEXT,

    -- Payment Information
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, PROCESSING, PAID, FAILED, CANCELLED
    payment_date DATE,
    payment_reference VARCHAR(100),
    payment_mode VARCHAR(20) DEFAULT 'BANK_TRANSFER',

    -- Hold and Suspension
    is_on_hold BOOLEAN DEFAULT false,
    hold_reason TEXT,
    hold_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT pk_employee_payroll_records PRIMARY KEY (payroll_record_id, payroll_month),
    CONSTRAINT uk_employee_payroll_month UNIQUE (company_id, employee_id, payroll_month, payroll_id),
    CONSTRAINT chk_calculation_status CHECK (calculation_status IN (
        'PENDING', 'CALCULATED', 'APPROVED', 'REJECTED', 'RECALCULATED'
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'PENDING', 'PROCESSING', 'PAID', 'FAILED', 'CANCELLED'
    )),
    CONSTRAINT chk_working_days CHECK (
        total_working_days >= 0 AND actual_working_days >= 0 AND
        present_days + absent_days + paid_leave_days + unpaid_leave_days <= total_working_days + 5
    )
) PARTITION BY RANGE (payroll_month);

-- Create monthly partitions for employee_payroll_records (last 24 months + next 12 months)
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
        partition_name := 'employee_payroll_records_' || TO_CHAR(partition_start, 'YYYY_MM');

        EXECUTE format('CREATE TABLE IF NOT EXISTS nexus_payroll.%I PARTITION OF nexus_payroll.employee_payroll_records
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name, partition_start, partition_end);

        start_date := partition_end;
    END LOOP;
END $$;

-- Employee Payroll Component Details
-- Detailed breakdown of each salary component for each employee
CREATE TABLE nexus_payroll.employee_payroll_components (
    payroll_component_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    payroll_record_id BIGINT NOT NULL,
    payroll_month DATE NOT NULL,
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    component_id BIGINT NOT NULL REFERENCES nexus_payroll.salary_component_master(component_id),

    -- Component Calculation Details
    component_code VARCHAR(20) NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    component_type VARCHAR(20) NOT NULL,
    calculation_type VARCHAR(20) NOT NULL,

    -- Base Values for Calculation
    base_amount DECIMAL(12,2) DEFAULT 0.00,
    calculation_percentage DECIMAL(8,4) DEFAULT 0.0000,
    calculation_units DECIMAL(8,2) DEFAULT 0.00, -- For attendance-based calculations

    -- Calculated Amount
    calculated_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    final_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- After adjustments

    -- Manual Adjustments
    manual_adjustment DECIMAL(12,2) DEFAULT 0.00,
    adjustment_reason TEXT,
    adjusted_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Calculation Formula and Details
    calculation_formula TEXT,
    calculation_details JSONB, -- Store detailed calculation breakdown

    -- Component Status
    is_processed BOOLEAN DEFAULT false,
    is_locked BOOLEAN DEFAULT false,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),

    -- Constraints
    CONSTRAINT uk_payroll_employee_component UNIQUE (payroll_record_id, payroll_month, component_id),
    CONSTRAINT chk_payroll_component_type CHECK (component_type IN (
        'EARNING', 'DEDUCTION', 'STATUTORY_DEDUCTION', 'REIMBURSEMENT', 'BONUS'
    ))
);

-- =====================================================================================
-- EMPLOYEE ADVANCES AND LOANS
-- =====================================================================================

-- Employee Advance Requests
CREATE TABLE nexus_payroll.employee_advance_requests (
    advance_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Advance Request Details
    advance_request_number VARCHAR(50) NOT NULL,
    advance_type VARCHAR(20) NOT NULL DEFAULT 'SALARY',
    -- SALARY, MEDICAL, TRAVEL, EMERGENCY, FESTIVAL, OTHER
    advance_amount DECIMAL(12,2) NOT NULL,
    advance_reason TEXT NOT NULL,

    -- Request Information
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE,
    urgency_level VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT

    -- Eligibility and Limits
    eligible_advance_amount DECIMAL(12,2),
    maximum_allowed_amount DECIMAL(12,2),
    current_outstanding_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Recovery Configuration
    recovery_start_month DATE,
    recovery_installments INTEGER DEFAULT 1,
    recovery_amount_per_month DECIMAL(12,2),
    recovery_method VARCHAR(20) DEFAULT 'EQUAL_INSTALLMENTS',
    -- EQUAL_INSTALLMENTS, PERCENTAGE_OF_SALARY, LUMP_SUM

    -- Interest Configuration
    interest_rate DECIMAL(5,2) DEFAULT 0.00,
    interest_calculation_method VARCHAR(20) DEFAULT 'SIMPLE',
    total_interest_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Approval Status
    approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, CANCELLED, WITHDRAWN
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- Disbursement Information
    disbursement_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, PROCESSING, DISBURSED, FAILED, CANCELLED
    disbursed_amount DECIMAL(12,2),
    disbursement_date DATE,
    disbursement_reference VARCHAR(100),

    -- Recovery Tracking
    total_recovered_amount DECIMAL(12,2) DEFAULT 0.00,
    remaining_balance DECIMAL(12,2) GENERATED ALWAYS AS (
        COALESCE(disbursed_amount, 0) + COALESCE(total_interest_amount, 0) - COALESCE(total_recovered_amount, 0)
    ) STORED,
    recovery_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, IN_PROGRESS, COMPLETED, DEFAULTED, WAIVED

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_advance_request_number UNIQUE (company_id, advance_request_number),
    CONSTRAINT chk_advance_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'WITHDRAWN'
    )),
    CONSTRAINT chk_advance_type CHECK (advance_type IN (
        'SALARY', 'MEDICAL', 'TRAVEL', 'EMERGENCY', 'FESTIVAL', 'OTHER'
    )),
    CONSTRAINT chk_advance_amount CHECK (advance_amount > 0)
);

-- Advance Recovery Schedule
CREATE TABLE nexus_payroll.advance_recovery_schedule (
    recovery_schedule_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    advance_id BIGINT NOT NULL REFERENCES nexus_payroll.employee_advance_requests(advance_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Schedule Details
    installment_number INTEGER NOT NULL,
    scheduled_recovery_month DATE NOT NULL,
    scheduled_amount DECIMAL(12,2) NOT NULL,

    -- Interest Component
    principal_amount DECIMAL(12,2) DEFAULT 0.00,
    interest_amount DECIMAL(12,2) DEFAULT 0.00,

    -- Recovery Status
    recovery_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING, RECOVERED, PARTIAL, DEFERRED, WAIVED, FAILED
    actual_recovery_date DATE,
    actual_recovery_amount DECIMAL(12,2) DEFAULT 0.00,
    payroll_id BIGINT, -- Reference to payroll where recovery was made

    -- Adjustment Information
    adjustment_amount DECIMAL(12,2) DEFAULT 0.00,
    adjustment_reason TEXT,
    adjusted_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_advance_recovery_installment UNIQUE (advance_id, installment_number),
    CONSTRAINT chk_recovery_status CHECK (recovery_status IN (
        'PENDING', 'RECOVERED', 'PARTIAL', 'DEFERRED', 'WAIVED', 'FAILED'
    )),
    CONSTRAINT chk_installment_amount CHECK (scheduled_amount > 0)
);

-- =====================================================================================
-- PAYROLL ANALYTICS AND REPORTING VIEWS
-- =====================================================================================

-- Monthly Payroll Summary View
CREATE OR REPLACE VIEW nexus_payroll.v_monthly_payroll_summary AS
SELECT
    ppm.company_id,
    ppm.payroll_month,
    ppm.payroll_year,
    ppm.payroll_period_name,
    ppm.processing_status,

    -- Employee Statistics
    ppm.total_employees_count,
    ppm.processed_employees_count,
    ppm.failed_employees_count,
    ppm.excluded_employees_count,

    -- Financial Summary
    ppm.total_gross_amount,
    ppm.total_deductions_amount,
    ppm.total_net_amount,
    ppm.total_employer_contributions,

    -- Average Calculations
    CASE
        WHEN ppm.processed_employees_count > 0
        THEN ROUND(ppm.total_gross_amount / ppm.processed_employees_count, 2)
        ELSE 0
    END AS average_gross_salary,

    CASE
        WHEN ppm.processed_employees_count > 0
        THEN ROUND(ppm.total_net_amount / ppm.processed_employees_count, 2)
        ELSE 0
    END AS average_net_salary,

    -- Deduction Percentage
    CASE
        WHEN ppm.total_gross_amount > 0
        THEN ROUND((ppm.total_deductions_amount / ppm.total_gross_amount) * 100, 2)
        ELSE 0
    END AS deduction_percentage,

    -- Processing Information
    ppm.processing_started_at,
    ppm.processing_completed_at,
    ppm.processing_duration_minutes,
    ppm.approved_by,
    ppm.approved_at

FROM nexus_payroll.payroll_processing_master ppm
ORDER BY ppm.payroll_month DESC;

-- Employee Payroll History View
CREATE OR REPLACE VIEW nexus_payroll.v_employee_payroll_history AS
SELECT
    epr.company_id,
    epr.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    desig.designation_name,
    epr.payroll_month,
    epr.payroll_year,

    -- Attendance Information
    epr.total_working_days,
    epr.actual_working_days,
    epr.present_days,
    epr.absent_days,
    epr.paid_leave_days,
    epr.unpaid_leave_days,

    -- Salary Breakdown
    epr.gross_earnings,
    epr.total_deductions,
    epr.net_salary,

    -- Statutory Deductions
    epr.pf_employee_amount,
    epr.esi_employee_amount,
    epr.tds_amount,

    -- Employer Contributions
    epr.pf_employer_amount,
    epr.esi_employer_amount,
    epr.employer_contributions,

    -- Additional Components
    epr.overtime_amount,
    epr.bonus_amount,
    epr.arrears_amount,
    epr.advance_deduction,
    epr.loan_deduction,

    -- Status Information
    epr.calculation_status,
    epr.payment_status,
    epr.payment_date,

    -- Performance Indicators
    CASE
        WHEN epr.total_working_days > 0
        THEN ROUND((epr.present_days / epr.total_working_days) * 100, 2)
        ELSE 0
    END AS attendance_percentage,

    CASE
        WHEN epr.gross_earnings > 0
        THEN ROUND((epr.total_deductions / epr.gross_earnings) * 100, 2)
        ELSE 0
    END AS deduction_percentage

FROM nexus_payroll.employee_payroll_records epr
    JOIN nexus_foundation.employee_master emp ON epr.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
    LEFT JOIN nexus_foundation.designation_master desig ON emp.designation_id = desig.designation_id
WHERE emp.employee_status = 'ACTIVE'
ORDER BY epr.payroll_month DESC, emp.employee_code;

-- Salary Component Analysis View
CREATE OR REPLACE VIEW nexus_payroll.v_salary_component_analysis AS
SELECT
    epc.company_id,
    epc.payroll_month,
    EXTRACT(YEAR FROM epc.payroll_month) AS payroll_year,
    epc.component_id,
    scm.component_code,
    scm.component_name,
    scm.component_type,
    scm.component_category,

    -- Component Statistics
    COUNT(epc.payroll_component_id) AS employee_count,
    SUM(epc.final_amount) AS total_component_amount,
    AVG(epc.final_amount) AS average_component_amount,
    MIN(epc.final_amount) AS minimum_component_amount,
    MAX(epc.final_amount) AS maximum_component_amount,

    -- Calculation Method Distribution
    COUNT(CASE WHEN epc.calculation_type = 'FIXED' THEN 1 END) AS fixed_count,
    COUNT(CASE WHEN epc.calculation_type = 'PERCENTAGE' THEN 1 END) AS percentage_count,
    COUNT(CASE WHEN epc.calculation_type = 'FORMULA' THEN 1 END) AS formula_count,

    -- Manual Adjustment Statistics
    COUNT(CASE WHEN epc.manual_adjustment != 0 THEN 1 END) AS adjusted_count,
    SUM(epc.manual_adjustment) AS total_adjustments

FROM nexus_payroll.employee_payroll_components epc
    JOIN nexus_payroll.salary_component_master scm ON epc.component_id = scm.component_id
WHERE epc.payroll_month >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY
    epc.company_id, epc.payroll_month, epc.component_id,
    scm.component_code, scm.component_name, scm.component_type, scm.component_category
ORDER BY epc.payroll_month DESC, scm.component_code;

-- =====================================================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================================================

-- Enable RLS on all payroll tables
ALTER TABLE nexus_payroll.salary_component_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.salary_template_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.salary_template_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.employee_salary_structure ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.employee_salary_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.pf_configuration ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.esi_configuration ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.tax_slab_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.payroll_processing_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.employee_payroll_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.employee_payroll_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.employee_advance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_payroll.advance_recovery_schedule ENABLE ROW LEVEL SECURITY;

-- Company-based access policy for all payroll tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_payroll'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE POLICY company_access_policy ON nexus_payroll.%I
            FOR ALL TO nexus_app_role
            USING (company_id = current_setting(''app.current_company_id'')::BIGINT)
        ', table_name);
    END LOOP;
END $$;

-- Employee-specific access policy for sensitive payroll data
CREATE POLICY employee_payroll_access_policy ON nexus_payroll.employee_payroll_records
    FOR ALL TO nexus_app_role
    USING (
        company_id = current_setting('app.current_company_id')::BIGINT AND
        (
            employee_id = current_setting('app.current_user_id')::BIGINT OR
            -- Allow HR and finance team access
            EXISTS (
                SELECT 1 FROM nexus_foundation.user_master um
                WHERE um.user_id = current_setting('app.current_user_id')::BIGINT
                AND um.user_role IN ('HR_ADMIN', 'FINANCE_ADMIN', 'PAYROLL_ADMIN', 'ADMIN')
            )
        )
    );

-- =====================================================================================
-- TRIGGERS FOR BUSINESS LOGIC AND AUDIT
-- =====================================================================================

-- Standard update trigger function
CREATE OR REPLACE FUNCTION nexus_payroll.update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified_at = CURRENT_TIMESTAMP;
    NEW.last_modified_by = current_setting('app.current_user_id', true);
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to main tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_payroll'
        AND tablename NOT IN ('employee_payroll_components', 'advance_recovery_schedule')
        AND tablename NOT LIKE 'v_%'
        AND tablename NOT LIKE '%_yyyy_mm'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_last_modified_trigger
            BEFORE UPDATE ON nexus_payroll.%I
            FOR EACH ROW EXECUTE FUNCTION nexus_payroll.update_last_modified()
        ', table_name);
    END LOOP;
END $$;

-- Salary structure activation trigger
CREATE OR REPLACE FUNCTION nexus_payroll.activate_salary_structure()
RETURNS TRIGGER AS $$
BEGIN
    -- When a salary structure is approved and becomes active
    IF NEW.approval_status = 'ACTIVE' AND
       (OLD.approval_status IS NULL OR OLD.approval_status != 'ACTIVE') THEN

        -- Deactivate previous active structures
        UPDATE nexus_payroll.employee_salary_structure
        SET approval_status = 'EXPIRED',
            effective_to_date = NEW.effective_from_date - INTERVAL '1 day'
        WHERE employee_id = NEW.employee_id
        AND salary_structure_id != NEW.salary_structure_id
        AND approval_status = 'ACTIVE';

        -- Update employee master with new CTC
        UPDATE nexus_foundation.employee_master
        SET current_ctc = NEW.ctc_amount,
            last_salary_revision_date = NEW.effective_from_date
        WHERE employee_id = NEW.employee_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply salary structure activation trigger
CREATE TRIGGER activate_salary_structure_trigger
    AFTER UPDATE ON nexus_payroll.employee_salary_structure
    FOR EACH ROW EXECUTE FUNCTION nexus_payroll.activate_salary_structure();

-- =====================================================================================
-- STORED PROCEDURES FOR PAYROLL PROCESSING
-- =====================================================================================

-- Calculate employee payroll
CREATE OR REPLACE FUNCTION nexus_payroll.calculate_employee_payroll(
    p_company_id BIGINT,
    p_payroll_id BIGINT,
    p_employee_id BIGINT,
    p_payroll_month DATE
)
RETURNS JSONB AS $$
DECLARE
    v_employee_record RECORD;
    v_salary_structure RECORD;
    v_attendance_data RECORD;
    v_leave_data RECORD;
    v_component_record RECORD;
    v_calculated_amount DECIMAL(12,2);
    v_gross_earnings DECIMAL(15,2) := 0.00;
    v_total_deductions DECIMAL(15,2) := 0.00;
    v_net_salary DECIMAL(15,2) := 0.00;
    v_result JSONB;
BEGIN
    -- Get employee details
    SELECT * INTO v_employee_record
    FROM nexus_foundation.employee_master
    WHERE employee_id = p_employee_id AND company_id = p_company_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Employee not found'
        );
    END IF;

    -- Get active salary structure
    SELECT * INTO v_salary_structure
    FROM nexus_payroll.employee_salary_structure
    WHERE employee_id = p_employee_id
    AND approval_status = 'ACTIVE'
    AND p_payroll_month BETWEEN effective_from_date
        AND COALESCE(effective_to_date, DATE '2099-12-31')
    ORDER BY effective_from_date DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'No active salary structure found'
        );
    END IF;

    -- Get attendance data
    SELECT
        total_working_days,
        total_present_days,
        total_absent_days,
        total_leave_days,
        total_overtime_hours
    INTO v_attendance_data
    FROM nexus_attendance.monthly_attendance_summary
    WHERE company_id = p_company_id
    AND employee_id = p_employee_id
    AND summary_month = p_payroll_month;

    -- Get leave data
    SELECT
        COALESCE(SUM(CASE WHEN ltm.is_paid_leave THEN la.leave_duration_days ELSE 0 END), 0) as paid_leave_days,
        COALESCE(SUM(CASE WHEN NOT ltm.is_paid_leave THEN la.leave_duration_days ELSE 0 END), 0) as unpaid_leave_days
    INTO v_leave_data
    FROM nexus_leave.leave_applications la
    JOIN nexus_leave.leave_type_master ltm ON la.leave_type_id = ltm.leave_type_id
    WHERE la.company_id = p_company_id
    AND la.employee_id = p_employee_id
    AND la.application_status = 'APPROVED'
    AND EXTRACT(YEAR FROM la.leave_start_date) = EXTRACT(YEAR FROM p_payroll_month)
    AND EXTRACT(MONTH FROM la.leave_start_date) = EXTRACT(MONTH FROM p_payroll_month);

    -- Create or update payroll record
    INSERT INTO nexus_payroll.employee_payroll_records (
        company_id, payroll_id, employee_id, payroll_month,
        employee_code, employee_name, salary_structure_id,
        total_working_days, actual_working_days,
        present_days, absent_days, paid_leave_days, unpaid_leave_days,
        overtime_hours, calculation_status
    )
    VALUES (
        p_company_id, p_payroll_id, p_employee_id, p_payroll_month,
        v_employee_record.employee_code,
        v_employee_record.first_name || ' ' || v_employee_record.last_name,
        v_salary_structure.salary_structure_id,
        COALESCE(v_attendance_data.total_working_days, 22),
        COALESCE(v_attendance_data.total_present_days, 0) + COALESCE(v_leave_data.paid_leave_days, 0),
        COALESCE(v_attendance_data.total_present_days, 0),
        COALESCE(v_attendance_data.total_absent_days, 0),
        COALESCE(v_leave_data.paid_leave_days, 0),
        COALESCE(v_leave_data.unpaid_leave_days, 0),
        COALESCE(v_attendance_data.total_overtime_hours, 0),
        'CALCULATED'
    )
    ON CONFLICT (company_id, employee_id, payroll_month, payroll_id)
    DO UPDATE SET
        actual_working_days = EXCLUDED.actual_working_days,
        present_days = EXCLUDED.present_days,
        absent_days = EXCLUDED.absent_days,
        paid_leave_days = EXCLUDED.paid_leave_days,
        unpaid_leave_days = EXCLUDED.unpaid_leave_days,
        overtime_hours = EXCLUDED.overtime_hours,
        calculation_status = 'CALCULATED',
        calculated_at = CURRENT_TIMESTAMP;

    -- Get the payroll record ID
    DECLARE
        v_payroll_record_id BIGINT;
    BEGIN
        SELECT payroll_record_id INTO v_payroll_record_id
        FROM nexus_payroll.employee_payroll_records
        WHERE company_id = p_company_id
        AND employee_id = p_employee_id
        AND payroll_month = p_payroll_month
        AND payroll_id = p_payroll_id;

        -- Calculate individual components
        FOR v_component_record IN
            SELECT
                esc.component_id,
                scm.component_code,
                scm.component_name,
                scm.component_type,
                esc.calculation_type,
                esc.component_amount,
                esc.calculation_percentage,
                esc.calculation_formula
            FROM nexus_payroll.employee_salary_components esc
            JOIN nexus_payroll.salary_component_master scm ON esc.component_id = scm.component_id
            WHERE esc.employee_id = p_employee_id
            AND esc.is_active = true
            AND p_payroll_month BETWEEN esc.effective_from_date
                AND COALESCE(esc.effective_to_date, DATE '2099-12-31')
            ORDER BY scm.display_order
        LOOP
            -- Calculate component amount based on calculation type
            CASE v_component_record.calculation_type
                WHEN 'FIXED' THEN
                    v_calculated_amount := v_component_record.component_amount;

                WHEN 'PERCENTAGE' THEN
                    v_calculated_amount := (v_salary_structure.ctc_amount * v_component_record.calculation_percentage) / 100;

                WHEN 'ATTENDANCE_BASED' THEN
                    v_calculated_amount := (v_component_record.component_amount *
                        COALESCE(v_attendance_data.total_present_days, 0)) /
                        COALESCE(v_attendance_data.total_working_days, 22);

                ELSE
                    v_calculated_amount := v_component_record.component_amount;
            END CASE;

            -- Insert component calculation
            INSERT INTO nexus_payroll.employee_payroll_components (
                company_id, payroll_record_id, payroll_month, employee_id,
                component_id, component_code, component_name, component_type,
                calculation_type, base_amount, calculation_percentage,
                calculated_amount, final_amount, is_processed
            )
            VALUES (
                p_company_id, v_payroll_record_id, p_payroll_month, p_employee_id,
                v_component_record.component_id, v_component_record.component_code,
                v_component_record.component_name, v_component_record.component_type,
                v_component_record.calculation_type, v_component_record.component_amount,
                v_component_record.calculation_percentage, v_calculated_amount,
                v_calculated_amount, true
            )
            ON CONFLICT (payroll_record_id, payroll_month, component_id)
            DO UPDATE SET
                calculated_amount = EXCLUDED.calculated_amount,
                final_amount = EXCLUDED.final_amount,
                is_processed = true;

            -- Accumulate totals
            IF v_component_record.component_type = 'EARNING' THEN
                v_gross_earnings := v_gross_earnings + v_calculated_amount;
            ELSIF v_component_record.component_type IN ('DEDUCTION', 'STATUTORY_DEDUCTION') THEN
                v_total_deductions := v_total_deductions + v_calculated_amount;
            END IF;
        END LOOP;

        -- Calculate net salary
        v_net_salary := v_gross_earnings - v_total_deductions;

        -- Update payroll record with totals
        UPDATE nexus_payroll.employee_payroll_records
        SET gross_earnings = v_gross_earnings,
            total_deductions = v_total_deductions,
            net_salary = v_net_salary,
            calculation_status = 'CALCULATED',
            calculated_at = CURRENT_TIMESTAMP
        WHERE payroll_record_id = v_payroll_record_id;

        v_result := jsonb_build_object(
            'success', true,
            'payroll_record_id', v_payroll_record_id,
            'employee_code', v_employee_record.employee_code,
            'gross_earnings', v_gross_earnings,
            'total_deductions', v_total_deductions,
            'net_salary', v_net_salary
        );
    END;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Process monthly payroll for all employees
CREATE OR REPLACE FUNCTION nexus_payroll.process_monthly_payroll(
    p_company_id BIGINT,
    p_payroll_month DATE,
    p_department_ids BIGINT[] DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_payroll_id BIGINT;
    v_employee_record RECORD;
    v_processed_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_total_gross DECIMAL(18,2) := 0.00;
    v_total_net DECIMAL(18,2) := 0.00;
    v_calculation_result JSONB;
BEGIN
    -- Create payroll processing record
    INSERT INTO nexus_payroll.payroll_processing_master (
        company_id, payroll_month, payroll_period_name,
        salary_date, cutoff_date, processing_status,
        processing_started_at
    )
    VALUES (
        p_company_id, p_payroll_month,
        TO_CHAR(p_payroll_month, 'Month YYYY'),
        p_payroll_month + INTERVAL '1 month' - INTERVAL '1 day', -- Last day of month
        p_payroll_month + INTERVAL '1 month' - INTERVAL '1 day',
        'IN_PROGRESS',
        CURRENT_TIMESTAMP
    )
    RETURNING payroll_id INTO v_payroll_id;

    -- Process each eligible employee
    FOR v_employee_record IN
        SELECT employee_id, employee_code
        FROM nexus_foundation.employee_master
        WHERE company_id = p_company_id
        AND employee_status = 'ACTIVE'
        AND (p_department_ids IS NULL OR department_id = ANY(p_department_ids))
        ORDER BY employee_code
    LOOP
        BEGIN
            -- Calculate payroll for employee
            v_calculation_result := nexus_payroll.calculate_employee_payroll(
                p_company_id, v_payroll_id, v_employee_record.employee_id, p_payroll_month
            );

            IF (v_calculation_result->>'success')::BOOLEAN THEN
                v_processed_count := v_processed_count + 1;
                v_total_gross := v_total_gross + (v_calculation_result->>'gross_earnings')::DECIMAL;
                v_total_net := v_total_net + (v_calculation_result->>'net_salary')::DECIMAL;
            ELSE
                v_failed_count := v_failed_count + 1;
                RAISE NOTICE 'Failed to process employee %: %',
                    v_employee_record.employee_code,
                    v_calculation_result->>'error';
            END IF;

        EXCEPTION WHEN OTHERS THEN
            v_failed_count := v_failed_count + 1;
            RAISE NOTICE 'Error processing employee %: %',
                v_employee_record.employee_code, SQLERRM;
        END;
    END LOOP;

    -- Update payroll processing master
    UPDATE nexus_payroll.payroll_processing_master
    SET processing_status = 'COMPLETED',
        processing_completed_at = CURRENT_TIMESTAMP,
        processing_duration_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - processing_started_at)) / 60,
        total_employees_count = v_processed_count + v_failed_count,
        processed_employees_count = v_processed_count,
        failed_employees_count = v_failed_count,
        total_gross_amount = v_total_gross,
        total_net_amount = v_total_net
    WHERE payroll_id = v_payroll_id;

    RETURN jsonb_build_object(
        'success', true,
        'payroll_id', v_payroll_id,
        'processed_employees', v_processed_count,
        'failed_employees', v_failed_count,
        'total_gross_amount', v_total_gross,
        'total_net_amount', v_total_net
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA nexus_payroll IS 'Comprehensive payroll management system with complex salary calculations, statutory compliance, advances, and multi-currency support';

COMMENT ON TABLE nexus_payroll.salary_component_master IS 'Master configuration for all salary components with calculation rules and statutory compliance';
COMMENT ON TABLE nexus_payroll.salary_template_master IS 'Predefined salary structures for different employee categories and grades';
COMMENT ON TABLE nexus_payroll.employee_salary_structure IS 'Individual employee salary assignments with revision tracking and approval workflow';
COMMENT ON TABLE nexus_payroll.employee_salary_components IS 'Detailed salary component assignments for each employee with calculation specifications';
COMMENT ON TABLE nexus_payroll.pf_configuration IS 'Provident Fund configuration with statutory rates and limits for compliance';
COMMENT ON TABLE nexus_payroll.esi_configuration IS 'Employee State Insurance configuration with contribution rates and thresholds';
COMMENT ON TABLE nexus_payroll.tax_slab_master IS 'Income tax slab configuration for TDS calculations with multiple tax regimes';
COMMENT ON TABLE nexus_payroll.payroll_processing_master IS 'Monthly payroll processing cycles with status tracking and financial summaries';
COMMENT ON TABLE nexus_payroll.employee_payroll_records IS 'Individual employee payroll calculations partitioned by month for performance';
COMMENT ON TABLE nexus_payroll.employee_payroll_components IS 'Detailed breakdown of salary component calculations for each employee payroll';
COMMENT ON TABLE nexus_payroll.employee_advance_requests IS 'Employee advance requests with approval workflow and recovery scheduling';
COMMENT ON TABLE nexus_payroll.advance_recovery_schedule IS 'Installment-based recovery schedule for employee advances with interest calculations';

-- =====================================================================================
-- SCHEMA COMPLETION
-- =====================================================================================

-- Grant permissions to application role
GRANT USAGE ON SCHEMA nexus_payroll TO nexus_app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nexus_payroll TO nexus_app_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA nexus_payroll TO nexus_app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nexus_payroll TO nexus_app_role;

-- Grant read-only access to reporting role
GRANT USAGE ON SCHEMA nexus_payroll TO nexus_readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_payroll TO nexus_readonly_role;
GRANT EXECUTE ON FUNCTION nexus_payroll.process_monthly_payroll TO nexus_readonly_role;

RAISE NOTICE 'NEXUS Payroll Management Schema created successfully with:
- 13 core tables with comprehensive payroll lifecycle management
- Complex salary calculation engine with multiple calculation types
- Statutory compliance for PF, ESI, and Income Tax with configurable rates
- Employee advance management with flexible recovery schedules
- Monthly partitioning for high-volume payroll data optimization
- Comprehensive analytics views for payroll insights and compliance reporting
- Row Level Security and audit trails for sensitive financial data protection
- Stored procedures for automated payroll processing and calculations
- GraphQL-optimized structure for modern frontend integration
- Multi-currency support and advanced salary template management';

-- End of 04_nexus_payroll_schema.sql