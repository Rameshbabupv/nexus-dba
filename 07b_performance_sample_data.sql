-- =====================================================================================
-- NEXUS HRMS - Performance Management Sample Data
-- Comprehensive test data for appraisals, goals, competencies, and 360-feedback
-- =====================================================================================
-- Dependencies: Employee Master, Organizational Structure, Payroll Management
-- Purpose: Realistic performance scenarios for testing and development
-- =====================================================================================

-- =====================================================================================
-- SECTION 1: COMPETENCY FRAMEWORK SETUP
-- =====================================================================================

-- Create comprehensive competency master for different types
INSERT INTO competency_master (
    company_master_id, competency_name, competency_code, competency_type,
    description, definition, behavioral_indicators,
    level_1_description, level_2_description, level_3_description,
    level_4_description, level_5_description,
    applies_to_all, is_mandatory, display_order, effective_from, created_by
)
SELECT
    cm.company_master_id,
    comp_data.competency_name,
    comp_data.competency_code,
    comp_data.competency_type::competency_type,
    comp_data.description,
    comp_data.definition,
    comp_data.behavioral_indicators,
    comp_data.level_1_description,
    comp_data.level_2_description,
    comp_data.level_3_description,
    comp_data.level_4_description,
    comp_data.level_5_description,
    comp_data.applies_to_all,
    comp_data.is_mandatory,
    comp_data.display_order,
    '2024-01-01'::DATE,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        -- TECHNICAL COMPETENCIES
        ('Technical Expertise', 'TECH_EXPERT', 'technical',
         'Demonstrates deep technical knowledge and skills in relevant domain',
         'Ability to apply technical knowledge effectively to solve complex problems',
         'Shows expertise in programming, system design, troubleshooting, and technical innovation',
         'Basic understanding of core technologies', 'Good grasp of technical concepts with some hands-on experience',
         'Strong technical skills with ability to work independently', 'Expert level with ability to mentor others',
         'Technical leader and innovator in the field',
         true, true, 1),

        ('Problem Solving', 'PROB_SOLVE', 'technical',
         'Ability to analyze complex problems and develop effective solutions',
         'Uses analytical thinking and creativity to resolve challenges',
         'Demonstrates logical approach, considers multiple alternatives, implements effective solutions',
         'Solves routine problems with guidance', 'Handles standard problems independently',
         'Tackles complex problems with innovative approaches', 'Solves critical business problems',
         'Sets problem-solving standards and methodologies',
         true, true, 2),

        ('Innovation & Creativity', 'INNOVATION', 'technical',
         'Brings new ideas and creative approaches to work',
         'Thinks outside the box and contributes to process improvements',
         'Generates new ideas, challenges status quo, implements creative solutions',
         'Suggests minor improvements', 'Proposes practical enhancements',
         'Develops innovative solutions regularly', 'Champions innovation initiatives',
         'Drives organizational innovation and transformation',
         true, false, 3),

        -- BEHAVIORAL COMPETENCIES
        ('Communication', 'COMMUNICATION', 'behavioral',
         'Effectively communicates ideas, information, and feedback',
         'Demonstrates clear, concise, and appropriate communication across all levels',
         'Active listening, clear articulation, appropriate medium selection, feedback delivery',
         'Basic communication with team members', 'Clear communication within department',
         'Effective communication across departments', 'Excellent communication with all stakeholders',
         'Exceptional communication leader and mentor',
         true, true, 4),

        ('Teamwork & Collaboration', 'TEAMWORK', 'behavioral',
         'Works effectively with others to achieve common goals',
         'Builds relationships, shares knowledge, and supports team success',
         'Cooperates willingly, shares resources, builds consensus, resolves conflicts',
         'Participates in team activities', 'Contributes actively to team goals',
         'Facilitates team collaboration', 'Leads collaborative initiatives',
         'Creates high-performing team culture',
         true, true, 5),

        ('Adaptability', 'ADAPTABILITY', 'behavioral',
         'Adjusts approach based on changing circumstances and requirements',
         'Demonstrates flexibility and resilience in dynamic environments',
         'Embraces change, learns quickly, adjusts priorities, maintains performance',
         'Adapts to minor changes with support', 'Handles routine changes well',
         'Thrives in changing environments', 'Leads change initiatives',
         'Champions organizational transformation',
         true, true, 6),

        -- LEADERSHIP COMPETENCIES
        ('People Leadership', 'LEADERSHIP', 'leadership',
         'Guides, motivates, and develops team members effectively',
         'Demonstrates ability to lead people and drive results through others',
         'Provides direction, develops others, delegates effectively, builds trust',
         'Shows potential for leadership roles', 'Leads small teams or projects',
         'Manages teams effectively', 'Senior leadership with multiple teams',
         'Executive leadership driving organizational success',
         false, false, 7),

        ('Strategic Thinking', 'STRATEGIC', 'leadership',
         'Thinks long-term and aligns actions with business strategy',
         'Demonstrates big-picture thinking and strategic planning abilities',
         'Analyzes trends, anticipates future needs, aligns resources with strategy',
         'Understands basic business strategy', 'Contributes to strategic discussions',
         'Develops functional strategies', 'Creates business unit strategies',
         'Drives enterprise-wide strategic initiatives',
         false, false, 8),

        ('Decision Making', 'DECISION', 'leadership',
         'Makes sound decisions in a timely manner with available information',
         'Demonstrates good judgment and takes accountability for decisions',
         'Gathers relevant data, considers alternatives, makes timely decisions, accepts accountability',
         'Makes routine decisions with guidance', 'Makes independent operational decisions',
         'Makes complex decisions affecting multiple areas', 'Makes critical business decisions',
         'Makes strategic decisions impacting organization',
         false, false, 9),

        -- CORE VALUES
        ('Integrity & Ethics', 'INTEGRITY', 'core_values',
         'Demonstrates honesty, transparency, and ethical behavior',
         'Acts with integrity and maintains high ethical standards',
         'Honest communication, ethical decision-making, maintains confidentiality, builds trust',
         'Shows basic ethical awareness', 'Demonstrates consistent ethical behavior',
         'Models integrity for others', 'Champions ethical standards',
         'Sets organizational integrity standards',
         true, true, 10),

        ('Customer Focus', 'CUSTOMER', 'core_values',
         'Prioritizes customer needs and delivers exceptional service',
         'Demonstrates commitment to customer satisfaction and service excellence',
         'Understands customer needs, responds promptly, seeks feedback, exceeds expectations',
         'Understands basic customer service', 'Provides good customer service',
         'Anticipates and exceeds customer needs', 'Drives customer-centric culture',
         'Sets industry standards for customer excellence',
         true, true, 11),

        ('Learning & Development', 'LEARNING', 'core_values',
         'Continuously learns and develops professional capabilities',
         'Shows commitment to personal and professional growth',
         'Seeks learning opportunities, applies new knowledge, shares learnings, stays current',
         'Participates in basic training programs', 'Actively seeks learning opportunities',
         'Applies learning to improve performance', 'Mentors others and shares knowledge',
         'Drives learning culture and organizational capability building',
         true, true, 12)
) AS comp_data(
    competency_name, competency_code, competency_type, description, definition, behavioral_indicators,
    level_1_description, level_2_description, level_3_description, level_4_description, level_5_description,
    applies_to_all, is_mandatory, display_order
)
WHERE cm.company_code = 'NXT001';

