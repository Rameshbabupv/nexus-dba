-- =====================================================================================
-- NEXUS HRMS - Performance Management Module
-- PostgreSQL Schema for Appraisals, Goal Setting, KRAs, and 360-Degree Feedback
-- =====================================================================================
-- Migration from: MongoDB MEAN Stack to PostgreSQL NEXUS Architecture
-- Phase: 7 - Performance Management Core Tables
-- Dependencies: Employee Master, Organizational Structure, Payroll Management
-- =====================================================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================================
-- SECTION 1: ENUMS AND CUSTOM TYPES
-- =====================================================================================

-- Performance rating scale
CREATE TYPE performance_rating AS ENUM (
    'outstanding',      -- 5 - Exceeds expectations significantly
    'exceeds',          -- 4 - Exceeds expectations
    'meets',            -- 3 - Meets expectations
    'below',            -- 2 - Below expectations
    'unsatisfactory'    -- 1 - Unsatisfactory performance
);

-- Goal/KRA status
CREATE TYPE goal_status AS ENUM (
    'draft',
    'active',
    'in_progress',
    'completed',
    'overdue',
    'cancelled',
    'deferred'
);

-- Appraisal cycle status
CREATE TYPE appraisal_cycle_status AS ENUM (
    'planning',
    'goal_setting',
    'mid_review',
    'final_review',
    'completed',
    'cancelled'
);

-- Appraisal status for individual employees
CREATE TYPE appraisal_status AS ENUM (
    'not_started',
    'self_assessment',
    'manager_review',
    'skip_level_review',
    'hr_review',
    'completed',
    'approved',
    'rejected'
);

-- Feedback type
CREATE TYPE feedback_type AS ENUM (
    'self',
    'manager',
    'peer',
    'subordinate',
    'skip_level',
    'customer',
    'hr'
);

-- Goal priority
CREATE TYPE goal_priority AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

-- Competency type
CREATE TYPE competency_type AS ENUM (
    'technical',
    'behavioral',
    'leadership',
    'functional',
    'core_values'
);

-- =====================================================================================
-- SECTION 2: PERFORMANCE FRAMEWORK SETUP
-- =====================================================================================

-- Performance competency master
CREATE TABLE competency_master (
    competency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Competency details
    competency_name VARCHAR(100) NOT NULL,
    competency_code VARCHAR(20) NOT NULL,
    competency_type competency_type NOT NULL,
    description TEXT,

    -- Competency definition
    definition TEXT,
    behavioral_indicators TEXT,

    -- Level specifications
    level_1_description TEXT, -- Basic level
    level_2_description TEXT, -- Intermediate level
    level_3_description TEXT, -- Advanced level
    level_4_description TEXT, -- Expert level
    level_5_description TEXT, -- Master level

    -- Applicability
    applies_to_all BOOLEAN DEFAULT true,
    is_mandatory BOOLEAN DEFAULT false,

    -- Display and processing
    display_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_to DATE,

    -- Audit fields
    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, competency_code)
);

