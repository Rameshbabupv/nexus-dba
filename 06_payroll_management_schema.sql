-- =====================================================================================
-- NEXUS HRMS - Payroll Management Module
-- PostgreSQL Schema for Salary Structures, Pay Components, and Payroll Processing
-- =====================================================================================
-- Migration from: MongoDB MEAN Stack to PostgreSQL NEXUS Architecture
-- Phase: 6 - Payroll Management Core Tables
-- Dependencies: Employee Master, Attendance Management, Leave Management
-- =====================================================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- SECTION 1: ENUMS AND CUSTOM TYPES
-- =====================================================================================

-- Pay component categories
CREATE TYPE pay_component_category AS ENUM (
    'earning',
    'deduction',
    'statutory',
    'reimbursement',
    'bonus',
    'allowance'
);

-- Pay component calculation types
CREATE TYPE calculation_type AS ENUM (
    'fixed_amount',
    'percentage_of_basic',
    'percentage_of_gross',
    'percentage_of_ctc',
    'formula_based',
    'attendance_based',
    'manual_entry'
);

-- Payroll period frequency
CREATE TYPE payroll_frequency AS ENUM (
    'monthly',
    'bi_weekly',
    'weekly',
    'quarterly',
    'yearly'
);

-- Payroll status
CREATE TYPE payroll_status AS ENUM (
    'draft',
    'in_progress',
    'calculated',
    'verified',
    'approved',
    'processed',
    'paid',
    'cancelled'
);

-- Tax regime types
CREATE TYPE tax_regime_type AS ENUM (
    'old_regime',
    'new_regime'
);

-- Payment methods
CREATE TYPE payment_method AS ENUM (
    'bank_transfer',
    'cash',
    'cheque',
    'digital_wallet'
);

-- =====================================================================================
-- SECTION 2: PAY COMPONENTS AND SALARY STRUCTURES
-- =====================================================================================

-- Master pay components (earnings, deductions, statutory)
CREATE TABLE pay_component_master (
    pay_component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Component identification
    component_name VARCHAR(100) NOT NULL,
    component_code VARCHAR(20) NOT NULL,
    abbreviation VARCHAR(10),
    description TEXT,

    -- Component classification
    component_category pay_component_category NOT NULL,
    component_sub_category VARCHAR(50),

    -- Calculation configuration
    calculation_type calculation_type DEFAULT 'fixed_amount',
    calculation_formula TEXT,
    default_value DECIMAL(12,2) DEFAULT 0,

    -- Tax and statutory settings
    is_taxable BOOLEAN DEFAULT true,
    include_in_gross BOOLEAN DEFAULT true,
    include_in_ctc BOOLEAN DEFAULT true,
    include_in_pf BOOLEAN DEFAULT false,
    include_in_esi BOOLEAN DEFAULT false,
    include_in_pt BOOLEAN DEFAULT false,

    -- Display and processing
    display_order INTEGER DEFAULT 1,
    is_system_defined BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_to DATE,

    -- Rounding rules
    round_off_to_nearest INTEGER DEFAULT 1, -- Round to nearest rupee
    round_off_method VARCHAR(20) DEFAULT 'normal', -- normal, up, down

    -- Finance integration
    finance_ledger_group VARCHAR(100),
    finance_ledger_parent_group VARCHAR(100),

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, component_code),
    UNIQUE(company_master_id, component_name)
);

-- Pay component calculation rules (for complex calculations)
CREATE TABLE pay_component_calculation_rule (
    pay_component_calculation_rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pay_component_id UUID NOT NULL REFERENCES pay_component_master(pay_component_id),

    -- Rule configuration
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    calculation_formula TEXT NOT NULL,

    -- Conditions and thresholds
    minimum_value DECIMAL(12,2),
    maximum_value DECIMAL(12,2),
    threshold_conditions JSON, -- For complex conditional logic

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Salary templates (pay structures)
CREATE TABLE salary_template_master (
    salary_template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Template identification
    template_name VARCHAR(100) NOT NULL,
    template_code VARCHAR(20) NOT NULL,
    description TEXT,

    -- Template configuration
    ctc_amount DECIMAL(12,2) NOT NULL,
    gross_amount DECIMAL(12,2) NOT NULL,
    net_amount DECIMAL(12,2) NOT NULL,

    -- Pay structure type
    pay_frequency payroll_frequency DEFAULT 'monthly',
    is_ctc_based BOOLEAN DEFAULT true,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    -- Template applicability
    applies_to_all BOOLEAN DEFAULT false,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, template_code)
);