-- Create competency applicability for leadership competencies
INSERT INTO competency_applicability (
    competency_id, employee_grade_id, competency_weight, is_mandatory, created_by
)
SELECT
    cm.competency_id,
    eg.employee_grade_id,
    CASE eg.grade_name
        WHEN 'Executive' THEN 150.00
        WHEN 'Senior Manager' THEN 120.00
        WHEN 'Manager' THEN 100.00
        ELSE 50.00
    END as competency_weight,
    CASE WHEN eg.grade_name IN ('Executive', 'Senior Manager', 'Manager') THEN true ELSE false END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM competency_master cm
CROSS JOIN employee_grade eg
WHERE cm.competency_type = 'leadership'
AND cm.competency_code IN ('LEADERSHIP', 'STRATEGIC', 'DECISION');

-- Create performance rating scale
INSERT INTO performance_rating_scale (
    company_master_id, scale_name, scale_description, rating_value,
    rating_label, rating_description, rating_color, min_score, max_score,
    effective_from, is_active, created_by
)
SELECT
    cm.company_master_id,
    'Standard 5-Point Scale',
    'Standard performance rating scale used across organization',
    rating_data.rating_value,
    rating_data.rating_label,
    rating_data.rating_description,
    rating_data.rating_color,
    rating_data.min_score,
    rating_data.max_score,
    '2024-01-01'::DATE,
    true,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM company_master cm
CROSS JOIN (
    VALUES
        (5, 'Outstanding', 'Consistently exceeds expectations and sets new standards', '#28a745', 90.00, 100.00),
        (4, 'Exceeds Expectations', 'Frequently exceeds expectations and adds significant value', '#17a2b8', 80.00, 89.99),
        (3, 'Meets Expectations', 'Consistently meets expectations and delivers quality results', '#ffc107', 60.00, 79.99),
        (2, 'Below Expectations', 'Sometimes meets expectations but needs improvement', '#fd7e14', 40.00, 59.99),
        (1, 'Unsatisfactory', 'Rarely meets expectations and requires significant improvement', '#dc3545', 0.00, 39.99)
) AS rating_data(rating_value, rating_label, rating_description, rating_color, min_score, max_score)
WHERE cm.company_code = 'NXT001';

-- =====================================================================================
-- SECTION 2: APPRAISAL CYCLES AND TEMPLATES
-- =====================================================================================

