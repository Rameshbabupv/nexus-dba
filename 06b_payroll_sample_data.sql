-- =====================================================================================
-- NEXUS HRMS - Payroll Management Sample Data
-- Comprehensive test data for salary structures, components, and payroll processing
-- =====================================================================================
-- Dependencies: Employee Master, Attendance Management, Leave Management
-- Purpose: Realistic payroll scenarios for testing and development
-- =====================================================================================

-- =====================================================================================
-- SECTION 1: PAY COMPONENTS SETUP
-- =====================================================================================

-- Create comprehensive pay components for different categories
INSERT INTO pay_component_master (
    company_master_id, component_name, component_code, abbreviation, description,
    component_category, calculation_type, default_value,
    is_taxable, include_in_gross, include_in_ctc, include_in_pf, include_in_esi,
    display_order, is_system_defined, effective_from, created_by
)
SELECT
    cm.company_master_id,
    comp_data.component_name,
    comp_data.component_code,
    comp_data.abbreviation,
    comp_data.description,
    comp_data.component_category::pay_component_category,
    comp_data.calculation_type::calculation_type,
    comp_data.default_value,
    comp_data.is_taxable,
    comp_data.include_in_gross,
    comp_data.include_in_ctc,
    comp_data.include_in_pf,
    comp_data.include_in_esi,
    comp_data.display_order,
    comp_data.is_system_defined,
    '2024-01-01'::DATE,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        -- EARNINGS COMPONENTS
        ('Basic Salary', 'BASIC', 'BASIC', 'Basic salary as per employment contract', 'earning', 'fixed_amount', 0, true, true, true, true, true, 1, true),
        ('House Rent Allowance', 'HRA', 'HRA', 'House rent allowance - 50% of basic salary', 'earning', 'percentage_of_basic', 50, true, true, true, false, true, 2, true),
        ('Dearness Allowance', 'DA', 'DA', 'Dearness allowance for cost of living', 'earning', 'percentage_of_basic', 10, true, true, true, false, true, 3, false),
        ('Transport Allowance', 'TA', 'TA', 'Conveyance and transport allowance', 'earning', 'fixed_amount', 2000, false, true, true, false, false, 4, false),
        ('Medical Allowance', 'MA', 'MA', 'Medical expenses allowance', 'earning', 'fixed_amount', 1250, false, true, true, false, false, 5, false),
        ('Special Allowance', 'SA', 'SA', 'Special allowance - balancing component', 'earning', 'fixed_amount', 0, true, true, true, false, true, 6, false),
        ('Performance Bonus', 'PB', 'PB', 'Performance-based bonus', 'bonus', 'fixed_amount', 0, true, true, false, false, false, 7, false),
        ('Overtime Pay', 'OT', 'OT', 'Overtime compensation', 'earning', 'fixed_amount', 0, true, true, false, false, true, 8, true),

        -- DEDUCTION COMPONENTS
        ('Professional Tax', 'PT', 'PT', 'State professional tax deduction', 'deduction', 'fixed_amount', 200, false, false, false, false, false, 21, true),
        ('Income Tax (TDS)', 'TDS', 'TDS', 'Tax deducted at source', 'deduction', 'manual_entry', 0, false, false, false, false, false, 22, true),
        ('Loan Deduction', 'LOAN', 'LOAN', 'Employee loan and advance deduction', 'deduction', 'manual_entry', 0, false, false, false, false, false, 23, false),
        ('Other Deductions', 'OTH_DED', 'OTH', 'Miscellaneous deductions', 'deduction', 'manual_entry', 0, false, false, false, false, false, 24, false),

        -- STATUTORY COMPONENTS
        ('Employee PF', 'EPF', 'EPF', 'Employee provident fund - 12% of basic', 'statutory', 'percentage_of_basic', 12, false, false, false, false, false, 31, true),
        ('Employer PF', 'CPF', 'CPF', 'Employer provident fund contribution - 12% of basic', 'statutory', 'percentage_of_basic', 12, false, false, false, false, false, 32, true),
        ('Employee ESI', 'EESI', 'EESI', 'Employee state insurance - 0.75% of gross', 'statutory', 'percentage_of_gross', 0.75, false, false, false, false, false, 33, true),
        ('Employer ESI', 'CESI', 'CESI', 'Employer state insurance contribution - 3.25% of gross', 'statutory', 'percentage_of_gross', 3.25, false, false, false, false, false, 34, true),

        -- REIMBURSEMENT COMPONENTS
        ('Mobile Reimbursement', 'MOB', 'MOB', 'Mobile phone bill reimbursement', 'reimbursement', 'fixed_amount', 1000, false, true, true, false, false, 41, false),
        ('Fuel Reimbursement', 'FUEL', 'FUEL', 'Fuel expenses reimbursement', 'reimbursement', 'manual_entry', 0, false, true, true, false, false, 42, false),
        ('Internet Reimbursement', 'INT', 'INT', 'Internet connection reimbursement', 'reimbursement', 'fixed_amount', 500, false, true, true, false, false, 43, false)
) AS comp_data(
    component_name, component_code, abbreviation, description,
    component_category, calculation_type, default_value,
    is_taxable, include_in_gross, include_in_ctc, include_in_pf, include_in_esi,
    display_order, is_system_defined
)
WHERE cm.company_code = 'NXT001';