-- Salary template components (earnings, deductions for each template)
CREATE TABLE salary_template_component (
    salary_template_component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salary_template_id UUID NOT NULL REFERENCES salary_template_master(salary_template_id),
    pay_component_id UUID NOT NULL REFERENCES pay_component_master(pay_component_id),

    -- Component configuration in template
    component_value DECIMAL(12,2) NOT NULL,
    calculation_basis VARCHAR(50), -- fixed, percentage_of_basic, percentage_of_gross, etc.
    percentage_value DECIMAL(5,2), -- For percentage-based calculations

    -- Override settings
    is_mandatory BOOLEAN DEFAULT false,
    is_editable BOOLEAN DEFAULT true,
    min_value DECIMAL(12,2),
    max_value DECIMAL(12,2),

    -- Display
    display_order INTEGER DEFAULT 1,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(salary_template_id, pay_component_id)
);

-- Salary template applicability (who gets which template)
CREATE TABLE salary_template_applicability (
    salary_template_applicability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salary_template_id UUID NOT NULL REFERENCES salary_template_master(salary_template_id),

    -- Applicability criteria
    applies_to_all BOOLEAN DEFAULT false,

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

    -- Salary range criteria
    min_ctc_amount DECIMAL(12,2),
    max_ctc_amount DECIMAL(12,2),

    -- Include/exclude flag
    is_inclusion BOOLEAN DEFAULT true,
    priority_order INTEGER DEFAULT 1,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 3: EMPLOYEE SALARY ASSIGNMENTS
-- =====================================================================================

-- Employee salary assignments (current salary structure)
CREATE TABLE employee_salary_assignment (
    employee_salary_assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    salary_template_id UUID REFERENCES salary_template_master(salary_template_id),

    -- Salary details
    current_ctc DECIMAL(12,2) NOT NULL,
    current_gross DECIMAL(12,2) NOT NULL,
    current_basic DECIMAL(12,2) NOT NULL,
    current_net DECIMAL(12,2) NOT NULL,

    -- Assignment details
    assignment_date DATE NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,

    -- Assignment source
    assignment_type VARCHAR(50) DEFAULT 'template_based', -- template_based, custom, promotion, increment
    assignment_reason TEXT,

    -- Override flags
    is_custom_salary BOOLEAN DEFAULT false,
    custom_salary_reason TEXT,

    -- Processing flags
    is_current_assignment BOOLEAN DEFAULT true,
    is_processed BOOLEAN DEFAULT false,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Employee salary component details (individual component amounts)
CREATE TABLE employee_salary_component (
    employee_salary_component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_salary_assignment_id UUID NOT NULL REFERENCES employee_salary_assignment(employee_salary_assignment_id),
    pay_component_id UUID NOT NULL REFERENCES pay_component_master(pay_component_id),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),

    -- Component amount details
    component_amount DECIMAL(12,2) NOT NULL,
    calculation_basis VARCHAR(50),
    calculation_percentage DECIMAL(5,2),

    -- Override information
    is_overridden BOOLEAN DEFAULT false,
    original_amount DECIMAL(12,2),
    override_reason TEXT,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_salary_assignment_id, pay_component_id)
);

-- =====================================================================================
-- SECTION 4: TAX AND STATUTORY CALCULATIONS
-- =====================================================================================

-- Income tax slabs and rates
CREATE TABLE income_tax_slab (
    income_tax_slab_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Tax year and regime
    assessment_year VARCHAR(10) NOT NULL, -- 2024-25
    tax_regime tax_regime_type NOT NULL,

    -- Tax slab details
    slab_from_amount DECIMAL(12,2) NOT NULL,
    slab_to_amount DECIMAL(12,2),
    tax_rate DECIMAL(5,2) NOT NULL,
    cess_rate DECIMAL(5,2) DEFAULT 0,

    -- Additional configurations
    is_surcharge_applicable BOOLEAN DEFAULT false,
    surcharge_threshold DECIMAL(12,2),
    surcharge_rate DECIMAL(5,2),

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Tax exemptions and deductions
CREATE TABLE tax_exemption_master (
    tax_exemption_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Exemption details
    exemption_name VARCHAR(100) NOT NULL,
    exemption_code VARCHAR(20) NOT NULL,
    exemption_section VARCHAR(20), -- 80C, 80D, etc.
    description TEXT,

    -- Exemption limits
    maximum_exemption_amount DECIMAL(12,2),
    minimum_exemption_amount DECIMAL(12,2) DEFAULT 0,

    -- Applicability
    assessment_year VARCHAR(10) NOT NULL,
    tax_regime tax_regime_type NOT NULL,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, exemption_code, assessment_year)
);