-- Create appraisal cycles for 2024
INSERT INTO appraisal_cycle (
    company_master_id, cycle_name, cycle_code, cycle_year, cycle_type,
    cycle_start_date, cycle_end_date, review_period_start, review_period_end,
    goal_setting_start_date, goal_setting_end_date,
    mid_review_start_date, mid_review_end_date,
    final_review_start_date, final_review_end_date,
    is_goal_setting_enabled, is_mid_review_enabled, is_360_feedback_enabled,
    is_self_assessment_mandatory, goal_achievement_weight, competency_weight,
    cycle_status, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Annual Performance Review 2024', 'APR2024', 2024, 'annual',
     '2024-01-01', '2024-12-31', '2024-01-01', '2024-12-31',
     '2024-01-01', '2024-01-31',
     '2024-06-01', '2024-06-30',
     '2024-11-01', '2024-12-15',
     true, true, true, true, 70.00, 30.00, 'final_review',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Mid-Year Review 2024', 'MYR2024', 2024, 'half_yearly',
     '2024-01-01', '2024-06-30', '2024-01-01', '2024-06-30',
     '2024-01-01', '2024-01-15',
     NULL, NULL,
     '2024-06-01', '2024-06-30',
     true, false, false, true, 80.00, 20.00, 'completed',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create appraisal templates
INSERT INTO appraisal_template (
    company_master_id, template_name, template_code, description, template_type,
    goals_section_weight, competency_section_weight, additional_section_weight,
    enable_self_assessment, enable_manager_assessment, enable_skip_level_review,
    enable_peer_feedback, enable_subordinate_feedback,
    goal_scoring_method, competency_scoring_method, overall_scoring_method,
    effective_from, is_active, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Standard Employee Template', 'STD_EMP', 'Standard template for individual contributors',
     'standard', 70.00, 30.00, 0.00, true, true, false, false, false,
     'weighted_average', 'simple_average', 'weighted_average', '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Manager Template', 'MGR_TMPL', 'Template for managerial positions with leadership focus',
     'leadership', 60.00, 40.00, 0.00, true, true, true, true, true,
     'weighted_average', 'simple_average', 'weighted_average', '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Senior Leadership Template', 'SR_LEAD', 'Template for senior leadership with strategic focus',
     'leadership', 50.00, 50.00, 0.00, true, true, true, true, true,
     'weighted_average', 'simple_average', 'weighted_average', '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Technical Specialist Template', 'TECH_SPEC', 'Template for technical specialists and architects',
     'technical', 80.00, 20.00, 0.00, true, true, false, true, false,
     'weighted_average', 'simple_average', 'weighted_average', '2024-01-01', true,
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Assign competencies to appraisal templates
DO $$
DECLARE
    v_template RECORD;
    v_competency RECORD;
BEGIN
    -- Assign competencies to Standard Employee Template
    INSERT INTO appraisal_template_competency (
        appraisal_template_id, competency_id, competency_weight,
        is_mandatory, expected_proficiency_level, display_order, created_by
    )
    SELECT
        (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'STD_EMP'),
        cm.competency_id,
        CASE cm.competency_code
            WHEN 'TECH_EXPERT' THEN 25.00
            WHEN 'PROB_SOLVE' THEN 20.00
            WHEN 'COMMUNICATION' THEN 15.00
            WHEN 'TEAMWORK' THEN 15.00
            WHEN 'ADAPTABILITY' THEN 10.00
            WHEN 'INTEGRITY' THEN 10.00
            WHEN 'LEARNING' THEN 5.00
            ELSE 0.00
        END as competency_weight,
        CASE WHEN cm.is_mandatory THEN true ELSE false END,
        3, -- Expected level: Meets expectations
        cm.display_order,
        (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
    FROM competency_master cm
    WHERE cm.competency_code IN ('TECH_EXPERT', 'PROB_SOLVE', 'COMMUNICATION', 'TEAMWORK', 'ADAPTABILITY', 'INTEGRITY', 'LEARNING');

    -- Assign competencies to Manager Template
    INSERT INTO appraisal_template_competency (
        appraisal_template_id, competency_id, competency_weight,
        is_mandatory, expected_proficiency_level, display_order, created_by
    )
    SELECT
        (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'MGR_TMPL'),
        cm.competency_id,
        CASE cm.competency_code
            WHEN 'LEADERSHIP' THEN 25.00
            WHEN 'COMMUNICATION' THEN 20.00
            WHEN 'DECISION' THEN 15.00
            WHEN 'TEAMWORK' THEN 15.00
            WHEN 'TECH_EXPERT' THEN 10.00
            WHEN 'STRATEGIC' THEN 10.00
            WHEN 'INTEGRITY' THEN 5.00
            ELSE 0.00
        END as competency_weight,
        true,
        4, -- Expected level: Exceeds expectations
        cm.display_order,
        (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
    FROM competency_master cm
    WHERE cm.competency_code IN ('LEADERSHIP', 'COMMUNICATION', 'DECISION', 'TEAMWORK', 'TECH_EXPERT', 'STRATEGIC', 'INTEGRITY');

    -- Assign competencies to Senior Leadership Template
    INSERT INTO appraisal_template_competency (
        appraisal_template_id, competency_id, competency_weight,
        is_mandatory, expected_proficiency_level, display_order, created_by
    )
    SELECT
        (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'SR_LEAD'),
        cm.competency_id,
        CASE cm.competency_code
            WHEN 'STRATEGIC' THEN 30.00
            WHEN 'LEADERSHIP' THEN 25.00
            WHEN 'DECISION' THEN 20.00
            WHEN 'COMMUNICATION' THEN 15.00
            WHEN 'INNOVATION' THEN 10.00
            ELSE 0.00
        END as competency_weight,
        true,
        5, -- Expected level: Outstanding
        cm.display_order,
        (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
    FROM competency_master cm
    WHERE cm.competency_code IN ('STRATEGIC', 'LEADERSHIP', 'DECISION', 'COMMUNICATION', 'INNOVATION');

END $$;

-- =====================================================================================
-- SECTION 3: GOAL CATEGORIES AND EMPLOYEE GOALS
-- =====================================================================================

-- Create goal categories
INSERT INTO goal_category (
    company_master_id, category_name, category_code, description,
    default_weight, is_mandatory, display_order, color_code, created_by
) VALUES
    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Business Results', 'BUS_RESULTS', 'Goals related to business outcomes and deliverables',
     40.00, true, 1, '#007bff',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Quality & Excellence', 'QUALITY', 'Goals focused on quality improvement and operational excellence',
     25.00, true, 2, '#28a745',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Innovation & Process', 'INNOVATION', 'Goals related to innovation and process improvements',
     20.00, false, 3, '#ffc107',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')),

    ((SELECT company_master_id FROM company_master WHERE company_code = 'NXT001'),
     'Team Development', 'TEAM_DEV', 'Goals focused on team building and people development',
     15.00, false, 4, '#17a2b8',
     (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

-- Create employee goals for the annual cycle
DO $$
DECLARE
    v_employee RECORD;
    v_goal_count INTEGER;
    v_cycle_id UUID;
BEGIN
    -- Get the annual cycle ID
    SELECT appraisal_cycle_id INTO v_cycle_id
    FROM appraisal_cycle
    WHERE cycle_code = 'APR2024';

    -- Create goals for each employee
    FOR v_employee IN
        SELECT em.employee_master_id, em.employee_code, em.full_name,
               dm.department_name, dg.designation_name
        FROM employee_master em
        LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
        LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
        WHERE em.row_status = 1
        AND em.employment_status = 'active'
        ORDER BY em.created_at
        LIMIT 20
    LOOP
        v_goal_count := 0;

        -- Create Business Results goals
        INSERT INTO employee_goal (
            employee_master_id, appraisal_cycle_id, goal_category_id,
            goal_title, goal_description, success_criteria, measurement_method,
            target_value, unit_of_measurement, start_date, target_completion_date,
            goal_priority, goal_weight, goal_status, progress_percentage,
            manager_approved, self_rating, self_achievement_percentage,
            manager_rating, manager_achievement_percentage,
            final_rating, final_achievement_percentage, created_by
        ) VALUES
            (v_employee.employee_master_id, v_cycle_id,
             (SELECT goal_category_id FROM goal_category WHERE category_code = 'BUS_RESULTS'),
             CASE v_employee.department_name
                WHEN 'Software Development' THEN 'Deliver High-Quality Software Features'
                WHEN 'Quality Assurance' THEN 'Improve Testing Coverage and Quality'
                WHEN 'Human Resources' THEN 'Enhance Employee Engagement'
                WHEN 'Finance' THEN 'Optimize Financial Processes'
                ELSE 'Achieve Department KPIs'
             END,
             CASE v_employee.department_name
                WHEN 'Software Development' THEN 'Successfully deliver assigned software features on time with zero critical bugs and positive user feedback'
                WHEN 'Quality Assurance' THEN 'Increase test coverage to 90% and reduce production defects by 30%'
                WHEN 'Human Resources' THEN 'Achieve 85% employee satisfaction score and reduce attrition to below 10%'
                WHEN 'Finance' THEN 'Streamline financial reporting process and reduce month-end close time by 2 days'
                ELSE 'Meet or exceed all assigned KPIs and contribute to department success'
             END,
             'Measurable delivery of features/outcomes as per defined acceptance criteria',
             'Quantitative metrics and stakeholder feedback',
             CASE v_employee.department_name
                WHEN 'Software Development' THEN '100'
                WHEN 'Quality Assurance' THEN '90'
                WHEN 'Human Resources' THEN '85'
                WHEN 'Finance' THEN '2'
                ELSE '100'
             END,
             CASE v_employee.department_name
                WHEN 'Software Development' THEN 'Percentage'
                WHEN 'Quality Assurance' THEN 'Percentage'
                WHEN 'Human Resources' THEN 'Percentage'
                WHEN 'Finance' THEN 'Days'
                ELSE 'Percentage'
             END,
             '2024-01-01', '2024-12-31', 'high', 40.00, 'completed',
             CASE WHEN RANDOM() > 0.1 THEN 85 + (RANDOM() * 15)::INTEGER ELSE 60 + (RANDOM() * 25)::INTEGER END,
             true, 'meets'::performance_rating,
             CASE WHEN RANDOM() > 0.1 THEN 85 + (RANDOM() * 15)::INTEGER ELSE 60 + (RANDOM() * 25)::INTEGER END,
             CASE WHEN RANDOM() > 0.2 THEN 'meets'::performance_rating ELSE 'exceeds'::performance_rating END,
             CASE WHEN RANDOM() > 0.1 THEN 85 + (RANDOM() * 15)::INTEGER ELSE 60 + (RANDOM() * 25)::INTEGER END,
             CASE WHEN RANDOM() > 0.2 THEN 'meets'::performance_rating ELSE 'exceeds'::performance_rating END,
             CASE WHEN RANDOM() > 0.1 THEN 85 + (RANDOM() * 15)::INTEGER ELSE 60 + (RANDOM() * 25)::INTEGER END,
             (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

        -- Create Quality goals
        INSERT INTO employee_goal (
            employee_master_id, appraisal_cycle_id, goal_category_id,
            goal_title, goal_description, success_criteria, measurement_method,
            target_value, unit_of_measurement, start_date, target_completion_date,
            goal_priority, goal_weight, goal_status, progress_percentage,
            manager_approved, self_rating, self_achievement_percentage,
            manager_rating, manager_achievement_percentage,
            final_rating, final_achievement_percentage, created_by
        ) VALUES
            (v_employee.employee_master_id, v_cycle_id,
             (SELECT goal_category_id FROM goal_category WHERE category_code = 'QUALITY'),
             'Maintain Quality Standards', 'Ensure all deliverables meet quality standards with minimal rework',
             'Zero critical defects and customer complaints below threshold',
             'Defect metrics and customer feedback scores', '95', 'Percentage',
             '2024-01-01', '2024-12-31', 'medium', 25.00, 'completed',
             80 + (RANDOM() * 20)::INTEGER, true, 'meets'::performance_rating,
             80 + (RANDOM() * 20)::INTEGER, 'meets'::performance_rating,
             80 + (RANDOM() * 20)::INTEGER, 'meets'::performance_rating,
             80 + (RANDOM() * 20)::INTEGER,
             (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));

        -- Create Innovation goal (if applicable)
        IF RANDOM() > 0.3 THEN
            INSERT INTO employee_goal (
                employee_master_id, appraisal_cycle_id, goal_category_id,
                goal_title, goal_description, success_criteria, measurement_method,
                target_value, unit_of_measurement, start_date, target_completion_date,
                goal_priority, goal_weight, goal_status, progress_percentage,
                manager_approved, self_rating, self_achievement_percentage,
                manager_rating, manager_achievement_percentage,
                final_rating, final_achievement_percentage, created_by
            ) VALUES
                (v_employee.employee_master_id, v_cycle_id,
                 (SELECT goal_category_id FROM goal_category WHERE category_code = 'INNOVATION'),
                 'Process Improvement Initiative', 'Identify and implement process improvements to increase efficiency',
                 'Documented process improvement with measurable impact',
                 'Time/cost savings and efficiency metrics', '20', 'Percentage',
                 '2024-03-01', '2024-11-30', 'medium', 20.00, 'completed',
                 70 + (RANDOM() * 25)::INTEGER, true, 'meets'::performance_rating,
                 70 + (RANDOM() * 25)::INTEGER, 'meets'::performance_rating,
                 70 + (RANDOM() * 25)::INTEGER, 'meets'::performance_rating,
                 70 + (RANDOM() * 25)::INTEGER,
                 (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));
        END IF;

        -- Create Team Development goal (for managers)
        IF v_employee.designation_name LIKE '%Manager%' OR v_employee.designation_name LIKE '%Lead%' THEN
            INSERT INTO employee_goal (
                employee_master_id, appraisal_cycle_id, goal_category_id,
                goal_title, goal_description, success_criteria, measurement_method,
                target_value, unit_of_measurement, start_date, target_completion_date,
                goal_priority, goal_weight, goal_status, progress_percentage,
                manager_approved, self_rating, self_achievement_percentage,
                manager_rating, manager_achievement_percentage,
                final_rating, final_achievement_percentage, created_by
            ) VALUES
                (v_employee.employee_master_id, v_cycle_id,
                 (SELECT goal_category_id FROM goal_category WHERE category_code = 'TEAM_DEV'),
                 'Team Development & Mentoring', 'Develop team members through mentoring and skill building',
                 'Team member skill advancement and engagement scores',
                 'Team feedback and skill assessment scores', '80', 'Percentage',
                 '2024-01-01', '2024-12-31', 'medium', 15.00, 'completed',
                 75 + (RANDOM() * 20)::INTEGER, true, 'meets'::performance_rating,
                 75 + (RANDOM() * 20)::INTEGER, 'meets'::performance_rating,
                 75 + (RANDOM() * 20)::INTEGER, 'meets'::performance_rating,
                 75 + (RANDOM() * 20)::INTEGER,
                 (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com'));
        END IF;

    END LOOP;
END $$;

-- =====================================================================================
-- SECTION 4: EMPLOYEE APPRAISALS AND ASSESSMENTS
-- =====================================================================================

-- Create employee appraisal records for annual cycle
INSERT INTO employee_appraisal (
    employee_master_id, appraisal_cycle_id, appraisal_template_id,
    reporting_manager_id, hr_partner_id, appraisal_status,
    started_date, self_assessment_date, manager_review_date, completed_date,
    total_goals, completed_goals, self_overall_comments, manager_overall_comments,
    strengths, improvement_areas, development_plan, career_aspirations,
    training_recommendations, created_by
)
SELECT
    em.employee_master_id,
    (SELECT appraisal_cycle_id FROM appraisal_cycle WHERE cycle_code = 'APR2024'),
    CASE
        WHEN dg.designation_name IN ('Chief Executive Officer', 'Chief Technology Officer') THEN
            (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'SR_LEAD')
        WHEN dg.designation_name LIKE '%Manager%' OR dg.designation_name LIKE '%Director%' THEN
            (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'MGR_TMPL')
        WHEN dg.designation_name LIKE '%Architect%' OR dg.designation_name LIKE '%Lead%' THEN
            (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'TECH_SPEC')
        ELSE
            (SELECT appraisal_template_id FROM appraisal_template WHERE template_code = 'STD_EMP')
    END as template_id,
    CASE
        WHEN dg.designation_name NOT IN ('Chief Executive Officer') THEN
            (SELECT user_master_id FROM user_master WHERE email IN (
                'priya.sharma@nexustech.com', 'amit.kumar@nexustech.com',
                'rajesh.singh@nexustech.com', 'sneha.patel@nexustech.com'
            ) ORDER BY RANDOM() LIMIT 1)
        ELSE NULL
    END as reporting_manager_id,
    (SELECT user_master_id FROM user_master WHERE email = 'kavya.reddy@nexustech.com'),
    'completed'::appraisal_status,
    '2024-11-01 09:00:00'::TIMESTAMP,
    '2024-11-05 14:30:00'::TIMESTAMP,
    '2024-11-15 16:45:00'::TIMESTAMP,
    '2024-11-20 11:20:00'::TIMESTAMP,
    (SELECT COUNT(*) FROM employee_goal eg WHERE eg.employee_master_id = em.employee_master_id),
    (SELECT COUNT(*) FROM employee_goal eg WHERE eg.employee_master_id = em.employee_master_id AND eg.goal_status = 'completed'),
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'I have successfully achieved most of my goals this year and contributed significantly to team success. Looking forward to taking on more challenging responsibilities.'
        WHEN 1 THEN 'This year has been a great learning experience. I have met my targets and improved my technical skills. I would like to focus on leadership development next year.'
        ELSE 'I am proud of my accomplishments this year, particularly in process improvements and quality delivery. I believe I am ready for the next level of responsibility.'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Shows consistent performance and good technical skills. Demonstrates reliability and team collaboration. Recommended for skill advancement programs.'
        WHEN 1 THEN 'Strong performer with excellent problem-solving abilities. Takes initiative and mentors junior team members effectively. Ready for additional responsibilities.'
        ELSE 'Outstanding contributor with innovative approach to challenges. Exceeds expectations consistently and drives team performance. Recommended for promotion.'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Technical expertise, problem-solving, team collaboration, customer focus'
        WHEN 1 THEN 'Leadership potential, communication skills, innovative thinking, adaptability'
        ELSE 'Strategic thinking, mentoring abilities, process improvement, quality focus'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Time management, presentation skills, cross-functional collaboration'
        WHEN 1 THEN 'Advanced technical certifications, leadership training, industry knowledge'
        ELSE 'Strategic planning, stakeholder management, change management'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Enroll in leadership development program, attend industry conferences, pursue advanced certifications'
        WHEN 1 THEN 'Shadow senior leaders, take on project management roles, improve presentation skills'
        ELSE 'Participate in cross-functional projects, mentor junior team members, develop domain expertise'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Move into technical leadership role, contribute to architectural decisions'
        WHEN 1 THEN 'Progress to management position, lead larger teams and projects'
        ELSE 'Become subject matter expert, drive innovation initiatives'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Technical leadership training, advanced programming courses, system architecture'
        WHEN 1 THEN 'Management fundamentals, people leadership, strategic planning'
        ELSE 'Industry certifications, communication skills, project management'
    END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
WHERE em.row_status = 1
AND em.employment_status = 'active'
ORDER BY em.created_at
LIMIT 20;

-- Create competency assessments for each appraisal
INSERT INTO competency_assessment (
    employee_appraisal_id, competency_id, competency_weight, expected_level,
    self_rating, self_comments, manager_rating, manager_comments,
    final_rating, development_required, created_by
)
SELECT
    ea.employee_appraisal_id,
    atc.competency_id,
    atc.competency_weight,
    atc.expected_proficiency_level,
    CASE
        WHEN RANDOM() > 0.7 THEN atc.expected_proficiency_level + 1
        WHEN RANDOM() > 0.2 THEN atc.expected_proficiency_level
        ELSE atc.expected_proficiency_level - 1
    END as self_rating,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'I believe I have demonstrated strong capabilities in this area throughout the year'
        WHEN 1 THEN 'This is an area where I have shown consistent performance and growth'
        ELSE 'I have made significant progress in this competency and contributed effectively'
    END,
    CASE
        WHEN RANDOM() > 0.8 THEN atc.expected_proficiency_level + 1
        WHEN RANDOM() > 0.3 THEN atc.expected_proficiency_level
        ELSE atc.expected_proficiency_level - 1
    END as manager_rating,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Shows good proficiency and applies skills effectively in daily work'
        WHEN 1 THEN 'Demonstrates strong capabilities and mentors others in this area'
        ELSE 'Meets expectations and shows potential for further development'
    END,
    CASE
        WHEN RANDOM() > 0.8 THEN atc.expected_proficiency_level + 1
        WHEN RANDOM() > 0.3 THEN atc.expected_proficiency_level
        ELSE atc.expected_proficiency_level - 1
    END as final_rating,
    CASE WHEN RANDOM() > 0.7 THEN false ELSE true END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_appraisal ea
JOIN appraisal_template_competency atc ON ea.appraisal_template_id = atc.appraisal_template_id
WHERE ea.appraisal_status = 'completed';

-- =====================================================================================
-- SECTION 5: 360-DEGREE FEEDBACK SYSTEM
-- =====================================================================================

-- Create feedback providers for employees with 360-feedback enabled
INSERT INTO feedback_provider (
    employee_appraisal_id, provider_user_id, feedback_type,
    provider_name, provider_email, relationship_description,
    request_sent_date, feedback_submitted, submission_date, created_by
)
SELECT
    ea.employee_appraisal_id,
    um.user_master_id,
    CASE
        WHEN um.user_master_id = ea.reporting_manager_id THEN 'manager'::feedback_type
        WHEN RANDOM() > 0.5 THEN 'peer'::feedback_type
        ELSE 'subordinate'::feedback_type
    END as feedback_type,
    um.full_name,
    um.email,
    CASE
        WHEN um.user_master_id = ea.reporting_manager_id THEN 'Direct reporting manager'
        WHEN RANDOM() > 0.5 THEN 'Peer colleague in same department'
        ELSE 'Team member reporting to this employee'
    END,
    '2024-11-10 09:00:00'::TIMESTAMP,
    CASE WHEN RANDOM() > 0.2 THEN true ELSE false END,
    CASE WHEN RANDOM() > 0.2 THEN '2024-11-18 15:30:00'::TIMESTAMP ELSE NULL END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_appraisal ea
CROSS JOIN user_master um
JOIN appraisal_template at ON ea.appraisal_template_id = at.appraisal_template_id
WHERE at.enable_peer_feedback = true
AND um.row_status = 1
AND um.user_master_id != (SELECT user_master_id FROM user_master WHERE employee_master_id = ea.employee_master_id)
AND RANDOM() > 0.7 -- Only create feedback for some combinations
LIMIT 50;

-- Create feedback responses for submitted feedback
INSERT INTO feedback_response (
    feedback_provider_id, competency_id, competency_rating,
    specific_feedback, improvement_suggestions, positive_examples, created_by
)
SELECT
    fp.feedback_provider_id,
    ca.competency_id,
    3 + (RANDOM() * 2)::INTEGER as rating, -- Ratings between 3-5
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Demonstrates good proficiency and contributes effectively to team goals'
        WHEN 1 THEN 'Shows strong capabilities and is reliable in delivering quality work'
        ELSE 'Excellent skills and often goes beyond expectations to help others'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Could benefit from more proactive communication during project updates'
        WHEN 1 THEN 'Would recommend seeking opportunities to lead cross-functional initiatives'
        ELSE 'Consider taking on mentoring responsibilities to share expertise with junior members'
    END,
    CASE (RANDOM() * 3)::INTEGER
        WHEN 0 THEN 'Successfully led the quarterly project delivery with excellent stakeholder management'
        WHEN 1 THEN 'Provided valuable technical guidance during critical problem resolution'
        ELSE 'Demonstrated exceptional collaboration during the system migration project'
    END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM feedback_provider fp
JOIN employee_appraisal ea ON fp.employee_appraisal_id = ea.employee_appraisal_id
JOIN competency_assessment ca ON ea.employee_appraisal_id = ca.employee_appraisal_id
WHERE fp.feedback_submitted = true
AND RANDOM() > 0.3; -- Generate responses for 70% of competencies

-- =====================================================================================
-- SECTION 6: PERFORMANCE ANALYTICS
-- =====================================================================================

-- Create performance analytics for employees
INSERT INTO performance_analytics (
    employee_master_id, analysis_year, analysis_quarter,
    goal_achievement_trend, competency_growth_trend, overall_performance_trend,
    peer_group_percentile, improvement_velocity, retention_risk_score,
    promotion_readiness_score, leadership_potential_score,
    training_completion_rate, skill_gap_score, created_by
)
SELECT
    em.employee_master_id,
    2024,
    4, -- Q4 analysis
    75 + (RANDOM() * 25)::INTEGER as goal_achievement_trend,
    70 + (RANDOM() * 30)::INTEGER as competency_growth_trend,
    75 + (RANDOM() * 25)::INTEGER as overall_performance_trend,
    (RANDOM() * 100)::INTEGER as peer_group_percentile,
    CASE
        WHEN RANDOM() > 0.7 THEN 80 + (RANDOM() * 20)::INTEGER
        WHEN RANDOM() > 0.3 THEN 60 + (RANDOM() * 20)::INTEGER
        ELSE 40 + (RANDOM() * 20)::INTEGER
    END as improvement_velocity,
    CASE
        WHEN RANDOM() > 0.8 THEN 80 + (RANDOM() * 20)::INTEGER -- High risk
        WHEN RANDOM() > 0.5 THEN 40 + (RANDOM() * 40)::INTEGER -- Medium risk
        ELSE (RANDOM() * 40)::INTEGER -- Low risk
    END as retention_risk_score,
    CASE
        WHEN dg.designation_name LIKE '%Senior%' OR dg.designation_name LIKE '%Lead%' THEN
            70 + (RANDOM() * 30)::INTEGER
        WHEN dg.designation_name LIKE '%Manager%' THEN
            80 + (RANDOM() * 20)::INTEGER
        ELSE 50 + (RANDOM() * 30)::INTEGER
    END as promotion_readiness_score,
    CASE
        WHEN dg.designation_name IN ('Chief Executive Officer', 'Chief Technology Officer') THEN
            90 + (RANDOM() * 10)::INTEGER
        WHEN dg.designation_name LIKE '%Manager%' OR dg.designation_name LIKE '%Director%' THEN
            70 + (RANDOM() * 30)::INTEGER
        WHEN dg.designation_name LIKE '%Lead%' THEN
            60 + (RANDOM() * 30)::INTEGER
        ELSE 30 + (RANDOM() * 40)::INTEGER
    END as leadership_potential_score,
    80 + (RANDOM() * 20)::INTEGER as training_completion_rate,
    CASE
        WHEN RANDOM() > 0.6 THEN 20 + (RANDOM() * 30)::INTEGER -- Lower gap is better
        ELSE 30 + (RANDOM() * 50)::INTEGER
    END as skill_gap_score,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_master em
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
WHERE em.row_status = 1
AND em.employment_status = 'active'
ORDER BY em.created_at
LIMIT 20;

-- =====================================================================================
-- SECTION 7: GOAL PROGRESS UPDATES
-- =====================================================================================

-- Create goal progress updates throughout the year
INSERT INTO goal_progress_update (
    employee_goal_id, update_date, progress_percentage, current_value,
    progress_description, challenges_faced, support_required, created_by
)
SELECT
    eg.employee_goal_id,
    progress_data.update_date,
    progress_data.progress_percentage,
    CASE
        WHEN eg.unit_of_measurement = 'Percentage' THEN progress_data.progress_percentage::TEXT
        WHEN eg.unit_of_measurement = 'Days' THEN (progress_data.progress_percentage * 2 / 100)::TEXT
        ELSE progress_data.progress_percentage::TEXT
    END,
    CASE progress_data.quarter
        WHEN 1 THEN 'Good progress on initial planning and setup. Key milestones identified and resource allocation completed.'
        WHEN 2 THEN 'Steady progress with some early wins. Mid-course adjustments made based on initial feedback.'
        WHEN 3 THEN 'Strong momentum with major deliverables on track. Quality metrics looking positive.'
        ELSE 'Final push towards completion. Most objectives achieved with excellent quality standards.'
    END,
    CASE progress_data.quarter
        WHEN 1 THEN CASE WHEN RANDOM() > 0.7 THEN 'Resource constraints and competing priorities' ELSE NULL END
        WHEN 2 THEN CASE WHEN RANDOM() > 0.6 THEN 'Technical challenges and scope creep' ELSE NULL END
        WHEN 3 THEN CASE WHEN RANDOM() > 0.8 THEN 'Timeline pressures and stakeholder alignment' ELSE NULL END
        ELSE CASE WHEN RANDOM() > 0.9 THEN 'Final integration challenges' ELSE NULL END
    END,
    CASE progress_data.quarter
        WHEN 1 THEN CASE WHEN RANDOM() > 0.7 THEN 'Additional team members for peak workload' ELSE NULL END
        WHEN 2 THEN CASE WHEN RANDOM() > 0.6 THEN 'Technical consultation and training support' ELSE NULL END
        WHEN 3 THEN CASE WHEN RANDOM() > 0.8 THEN 'Stakeholder communication and change management' ELSE NULL END
        ELSE CASE WHEN RANDOM() > 0.9 THEN 'Extended timeline for quality assurance' ELSE NULL END
    END,
    (SELECT user_master_id FROM user_master WHERE email = 'ramesh.babu@nexustech.com')
FROM employee_goal eg
CROSS JOIN (
    VALUES
        ('2024-03-31', 25, 1),
        ('2024-06-30', 50, 2),
        ('2024-09-30', 75, 3),
        ('2024-12-15', 95, 4)
) AS progress_data(update_date, progress_percentage, quarter)
WHERE eg.goal_status = 'completed'
AND RANDOM() > 0.3; -- Create updates for 70% of goals

-- =====================================================================================
-- SECTION 8: VERIFICATION QUERIES AND STATISTICS
-- =====================================================================================

-- Summary statistics for verification
SELECT
    'Total Competencies Configured' as metric,
    COUNT(*) as count
FROM competency_master
WHERE is_active = true

UNION ALL

SELECT
    'Total Appraisal Cycles' as metric,
    COUNT(*) as count
FROM appraisal_cycle

UNION ALL

SELECT
    'Total Employee Goals' as metric,
    COUNT(*) as count
FROM employee_goal

UNION ALL

SELECT
    'Total Employee Appraisals' as metric,
    COUNT(*) as count
FROM employee_appraisal

UNION ALL

SELECT
    'Total Competency Assessments' as metric,
    COUNT(*) as count
FROM competency_assessment

UNION ALL

SELECT
    'Total 360-Feedback Providers' as metric,
    COUNT(*) as count
FROM feedback_provider

UNION ALL

SELECT
    'Total Goal Progress Updates' as metric,
    COUNT(*) as count
FROM goal_progress_update;

-- Competency distribution by type
SELECT
    'Competency Distribution by Type' as category,
    competency_type,
    COUNT(*) as count,
    ROUND(AVG(CASE WHEN applies_to_all THEN 100 ELSE 50 END), 2) as avg_applicability
FROM competency_master
WHERE is_active = true
GROUP BY competency_type
ORDER BY count DESC;

-- Appraisal completion summary
SELECT
    'Appraisal Status Distribution' as category,
    appraisal_status,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) as percentage
FROM employee_appraisal
GROUP BY appraisal_status
ORDER BY count DESC;

-- Goal achievement analysis
SELECT
    'Goal Achievement by Category' as category,
    gc.category_name,
    COUNT(eg.employee_goal_id) as total_goals,
    COUNT(CASE WHEN eg.goal_status = 'completed' THEN 1 END) as completed_goals,
    ROUND(AVG(eg.final_achievement_percentage), 2) as avg_achievement,
    ROUND(AVG(eg.goal_weight), 2) as avg_weight
FROM goal_category gc
LEFT JOIN employee_goal eg ON gc.goal_category_id = eg.goal_category_id
GROUP BY gc.goal_category_id, gc.category_name
ORDER BY avg_achievement DESC;

-- Performance rating distribution
SELECT
    'Performance Rating Distribution' as category,
    final_rating,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()), 2) as percentage,
    ROUND(AVG(overall_score), 2) as avg_score
FROM employee_appraisal
WHERE final_rating IS NOT NULL
GROUP BY final_rating
ORDER BY
    CASE final_rating
        WHEN 'outstanding' THEN 5
        WHEN 'exceeds' THEN 4
        WHEN 'meets' THEN 3
        WHEN 'below' THEN 2
        WHEN 'unsatisfactory' THEN 1
    END DESC;

-- Top performers summary
SELECT
    'Top Performers (Overall Score > 85)' as category,
    em.employee_code,
    em.full_name,
    dm.department_name,
    ea.overall_score,
    ea.goal_achievement_score,
    ea.competency_score,
    ea.final_rating
FROM employee_appraisal ea
JOIN employee_master em ON ea.employee_master_id = em.employee_master_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
WHERE ea.overall_score > 85
ORDER BY ea.overall_score DESC
LIMIT 10;

-- 360-feedback participation rates
SELECT
    '360-Feedback Participation' as category,
    feedback_type,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN feedback_submitted THEN 1 END) as submitted_feedback,
    ROUND((COUNT(CASE WHEN feedback_submitted THEN 1 END) * 100.0 / COUNT(*)), 2) as participation_rate
FROM feedback_provider
GROUP BY feedback_type
ORDER BY participation_rate DESC;

-- =====================================================================================
-- END OF PERFORMANCE MANAGEMENT SAMPLE DATA
-- =====================================================================================