-- Competency applicability (role-based competencies)
CREATE TABLE competency_applicability (
    competency_applicability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    competency_id UUID NOT NULL REFERENCES competency_master(competency_id),

    -- Applicability criteria
    applies_to_all BOOLEAN DEFAULT false,

    -- Organizational filters
    division_master_id UUID REFERENCES division_master(division_master_id),
    department_master_id UUID REFERENCES department_master(department_master_id),
    designation_master_id UUID REFERENCES designation_master(designation_master_id),
    employee_category_id UUID REFERENCES employee_category(employee_category_id),
    employee_group_id UUID REFERENCES employee_group(employee_group_id),
    employee_grade_id UUID REFERENCES employee_grade(employee_grade_id),

    -- Specific employee assignment
    employee_master_id UUID REFERENCES employee_master(employee_master_id),

    -- Weight and importance
    competency_weight DECIMAL(5,2) DEFAULT 100.00,
    is_mandatory BOOLEAN DEFAULT false,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Performance rating scale configuration
CREATE TABLE performance_rating_scale (
    performance_rating_scale_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Rating configuration
    scale_name VARCHAR(50) NOT NULL,
    scale_description TEXT,

    -- Rating levels
    rating_value INTEGER NOT NULL, -- 1-5
    rating_label VARCHAR(50) NOT NULL,
    rating_description TEXT,
    rating_color VARCHAR(7), -- Hex color code

    -- Score ranges
    min_score DECIMAL(5,2) NOT NULL,
    max_score DECIMAL(5,2) NOT NULL,

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
-- SECTION 3: APPRAISAL CYCLES AND PERIODS
-- =====================================================================================

-- Performance appraisal cycles
CREATE TABLE appraisal_cycle (
    appraisal_cycle_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Cycle identification
    cycle_name VARCHAR(100) NOT NULL,
    cycle_code VARCHAR(20) NOT NULL,
    cycle_year INTEGER NOT NULL,
    cycle_type VARCHAR(50) DEFAULT 'annual', -- annual, half_yearly, quarterly

    -- Cycle periods
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE NOT NULL,
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,

    -- Goal setting period
    goal_setting_start_date DATE,
    goal_setting_end_date DATE,

    -- Mid-cycle review (if applicable)
    mid_review_start_date DATE,
    mid_review_end_date DATE,

    -- Final review period
    final_review_start_date DATE NOT NULL,
    final_review_end_date DATE NOT NULL,

    -- Cycle configuration
    is_goal_setting_enabled BOOLEAN DEFAULT true,
    is_mid_review_enabled BOOLEAN DEFAULT true,
    is_360_feedback_enabled BOOLEAN DEFAULT false,
    is_self_assessment_mandatory BOOLEAN DEFAULT true,

    -- Weightages
    goal_achievement_weight DECIMAL(5,2) DEFAULT 70.00,
    competency_weight DECIMAL(5,2) DEFAULT 30.00,

    -- Status and processing
    cycle_status appraisal_cycle_status DEFAULT 'planning',
    is_published BOOLEAN DEFAULT false,
    published_date TIMESTAMP,

    -- Participation
    total_eligible_employees INTEGER DEFAULT 0,
    total_participating_employees INTEGER DEFAULT 0,
    completed_appraisals INTEGER DEFAULT 0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, cycle_code)
);

-- Appraisal template master
CREATE TABLE appraisal_template (
    appraisal_template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Template identification
    template_name VARCHAR(100) NOT NULL,
    template_code VARCHAR(20) NOT NULL,
    description TEXT,

    -- Template configuration
    template_type VARCHAR(50) DEFAULT 'standard', -- standard, leadership, technical, sales

    -- Section weights
    goals_section_weight DECIMAL(5,2) DEFAULT 70.00,
    competency_section_weight DECIMAL(5,2) DEFAULT 30.00,
    additional_section_weight DECIMAL(5,2) DEFAULT 0.00,

    -- Review settings
    enable_self_assessment BOOLEAN DEFAULT true,
    enable_manager_assessment BOOLEAN DEFAULT true,
    enable_skip_level_review BOOLEAN DEFAULT false,
    enable_peer_feedback BOOLEAN DEFAULT false,
    enable_subordinate_feedback BOOLEAN DEFAULT false,

    -- Scoring methodology
    goal_scoring_method VARCHAR(50) DEFAULT 'weighted_average',
    competency_scoring_method VARCHAR(50) DEFAULT 'simple_average',
    overall_scoring_method VARCHAR(50) DEFAULT 'weighted_average',

    -- Effective period
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, template_code)
);

-- Appraisal template competencies
CREATE TABLE appraisal_template_competency (
    appraisal_template_competency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appraisal_template_id UUID NOT NULL REFERENCES appraisal_template(appraisal_template_id),
    competency_id UUID NOT NULL REFERENCES competency_master(competency_id),

    -- Competency configuration in template
    competency_weight DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    is_mandatory BOOLEAN DEFAULT true,
    expected_proficiency_level INTEGER DEFAULT 3, -- 1-5 scale

    -- Display order
    display_order INTEGER DEFAULT 1,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(appraisal_template_id, competency_id)
);

-- =====================================================================================
-- SECTION 4: GOALS AND KRA MANAGEMENT
-- =====================================================================================

-- Employee goal categories
CREATE TABLE goal_category (
    goal_category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_master_id UUID NOT NULL REFERENCES company_master(company_master_id),

    -- Category details
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(20) NOT NULL,
    description TEXT,

    -- Category configuration
    default_weight DECIMAL(5,2) DEFAULT 100.00,
    is_mandatory BOOLEAN DEFAULT false,

    -- Display
    display_order INTEGER DEFAULT 1,
    color_code VARCHAR(7), -- Hex color

    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(company_master_id, category_code)
);