-- Employee tax declarations
CREATE TABLE employee_tax_declaration (
    employee_tax_declaration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    tax_exemption_id UUID NOT NULL REFERENCES tax_exemption_master(tax_exemption_id),

    -- Declaration details
    assessment_year VARCHAR(10) NOT NULL,
    declared_amount DECIMAL(12,2) NOT NULL,
    approved_amount DECIMAL(12,2),

    -- Supporting documents
    has_supporting_documents BOOLEAN DEFAULT false,
    document_verification_status VARCHAR(20) DEFAULT 'pending',

    -- Processing
    declaration_date DATE NOT NULL,
    approval_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date DATE,
    rejection_reason TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- PF (Provident Fund) configuration
CREATE TABLE pf_configuration (
    pf_configuration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- PF settings
    employee_pf_rate DECIMAL(5,2) DEFAULT 12.00,
    employer_pf_rate DECIMAL(5,2) DEFAULT 12.00,
    pf_ceiling_amount DECIMAL(12,2) DEFAULT 15000,

    -- Pension fund
    pension_fund_rate DECIMAL(5,2) DEFAULT 8.33,
    pension_ceiling_amount DECIMAL(12,2) DEFAULT 15000,

    -- EDLI (Employee Deposit Linked Insurance)
    edli_rate DECIMAL(5,2) DEFAULT 0.50,
    edli_ceiling_amount DECIMAL(12,2) DEFAULT 15000,

    -- Administrative charges
    pf_admin_charges DECIMAL(5,2) DEFAULT 0.65,
    inspection_charges DECIMAL(5,2) DEFAULT 0.01,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- ESI (Employee State Insurance) configuration
CREATE TABLE esi_configuration (
    esi_configuration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- ESI rates
    employee_esi_rate DECIMAL(5,2) DEFAULT 0.75,
    employer_esi_rate DECIMAL(5,2) DEFAULT 3.25,

    -- ESI limits
    esi_ceiling_amount DECIMAL(12,2) DEFAULT 25000,
    esi_minimum_wage DECIMAL(12,2) DEFAULT 0,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Professional Tax configuration (state-wise)
CREATE TABLE professional_tax_configuration (
    professional_tax_configuration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),
    state_master_id UUID NOT NULL REFERENCES state_master(state_master_id),

    -- PT slab details
    slab_from_amount DECIMAL(12,2) NOT NULL,
    slab_to_amount DECIMAL(12,2),
    pt_amount DECIMAL(8,2) NOT NULL,

    -- PT settings
    is_annual_calculation BOOLEAN DEFAULT false,
    exemption_amount DECIMAL(12,2) DEFAULT 0,

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 5: PAYROLL PERIODS AND PROCESSING
-- =====================================================================================

-- Payroll periods (monthly cycles)
CREATE TABLE payroll_period (
    payroll_period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Period details
    period_name VARCHAR(50) NOT NULL, -- March 2024
    period_code VARCHAR(20) NOT NULL, -- 2024-03
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL,

    -- Period dates
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    pay_date DATE NOT NULL,

    -- Working days calculation
    total_calendar_days INTEGER NOT NULL,
    total_working_days INTEGER NOT NULL,
    total_holidays INTEGER DEFAULT 0,
    total_weekends INTEGER DEFAULT 0,

    -- Processing status
    processing_status payroll_status DEFAULT 'draft',
    is_locked BOOLEAN DEFAULT false,
    locked_by UUID REFERENCES user_master(user_master_id),
    locked_date TIMESTAMP,

    -- Calculation dates
    calculation_start_date TIMESTAMP,
    calculation_end_date TIMESTAMP,
    approval_date TIMESTAMP,
    payment_date TIMESTAMP,

    -- Employee counts
    total_employees INTEGER DEFAULT 0,
    processed_employees INTEGER DEFAULT 0,
    failed_employees INTEGER DEFAULT 0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, period_code)
);

-- Payroll master (employee payroll for each period)
CREATE TABLE payroll_master (
    payroll_master_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    payroll_period_id UUID NOT NULL REFERENCES payroll_period(payroll_period_id),
    employee_salary_assignment_id UUID REFERENCES employee_salary_assignment(employee_salary_assignment_id),

    -- Payroll identification
    payroll_number VARCHAR(50) NOT NULL,

    -- Basic salary information
    ctc_amount DECIMAL(12,2) NOT NULL,
    gross_salary DECIMAL(12,2) NOT NULL,
    basic_salary DECIMAL(12,2) NOT NULL,
    net_salary DECIMAL(12,2) NOT NULL,

    -- Attendance and leave impact
    total_working_days INTEGER NOT NULL,
    days_present DECIMAL(5,2) NOT NULL,
    days_absent DECIMAL(5,2) DEFAULT 0,
    paid_leave_days DECIMAL(5,2) DEFAULT 0,
    unpaid_leave_days DECIMAL(5,2) DEFAULT 0,
    overtime_hours DECIMAL(5,2) DEFAULT 0,

    -- Salary calculations
    earned_basic DECIMAL(12,2) NOT NULL,
    earned_gross DECIMAL(12,2) NOT NULL,
    total_earnings DECIMAL(12,2) NOT NULL,
    total_deductions DECIMAL(12,2) NOT NULL,
    total_statutory DECIMAL(12,2) NOT NULL,

    -- Tax calculations
    taxable_income DECIMAL(12,2) NOT NULL,
    income_tax DECIMAL(12,2) DEFAULT 0,
    professional_tax DECIMAL(12,2) DEFAULT 0,

    -- Statutory contributions
    employee_pf DECIMAL(12,2) DEFAULT 0,
    employer_pf DECIMAL(12,2) DEFAULT 0,
    employee_esi DECIMAL(12,2) DEFAULT 0,
    employer_esi DECIMAL(12,2) DEFAULT 0,

    -- Payment details
    payment_method payment_method DEFAULT 'bank_transfer',
    bank_account_number VARCHAR(20),
    ifsc_code VARCHAR(15),

    -- Processing status
    calculation_status payroll_status DEFAULT 'draft',
    is_hold BOOLEAN DEFAULT false,
    hold_reason TEXT,

    -- Calculation tracking
    calculated_date TIMESTAMP,
    calculated_by UUID REFERENCES user_master(user_master_id),
    approved_date TIMESTAMP,
    approved_by UUID REFERENCES user_master(user_master_id),

    -- Error handling
    has_calculation_errors BOOLEAN DEFAULT false,
    calculation_errors TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, payroll_period_id),
    UNIQUE(payroll_number)
);

-- Payroll component details (earnings, deductions for each employee)
CREATE TABLE payroll_component_detail (
    payroll_component_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_master_id UUID NOT NULL REFERENCES payroll_master(payroll_master_id),
    pay_component_id UUID NOT NULL REFERENCES pay_component_master(pay_component_id),

    -- Component calculation
    component_amount DECIMAL(12,2) NOT NULL,
    calculated_amount DECIMAL(12,2), -- Before rounding
    calculation_basis VARCHAR(100),
    calculation_formula TEXT,

    -- Override information
    is_manual_override BOOLEAN DEFAULT false,
    original_amount DECIMAL(12,2),
    override_reason TEXT,
    override_by UUID REFERENCES user_master(user_master_id),
    override_date TIMESTAMP,

    -- Proration details
    is_prorated BOOLEAN DEFAULT false,
    proration_factor DECIMAL(8,4), -- For partial month calculations

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(payroll_master_id, pay_component_id)
);

-- =====================================================================================
-- SECTION 6: PAYROLL ADJUSTMENTS AND ARREARS
-- =====================================================================================

-- Salary adjustments (one-time adjustments)
CREATE TABLE salary_adjustment (
    salary_adjustment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    payroll_period_id UUID REFERENCES payroll_period(payroll_period_id),

    -- Adjustment details
    adjustment_type VARCHAR(50) NOT NULL, -- bonus, arrear, deduction, reimbursement
    adjustment_name VARCHAR(100) NOT NULL,
    adjustment_amount DECIMAL(12,2) NOT NULL,
    adjustment_reason TEXT,

    -- Processing
    is_recurring BOOLEAN DEFAULT false,
    recurring_months INTEGER,
    is_processed BOOLEAN DEFAULT false,
    processed_in_payroll_id UUID REFERENCES payroll_master(payroll_master_id),

    -- Approval
    approval_status VARCHAR(20) DEFAULT 'pending',
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,

    -- Tax implications
    is_taxable BOOLEAN DEFAULT true,
    include_in_gross BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Loan and advance deductions
CREATE TABLE loan_advance_deduction (
    loan_advance_deduction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),

    -- Loan details
    loan_type VARCHAR(50) NOT NULL, -- salary_advance, loan, emergency_advance
    loan_amount DECIMAL(12,2) NOT NULL,
    outstanding_amount DECIMAL(12,2) NOT NULL,
    monthly_deduction_amount DECIMAL(12,2) NOT NULL,

    -- Deduction schedule
    total_installments INTEGER NOT NULL,
    paid_installments INTEGER DEFAULT 0,
    remaining_installments INTEGER NOT NULL,

    -- Loan period
    loan_start_date DATE NOT NULL,
    first_deduction_date DATE NOT NULL,
    expected_completion_date DATE,

    -- Interest (if applicable)
    interest_rate DECIMAL(5,2) DEFAULT 0,
    interest_amount DECIMAL(12,2) DEFAULT 0,

    -- Status
    loan_status VARCHAR(20) DEFAULT 'active', -- active, completed, cancelled
    is_active BOOLEAN DEFAULT true,

    -- Approval
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date DATE,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 7: INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Pay component and template indexes
CREATE INDEX idx_pay_component_master_company ON pay_component_master(company_master_id);
CREATE INDEX idx_pay_component_master_category ON pay_component_master(component_category);
CREATE INDEX idx_salary_template_master_company ON salary_template_master(company_master_id);
CREATE INDEX idx_salary_template_component_template ON salary_template_component(salary_template_id);
CREATE INDEX idx_salary_template_applicability_template ON salary_template_applicability(salary_template_id);

-- Employee salary indexes
CREATE INDEX idx_employee_salary_assignment_employee ON employee_salary_assignment(employee_master_id);
CREATE INDEX idx_employee_salary_assignment_current ON employee_salary_assignment(is_current_assignment);
CREATE INDEX idx_employee_salary_component_assignment ON employee_salary_component(employee_salary_assignment_id);
CREATE INDEX idx_employee_salary_component_effective ON employee_salary_component(effective_from, effective_to);

-- Tax and statutory indexes
CREATE INDEX idx_income_tax_slab_company_year ON income_tax_slab(company_master_id, assessment_year);
CREATE INDEX idx_tax_exemption_master_company_year ON tax_exemption_master(company_master_id, assessment_year);
CREATE INDEX idx_employee_tax_declaration_employee ON employee_tax_declaration(employee_master_id);
CREATE INDEX idx_employee_tax_declaration_year ON employee_tax_declaration(assessment_year);

-- Payroll processing indexes
CREATE INDEX idx_payroll_period_company ON payroll_period(company_master_id);
CREATE INDEX idx_payroll_period_year_month ON payroll_period(period_year, period_month);
CREATE INDEX idx_payroll_master_employee ON payroll_master(employee_master_id);
CREATE INDEX idx_payroll_master_period ON payroll_master(payroll_period_id);
CREATE INDEX idx_payroll_master_status ON payroll_master(calculation_status);
CREATE INDEX idx_payroll_component_detail_payroll ON payroll_component_detail(payroll_master_id);

-- Adjustment and loan indexes
CREATE INDEX idx_salary_adjustment_employee ON salary_adjustment(employee_master_id);
CREATE INDEX idx_salary_adjustment_period ON salary_adjustment(payroll_period_id);
CREATE INDEX idx_loan_advance_deduction_employee ON loan_advance_deduction(employee_master_id);
CREATE INDEX idx_loan_advance_deduction_status ON loan_advance_deduction(loan_status);

-- =====================================================================================
-- SECTION 8: TRIGGERS AND BUSINESS LOGIC FUNCTIONS
-- =====================================================================================

-- Function to generate payroll number
CREATE OR REPLACE FUNCTION generate_payroll_number()
RETURNS TRIGGER AS $$
DECLARE
    v_year TEXT;
    v_month TEXT;
    v_sequence INTEGER;
    v_company_code VARCHAR(10);
BEGIN
    -- Get period details
    SELECT pp.period_year::TEXT, LPAD(pp.period_month::TEXT, 2, '0')
    INTO v_year, v_month
    FROM payroll_period pp
    WHERE pp.payroll_period_id = NEW.payroll_period_id;

    -- Get company code
    SELECT cm.company_code INTO v_company_code
    FROM employee_master em
    JOIN company_master cm ON em.company_master_id = cm.company_master_id
    WHERE em.employee_master_id = NEW.employee_master_id;

    -- Get next sequence number for the period
    SELECT COALESCE(MAX(CAST(SUBSTRING(payroll_number FROM 'PR' || v_year || v_month || '-' || v_company_code || '-([0-9]+)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM payroll_master pm
    JOIN payroll_period pp ON pm.payroll_period_id = pp.payroll_period_id
    WHERE pp.period_year = v_year::INTEGER
    AND pp.period_month = v_month::INTEGER;

    -- Generate payroll number: PR202403-NXT001-0001
    NEW.payroll_number := 'PR' || v_year || v_month || '-' || v_company_code || '-' || LPAD(v_sequence::TEXT, 4, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate payroll number
CREATE TRIGGER trigger_generate_payroll_number
    BEFORE INSERT ON payroll_master
    FOR EACH ROW
    WHEN (NEW.payroll_number IS NULL OR NEW.payroll_number = '')
    EXECUTE FUNCTION generate_payroll_number();

-- Function to assign salary template to employee
CREATE OR REPLACE FUNCTION assign_salary_template_to_employee(
    p_employee_id UUID,
    p_effective_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID AS $$
DECLARE
    v_template_record RECORD;
    v_assignment_id UUID;
BEGIN
    -- Find applicable salary template for the employee
    FOR v_template_record IN
        SELECT DISTINCT stm.salary_template_id, stm.template_name, stm.ctc_amount, stm.gross_amount
        FROM salary_template_master stm
        WHERE stm.is_active = true
        AND p_effective_date BETWEEN stm.effective_from AND COALESCE(stm.effective_to, '2099-12-31')
        AND stm.row_status = 1
        AND EXISTS (
            SELECT 1 FROM salary_template_applicability sta
            JOIN employee_master em ON em.employee_master_id = p_employee_id
            WHERE sta.salary_template_id = stm.salary_template_id
            AND sta.is_inclusion = true
            AND sta.row_status = 1
            AND (
                sta.applies_to_all = true
                OR sta.employee_master_id = p_employee_id
                OR sta.division_master_id = em.division_master_id
                OR sta.department_master_id = em.department_master_id
                OR sta.designation_master_id = em.designation_master_id
                OR sta.employee_category_id = em.employee_category_id
                OR sta.employee_group_id = em.employee_group_id
                OR sta.employee_grade_id = em.employee_grade_id
                OR sta.location_master_id = em.location_master_id
                OR (sta.min_ctc_amount IS NOT NULL AND em.ctc >= sta.min_ctc_amount)
                OR (sta.max_ctc_amount IS NOT NULL AND em.ctc <= sta.max_ctc_amount)
            )
        )
        ORDER BY stm.created_at DESC
        LIMIT 1
    LOOP
        -- Deactivate existing assignments
        UPDATE employee_salary_assignment SET
            is_current_assignment = false,
            effective_to = p_effective_date - INTERVAL '1 day',
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_master_id = p_employee_id
        AND is_current_assignment = true;

        -- Create new assignment
        INSERT INTO employee_salary_assignment (
            employee_master_id,
            salary_template_id,
            current_ctc,
            current_gross,
            current_basic,
            current_net,
            assignment_date,
            effective_from,
            assignment_type,
            is_current_assignment,
            created_by
        ) VALUES (
            p_employee_id,
            v_template_record.salary_template_id,
            v_template_record.ctc_amount,
            v_template_record.gross_amount,
            ROUND(v_template_record.ctc_amount * 0.40, 2), -- Basic = 40% of CTC
            ROUND(v_template_record.gross_amount * 0.70, 2), -- Net = 70% of Gross (approximate)
            p_effective_date,
            p_effective_date,
            'template_based',
            true,
            (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
        ) RETURNING employee_salary_assignment_id INTO v_assignment_id;

        EXIT; -- Exit after first match
    END LOOP;

    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate payroll for an employee
CREATE OR REPLACE FUNCTION calculate_employee_payroll(
    p_employee_id UUID,
    p_payroll_period_id UUID
) RETURNS UUID AS $$
DECLARE
    v_payroll_id UUID;
    v_employee_record RECORD;
    v_period_record RECORD;
    v_salary_record RECORD;
    v_attendance_record RECORD;
    v_earning_total DECIMAL(12,2) := 0;
    v_deduction_total DECIMAL(12,2) := 0;
    v_statutory_total DECIMAL(12,2) := 0;
    v_component_record RECORD;
    v_component_amount DECIMAL(12,2);
BEGIN
    -- Get employee details
    SELECT * INTO v_employee_record
    FROM employee_master
    WHERE employee_master_id = p_employee_id;

    -- Get payroll period details
    SELECT * INTO v_period_record
    FROM payroll_period
    WHERE payroll_period_id = p_payroll_period_id;

    -- Get current salary assignment
    SELECT esa.*, stm.template_name
    INTO v_salary_record
    FROM employee_salary_assignment esa
    LEFT JOIN salary_template_master stm ON esa.salary_template_id = stm.salary_template_id
    WHERE esa.employee_master_id = p_employee_id
    AND esa.is_current_assignment = true
    AND v_period_record.period_start_date BETWEEN esa.effective_from AND COALESCE(esa.effective_to, '2099-12-31');

    -- Get attendance summary for the period
    SELECT
        COALESCE(SUM(CASE WHEN ae.attendance_status IN ('present', 'late', 'early_leaving') THEN 1 ELSE 0 END), 0) as days_present,
        COALESCE(SUM(CASE WHEN ae.attendance_status = 'absent' THEN 1 ELSE 0 END), 0) as days_absent,
        COALESCE(SUM(CASE WHEN la.application_status = 'approved' AND ltm.leave_type_code != 'LOP_001' THEN la.leave_days ELSE 0 END), 0) as paid_leave_days,
        COALESCE(SUM(CASE WHEN la.application_status = 'approved' AND ltm.leave_type_code = 'LOP_001' THEN la.leave_days ELSE 0 END), 0) as unpaid_leave_days,
        COALESCE(SUM(EXTRACT(EPOCH FROM ae.overtime_hours)/3600), 0) as overtime_hours
    INTO v_attendance_record
    FROM attendance_entry ae
    LEFT JOIN leave_application la ON ae.employee_master_id = la.employee_master_id
        AND ae.attendance_date BETWEEN la.leave_from_date AND la.leave_to_date
    LEFT JOIN leave_type_master ltm ON la.leave_type_id = ltm.leave_type_id
    WHERE ae.employee_master_id = p_employee_id
    AND ae.attendance_date BETWEEN v_period_record.period_start_date AND v_period_record.period_end_date;

    -- Create payroll master record
    INSERT INTO payroll_master (
        employee_master_id,
        payroll_period_id,
        employee_salary_assignment_id,
        ctc_amount,
        gross_salary,
        basic_salary,
        total_working_days,
        days_present,
        days_absent,
        paid_leave_days,
        unpaid_leave_days,
        overtime_hours,
        calculation_status,
        created_by
    ) VALUES (
        p_employee_id,
        p_payroll_period_id,
        v_salary_record.employee_salary_assignment_id,
        v_salary_record.current_ctc,
        v_salary_record.current_gross,
        v_salary_record.current_basic,
        v_period_record.total_working_days,
        COALESCE(v_attendance_record.days_present, 0),
        COALESCE(v_attendance_record.days_absent, 0),
        COALESCE(v_attendance_record.paid_leave_days, 0),
        COALESCE(v_attendance_record.unpaid_leave_days, 0),
        COALESCE(v_attendance_record.overtime_hours, 0),
        'calculated',
        (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
    ) RETURNING payroll_master_id INTO v_payroll_id;

    -- Calculate salary components
    FOR v_component_record IN
        SELECT esc.*, pcm.component_name, pcm.component_category, pcm.calculation_type
        FROM employee_salary_component esc
        JOIN pay_component_master pcm ON esc.pay_component_id = pcm.pay_component_id
        WHERE esc.employee_salary_assignment_id = v_salary_record.employee_salary_assignment_id
        AND v_period_record.period_start_date BETWEEN esc.effective_from AND COALESCE(esc.effective_to, '2099-12-31')
        ORDER BY pcm.component_category, pcm.display_order
    LOOP
        -- Calculate component amount based on attendance
        v_component_amount := v_component_record.component_amount;

        -- Apply proration for unpaid leave
        IF v_attendance_record.unpaid_leave_days > 0 THEN
            v_component_amount := v_component_amount *
                (v_period_record.total_working_days - v_attendance_record.unpaid_leave_days) /
                v_period_record.total_working_days;
        END IF;

        -- Insert component detail
        INSERT INTO payroll_component_detail (
            payroll_master_id,
            pay_component_id,
            component_amount,
            calculated_amount,
            calculation_basis,
            is_prorated,
            proration_factor,
            created_by
        ) VALUES (
            v_payroll_id,
            v_component_record.pay_component_id,
            ROUND(v_component_amount, 2),
            v_component_record.component_amount,
            v_component_record.calculation_basis,
            v_attendance_record.unpaid_leave_days > 0,
            CASE WHEN v_attendance_record.unpaid_leave_days > 0 THEN
                (v_period_record.total_working_days - v_attendance_record.unpaid_leave_days) /
                v_period_record.total_working_days
            ELSE 1.0 END,
            (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
        );

        -- Add to totals
        CASE v_component_record.component_category
            WHEN 'earning' THEN v_earning_total := v_earning_total + ROUND(v_component_amount, 2);
            WHEN 'deduction' THEN v_deduction_total := v_deduction_total + ROUND(v_component_amount, 2);
            WHEN 'statutory' THEN v_statutory_total := v_statutory_total + ROUND(v_component_amount, 2);
            ELSE NULL;
        END CASE;
    END LOOP;

    -- Update payroll master with calculated totals
    UPDATE payroll_master SET
        earned_basic = v_salary_record.current_basic *
            (v_period_record.total_working_days - COALESCE(v_attendance_record.unpaid_leave_days, 0)) /
            v_period_record.total_working_days,
        earned_gross = v_earning_total,
        total_earnings = v_earning_total,
        total_deductions = v_deduction_total,
        total_statutory = v_statutory_total,
        taxable_income = v_earning_total - v_statutory_total,
        net_salary = v_earning_total - v_deduction_total - v_statutory_total,
        calculated_date = CURRENT_TIMESTAMP,
        calculated_by = (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1),
        updated_at = CURRENT_TIMESTAMP
    WHERE payroll_master_id = v_payroll_id;

    RETURN v_payroll_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SECTION 9: UTILITY VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- View for current employee salary details
CREATE VIEW current_employee_salary_details AS
SELECT
    esa.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    dg.designation_name,
    esa.current_ctc,
    esa.current_gross,
    esa.current_basic,
    esa.current_net,
    stm.template_name,
    esa.effective_from,
    esa.assignment_type
FROM employee_salary_assignment esa
JOIN employee_master em ON esa.employee_master_id = em.employee_master_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
LEFT JOIN salary_template_master stm ON esa.salary_template_id = stm.salary_template_id
WHERE esa.is_current_assignment = true
AND esa.row_status = 1
AND em.row_status = 1
ORDER BY em.employee_code;

-- View for payroll summary by period
CREATE VIEW payroll_period_summary AS
SELECT
    pp.payroll_period_id,
    pp.period_name,
    pp.period_code,
    pp.processing_status,
    COUNT(pm.payroll_master_id) as total_employees,
    SUM(pm.gross_salary) as total_gross_salary,
    SUM(pm.total_earnings) as total_earnings,
    SUM(pm.total_deductions) as total_deductions,
    SUM(pm.net_salary) as total_net_salary,
    SUM(pm.employee_pf) as total_pf_deduction,
    SUM(pm.employee_esi) as total_esi_deduction,
    SUM(pm.income_tax) as total_income_tax
FROM payroll_period pp
LEFT JOIN payroll_master pm ON pp.payroll_period_id = pm.payroll_period_id
WHERE pp.row_status = 1
GROUP BY pp.payroll_period_id, pp.period_name, pp.period_code, pp.processing_status
ORDER BY pp.period_year DESC, pp.period_month DESC;

-- View for employee payroll history
CREATE VIEW employee_payroll_history AS
SELECT
    pm.employee_master_id,
    em.employee_code,
    em.full_name,
    pp.period_name,
    pp.period_code,
    pm.gross_salary,
    pm.total_earnings,
    pm.total_deductions,
    pm.net_salary,
    pm.days_present,
    pm.days_absent,
    pm.calculation_status,
    pm.calculated_date
FROM payroll_master pm
JOIN employee_master em ON pm.employee_master_id = em.employee_master_id
JOIN payroll_period pp ON pm.payroll_period_id = pp.payroll_period_id
WHERE pm.row_status = 1
ORDER BY em.employee_code, pp.period_year DESC, pp.period_month DESC;

-- =====================================================================================
-- SECTION 10: COMMENTS AND DOCUMENTATION
-- =====================================================================================

-- Table documentation
COMMENT ON TABLE pay_component_master IS 'Master pay components for earnings, deductions, and statutory calculations';
COMMENT ON TABLE salary_template_master IS 'Salary structure templates with CTC breakdowns and applicability rules';
COMMENT ON TABLE employee_salary_assignment IS 'Current and historical salary assignments for employees';
COMMENT ON TABLE payroll_master IS 'Monthly payroll processing records with attendance integration';
COMMENT ON TABLE payroll_component_detail IS 'Detailed component-wise calculations for each payroll';
COMMENT ON TABLE income_tax_slab IS 'Income tax slabs and rates for different tax regimes';
COMMENT ON TABLE pf_configuration IS 'PF rates, ceilings, and calculation parameters';

-- Function documentation
COMMENT ON FUNCTION assign_salary_template_to_employee(UUID, DATE) IS 'Automatically assigns applicable salary template to employee based on organizational rules';
COMMENT ON FUNCTION calculate_employee_payroll(UUID, UUID) IS 'Calculates complete payroll for employee including attendance and leave integration';

-- =====================================================================================
-- END OF PAYROLL MANAGEMENT SCHEMA
-- =====================================================================================