-- =====================================================================================
-- SECTION 2: SALARY TEMPLATES SETUP
-- =====================================================================================

-- Create salary templates for different grades
INSERT INTO salary_template_master (
    company_master_id, template_name, template_code, description,
    ctc_amount, gross_amount, net_amount, pay_frequency,
    is_ctc_based, effective_from, is_active, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Executive Level Template', 'TMPL_EXEC', 'Salary template for executive level positions',
     6500000, 5500000, 4500000, 'monthly', true, '2024-01-01',  true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Senior Manager Template', 'TMPL_SM', 'Salary template for senior manager positions',
     2500000, 2100000, 1750000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Manager Template', 'TMPL_MGR', 'Salary template for manager positions',
     1800000, 1550000, 1300000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Senior Developer Template', 'TMPL_SD', 'Salary template for senior developer positions',
     1200000, 1050000, 900000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Developer Template', 'TMPL_DEV', 'Salary template for developer positions',
     800000, 700000, 600000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Junior Developer Template', 'TMPL_JD', 'Salary template for junior developer positions',
     500000, 450000, 400000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Trainee Template', 'TMPL_TRN', 'Salary template for trainee positions',
     300000, 280000, 250000, 'monthly', true, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create salary template components for each template
DO $$
DECLARE
    v_template RECORD;
    v_component RECORD;
    v_basic_amount DECIMAL(12,2);
    v_hra_amount DECIMAL(12,2);
    v_special_amount DECIMAL(12,2);
    v_gross_total DECIMAL(12,2);
BEGIN
    -- Loop through each template
    FOR v_template IN
        SELECT salary_template_id, template_code, ctc_amount, gross_amount
        FROM salary_template_master
        WHERE template_code LIKE 'TMPL_%'
    LOOP
        -- Calculate basic salary (40% of CTC)
        v_basic_amount := ROUND(v_template.ctc_amount * 0.40, 0);

        -- Calculate HRA (50% of basic)
        v_hra_amount := ROUND(v_basic_amount * 0.50, 0);

        -- Calculate special allowance to balance gross
        v_gross_total := v_basic_amount + v_hra_amount + 2000 + 1250; -- Basic + HRA + TA + MA
        v_special_amount := v_template.gross_amount - v_gross_total;

        -- Insert earning components
        INSERT INTO salary_template_component (
            salary_template_id, pay_component_id, component_value,
            calculation_basis, percentage_value, is_mandatory, display_order, created_by
        )
        SELECT
            v_template.salary_template_id,
            pcm.pay_component_id,
            CASE pcm.component_code
                WHEN 'BASIC' THEN v_basic_amount
                WHEN 'HRA' THEN v_hra_amount
                WHEN 'TA' THEN 2000
                WHEN 'MA' THEN 1250
                WHEN 'SA' THEN GREATEST(v_special_amount, 0)
                WHEN 'MOB' THEN 1000
                WHEN 'INT' THEN 500
                ELSE 0
            END,
            CASE pcm.component_code
                WHEN 'BASIC' THEN 'fixed'
                WHEN 'HRA' THEN 'percentage_of_basic'
                WHEN 'SA' THEN 'balancing_component'
                ELSE 'fixed'
            END,
            CASE pcm.component_code
                WHEN 'HRA' THEN 50.0
                ELSE NULL
            END,
            CASE pcm.component_code
                WHEN 'BASIC' THEN true
                WHEN 'HRA' THEN true
                ELSE false
            END,
            pcm.display_order,
            (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
        FROM pay_component_master pcm
        WHERE pcm.component_category IN ('earning', 'reimbursement')
        AND pcm.component_code IN ('BASIC', 'HRA', 'TA', 'MA', 'SA', 'MOB', 'INT');

        -- Insert statutory deduction components
        INSERT INTO salary_template_component (
            salary_template_id, pay_component_id, component_value,
            calculation_basis, percentage_value, is_mandatory, display_order, created_by
        )
        SELECT
            v_template.salary_template_id,
            pcm.pay_component_id,
            CASE pcm.component_code
                WHEN 'EPF' THEN LEAST(ROUND(v_basic_amount * 0.12, 0), 1800) -- PF ceiling 15000
                WHEN 'EESI' THEN CASE WHEN v_template.gross_amount <= 25000 THEN ROUND(v_template.gross_amount * 0.0075, 0) ELSE 0 END
                WHEN 'PT' THEN 200
                ELSE 0
            END,
            CASE pcm.component_code
                WHEN 'EPF' THEN 'percentage_of_basic'
                WHEN 'EESI' THEN 'percentage_of_gross'
                ELSE 'fixed'
            END,
            CASE pcm.component_code
                WHEN 'EPF' THEN 12.0
                WHEN 'EESI' THEN 0.75
                ELSE NULL
            END,
            true,
            pcm.display_order,
            (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
        FROM pay_component_master pcm
        WHERE pcm.component_category = 'deduction'
        AND pcm.component_code IN ('EPF', 'EESI', 'PT');

    END LOOP;
END $$;

-- Create template applicability rules based on grades
INSERT INTO salary_template_applicability (
    salary_template_id, employee_grade_id, is_inclusion, priority_order, created_by
)
SELECT
    stm.salary_template_id,
    eg.employee_grade_id,
    true,
    1,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM salary_template_master stm
CROSS JOIN employee_grade eg
WHERE (
    (stm.template_code = 'TMPL_EXEC' AND eg.grade_name = 'Executive')
    OR (stm.template_code = 'TMPL_SM' AND eg.grade_name = 'Senior Manager')
    OR (stm.template_code = 'TMPL_MGR' AND eg.grade_name = 'Manager')
    OR (stm.template_code = 'TMPL_SD' AND eg.grade_name = 'Senior')
    OR (stm.template_code = 'TMPL_DEV' AND eg.grade_name = 'Intermediate')
    OR (stm.template_code = 'TMPL_JD' AND eg.grade_name = 'Junior')
    OR (stm.template_code = 'TMPL_TRN' AND eg.grade_name = 'Trainee')
);

-- =====================================================================================
-- SECTION 3: TAX AND STATUTORY CONFIGURATION
-- =====================================================================================

-- Create income tax slabs for AY 2024-25 (New Regime)
INSERT INTO income_tax_slab (
    company_master_id, assessment_year, tax_regime,
    slab_from_amount, slab_to_amount, tax_rate, cess_rate,
    effective_from, is_active, created_by
)
SELECT
    cm.company_master_id,
    '2024-25',
    'new_regime'::tax_regime_type,
    slab_data.slab_from_amount,
    slab_data.slab_to_amount,
    slab_data.tax_rate,
    4.0, -- 4% Health and Education Cess
    '2024-04-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        (0, 300000, 0),
        (300001, 600000, 5),
        (600001, 900000, 10),
        (900001, 1200000, 15),
        (1200001, 1500000, 20),
        (1500001, NULL, 30)
) AS slab_data(slab_from_amount, slab_to_amount, tax_rate)
WHERE cm.company_code = 'NXT001';

-- Create income tax slabs for AY 2024-25 (Old Regime)
INSERT INTO income_tax_slab (
    company_master_id, assessment_year, tax_regime,
    slab_from_amount, slab_to_amount, tax_rate, cess_rate,
    effective_from, is_active, created_by
)
SELECT
    cm.company_master_id,
    '2024-25',
    'old_regime'::tax_regime_type,
    slab_data.slab_from_amount,
    slab_data.slab_to_amount,
    slab_data.tax_rate,
    4.0,
    '2024-04-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        (0, 250000, 0),
        (250001, 500000, 5),
        (500001, 1000000, 20),
        (1000001, NULL, 30)
) AS slab_data(slab_from_amount, slab_to_amount, tax_rate)
WHERE cm.company_code = 'NXT001';

-- Create PF configuration
INSERT INTO pf_configuration (
    company_master_id, employee_pf_rate, employer_pf_rate, pf_ceiling_amount,
    pension_fund_rate, pension_ceiling_amount, edli_rate, edli_ceiling_amount,
    pf_admin_charges, inspection_charges, effective_from, is_active, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     12.00, 12.00, 15000, 8.33, 15000, 0.50, 15000, 0.65, 0.01,
     '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create ESI configuration
INSERT INTO esi_configuration (
    company_master_id, employee_esi_rate, employer_esi_rate,
    esi_ceiling_amount, esi_minimum_wage, effective_from, is_active, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     0.75, 3.25, 25000, 0, '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create Professional Tax configuration for Karnataka
INSERT INTO professional_tax_configuration (
    company_master_id, state_master_id, slab_from_amount, slab_to_amount,
    pt_amount, is_annual_calculation, effective_from, is_active, created_by
)
SELECT
    cm.company_master_id,
    sm.state_master_id,
    pt_data.slab_from_amount,
    pt_data.slab_to_amount,
    pt_data.pt_amount,
    false,
    '2024-01-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN state_master sm
CROSS JOIN (
    VALUES
        (0, 15000, 0),
        (15001, NULL, 200)
) AS pt_data(slab_from_amount, slab_to_amount, pt_amount)
WHERE cm.company_code = 'NXT001'
AND sm.state_name = 'Karnataka';

-- =====================================================================================
-- SECTION 4: EMPLOYEE SALARY ASSIGNMENTS
-- =====================================================================================

-- Assign salary templates to employees based on their grades
INSERT INTO employee_salary_assignment (
    employee_master_id, salary_template_id, current_ctc, current_gross,
    current_basic, current_net, assignment_date, effective_from,
    assignment_type, is_current_assignment, created_by
)
SELECT
    em.employee_master_id,
    stm.salary_template_id,
    stm.ctc_amount,
    stm.gross_amount,
    ROUND(stm.ctc_amount * 0.40, 0) as current_basic,
    stm.net_amount,
    '2024-01-01'::DATE,
    '2024-01-01'::DATE,
    'template_based',
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
JOIN employee_grade eg ON em.employee_grade_id = eg.employee_grade_id
JOIN salary_template_applicability sta ON eg.employee_grade_id = sta.employee_grade_id
JOIN salary_template_master stm ON sta.salary_template_id = stm.salary_template_id
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND sta.is_inclusion = true
-- Only assign to first 20 employees for sample data
AND em.employee_master_id IN (
    SELECT employee_master_id FROM employee_master
    WHERE row_status = 1 ORDER BY created_at LIMIT 20
);

-- Create individual salary components for each employee
INSERT INTO employee_salary_component (
    employee_salary_assignment_id, pay_component_id, employee_master_id,
    component_amount, calculation_basis, calculation_percentage,
    effective_from, created_by
)
SELECT
    esa.employee_salary_assignment_id,
    stc.pay_component_id,
    esa.employee_master_id,
    stc.component_value,
    stc.calculation_basis,
    stc.percentage_value,
    esa.effective_from,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_salary_assignment esa
JOIN salary_template_component stc ON esa.salary_template_id = stc.salary_template_id
WHERE esa.is_current_assignment = true;

-- =====================================================================================
-- SECTION 5: PAYROLL PERIODS
-- =====================================================================================

-- Create payroll periods for 2024 (Jan-Mar)
INSERT INTO payroll_period (
    company_master_id, period_name, period_code, period_year, period_month,
    period_start_date, period_end_date, pay_date,
    total_calendar_days, total_working_days, total_holidays, total_weekends,
    processing_status, created_by
)
SELECT
    cm.company_master_id,
    period_data.period_name,
    period_data.period_code,
    period_data.period_year,
    period_data.period_month,
    period_data.period_start_date::DATE,
    period_data.period_end_date::DATE,
    period_data.pay_date::DATE,
    period_data.total_calendar_days,
    period_data.total_working_days,
    period_data.total_holidays,
    period_data.total_weekends,
    period_data.processing_status::payroll_status,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        ('January 2024', '2024-01', 2024, 1, '2024-01-01', '2024-01-31', '2024-02-01', 31, 22, 3, 8, 'processed'),
        ('February 2024', '2024-02', 2024, 2, '2024-02-01', '2024-02-29', '2024-03-01', 29, 21, 2, 8, 'processed'),
        ('March 2024', '2024-03', 2024, 3, '2024-03-01', '2024-03-31', '2024-04-01', 31, 21, 4, 10, 'calculated')
) AS period_data(period_name, period_code, period_year, period_month,
                 period_start_date, period_end_date, pay_date,
                 total_calendar_days, total_working_days, total_holidays, total_weekends, processing_status)
WHERE cm.company_code = 'NXT001';

-- =====================================================================================
-- SECTION 6: PAYROLL CALCULATIONS (MARCH 2024)
-- =====================================================================================

-- Create payroll master records for March 2024
INSERT INTO payroll_master (
    employee_master_id, payroll_period_id, employee_salary_assignment_id,
    ctc_amount, gross_salary, basic_salary, total_working_days,
    days_present, days_absent, paid_leave_days, unpaid_leave_days,
    earned_basic, earned_gross, total_earnings, total_deductions,
    taxable_income, net_salary, calculation_status, calculated_date, created_by
)
SELECT
    esa.employee_master_id,
    pp.payroll_period_id,
    esa.employee_salary_assignment_id,
    esa.current_ctc,
    esa.current_gross,
    esa.current_basic,
    pp.total_working_days,
    COALESCE(att_summary.days_present, pp.total_working_days),
    COALESCE(att_summary.days_absent, 0),
    COALESCE(att_summary.paid_leave_days, 0),
    COALESCE(att_summary.unpaid_leave_days, 0),
    -- Earned basic (prorated for unpaid leave)
    ROUND(esa.current_basic *
          (pp.total_working_days - COALESCE(att_summary.unpaid_leave_days, 0)) /
          pp.total_working_days, 2),
    -- Earned gross (will be calculated from components)
    esa.current_gross,
    esa.current_gross, -- Will be updated after component calculations
    0, -- Will be calculated from deduction components
    esa.current_gross, -- Will be updated with actual taxable income
    0, -- Will be calculated as earnings - deductions
    'calculated'::payroll_status,
    '2024-03-25 10:00:00'::TIMESTAMP,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_salary_assignment esa
JOIN payroll_period pp ON pp.period_code = '2024-03'
LEFT JOIN (
    -- Get attendance summary for March 2024
    SELECT
        ams.employee_master_id,
        ams.present_days as days_present,
        ams.absent_days as days_absent,
        ams.leave_days as paid_leave_days,
        0 as unpaid_leave_days -- No LOP in sample data
    FROM attendance_monthly_summary ams
    WHERE ams.summary_year = 2024 AND ams.summary_month = 3
) att_summary ON esa.employee_master_id = att_summary.employee_master_id
WHERE esa.is_current_assignment = true
AND pp.company_master_id = (SELECT company_master_id FROM company_master WHERE company_code = 'NXT001');

-- Calculate and insert payroll component details
INSERT INTO payroll_component_detail (
    payroll_master_id, pay_component_id, component_amount,
    calculated_amount, calculation_basis, is_prorated, proration_factor, created_by
)
SELECT
    pm.payroll_master_id,
    esc.pay_component_id,
    CASE
        -- Prorate earnings for unpaid leave days
        WHEN pcm.component_category = 'earning' AND pm.unpaid_leave_days > 0 THEN
            ROUND(esc.component_amount *
                  (pm.total_working_days - pm.unpaid_leave_days) / pm.total_working_days, 2)
        ELSE esc.component_amount
    END as component_amount,
    esc.component_amount as calculated_amount,
    esc.calculation_basis,
    pm.unpaid_leave_days > 0 AND pcm.component_category = 'earning',
    CASE WHEN pm.unpaid_leave_days > 0 AND pcm.component_category = 'earning' THEN
        (pm.total_working_days - pm.unpaid_leave_days) / pm.total_working_days
    ELSE 1.0 END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM payroll_master pm
JOIN employee_salary_component esc ON pm.employee_salary_assignment_id = esc.employee_salary_assignment_id
JOIN pay_component_master pcm ON esc.pay_component_id = pcm.pay_component_id
WHERE pm.calculation_status = 'calculated';

-- Add some overtime pay for employees who worked overtime
INSERT INTO payroll_component_detail (
    payroll_master_id, pay_component_id, component_amount,
    calculated_amount, calculation_basis, created_by
)
SELECT
    pm.payroll_master_id,
    pcm.pay_component_id,
    ROUND((pm.basic_salary / pm.total_working_days / 8) * pm.overtime_hours * 2, 2) as component_amount,
    ROUND((pm.basic_salary / pm.total_working_days / 8) * pm.overtime_hours * 2, 2) as calculated_amount,
    'overtime_calculation',
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM payroll_master pm
CROSS JOIN pay_component_master pcm
WHERE pm.calculation_status = 'calculated'
AND pm.overtime_hours > 0
AND pcm.component_code = 'OT';

-- Update payroll master with calculated totals
UPDATE payroll_master pm SET
    total_earnings = earnings_calc.total_earnings,
    total_deductions = deductions_calc.total_deductions,
    net_salary = earnings_calc.total_earnings - deductions_calc.total_deductions,
    employee_pf = pf_calc.pf_amount,
    professional_tax = pt_calc.pt_amount,
    updated_at = CURRENT_TIMESTAMP
FROM (
    -- Calculate total earnings
    SELECT
        pcd.payroll_master_id,
        SUM(pcd.component_amount) as total_earnings
    FROM payroll_component_detail pcd
    JOIN pay_component_master pcm ON pcd.pay_component_id = pcm.pay_component_id
    WHERE pcm.component_category IN ('earning', 'bonus', 'reimbursement')
    GROUP BY pcd.payroll_master_id
) earnings_calc,
(
    -- Calculate total deductions
    SELECT
        pcd.payroll_master_id,
        SUM(pcd.component_amount) as total_deductions
    FROM payroll_component_detail pcd
    JOIN pay_component_master pcm ON pcd.pay_component_id = pcm.pay_component_id
    WHERE pcm.component_category = 'deduction'
    GROUP BY pcd.payroll_master_id
) deductions_calc,
(
    -- Calculate PF amount
    SELECT
        pcd.payroll_master_id,
        COALESCE(SUM(CASE WHEN pcm.component_code = 'EPF' THEN pcd.component_amount ELSE 0 END), 0) as pf_amount
    FROM payroll_component_detail pcd
    JOIN pay_component_master pcm ON pcd.pay_component_id = pcm.pay_component_id
    WHERE pcm.component_code = 'EPF'
    GROUP BY pcd.payroll_master_id
) pf_calc,
(
    -- Calculate PT amount
    SELECT
        pcd.payroll_master_id,
        COALESCE(SUM(CASE WHEN pcm.component_code = 'PT' THEN pcd.component_amount ELSE 0 END), 0) as pt_amount
    FROM payroll_component_detail pcd
    JOIN pay_component_master pcm ON pcd.pay_component_id = pcm.pay_component_id
    WHERE pcm.component_code = 'PT'
    GROUP BY pcd.payroll_master_id
) pt_calc
WHERE pm.payroll_master_id = earnings_calc.payroll_master_id
AND pm.payroll_master_id = deductions_calc.payroll_master_id
AND pm.payroll_master_id = pf_calc.payroll_master_id
AND pm.payroll_master_id = pt_calc.payroll_master_id;

-- =====================================================================================
-- SECTION 7: SALARY ADJUSTMENTS AND BONUSES
-- =====================================================================================

-- Create some salary adjustments (bonuses, arrears, deductions)
INSERT INTO salary_adjustment (
    employee_master_id, payroll_period_id, adjustment_type, adjustment_name,
    adjustment_amount, adjustment_reason, is_recurring, is_processed,
    approval_status, approved_by, approval_date, is_taxable, include_in_gross, created_by
)
SELECT
    em.employee_master_id,
    pp.payroll_period_id,
    adj_data.adjustment_type,
    adj_data.adjustment_name,
    adj_data.adjustment_amount,
    adj_data.adjustment_reason,
    false,
    false,
    'approved',
    (SELECT user_master_id FROM user_master WHERE email = 'priya.sharma@nexustech.com'),
    '2024-03-15'::DATE,
    adj_data.is_taxable,
    adj_data.include_in_gross,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
JOIN payroll_period pp ON pp.period_code = '2024-03'
CROSS JOIN (
    VALUES
        ('bonus', 'Performance Bonus Q4', 25000, 'Quarterly performance bonus for excellent work', true, true),
        ('reimbursement', 'Travel Reimbursement', 5000, 'Client visit travel expenses', false, true),
        ('arrear', 'Salary Arrear Feb', 3000, 'Salary difference for February correction', true, true),
        ('deduction', 'Parking Fine', 500, 'Parking violation fine deduction', false, false)
) AS adj_data(adjustment_type, adjustment_name, adjustment_amount, adjustment_reason, is_taxable, include_in_gross)
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND RANDOM() > 0.7 -- Only 30% of employees get adjustments
LIMIT 15;

-- =====================================================================================
-- SECTION 8: LOAN AND ADVANCE DEDUCTIONS
-- =====================================================================================

-- Create some loan and advance records
INSERT INTO loan_advance_deduction (
    employee_master_id, loan_type, loan_amount, outstanding_amount,
    monthly_deduction_amount, total_installments, paid_installments,
    remaining_installments, loan_start_date, first_deduction_date,
    expected_completion_date, interest_rate, loan_status,
    approved_by, approval_date, created_by
)
SELECT
    em.employee_master_id,
    loan_data.loan_type,
    loan_data.loan_amount,
    loan_data.outstanding_amount,
    loan_data.monthly_deduction_amount,
    loan_data.total_installments,
    loan_data.paid_installments,
    loan_data.remaining_installments,
    loan_data.loan_start_date::DATE,
    loan_data.first_deduction_date::DATE,
    loan_data.expected_completion_date::DATE,
    loan_data.interest_rate,
    'active',
    (SELECT user_master_id FROM user_master WHERE email = 'priya.sharma@nexustech.com'),
    loan_data.loan_start_date::DATE,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
CROSS JOIN (
    VALUES
        ('salary_advance', 50000, 40000, 5000, 10, 2, 8, '2024-01-15', '2024-02-01', '2024-10-01', 0),
        ('loan', 200000, 150000, 10000, 20, 5, 15, '2023-08-01', '2023-09-01', '2025-04-01', 8.5),
        ('emergency_advance', 25000, 15000, 2500, 10, 4, 6, '2023-12-01', '2024-01-01', '2024-07-01', 0)
) AS loan_data(loan_type, loan_amount, outstanding_amount, monthly_deduction_amount,
               total_installments, paid_installments, remaining_installments,
               loan_start_date, first_deduction_date, expected_completion_date, interest_rate)
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND em.date_of_joining < '2024-01-01' -- Only existing employees
AND RANDOM() > 0.8 -- Only 20% of employees have loans
LIMIT 8;

-- =====================================================================================
-- SECTION 9: TAX DECLARATIONS
-- =====================================================================================

-- Create tax exemption master records for common sections
INSERT INTO tax_exemption_master (
    company_master_id, exemption_name, exemption_code, exemption_section,
    description, maximum_exemption_amount, assessment_year, tax_regime,
    effective_from, is_active, created_by
)
SELECT
    cm.company_master_id,
    exemption_data.exemption_name,
    exemption_data.exemption_code,
    exemption_data.exemption_section,
    exemption_data.description,
    exemption_data.maximum_exemption_amount,
    '2024-25',
    exemption_data.tax_regime::tax_regime_type,
    '2024-04-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        ('Life Insurance Premium', '80C_LIC', '80C', 'Life insurance premium payments', 150000, 'old_regime'),
        ('PPF Contribution', '80C_PPF', '80C', 'Public Provident Fund contributions', 150000, 'old_regime'),
        ('ELSS Mutual Funds', '80C_ELSS', '80C', 'Equity Linked Savings Scheme investments', 150000, 'old_regime'),
        ('Health Insurance Premium', '80D_HEALTH', '80D', 'Health insurance premium for self and family', 25000, 'old_regime'),
        ('House Rent Allowance', 'HRA_10_13A', '10(13A)', 'House rent allowance exemption', 0, 'old_regime'),
        ('Standard Deduction', 'STD_DED', 'Standard', 'Standard deduction for salaried employees', 50000, 'old_regime')
) AS exemption_data(exemption_name, exemption_code, exemption_section, description, maximum_exemption_amount, tax_regime)
WHERE cm.company_code = 'NXT001';

-- Create employee tax declarations
INSERT INTO employee_tax_declaration (
    employee_master_id, tax_exemption_id, assessment_year, declared_amount,
    approved_amount, declaration_date, approval_status, approved_by, approval_date, created_by
)
SELECT
    em.employee_master_id,
    tem.tax_exemption_id,
    '2024-25',
    CASE tem.exemption_code
        WHEN '80C_LIC' THEN 50000 + (RANDOM() * 50000)::INTEGER
        WHEN '80C_PPF' THEN 30000 + (RANDOM() * 50000)::INTEGER
        WHEN '80D_HEALTH' THEN 15000 + (RANDOM() * 10000)::INTEGER
        WHEN 'STD_DED' THEN 50000
        ELSE 0
    END as declared_amount,
    CASE tem.exemption_code
        WHEN '80C_LIC' THEN 50000 + (RANDOM() * 50000)::INTEGER
        WHEN '80C_PPF' THEN 30000 + (RANDOM() * 50000)::INTEGER
        WHEN '80D_HEALTH' THEN 15000 + (RANDOM() * 10000)::INTEGER
        WHEN 'STD_DED' THEN 50000
        ELSE 0
    END as approved_amount,
    '2024-04-15'::DATE,
    'approved',
    (SELECT user_master_id FROM user_master WHERE email = 'priya.sharma@nexustech.com'),
    '2024-04-20'::DATE,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
CROSS JOIN tax_exemption_master tem
WHERE em.row_status = 1
AND em.employment_status = 'active'
AND em.employee_master_id IN (
    SELECT employee_master_id FROM employee_master
    WHERE row_status = 1 ORDER BY created_at LIMIT 15
)
AND tem.exemption_code IN ('80C_LIC', '80C_PPF', '80D_HEALTH', 'STD_DED');

-- =====================================================================================
-- SECTION 10: VERIFICATION QUERIES AND STATISTICS
-- =====================================================================================

-- Summary statistics for verification
SELECT
    'Total Pay Components Configured' as metric,
    COUNT(*) as count
FROM pay_component_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Salary Templates Active' as metric,
    COUNT(*) as count
FROM salary_template_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Employee Salary Assignments' as metric,
    COUNT(*) as count
FROM employee_salary_assignment
WHERE is_current_assignment = true

UNION ALL

SELECT
    'Total Payroll Records (March 2024)' as metric,
    COUNT(*) as count
FROM payroll_master pm
JOIN payroll_period pp ON pm.payroll_period_id = pp.payroll_period_id
WHERE pp.period_code = '2024-03'

UNION ALL

SELECT
    'Total Salary Adjustments' as metric,
    COUNT(*) as count
FROM salary_adjustment

UNION ALL

SELECT
    'Total Active Loans/Advances' as metric,
    COUNT(*) as count
FROM loan_advance_deduction
WHERE loan_status = 'active';

-- Pay component distribution by category
SELECT
    'Pay Component Distribution' as category,
    component_category,
    COUNT(*) as count,
    ROUND(AVG(default_value), 2) as avg_default_value
FROM pay_component_master
WHERE is_active = true
GROUP BY component_category
ORDER BY count DESC;

-- Salary distribution by template
SELECT
    'Salary Distribution by Template' as category,
    stm.template_name,
    COUNT(esa.employee_salary_assignment_id) as employee_count,
    AVG(esa.current_ctc) as avg_ctc,
    MIN(esa.current_ctc) as min_ctc,
    MAX(esa.current_ctc) as max_ctc
FROM salary_template_master stm
LEFT JOIN employee_salary_assignment esa ON stm.salary_template_id = esa.salary_template_id
    AND esa.is_current_assignment = true
GROUP BY stm.salary_template_id, stm.template_name
ORDER BY avg_ctc DESC;

-- Payroll summary for March 2024
SELECT
    'March 2024 Payroll Summary' as category,
    COUNT(*) as total_employees,
    SUM(gross_salary) as total_gross_salary,
    SUM(total_earnings) as total_earnings,
    SUM(total_deductions) as total_deductions,
    SUM(net_salary) as total_net_salary,
    SUM(employee_pf) as total_pf_deduction,
    AVG(net_salary) as avg_net_salary
FROM payroll_master pm
JOIN payroll_period pp ON pm.payroll_period_id = pp.payroll_period_id
WHERE pp.period_code = '2024-03';

-- Employee-wise payroll breakdown (top 10 by salary)
SELECT
    'Top Earners - March 2024' as category,
    em.employee_code,
    em.full_name,
    dm.department_name,
    pm.gross_salary,
    pm.total_earnings,
    pm.total_deductions,
    pm.net_salary,
    pm.days_present,
    pm.calculation_status
FROM payroll_master pm
JOIN employee_master em ON pm.employee_master_id = em.employee_master_id
JOIN payroll_period pp ON pm.payroll_period_id = pp.payroll_period_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
WHERE pp.period_code = '2024-03'
ORDER BY pm.net_salary DESC
LIMIT 10;

-- Tax exemption utilization
SELECT
    'Tax Exemption Utilization' as category,
    tem.exemption_name,
    COUNT(etd.employee_tax_declaration_id) as declaration_count,
    SUM(etd.declared_amount) as total_declared_amount,
    SUM(etd.approved_amount) as total_approved_amount,
    AVG(etd.approved_amount) as avg_approved_amount
FROM tax_exemption_master tem
LEFT JOIN employee_tax_declaration etd ON tem.tax_exemption_id = etd.tax_exemption_id
    AND etd.approval_status = 'approved'
GROUP BY tem.tax_exemption_id, tem.exemption_name
ORDER BY total_approved_amount DESC;

-- =====================================================================================
-- END OF PAYROLL MANAGEMENT SAMPLE DATA
-- =====================================================================================