-- Employee goals and KRAs
CREATE TABLE employee_goal (
    employee_goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    appraisal_cycle_id UUID NOT NULL REFERENCES appraisal_cycle(appraisal_cycle_id),
    goal_category_id UUID REFERENCES goal_category(goal_category_id),

    -- Goal identification
    goal_title VARCHAR(200) NOT NULL,
    goal_description TEXT NOT NULL,

    -- Goal metrics
    success_criteria TEXT,
    measurement_method VARCHAR(100),
    target_value VARCHAR(100),
    unit_of_measurement VARCHAR(50),

    -- Goal timeline
    start_date DATE NOT NULL,
    target_completion_date DATE NOT NULL,
    actual_completion_date DATE,

    -- Goal classification
    goal_priority goal_priority DEFAULT 'medium',
    goal_weight DECIMAL(5,2) NOT NULL DEFAULT 100.00,

    -- Progress tracking
    goal_status goal_status DEFAULT 'draft',
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    current_value VARCHAR(100),

    -- Review and approval
    manager_approved BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES user_master(user_master_id),
    approval_date TIMESTAMP,
    approval_comments TEXT,

    -- Self-assessment
    self_rating performance_rating,
    self_achievement_percentage DECIMAL(5,2),
    self_comments TEXT,

    -- Manager assessment
    manager_rating performance_rating,
    manager_achievement_percentage DECIMAL(5,2),
    manager_comments TEXT,

    -- Final rating
    final_rating performance_rating,
    final_achievement_percentage DECIMAL(5,2),
    weighted_score DECIMAL(8,4),

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Goal progress updates
CREATE TABLE goal_progress_update (
    goal_progress_update_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_goal_id UUID NOT NULL REFERENCES employee_goal(employee_goal_id),

    -- Progress details
    update_date DATE NOT NULL,
    progress_percentage DECIMAL(5,2) NOT NULL,
    current_value VARCHAR(100),

    -- Update description
    progress_description TEXT,
    challenges_faced TEXT,
    support_required TEXT,

    -- Attachments
    has_attachments BOOLEAN DEFAULT false,
    attachment_count INTEGER DEFAULT 0,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- =====================================================================================
-- SECTION 5: APPRAISAL EXECUTION AND REVIEWS
-- =====================================================================================

-- Employee appraisal records
CREATE TABLE employee_appraisal (
    employee_appraisal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),
    appraisal_cycle_id UUID NOT NULL REFERENCES appraisal_cycle(appraisal_cycle_id),
    appraisal_template_id UUID NOT NULL REFERENCES appraisal_template(appraisal_template_id),

    -- Reporting hierarchy
    reporting_manager_id UUID REFERENCES user_master(user_master_id),
    skip_level_manager_id UUID REFERENCES user_master(user_master_id),
    hr_partner_id UUID REFERENCES user_master(user_master_id),

    -- Appraisal status
    appraisal_status appraisal_status DEFAULT 'not_started',

    -- Timeline tracking
    started_date TIMESTAMP,
    self_assessment_date TIMESTAMP,
    manager_review_date TIMESTAMP,
    skip_level_review_date TIMESTAMP,
    hr_review_date TIMESTAMP,
    completed_date TIMESTAMP,
    approved_date TIMESTAMP,

    -- Overall scores
    total_goals INTEGER DEFAULT 0,
    completed_goals INTEGER DEFAULT 0,
    goal_achievement_score DECIMAL(8,4) DEFAULT 0,
    competency_score DECIMAL(8,4) DEFAULT 0,
    overall_score DECIMAL(8,4) DEFAULT 0,
    final_rating performance_rating,

    -- Comments and feedback
    self_overall_comments TEXT,
    manager_overall_comments TEXT,
    skip_level_comments TEXT,
    hr_comments TEXT,
    final_comments TEXT,

    -- Development planning
    strengths TEXT,
    improvement_areas TEXT,
    development_plan TEXT,
    career_aspirations TEXT,
    training_recommendations TEXT,

    -- Salary and promotion recommendations
    salary_increase_recommended BOOLEAN DEFAULT false,
    recommended_salary_increase_percentage DECIMAL(5,2),
    promotion_recommended BOOLEAN DEFAULT false,
    recommended_designation_id UUID REFERENCES designation_master(designation_master_id),

    -- Processing flags
    is_calibrated BOOLEAN DEFAULT false,
    calibration_date TIMESTAMP,
    calibrated_by UUID REFERENCES user_master(user_master_id),

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, appraisal_cycle_id)
);

-- Competency assessments
CREATE TABLE competency_assessment (
    competency_assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_appraisal_id UUID NOT NULL REFERENCES employee_appraisal(employee_appraisal_id),
    competency_id UUID NOT NULL REFERENCES competency_master(competency_id),

    -- Assessment details
    competency_weight DECIMAL(5,2) NOT NULL,
    expected_level INTEGER NOT NULL, -- 1-5 scale

    -- Self-assessment
    self_rating INTEGER, -- 1-5 scale
    self_comments TEXT,

    -- Manager assessment
    manager_rating INTEGER, -- 1-5 scale
    manager_comments TEXT,

    -- Skip-level assessment
    skip_level_rating INTEGER, -- 1-5 scale
    skip_level_comments TEXT,

    -- Final assessment
    final_rating INTEGER, -- 1-5 scale
    weighted_score DECIMAL(8,4),
    development_required BOOLEAN DEFAULT false,
    development_action_plan TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_appraisal_id, competency_id)
);

-- =====================================================================================
-- SECTION 6: 360-DEGREE FEEDBACK SYSTEM
-- =====================================================================================

-- Feedback providers setup
CREATE TABLE feedback_provider (
    feedback_provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_appraisal_id UUID NOT NULL REFERENCES employee_appraisal(employee_appraisal_id),
    provider_user_id UUID NOT NULL REFERENCES user_master(user_master_id),

    -- Provider details
    feedback_type feedback_type NOT NULL,
    provider_name VARCHAR(100),
    provider_email VARCHAR(100),
    provider_designation VARCHAR(100),
    relationship_description TEXT,

    -- Feedback request
    request_sent_date TIMESTAMP,
    reminder_count INTEGER DEFAULT 0,
    last_reminder_date TIMESTAMP,

    -- Feedback submission
    feedback_submitted BOOLEAN DEFAULT false,
    submission_date TIMESTAMP,

    -- Status
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- 360-degree feedback responses
CREATE TABLE feedback_response (
    feedback_response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feedback_provider_id UUID NOT NULL REFERENCES feedback_provider(feedback_provider_id),
    competency_id UUID NOT NULL REFERENCES competency_master(competency_id),

    -- Rating and feedback
    competency_rating INTEGER NOT NULL, -- 1-5 scale
    specific_feedback TEXT,
    improvement_suggestions TEXT,

    -- Behavioral examples
    positive_examples TEXT,
    development_examples TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- 360-degree feedback summary
CREATE TABLE feedback_summary (
    feedback_summary_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_appraisal_id UUID NOT NULL REFERENCES employee_appraisal(employee_appraisal_id),
    competency_id UUID NOT NULL REFERENCES competency_master(competency_id),

    -- Response statistics
    total_responses INTEGER DEFAULT 0,
    manager_responses INTEGER DEFAULT 0,
    peer_responses INTEGER DEFAULT 0,
    subordinate_responses INTEGER DEFAULT 0,
    customer_responses INTEGER DEFAULT 0,

    -- Average ratings
    average_rating DECIMAL(4,2),
    manager_average_rating DECIMAL(4,2),
    peer_average_rating DECIMAL(4,2),
    subordinate_average_rating DECIMAL(4,2),
    customer_average_rating DECIMAL(4,2),

    -- Feedback themes
    common_strengths TEXT,
    common_development_areas TEXT,
    key_feedback_themes TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_appraisal_id, competency_id)
);

-- =====================================================================================
-- SECTION 7: PERFORMANCE ANALYTICS AND REPORTING
-- =====================================================================================

-- Performance calibration sessions
CREATE TABLE performance_calibration (
    performance_calibration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appraisal_cycle_id UUID NOT NULL REFERENCES appraisal_cycle(appraisal_cycle_id),

    -- Calibration session details
    calibration_name VARCHAR(100) NOT NULL,
    calibration_date DATE NOT NULL,
    department_master_id UUID REFERENCES department_master(department_master_id),

    -- Participants
    calibration_chair_id UUID NOT NULL REFERENCES user_master(user_master_id),
    hr_representative_id UUID REFERENCES user_master(user_master_id),

    -- Calibration results
    total_employees_reviewed INTEGER DEFAULT 0,
    rating_adjustments_made INTEGER DEFAULT 0,

    -- Status
    calibration_status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, in_progress, completed
    completion_date TIMESTAMP,

    -- Notes
    session_notes TEXT,
    key_decisions TEXT,

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1
);

-- Performance trends and analytics
CREATE TABLE performance_analytics (
    performance_analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_master_id UUID NOT NULL REFERENCES employee_master(employee_master_id),

    -- Performance period
    analysis_year INTEGER NOT NULL,
    analysis_quarter INTEGER,

    -- Performance metrics
    goal_achievement_trend DECIMAL(5,2),
    competency_growth_trend DECIMAL(5,2),
    overall_performance_trend DECIMAL(5,2),

    -- Comparative metrics
    peer_group_percentile DECIMAL(5,2),
    department_ranking INTEGER,
    improvement_velocity DECIMAL(5,2),

    -- Predictive indicators
    retention_risk_score DECIMAL(5,2),
    promotion_readiness_score DECIMAL(5,2),
    leadership_potential_score DECIMAL(5,2),

    -- Development tracking
    training_completion_rate DECIMAL(5,2),
    skill_gap_score DECIMAL(5,2),
    career_progression_score DECIMAL(5,2),

    created_by UUID NOT NULL REFERENCES user_master(user_master_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES user_master(user_master_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_status INTEGER DEFAULT 1,

    UNIQUE(employee_master_id, analysis_year, analysis_quarter)
);

-- =====================================================================================
-- SECTION 8: INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================================================

-- Competency and framework indexes
CREATE INDEX idx_competency_master_company ON competency_master(company_master_id);
CREATE INDEX idx_competency_master_type ON competency_master(competency_type);
CREATE INDEX idx_competency_applicability_competency ON competency_applicability(competency_id);
CREATE INDEX idx_performance_rating_scale_company ON performance_rating_scale(company_master_id);

-- Appraisal cycle indexes
CREATE INDEX idx_appraisal_cycle_company ON appraisal_cycle(company_master_id);
CREATE INDEX idx_appraisal_cycle_year ON appraisal_cycle(cycle_year);
CREATE INDEX idx_appraisal_cycle_status ON appraisal_cycle(cycle_status);
CREATE INDEX idx_appraisal_template_company ON appraisal_template(company_master_id);
CREATE INDEX idx_appraisal_template_competency_template ON appraisal_template_competency(appraisal_template_id);

-- Goal management indexes
CREATE INDEX idx_goal_category_company ON goal_category(company_master_id);
CREATE INDEX idx_employee_goal_employee ON employee_goal(employee_master_id);
CREATE INDEX idx_employee_goal_cycle ON employee_goal(appraisal_cycle_id);
CREATE INDEX idx_employee_goal_status ON employee_goal(goal_status);
CREATE INDEX idx_goal_progress_update_goal ON goal_progress_update(employee_goal_id);

-- Appraisal execution indexes
CREATE INDEX idx_employee_appraisal_employee ON employee_appraisal(employee_master_id);
CREATE INDEX idx_employee_appraisal_cycle ON employee_appraisal(appraisal_cycle_id);
CREATE INDEX idx_employee_appraisal_status ON employee_appraisal(appraisal_status);
CREATE INDEX idx_employee_appraisal_manager ON employee_appraisal(reporting_manager_id);
CREATE INDEX idx_competency_assessment_appraisal ON competency_assessment(employee_appraisal_id);

-- 360-feedback indexes
CREATE INDEX idx_feedback_provider_appraisal ON feedback_provider(employee_appraisal_id);
CREATE INDEX idx_feedback_provider_user ON feedback_provider(provider_user_id);
CREATE INDEX idx_feedback_response_provider ON feedback_response(feedback_provider_id);
CREATE INDEX idx_feedback_summary_appraisal ON feedback_summary(employee_appraisal_id);

-- Analytics indexes
CREATE INDEX idx_performance_calibration_cycle ON performance_calibration(appraisal_cycle_id);
CREATE INDEX idx_performance_analytics_employee ON performance_analytics(employee_master_id);
CREATE INDEX idx_performance_analytics_year ON performance_analytics(analysis_year);

-- =====================================================================================
-- SECTION 9: TRIGGERS AND BUSINESS LOGIC FUNCTIONS
-- =====================================================================================

-- Function to calculate goal achievement score
CREATE OR REPLACE FUNCTION calculate_goal_achievement_score(p_employee_appraisal_id UUID)
RETURNS DECIMAL(8,4) AS $$
DECLARE
    v_total_weighted_score DECIMAL(12,4) := 0;
    v_total_weight DECIMAL(8,2) := 0;
    v_goal_record RECORD;
BEGIN
    -- Calculate weighted average of all goals
    FOR v_goal_record IN
        SELECT
            goal_weight,
            CASE
                WHEN final_achievement_percentage IS NOT NULL THEN final_achievement_percentage
                WHEN manager_achievement_percentage IS NOT NULL THEN manager_achievement_percentage
                WHEN self_achievement_percentage IS NOT NULL THEN self_achievement_percentage
                ELSE 0
            END as achievement_percentage
        FROM employee_goal eg
        JOIN employee_appraisal ea ON eg.employee_master_id = ea.employee_master_id
            AND eg.appraisal_cycle_id = ea.appraisal_cycle_id
        WHERE ea.employee_appraisal_id = p_employee_appraisal_id
        AND eg.goal_status != 'cancelled'
    LOOP
        v_total_weighted_score := v_total_weighted_score +
            (v_goal_record.goal_weight * v_goal_record.achievement_percentage / 100);
        v_total_weight := v_total_weight + v_goal_record.goal_weight;
    END LOOP;

    -- Return weighted average score
    IF v_total_weight > 0 THEN
        RETURN ROUND(v_total_weighted_score / v_total_weight, 4);
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate competency score
CREATE OR REPLACE FUNCTION calculate_competency_score(p_employee_appraisal_id UUID)
RETURNS DECIMAL(8,4) AS $$
DECLARE
    v_total_weighted_score DECIMAL(12,4) := 0;
    v_total_weight DECIMAL(8,2) := 0;
    v_competency_record RECORD;
BEGIN
    -- Calculate weighted average of all competencies
    FOR v_competency_record IN
        SELECT
            competency_weight,
            CASE
                WHEN final_rating IS NOT NULL THEN final_rating
                WHEN manager_rating IS NOT NULL THEN manager_rating
                WHEN self_rating IS NOT NULL THEN self_rating
                ELSE 3 -- Default to meets expectations
            END as rating_value
        FROM competency_assessment
        WHERE employee_appraisal_id = p_employee_appraisal_id
    LOOP
        v_total_weighted_score := v_total_weighted_score +
            (v_competency_record.competency_weight * v_competency_record.rating_value * 20); -- Convert 1-5 scale to percentage
        v_total_weight := v_total_weight + v_competency_record.competency_weight;
    END LOOP;

    -- Return weighted average score
    IF v_total_weight > 0 THEN
        RETURN ROUND(v_total_weighted_score / v_total_weight, 4);
    ELSE
        RETURN 60; -- Default score
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to update overall appraisal scores
CREATE OR REPLACE FUNCTION update_appraisal_scores()
RETURNS TRIGGER AS $$
DECLARE
    v_goal_score DECIMAL(8,4);
    v_competency_score DECIMAL(8,4);
    v_overall_score DECIMAL(8,4);
    v_template_record RECORD;
BEGIN
    -- Get template weights
    SELECT
        goals_section_weight,
        competency_section_weight
    INTO v_template_record
    FROM appraisal_template
    WHERE appraisal_template_id = NEW.appraisal_template_id;

    -- Calculate goal achievement score
    v_goal_score := calculate_goal_achievement_score(NEW.employee_appraisal_id);

    -- Calculate competency score
    v_competency_score := calculate_competency_score(NEW.employee_appraisal_id);

    -- Calculate overall score
    v_overall_score := ROUND(
        (v_goal_score * v_template_record.goals_section_weight / 100) +
        (v_competency_score * v_template_record.competency_section_weight / 100),
        4
    );

    -- Update appraisal record
    UPDATE employee_appraisal SET
        goal_achievement_score = v_goal_score,
        competency_score = v_competency_score,
        overall_score = v_overall_score,
        final_rating = CASE
            WHEN v_overall_score >= 90 THEN 'outstanding'::performance_rating
            WHEN v_overall_score >= 80 THEN 'exceeds'::performance_rating
            WHEN v_overall_score >= 60 THEN 'meets'::performance_rating
            WHEN v_overall_score >= 40 THEN 'below'::performance_rating
            ELSE 'unsatisfactory'::performance_rating
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE employee_appraisal_id = NEW.employee_appraisal_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update scores when goals or competencies are updated
CREATE TRIGGER trigger_update_goal_scores
    AFTER INSERT OR UPDATE ON employee_goal
    FOR EACH ROW
    EXECUTE FUNCTION update_appraisal_scores();

CREATE TRIGGER trigger_update_competency_scores
    AFTER INSERT OR UPDATE ON competency_assessment
    FOR EACH ROW
    EXECUTE FUNCTION update_appraisal_scores();

-- Function to auto-assign competencies to appraisal
CREATE OR REPLACE FUNCTION assign_competencies_to_appraisal(
    p_employee_appraisal_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_appraisal_record RECORD;
    v_competency_record RECORD;
    v_assigned_count INTEGER := 0;
BEGIN
    -- Get appraisal details
    SELECT ea.*, em.department_master_id, em.designation_master_id, em.employee_grade_id
    INTO v_appraisal_record
    FROM employee_appraisal ea
    JOIN employee_master em ON ea.employee_master_id = em.employee_master_id
    WHERE ea.employee_appraisal_id = p_employee_appraisal_id;

    -- Assign template competencies
    FOR v_competency_record IN
        SELECT atc.competency_id, atc.competency_weight, atc.expected_proficiency_level
        FROM appraisal_template_competency atc
        WHERE atc.appraisal_template_id = v_appraisal_record.appraisal_template_id
    LOOP
        INSERT INTO competency_assessment (
            employee_appraisal_id,
            competency_id,
            competency_weight,
            expected_level,
            created_by
        ) VALUES (
            p_employee_appraisal_id,
            v_competency_record.competency_id,
            v_competency_record.competency_weight,
            v_competency_record.expected_proficiency_level,
            (SELECT user_master_id FROM user_master WHERE email = 'system@nexushrms.com' LIMIT 1)
        );

        v_assigned_count := v_assigned_count + 1;
    END LOOP;

    RETURN v_assigned_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- SECTION 10: UTILITY VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- View for active appraisal cycles
CREATE VIEW active_appraisal_cycles AS
SELECT
    ac.appraisal_cycle_id,
    ac.cycle_name,
    ac.cycle_code,
    ac.cycle_year,
    ac.cycle_type,
    ac.cycle_start_date,
    ac.cycle_end_date,
    ac.cycle_status,
    ac.total_eligible_employees,
    ac.total_participating_employees,
    ac.completed_appraisals,
    ROUND((ac.completed_appraisals::DECIMAL / NULLIF(ac.total_participating_employees, 0)) * 100, 2) as completion_percentage
FROM appraisal_cycle ac
WHERE ac.cycle_status IN ('goal_setting', 'mid_review', 'final_review')
AND ac.row_status = 1
ORDER BY ac.cycle_year DESC, ac.cycle_start_date DESC;

-- View for employee appraisal dashboard
CREATE VIEW employee_appraisal_dashboard AS
SELECT
    ea.employee_appraisal_id,
    ea.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    dg.designation_name,
    ac.cycle_name,
    ac.cycle_year,
    ea.appraisal_status,
    ea.goal_achievement_score,
    ea.competency_score,
    ea.overall_score,
    ea.final_rating,
    ea.completed_date,
    mg.full_name as manager_name,
    CASE
        WHEN ea.appraisal_status = 'completed' THEN 100
        WHEN ea.appraisal_status = 'hr_review' THEN 90
        WHEN ea.appraisal_status = 'skip_level_review' THEN 80
        WHEN ea.appraisal_status = 'manager_review' THEN 60
        WHEN ea.appraisal_status = 'self_assessment' THEN 30
        ELSE 0
    END as progress_percentage
FROM employee_appraisal ea
JOIN employee_master em ON ea.employee_master_id = em.employee_master_id
JOIN appraisal_cycle ac ON ea.appraisal_cycle_id = ac.appraisal_cycle_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
LEFT JOIN user_master mg ON ea.reporting_manager_id = mg.user_master_id
WHERE ea.row_status = 1
ORDER BY ac.cycle_year DESC, em.employee_code;

-- View for goal tracking summary
CREATE VIEW goal_tracking_summary AS
SELECT
    eg.employee_master_id,
    em.employee_code,
    em.full_name,
    ac.cycle_name,
    COUNT(eg.employee_goal_id) as total_goals,
    COUNT(CASE WHEN eg.goal_status = 'completed' THEN 1 END) as completed_goals,
    COUNT(CASE WHEN eg.goal_status = 'in_progress' THEN 1 END) as in_progress_goals,
    COUNT(CASE WHEN eg.goal_status = 'overdue' THEN 1 END) as overdue_goals,
    AVG(eg.progress_percentage) as average_progress,
    SUM(CASE WHEN eg.final_achievement_percentage IS NOT NULL
             THEN eg.final_achievement_percentage * eg.goal_weight / 100
             ELSE 0 END) / NULLIF(SUM(eg.goal_weight), 0) as weighted_achievement
FROM employee_goal eg
JOIN employee_master em ON eg.employee_master_id = em.employee_master_id
JOIN appraisal_cycle ac ON eg.appraisal_cycle_id = ac.appraisal_cycle_id
WHERE eg.row_status = 1
GROUP BY eg.employee_master_id, em.employee_code, em.full_name, ac.cycle_name, ac.appraisal_cycle_id
ORDER BY em.employee_code;

-- View for performance analytics
CREATE VIEW performance_analytics_view AS
SELECT
    em.employee_master_id,
    em.employee_code,
    em.full_name,
    dm.department_name,
    dg.designation_name,
    ea.cycle_year,
    ea.final_rating,
    ea.overall_score,
    ea.goal_achievement_score,
    ea.competency_score,
    RANK() OVER (PARTITION BY dm.department_master_id, ea.cycle_year ORDER BY ea.overall_score DESC) as department_rank,
    PERCENT_RANK() OVER (PARTITION BY ea.cycle_year ORDER BY ea.overall_score) as performance_percentile,
    LAG(ea.overall_score) OVER (PARTITION BY em.employee_master_id ORDER BY ea.cycle_year) as previous_year_score,
    ea.overall_score - LAG(ea.overall_score) OVER (PARTITION BY em.employee_master_id ORDER BY ea.cycle_year) as score_improvement
FROM employee_appraisal ea
JOIN employee_master em ON ea.employee_master_id = em.employee_master_id
JOIN appraisal_cycle ac ON ea.appraisal_cycle_id = ac.appraisal_cycle_id
LEFT JOIN department_master dm ON em.department_master_id = dm.department_master_id
LEFT JOIN designation_master dg ON em.designation_master_id = dg.designation_master_id
WHERE ea.appraisal_status = 'completed'
AND ea.row_status = 1
ORDER BY ea.cycle_year DESC, ea.overall_score DESC;

-- =====================================================================================
-- SECTION 11: COMMENTS AND DOCUMENTATION
-- =====================================================================================

-- Table documentation
COMMENT ON TABLE competency_master IS 'Master competency framework with behavioral indicators and proficiency levels';
COMMENT ON TABLE appraisal_cycle IS 'Performance appraisal cycles with timeline management and participation tracking';
COMMENT ON TABLE employee_goal IS 'Employee goals and KRAs with progress tracking and multi-level assessments';
COMMENT ON TABLE employee_appraisal IS 'Comprehensive employee appraisal records with scores and development planning';
COMMENT ON TABLE competency_assessment IS 'Competency-wise assessments with self, manager, and skip-level ratings';
COMMENT ON TABLE feedback_provider IS '360-degree feedback provider management with request tracking';
COMMENT ON TABLE performance_analytics IS 'Performance trends and predictive analytics for talent management';

-- Function documentation
COMMENT ON FUNCTION calculate_goal_achievement_score(UUID) IS 'Calculates weighted average goal achievement score for employee appraisal';
COMMENT ON FUNCTION assign_competencies_to_appraisal(UUID) IS 'Auto-assigns applicable competencies to employee appraisal based on template';

-- =====================================================================================
-- END OF PERFORMANCE MANAGEMENT SCHEMA
-- =====================================================================================