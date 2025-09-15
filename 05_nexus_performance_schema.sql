-- =====================================================================================
-- NEXUS HRMS - Performance Management Schema
-- =====================================================================================
-- Version: 5.0
-- Date: 2025-01-14
-- Module: Performance Management System
-- Description: Comprehensive performance management with goal setting, appraisals,
--              360-degree feedback, KPI tracking, competency assessment, and
--              performance improvement plans with multi-level approval workflows
-- Dependencies: 01_nexus_foundation_schema.sql, 02_nexus_attendance_schema.sql, 03_nexus_leave_schema.sql, 04_nexus_payroll_schema.sql
-- Author: PostgreSQL DBA (20+ Years Experience)
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create performance management schema
CREATE SCHEMA IF NOT EXISTS nexus_performance;

-- Set search path for this schema
SET search_path = nexus_performance, nexus_foundation, nexus_attendance, nexus_leave, nexus_payroll, nexus_security, public;

-- =====================================================================================
-- PERFORMANCE CONFIGURATION AND TEMPLATES
-- =====================================================================================

-- Performance Cycle Master
-- Defines annual/periodic performance review cycles
CREATE TABLE nexus_performance.performance_cycle_master (
    cycle_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Cycle Identification
    cycle_code VARCHAR(20) NOT NULL,
    cycle_name VARCHAR(100) NOT NULL,
    cycle_description TEXT,
    cycle_type VARCHAR(20) NOT NULL DEFAULT 'ANNUAL',
    -- ANNUAL, SEMI_ANNUAL, QUARTERLY, PROJECT_BASED, CONTINUOUS

    -- Cycle Period
    cycle_year INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE NOT NULL,

    -- Review Period
    review_start_date DATE NOT NULL,
    review_end_date DATE NOT NULL,

    -- Goal Setting Period
    goal_setting_start_date DATE,
    goal_setting_end_date DATE,

    -- Cycle Configuration
    is_goal_setting_enabled BOOLEAN DEFAULT true,
    is_self_assessment_enabled BOOLEAN DEFAULT true,
    is_manager_assessment_enabled BOOLEAN DEFAULT true,
    is_peer_review_enabled BOOLEAN DEFAULT false,
    is_subordinate_review_enabled BOOLEAN DEFAULT false,
    is_360_feedback_enabled BOOLEAN DEFAULT false,

    -- Weightage Configuration
    self_assessment_weightage DECIMAL(5,2) DEFAULT 20.00,
    manager_assessment_weightage DECIMAL(5,2) DEFAULT 60.00,
    peer_review_weightage DECIMAL(5,2) DEFAULT 10.00,
    subordinate_review_weightage DECIMAL(5,2) DEFAULT 10.00,

    -- Rating Configuration
    rating_scale_type VARCHAR(20) DEFAULT 'FIVE_POINT',
    -- FIVE_POINT, TEN_POINT, PERCENTAGE, CUSTOM
    minimum_rating DECIMAL(4,2) DEFAULT 1.00,
    maximum_rating DECIMAL(4,2) DEFAULT 5.00,

    -- Normalization and Calibration
    is_forced_ranking_enabled BOOLEAN DEFAULT false,
    forced_ranking_percentages JSONB, -- Distribution percentages for ratings
    calibration_required BOOLEAN DEFAULT false,

    -- Cycle Status
    cycle_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, PUBLISHED, IN_PROGRESS, COMPLETED, CLOSED, CANCELLED

    -- Publication and Activation
    published_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    published_at TIMESTAMP WITH TIME ZONE,
    activated_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_performance_cycle_company_code UNIQUE (company_id, cycle_code),
    CONSTRAINT chk_cycle_type CHECK (cycle_type IN (
        'ANNUAL', 'SEMI_ANNUAL', 'QUARTERLY', 'PROJECT_BASED', 'CONTINUOUS'
    )),
    CONSTRAINT chk_cycle_status CHECK (cycle_status IN (
        'DRAFT', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'CLOSED', 'CANCELLED'
    )),
    CONSTRAINT chk_cycle_dates CHECK (
        cycle_end_date >= cycle_start_date AND
        review_end_date >= review_start_date AND
        review_start_date >= cycle_start_date
    ),
    CONSTRAINT chk_weightage_total CHECK (
        (self_assessment_weightage + manager_assessment_weightage +
         peer_review_weightage + subordinate_review_weightage) <= 100.00
    )
);

-- Performance Template Master
-- Configurable templates for different employee categories
CREATE TABLE nexus_performance.performance_template_master (
    template_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Template Identification
    template_code VARCHAR(20) NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_type VARCHAR(20) DEFAULT 'STANDARD',
    -- STANDARD, EXECUTIVE, MANAGER, INDIVIDUAL_CONTRIBUTOR, PROBATIONARY

    -- Applicability
    applicable_designations BIGINT[], -- Array of designation IDs
    applicable_departments BIGINT[], -- Array of department IDs
    applicable_grades VARCHAR(20)[], -- Array of employee grades
    applicable_locations BIGINT[], -- Array of location IDs

    -- Template Configuration
    goal_setting_required BOOLEAN DEFAULT true,
    minimum_goals_required INTEGER DEFAULT 3,
    maximum_goals_allowed INTEGER DEFAULT 10,

    competency_assessment_required BOOLEAN DEFAULT true,
    kpi_tracking_required BOOLEAN DEFAULT false,
    development_plan_required BOOLEAN DEFAULT true,

    -- Rating and Scoring
    overall_rating_formula TEXT, -- Formula to calculate overall rating
    goal_achievement_weightage DECIMAL(5,2) DEFAULT 60.00,
    competency_rating_weightage DECIMAL(5,2) DEFAULT 30.00,
    behavioral_rating_weightage DECIMAL(5,2) DEFAULT 10.00,

    -- Template Status
    template_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    effective_from_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to_date DATE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_performance_template_company_code UNIQUE (company_id, template_code),
    CONSTRAINT chk_template_type CHECK (template_type IN (
        'STANDARD', 'EXECUTIVE', 'MANAGER', 'INDIVIDUAL_CONTRIBUTOR', 'PROBATIONARY'
    )),
    CONSTRAINT chk_template_status CHECK (template_status IN ('ACTIVE', 'INACTIVE', 'DRAFT')),
    CONSTRAINT chk_goal_limits CHECK (minimum_goals_required <= maximum_goals_allowed),
    CONSTRAINT chk_weightage_sum CHECK (
        (goal_achievement_weightage + competency_rating_weightage + behavioral_rating_weightage) = 100.00
    )
);

-- Competency Master
-- Skills and competencies framework for assessment
CREATE TABLE nexus_performance.competency_master (
    competency_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Competency Identification
    competency_code VARCHAR(20) NOT NULL,
    competency_name VARCHAR(100) NOT NULL,
    competency_description TEXT,
    competency_category VARCHAR(30) NOT NULL DEFAULT 'FUNCTIONAL',
    -- FUNCTIONAL, BEHAVIORAL, LEADERSHIP, TECHNICAL, COMMUNICATION

    -- Competency Levels
    proficiency_levels JSONB NOT NULL, -- Array of level definitions
    -- Example: [{"level": 1, "name": "Basic", "description": "..."}, ...]

    -- Assessment Configuration
    assessment_method VARCHAR(20) DEFAULT 'RATING',
    -- RATING, BINARY, DESCRIPTIVE, MULTI_CHOICE
    rating_scale INTEGER DEFAULT 5,

    -- Applicability
    applicable_designations BIGINT[],
    applicable_departments BIGINT[],
    applicable_grades VARCHAR(20)[],

    -- Competency Weightage
    default_weightage DECIMAL(5,2) DEFAULT 10.00,
    is_core_competency BOOLEAN DEFAULT false,
    is_mandatory BOOLEAN DEFAULT true,

    -- Display Configuration
    display_order INTEGER DEFAULT 100,
    competency_group VARCHAR(50) DEFAULT 'GENERAL',

    -- Status
    competency_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_competency_company_code UNIQUE (company_id, competency_code),
    CONSTRAINT chk_competency_category CHECK (competency_category IN (
        'FUNCTIONAL', 'BEHAVIORAL', 'LEADERSHIP', 'TECHNICAL', 'COMMUNICATION'
    )),
    CONSTRAINT chk_competency_status CHECK (competency_status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT chk_rating_scale CHECK (rating_scale >= 2 AND rating_scale <= 10)
);

-- =====================================================================================
-- GOAL SETTING AND TRACKING
-- =====================================================================================

-- Employee Goals
-- Individual employee goals for performance cycles
CREATE TABLE nexus_performance.employee_goals (
    goal_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    cycle_id BIGINT NOT NULL REFERENCES nexus_performance.performance_cycle_master(cycle_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Goal Identification
    goal_number INTEGER NOT NULL,
    goal_title VARCHAR(200) NOT NULL,
    goal_description TEXT NOT NULL,
    goal_category VARCHAR(30) DEFAULT 'PERFORMANCE',
    -- PERFORMANCE, DEVELOPMENT, BEHAVIORAL, PROJECT, STRATEGIC

    -- Goal Details
    goal_type VARCHAR(20) DEFAULT 'QUANTITATIVE',
    -- QUANTITATIVE, QUALITATIVE, MILESTONE, BEHAVIORAL
    measurement_criteria TEXT,
    target_value DECIMAL(15,4),
    target_unit VARCHAR(50),
    baseline_value DECIMAL(15,4),

    -- Timeline
    target_completion_date DATE,
    milestone_dates JSONB, -- Array of milestone dates and descriptions

    -- Priority and Weightage
    goal_priority VARCHAR(20) DEFAULT 'MEDIUM',
    -- HIGH, MEDIUM, LOW, CRITICAL
    goal_weightage DECIMAL(5,2) DEFAULT 20.00,

    -- Goal Alignment
    aligned_to_department_goal BIGINT,
    aligned_to_company_objective TEXT,
    cascaded_from_goal_id BIGINT REFERENCES nexus_performance.employee_goals(goal_id),

    -- Progress Tracking
    current_value DECIMAL(15,4) DEFAULT 0,
    achievement_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN target_value IS NOT NULL AND target_value != 0
            THEN LEAST(ROUND((current_value / target_value) * 100, 2), 100.00)
            ELSE 0
        END
    ) STORED,

    -- Goal Status
    goal_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, APPROVED, REJECTED, ACTIVE, COMPLETED, CANCELLED, ON_HOLD

    -- Approval Workflow
    manager_approval_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, APPROVED, REJECTED, CHANGES_REQUESTED
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- Final Assessment
    final_achievement_percentage DECIMAL(5,2),
    final_rating DECIMAL(4,2),
    achievement_comments TEXT,
    assessed_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    assessed_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_goal_number UNIQUE (cycle_id, employee_id, goal_number),
    CONSTRAINT chk_goal_status CHECK (goal_status IN (
        'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'ACTIVE', 'COMPLETED', 'CANCELLED', 'ON_HOLD'
    )),
    CONSTRAINT chk_goal_priority CHECK (goal_priority IN ('HIGH', 'MEDIUM', 'LOW', 'CRITICAL')),
    CONSTRAINT chk_goal_category CHECK (goal_category IN (
        'PERFORMANCE', 'DEVELOPMENT', 'BEHAVIORAL', 'PROJECT', 'STRATEGIC'
    )),
    CONSTRAINT chk_goal_weightage CHECK (goal_weightage >= 0 AND goal_weightage <= 100),
    CONSTRAINT chk_achievement_percentage CHECK (
        final_achievement_percentage IS NULL OR
        (final_achievement_percentage >= 0 AND final_achievement_percentage <= 200)
    )
);

-- Goal Progress Updates
-- Periodic updates on goal progress
CREATE TABLE nexus_performance.goal_progress_updates (
    progress_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    goal_id BIGINT NOT NULL REFERENCES nexus_performance.employee_goals(goal_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Update Details
    update_date DATE NOT NULL DEFAULT CURRENT_DATE,
    update_period VARCHAR(20) DEFAULT 'MONTHLY',
    -- WEEKLY, MONTHLY, QUARTERLY, MILESTONE, AD_HOC

    -- Progress Information
    progress_value DECIMAL(15,4),
    progress_percentage DECIMAL(5,2),
    progress_description TEXT NOT NULL,

    -- Challenges and Support
    challenges_faced TEXT,
    support_required TEXT,
    manager_feedback TEXT,
    manager_support_provided TEXT,

    -- Attachments and Evidence
    supporting_documents JSONB, -- Array of document references
    evidence_links TEXT,

    -- Review Status
    review_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, REVIEWED, ACKNOWLEDGED, REQUIRES_ACTION
    reviewed_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    manager_comments TEXT,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT chk_progress_percentage CHECK (
        progress_percentage IS NULL OR (progress_percentage >= 0 AND progress_percentage <= 200)
    ),
    CONSTRAINT chk_review_status CHECK (review_status IN (
        'PENDING', 'REVIEWED', 'ACKNOWLEDGED', 'REQUIRES_ACTION'
    ))
);

-- =====================================================================================
-- PERFORMANCE APPRAISAL SYSTEM
-- =====================================================================================

-- Employee Performance Appraisals
-- Core appraisal records for each employee in a cycle
CREATE TABLE nexus_performance.employee_performance_appraisals (
    appraisal_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    cycle_id BIGINT NOT NULL REFERENCES nexus_performance.performance_cycle_master(cycle_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    template_id BIGINT NOT NULL REFERENCES nexus_performance.performance_template_master(template_id),

    -- Appraisal Identification
    appraisal_number VARCHAR(50) NOT NULL,
    appraisal_year INTEGER NOT NULL,

    -- Employee Information (Snapshot at appraisal time)
    employee_code VARCHAR(20) NOT NULL,
    employee_name VARCHAR(200) NOT NULL,
    employee_designation VARCHAR(100),
    employee_department VARCHAR(100),
    employee_grade VARCHAR(20),
    reporting_manager_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    date_of_joining DATE,
    tenure_months INTEGER,

    -- Appraisal Period
    appraisal_start_date DATE NOT NULL,
    appraisal_end_date DATE NOT NULL,

    -- Assessment Scores
    self_assessment_score DECIMAL(5,2),
    manager_assessment_score DECIMAL(5,2),
    peer_review_score DECIMAL(5,2),
    subordinate_review_score DECIMAL(5,2),
    skip_level_review_score DECIMAL(5,2),

    -- Component Scores
    goal_achievement_score DECIMAL(5,2),
    competency_score DECIMAL(5,2),
    behavioral_score DECIMAL(5,2),
    overall_score DECIMAL(5,2),

    -- Final Rating and Ranking
    final_rating DECIMAL(4,2),
    performance_grade VARCHAR(10), -- A+, A, B+, B, C+, C, D
    performance_category VARCHAR(20), -- OUTSTANDING, EXCEEDS, MEETS, BELOW, UNSATISFACTORY

    -- Ranking Information
    department_rank INTEGER,
    grade_rank INTEGER,
    overall_company_rank INTEGER,
    percentile_rank DECIMAL(5,2),

    -- Appraisal Status
    appraisal_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SELF_ASSESSMENT, MANAGER_REVIEW, SKIP_LEVEL_REVIEW,
    -- CALIBRATION, COMPLETED, PUBLISHED, ACKNOWLEDGED

    -- Workflow Tracking
    self_assessment_completed_at TIMESTAMP WITH TIME ZONE,
    manager_review_completed_at TIMESTAMP WITH TIME ZONE,
    skip_level_review_completed_at TIMESTAMP WITH TIME ZONE,
    calibration_completed_at TIMESTAMP WITH TIME ZONE,
    final_review_completed_at TIMESTAMP WITH TIME ZONE,

    -- Calibration Information
    pre_calibration_rating DECIMAL(4,2),
    post_calibration_rating DECIMAL(4,2),
    calibration_reason TEXT,
    calibration_committee_members BIGINT[],

    -- Employee Acknowledgment
    employee_acknowledgment_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, ACKNOWLEDGED, DISPUTED, ESCALATED
    employee_comments TEXT,
    employee_acknowledgment_date DATE,

    -- Development and Career Planning
    promotion_recommended BOOLEAN DEFAULT false,
    promotion_recommendation_comments TEXT,
    increment_recommended_percentage DECIMAL(5,2),
    training_recommendations TEXT,

    -- Performance Improvement
    requires_improvement_plan BOOLEAN DEFAULT false,
    improvement_areas TEXT,
    support_required TEXT,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_employee_appraisal_cycle UNIQUE (cycle_id, employee_id),
    CONSTRAINT uk_appraisal_number UNIQUE (company_id, appraisal_number),
    CONSTRAINT chk_appraisal_status CHECK (appraisal_status IN (
        'DRAFT', 'SELF_ASSESSMENT', 'MANAGER_REVIEW', 'SKIP_LEVEL_REVIEW',
        'CALIBRATION', 'COMPLETED', 'PUBLISHED', 'ACKNOWLEDGED'
    )),
    CONSTRAINT chk_performance_category CHECK (performance_category IN (
        'OUTSTANDING', 'EXCEEDS', 'MEETS', 'BELOW', 'UNSATISFACTORY'
    )),
    CONSTRAINT chk_appraisal_dates CHECK (appraisal_end_date >= appraisal_start_date),
    CONSTRAINT chk_rating_bounds CHECK (
        (final_rating IS NULL) OR (final_rating >= 1.0 AND final_rating <= 5.0)
    )
);

-- Competency Assessment
-- Individual competency ratings for each appraisal
CREATE TABLE nexus_performance.competency_assessments (
    assessment_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    appraisal_id BIGINT NOT NULL REFERENCES nexus_performance.employee_performance_appraisals(appraisal_id),
    competency_id BIGINT NOT NULL REFERENCES nexus_performance.competency_master(competency_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Assessment Details
    competency_code VARCHAR(20) NOT NULL,
    competency_name VARCHAR(100) NOT NULL,
    competency_category VARCHAR(30) NOT NULL,
    competency_weightage DECIMAL(5,2) DEFAULT 10.00,

    -- Ratings from Different Sources
    self_rating DECIMAL(4,2),
    manager_rating DECIMAL(4,2),
    peer_average_rating DECIMAL(4,2),
    subordinate_average_rating DECIMAL(4,2),
    skip_level_rating DECIMAL(4,2),

    -- Final Assessment
    final_rating DECIMAL(4,2),
    proficiency_level INTEGER, -- 1-5 based on competency master
    rating_justification TEXT,

    -- Development Areas
    is_strength BOOLEAN DEFAULT false,
    is_development_area BOOLEAN DEFAULT false,
    development_recommendations TEXT,
    training_suggestions TEXT,

    -- Assessment Status
    assessment_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, SELF_COMPLETED, MANAGER_COMPLETED, FINAL_COMPLETED

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_appraisal_competency UNIQUE (appraisal_id, competency_id),
    CONSTRAINT chk_assessment_status CHECK (assessment_status IN (
        'PENDING', 'SELF_COMPLETED', 'MANAGER_COMPLETED', 'FINAL_COMPLETED'
    )),
    CONSTRAINT chk_competency_ratings CHECK (
        (self_rating IS NULL OR (self_rating >= 1.0 AND self_rating <= 5.0)) AND
        (manager_rating IS NULL OR (manager_rating >= 1.0 AND manager_rating <= 5.0)) AND
        (final_rating IS NULL OR (final_rating >= 1.0 AND final_rating <= 5.0))
    )
);

-- =====================================================================================
-- 360-DEGREE FEEDBACK SYSTEM
-- =====================================================================================

-- Feedback Requests
-- Requests for 360-degree feedback collection
CREATE TABLE nexus_performance.feedback_requests (
    feedback_request_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    appraisal_id BIGINT NOT NULL REFERENCES nexus_performance.employee_performance_appraisals(appraisal_id),
    cycle_id BIGINT NOT NULL REFERENCES nexus_performance.performance_cycle_master(cycle_id),

    -- Subject and Reviewer
    subject_employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    reviewer_employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Feedback Relationship
    feedback_type VARCHAR(20) NOT NULL,
    -- MANAGER, PEER, SUBORDINATE, SKIP_LEVEL, CUSTOMER, SELF
    relationship_description TEXT,
    working_relationship_duration_months INTEGER,

    -- Request Configuration
    feedback_template_id BIGINT,
    competencies_to_assess BIGINT[], -- Array of competency IDs
    custom_questions JSONB, -- Array of custom questions

    -- Request Timeline
    request_sent_date DATE NOT NULL DEFAULT CURRENT_DATE,
    response_deadline DATE NOT NULL,
    reminder_frequency_days INTEGER DEFAULT 3,

    -- Request Status
    request_status VARCHAR(20) NOT NULL DEFAULT 'SENT',
    -- SENT, VIEWED, IN_PROGRESS, COMPLETED, EXPIRED, DECLINED

    -- Response Information
    response_submitted_at TIMESTAMP WITH TIME ZONE,
    response_completion_percentage DECIMAL(5,2) DEFAULT 0.00,

    -- Confidentiality and Anonymity
    is_anonymous_feedback BOOLEAN DEFAULT false,
    is_confidential BOOLEAN DEFAULT true,
    can_view_feedback BOOLEAN DEFAULT false,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_feedback_request_unique UNIQUE (appraisal_id, subject_employee_id, reviewer_employee_id, feedback_type),
    CONSTRAINT chk_feedback_type CHECK (feedback_type IN (
        'MANAGER', 'PEER', 'SUBORDINATE', 'SKIP_LEVEL', 'CUSTOMER', 'SELF'
    )),
    CONSTRAINT chk_feedback_request_status CHECK (request_status IN (
        'SENT', 'VIEWED', 'IN_PROGRESS', 'COMPLETED', 'EXPIRED', 'DECLINED'
    )),
    CONSTRAINT chk_different_employees CHECK (subject_employee_id != reviewer_employee_id OR feedback_type = 'SELF')
);

-- Feedback Responses
-- Detailed 360-degree feedback responses
CREATE TABLE nexus_performance.feedback_responses (
    response_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    feedback_request_id BIGINT NOT NULL REFERENCES nexus_performance.feedback_requests(feedback_request_id),
    appraisal_id BIGINT NOT NULL REFERENCES nexus_performance.employee_performance_appraisals(appraisal_id),

    -- Response Identification
    subject_employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    reviewer_employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    feedback_type VARCHAR(20) NOT NULL,

    -- Overall Assessment
    overall_performance_rating DECIMAL(4,2),
    overall_comments TEXT,

    -- Strength and Development Areas
    key_strengths TEXT,
    development_areas TEXT,
    specific_examples TEXT,

    -- Recommendations
    development_recommendations TEXT,
    training_suggestions TEXT,
    coaching_areas TEXT,

    -- Working Relationship Feedback
    collaboration_effectiveness_rating DECIMAL(4,2),
    communication_effectiveness_rating DECIMAL(4,2),
    leadership_effectiveness_rating DECIMAL(4,2),

    -- Future Potential Assessment
    promotion_readiness VARCHAR(20) DEFAULT 'NOT_READY',
    -- READY_NOW, READY_1_YEAR, READY_2_YEARS, NOT_READY, UNCLEAR
    potential_roles TEXT,

    -- Additional Feedback
    what_should_continue TEXT,
    what_should_start TEXT,
    what_should_stop TEXT,

    -- Response Status and Completion
    response_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, FINALIZED
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    time_spent_minutes INTEGER,

    -- Response Timeline
    started_at TIMESTAMP WITH TIME ZONE,
    last_saved_at TIMESTAMP WITH TIME ZONE,
    submitted_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_feedback_response UNIQUE (feedback_request_id),
    CONSTRAINT chk_feedback_response_status CHECK (response_status IN (
        'DRAFT', 'SUBMITTED', 'FINALIZED'
    )),
    CONSTRAINT chk_promotion_readiness CHECK (promotion_readiness IN (
        'READY_NOW', 'READY_1_YEAR', 'READY_2_YEARS', 'NOT_READY', 'UNCLEAR'
    )),
    CONSTRAINT chk_completion_percentage CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    )
);

-- =====================================================================================
-- PERFORMANCE IMPROVEMENT PLANS
-- =====================================================================================

-- Performance Improvement Plans
-- Structured improvement plans for underperforming employees
CREATE TABLE nexus_performance.performance_improvement_plans (
    pip_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    appraisal_id BIGINT REFERENCES nexus_performance.employee_performance_appraisals(appraisal_id),

    -- PIP Identification
    pip_number VARCHAR(50) NOT NULL,
    pip_title VARCHAR(200) NOT NULL,
    pip_type VARCHAR(20) DEFAULT 'PERFORMANCE',
    -- PERFORMANCE, BEHAVIORAL, ATTENDANCE, SKILL_GAP, DISCIPLINARY

    -- PIP Period
    pip_start_date DATE NOT NULL,
    pip_end_date DATE NOT NULL,
    pip_duration_months INTEGER GENERATED ALWAYS AS (
        EXTRACT(MONTH FROM AGE(pip_end_date, pip_start_date))
    ) STORED,

    -- Review Schedule
    review_frequency VARCHAR(20) DEFAULT 'MONTHLY',
    -- WEEKLY, BIWEEKLY, MONTHLY, QUARTERLY
    next_review_date DATE,

    -- Performance Issues
    performance_concerns TEXT NOT NULL,
    specific_issues JSONB, -- Array of specific issue descriptions
    impact_on_business TEXT,
    root_cause_analysis TEXT,

    -- Improvement Objectives
    improvement_objectives JSONB NOT NULL, -- Array of SMART objectives
    success_criteria TEXT NOT NULL,
    measurement_methods TEXT,

    -- Support and Resources
    training_required TEXT,
    coaching_support TEXT,
    resources_provided TEXT,
    manager_support_commitment TEXT,

    -- Consequences and Outcomes
    consequences_of_non_improvement TEXT,
    potential_outcomes TEXT,
    alternative_role_considerations TEXT,

    -- PIP Status
    pip_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, ACTIVE, EXTENDED, COMPLETED_SUCCESSFUL, COMPLETED_UNSUCCESSFUL, CANCELLED

    -- Approval Information
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    hr_approval_required BOOLEAN DEFAULT true,
    hr_approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    hr_approved_at TIMESTAMP WITH TIME ZONE,

    -- Employee Acknowledgment
    employee_acknowledgment_status VARCHAR(20) DEFAULT 'PENDING',
    employee_acknowledgment_date DATE,
    employee_comments TEXT,
    employee_agreement BOOLEAN DEFAULT false,

    -- Final Outcome
    final_outcome VARCHAR(30),
    -- SUCCESSFUL_COMPLETION, PARTIAL_IMPROVEMENT, NO_IMPROVEMENT, TERMINATED, REASSIGNED
    outcome_date DATE,
    outcome_comments TEXT,
    outcome_decided_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_pip_number UNIQUE (company_id, pip_number),
    CONSTRAINT chk_pip_dates CHECK (pip_end_date > pip_start_date),
    CONSTRAINT chk_pip_status CHECK (pip_status IN (
        'DRAFT', 'ACTIVE', 'EXTENDED', 'COMPLETED_SUCCESSFUL',
        'COMPLETED_UNSUCCESSFUL', 'CANCELLED'
    )),
    CONSTRAINT chk_pip_type CHECK (pip_type IN (
        'PERFORMANCE', 'BEHAVIORAL', 'ATTENDANCE', 'SKILL_GAP', 'DISCIPLINARY'
    )),
    CONSTRAINT chk_final_outcome CHECK (final_outcome IS NULL OR final_outcome IN (
        'SUCCESSFUL_COMPLETION', 'PARTIAL_IMPROVEMENT', 'NO_IMPROVEMENT',
        'TERMINATED', 'REASSIGNED'
    ))
);

-- PIP Progress Reviews
-- Regular review sessions during PIP period
CREATE TABLE nexus_performance.pip_progress_reviews (
    review_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    pip_id BIGINT NOT NULL REFERENCES nexus_performance.performance_improvement_plans(pip_id),
    employee_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),

    -- Review Details
    review_number INTEGER NOT NULL,
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,

    -- Progress Assessment
    overall_progress_rating VARCHAR(20) NOT NULL,
    -- EXCELLENT, GOOD, SATISFACTORY, NEEDS_IMPROVEMENT, UNSATISFACTORY
    progress_percentage DECIMAL(5,2),

    -- Objective-wise Progress
    objectives_progress JSONB, -- Progress on each objective
    goals_achieved JSONB,
    goals_pending JSONB,

    -- Performance Observations
    performance_improvements TEXT,
    areas_of_concern TEXT,
    behavioral_changes TEXT,
    skill_development_progress TEXT,

    -- Manager Assessment
    manager_feedback TEXT NOT NULL,
    manager_rating DECIMAL(4,2),
    support_effectiveness TEXT,
    additional_support_needed TEXT,

    -- Employee Input
    employee_self_assessment TEXT,
    employee_challenges TEXT,
    employee_suggestions TEXT,
    employee_commitment_level VARCHAR(20),
    -- HIGH, MEDIUM, LOW, UNCLEAR

    -- Action Items
    action_items_for_employee JSONB,
    action_items_for_manager JSONB,
    additional_resources_required TEXT,
    timeline_adjustments TEXT,

    -- Review Outcome
    review_outcome VARCHAR(30) NOT NULL,
    -- CONTINUE_PIP, EXTEND_PIP, EARLY_SUCCESS, ESCALATE, TERMINATE
    next_review_date DATE,
    outcome_justification TEXT,

    -- Attendance and Participation
    review_conducted_by BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    hr_representative BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    employee_attendance BOOLEAN DEFAULT true,
    meeting_duration_minutes INTEGER,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_pip_review_number UNIQUE (pip_id, review_number),
    CONSTRAINT chk_progress_rating CHECK (overall_progress_rating IN (
        'EXCELLENT', 'GOOD', 'SATISFACTORY', 'NEEDS_IMPROVEMENT', 'UNSATISFACTORY'
    )),
    CONSTRAINT chk_review_dates CHECK (review_period_end >= review_period_start),
    CONSTRAINT chk_review_outcome CHECK (review_outcome IN (
        'CONTINUE_PIP', 'EXTEND_PIP', 'EARLY_SUCCESS', 'ESCALATE', 'TERMINATE'
    )),
    CONSTRAINT chk_commitment_level CHECK (employee_commitment_level IS NULL OR employee_commitment_level IN (
        'HIGH', 'MEDIUM', 'LOW', 'UNCLEAR'
    ))
);

-- =====================================================================================
-- PERFORMANCE ANALYTICS AND REPORTING VIEWS
-- =====================================================================================

-- Performance Dashboard View
CREATE OR REPLACE VIEW nexus_performance.v_performance_dashboard AS
SELECT
    epa.company_id,
    epa.cycle_id,
    pcm.cycle_name,
    pcm.cycle_year,
    epa.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    desig.designation_name,
    epa.employee_grade,

    -- Performance Scores
    epa.goal_achievement_score,
    epa.competency_score,
    epa.behavioral_score,
    epa.overall_score,
    epa.final_rating,
    epa.performance_grade,
    epa.performance_category,

    -- Rankings
    epa.department_rank,
    epa.grade_rank,
    epa.overall_company_rank,
    epa.percentile_rank,

    -- Goal Statistics
    goal_stats.total_goals,
    goal_stats.completed_goals,
    goal_stats.average_achievement,

    -- Status Information
    epa.appraisal_status,
    epa.employee_acknowledgment_status,
    epa.promotion_recommended,
    epa.requires_improvement_plan,

    -- Timeline Information
    epa.self_assessment_completed_at,
    epa.manager_review_completed_at,
    epa.final_review_completed_at

FROM nexus_performance.employee_performance_appraisals epa
    JOIN nexus_performance.performance_cycle_master pcm ON epa.cycle_id = pcm.cycle_id
    JOIN nexus_foundation.employee_master emp ON epa.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
    LEFT JOIN nexus_foundation.designation_master desig ON emp.designation_id = desig.designation_id
    LEFT JOIN (
        SELECT
            cycle_id,
            employee_id,
            COUNT(*) as total_goals,
            COUNT(CASE WHEN goal_status = 'COMPLETED' THEN 1 END) as completed_goals,
            AVG(COALESCE(final_achievement_percentage, achievement_percentage)) as average_achievement
        FROM nexus_performance.employee_goals
        WHERE goal_status IN ('ACTIVE', 'COMPLETED')
        GROUP BY cycle_id, employee_id
    ) goal_stats ON epa.cycle_id = goal_stats.cycle_id AND epa.employee_id = goal_stats.employee_id
WHERE emp.employee_status = 'ACTIVE';

-- Competency Analysis View
CREATE OR REPLACE VIEW nexus_performance.v_competency_analysis AS
SELECT
    ca.company_id,
    epa.cycle_id,
    pcm.cycle_year,
    ca.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    ca.competency_id,
    ca.competency_code,
    ca.competency_name,
    ca.competency_category,

    -- Ratings Analysis
    ca.self_rating,
    ca.manager_rating,
    ca.peer_average_rating,
    ca.subordinate_average_rating,
    ca.final_rating,
    ca.proficiency_level,

    -- Rating Variance Analysis
    ABS(ca.self_rating - ca.manager_rating) AS self_manager_variance,
    CASE
        WHEN ca.self_rating > ca.manager_rating THEN 'OVERRATED_SELF'
        WHEN ca.self_rating < ca.manager_rating THEN 'UNDERRATED_SELF'
        ELSE 'ALIGNED'
    END AS self_assessment_alignment,

    -- Development Areas
    ca.is_strength,
    ca.is_development_area,
    ca.development_recommendations,

    -- Assessment Status
    ca.assessment_status

FROM nexus_performance.competency_assessments ca
    JOIN nexus_performance.employee_performance_appraisals epa ON ca.appraisal_id = epa.appraisal_id
    JOIN nexus_performance.performance_cycle_master pcm ON epa.cycle_id = pcm.cycle_id
    JOIN nexus_foundation.employee_master emp ON ca.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
WHERE emp.employee_status = 'ACTIVE';

-- Goal Achievement Analysis View
CREATE OR REPLACE VIEW nexus_performance.v_goal_achievement_analysis AS
SELECT
    eg.company_id,
    eg.cycle_id,
    pcm.cycle_year,
    eg.employee_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name AS employee_name,
    dept.department_name,
    eg.goal_id,
    eg.goal_number,
    eg.goal_title,
    eg.goal_category,
    eg.goal_type,
    eg.goal_priority,
    eg.goal_weightage,

    -- Achievement Analysis
    eg.target_value,
    eg.current_value,
    eg.achievement_percentage,
    eg.final_achievement_percentage,
    eg.final_rating,

    -- Timeline Analysis
    eg.target_completion_date,
    eg.goal_status,
    CASE
        WHEN eg.target_completion_date < CURRENT_DATE AND eg.goal_status != 'COMPLETED'
        THEN 'OVERDUE'
        WHEN eg.target_completion_date = CURRENT_DATE AND eg.goal_status != 'COMPLETED'
        THEN 'DUE_TODAY'
        WHEN eg.target_completion_date > CURRENT_DATE AND eg.goal_status != 'COMPLETED'
        THEN 'ON_TRACK'
        ELSE 'COMPLETED'
    END AS timeline_status,

    -- Progress Analysis
    CASE
        WHEN eg.final_achievement_percentage >= 100 THEN 'EXCEEDED'
        WHEN eg.final_achievement_percentage >= 80 THEN 'ACHIEVED'
        WHEN eg.final_achievement_percentage >= 60 THEN 'PARTIALLY_ACHIEVED'
        ELSE 'NOT_ACHIEVED'
    END AS achievement_status

FROM nexus_performance.employee_goals eg
    JOIN nexus_performance.performance_cycle_master pcm ON eg.cycle_id = pcm.cycle_id
    JOIN nexus_foundation.employee_master emp ON eg.employee_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
WHERE emp.employee_status = 'ACTIVE';

-- =====================================================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================================================

-- Enable RLS on all performance tables
ALTER TABLE nexus_performance.performance_cycle_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.performance_template_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.competency_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.employee_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.goal_progress_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.employee_performance_appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.competency_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.feedback_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.feedback_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.performance_improvement_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_performance.pip_progress_reviews ENABLE ROW LEVEL SECURITY;

-- Company-based access policy for all performance tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_performance'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE POLICY company_access_policy ON nexus_performance.%I
            FOR ALL TO nexus_app_role
            USING (company_id = current_setting(''app.current_company_id'')::BIGINT)
        ', table_name);
    END LOOP;
END $$;

-- Employee-specific access policy for sensitive performance data
CREATE POLICY employee_performance_access_policy ON nexus_performance.employee_performance_appraisals
    FOR ALL TO nexus_app_role
    USING (
        company_id = current_setting('app.current_company_id')::BIGINT AND
        (
            employee_id = current_setting('app.current_user_id')::BIGINT OR
            reporting_manager_id = current_setting('app.current_user_id')::BIGINT OR
            -- Allow HR and senior management access
            EXISTS (
                SELECT 1 FROM nexus_foundation.user_master um
                WHERE um.user_id = current_setting('app.current_user_id')::BIGINT
                AND um.user_role IN ('HR_ADMIN', 'HR_MANAGER', 'SENIOR_MANAGER', 'ADMIN')
            )
        )
    );

-- =====================================================================================
-- TRIGGERS FOR BUSINESS LOGIC AND AUDIT
-- =====================================================================================

-- Standard update trigger function
CREATE OR REPLACE FUNCTION nexus_performance.update_last_modified()
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
        WHERE schemaname = 'nexus_performance'
        AND tablename NOT IN ('goal_progress_updates', 'pip_progress_reviews')
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_last_modified_trigger
            BEFORE UPDATE ON nexus_performance.%I
            FOR EACH ROW EXECUTE FUNCTION nexus_performance.update_last_modified()
        ', table_name);
    END LOOP;
END $$;

-- Goal progress update trigger
CREATE OR REPLACE FUNCTION nexus_performance.update_goal_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Update current value in employee_goals when progress is updated
    UPDATE nexus_performance.employee_goals
    SET current_value = NEW.progress_value,
        last_modified_at = CURRENT_TIMESTAMP
    WHERE goal_id = NEW.goal_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply goal progress update trigger
CREATE TRIGGER update_goal_progress_trigger
    AFTER INSERT OR UPDATE ON nexus_performance.goal_progress_updates
    FOR EACH ROW EXECUTE FUNCTION nexus_performance.update_goal_progress();

-- =====================================================================================
-- STORED PROCEDURES FOR PERFORMANCE PROCESSING
-- =====================================================================================

-- Calculate overall performance score
CREATE OR REPLACE FUNCTION nexus_performance.calculate_overall_performance_score(
    p_appraisal_id BIGINT
)
RETURNS JSONB AS $$
DECLARE
    v_appraisal_record nexus_performance.employee_performance_appraisals%ROWTYPE;
    v_template_record nexus_performance.performance_template_master%ROWTYPE;
    v_goal_score DECIMAL(5,2) := 0.00;
    v_competency_score DECIMAL(5,2) := 0.00;
    v_behavioral_score DECIMAL(5,2) := 0.00;
    v_overall_score DECIMAL(5,2) := 0.00;
    v_final_rating DECIMAL(4,2);
    v_performance_category VARCHAR(20);
BEGIN
    -- Get appraisal record
    SELECT * INTO v_appraisal_record
    FROM nexus_performance.employee_performance_appraisals
    WHERE appraisal_id = p_appraisal_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Appraisal record not found'
        );
    END IF;

    -- Get template configuration
    SELECT * INTO v_template_record
    FROM nexus_performance.performance_template_master
    WHERE template_id = v_appraisal_record.template_id;

    -- Calculate Goal Achievement Score
    SELECT AVG(COALESCE(final_achievement_percentage, achievement_percentage))
    INTO v_goal_score
    FROM nexus_performance.employee_goals
    WHERE cycle_id = v_appraisal_record.cycle_id
    AND employee_id = v_appraisal_record.employee_id
    AND goal_status IN ('ACTIVE', 'COMPLETED');

    v_goal_score := COALESCE(v_goal_score, 0.00);

    -- Calculate Competency Score
    SELECT AVG(final_rating)
    INTO v_competency_score
    FROM nexus_performance.competency_assessments
    WHERE appraisal_id = p_appraisal_id
    AND final_rating IS NOT NULL;

    v_competency_score := COALESCE(v_competency_score, 0.00);

    -- Calculate Behavioral Score (based on behavioral competencies)
    SELECT AVG(final_rating)
    INTO v_behavioral_score
    FROM nexus_performance.competency_assessments ca
    JOIN nexus_performance.competency_master cm ON ca.competency_id = cm.competency_id
    WHERE ca.appraisal_id = p_appraisal_id
    AND cm.competency_category = 'BEHAVIORAL'
    AND ca.final_rating IS NOT NULL;

    v_behavioral_score := COALESCE(v_behavioral_score, v_competency_score);

    -- Calculate Overall Score using template weightages
    v_overall_score := (
        (v_goal_score * v_template_record.goal_achievement_weightage / 100) +
        (v_competency_score * v_template_record.competency_rating_weightage / 100) +
        (v_behavioral_score * v_template_record.behavioral_rating_weightage / 100)
    );

    -- Convert to final rating (assuming 5-point scale)
    v_final_rating := (v_overall_score / 100) * 5;

    -- Determine performance category
    v_performance_category := CASE
        WHEN v_final_rating >= 4.5 THEN 'OUTSTANDING'
        WHEN v_final_rating >= 3.5 THEN 'EXCEEDS'
        WHEN v_final_rating >= 2.5 THEN 'MEETS'
        WHEN v_final_rating >= 1.5 THEN 'BELOW'
        ELSE 'UNSATISFACTORY'
    END;

    -- Update appraisal record
    UPDATE nexus_performance.employee_performance_appraisals
    SET goal_achievement_score = v_goal_score,
        competency_score = v_competency_score,
        behavioral_score = v_behavioral_score,
        overall_score = v_overall_score,
        final_rating = v_final_rating,
        performance_category = v_performance_category,
        last_modified_at = CURRENT_TIMESTAMP
    WHERE appraisal_id = p_appraisal_id;

    RETURN jsonb_build_object(
        'success', true,
        'appraisal_id', p_appraisal_id,
        'goal_achievement_score', v_goal_score,
        'competency_score', v_competency_score,
        'behavioral_score', v_behavioral_score,
        'overall_score', v_overall_score,
        'final_rating', v_final_rating,
        'performance_category', v_performance_category
    );
END;
$$ LANGUAGE plpgsql;

-- Generate performance rankings
CREATE OR REPLACE FUNCTION nexus_performance.generate_performance_rankings(
    p_company_id BIGINT,
    p_cycle_id BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    v_appraisal_record RECORD;
    v_rank INTEGER;
    v_processed_count INTEGER := 0;
BEGIN
    -- Generate overall company rankings
    FOR v_appraisal_record IN
        SELECT appraisal_id, final_rating,
               ROW_NUMBER() OVER (ORDER BY final_rating DESC, overall_score DESC) as company_rank
        FROM nexus_performance.employee_performance_appraisals
        WHERE company_id = p_company_id
        AND cycle_id = p_cycle_id
        AND final_rating IS NOT NULL
        ORDER BY final_rating DESC, overall_score DESC
    LOOP
        UPDATE nexus_performance.employee_performance_appraisals
        SET overall_company_rank = v_appraisal_record.company_rank,
            percentile_rank = ROUND(
                (1.0 - (v_appraisal_record.company_rank - 1.0) /
                 (SELECT COUNT(*) FROM nexus_performance.employee_performance_appraisals
                  WHERE company_id = p_company_id AND cycle_id = p_cycle_id AND final_rating IS NOT NULL)
                ) * 100, 2
            )
        WHERE appraisal_id = v_appraisal_record.appraisal_id;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    -- Generate department rankings
    FOR v_appraisal_record IN
        SELECT
            epa.appraisal_id,
            emp.department_id,
            ROW_NUMBER() OVER (
                PARTITION BY emp.department_id
                ORDER BY epa.final_rating DESC, epa.overall_score DESC
            ) as dept_rank
        FROM nexus_performance.employee_performance_appraisals epa
        JOIN nexus_foundation.employee_master emp ON epa.employee_id = emp.employee_id
        WHERE epa.company_id = p_company_id
        AND epa.cycle_id = p_cycle_id
        AND epa.final_rating IS NOT NULL
    LOOP
        UPDATE nexus_performance.employee_performance_appraisals
        SET department_rank = v_appraisal_record.dept_rank
        WHERE appraisal_id = v_appraisal_record.appraisal_id;
    END LOOP;

    -- Generate grade rankings
    FOR v_appraisal_record IN
        SELECT
            appraisal_id,
            employee_grade,
            ROW_NUMBER() OVER (
                PARTITION BY employee_grade
                ORDER BY final_rating DESC, overall_score DESC
            ) as grade_rank
        FROM nexus_performance.employee_performance_appraisals
        WHERE company_id = p_company_id
        AND cycle_id = p_cycle_id
        AND final_rating IS NOT NULL
        AND employee_grade IS NOT NULL
    LOOP
        UPDATE nexus_performance.employee_performance_appraisals
        SET grade_rank = v_appraisal_record.grade_rank
        WHERE appraisal_id = v_appraisal_record.appraisal_id;
    END LOOP;

    RETURN v_processed_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA nexus_performance IS 'Comprehensive performance management system with goal setting, appraisals, 360-degree feedback, competency assessment, and performance improvement plans';

COMMENT ON TABLE nexus_performance.performance_cycle_master IS 'Annual or periodic performance review cycles with configurable timelines and assessment methods';
COMMENT ON TABLE nexus_performance.performance_template_master IS 'Configurable performance templates for different employee categories with assessment criteria';
COMMENT ON TABLE nexus_performance.competency_master IS 'Skills and competencies framework for structured assessment across the organization';
COMMENT ON TABLE nexus_performance.employee_goals IS 'Individual employee goals with SMART criteria, progress tracking, and achievement measurement';
COMMENT ON TABLE nexus_performance.goal_progress_updates IS 'Regular progress updates on employee goals with manager feedback and support tracking';
COMMENT ON TABLE nexus_performance.employee_performance_appraisals IS 'Core appraisal records with comprehensive scoring, ranking, and workflow management';
COMMENT ON TABLE nexus_performance.competency_assessments IS 'Detailed competency ratings from multiple sources with development recommendations';
COMMENT ON TABLE nexus_performance.feedback_requests IS '360-degree feedback collection system with configurable reviewer relationships';
COMMENT ON TABLE nexus_performance.feedback_responses IS 'Detailed 360-degree feedback responses with anonymity and confidentiality controls';
COMMENT ON TABLE nexus_performance.performance_improvement_plans IS 'Structured improvement plans for underperforming employees with clear objectives and timelines';
COMMENT ON TABLE nexus_performance.pip_progress_reviews IS 'Regular review sessions during PIP period with progress assessment and outcome tracking';

-- =====================================================================================
-- SCHEMA COMPLETION
-- =====================================================================================

-- Grant permissions to application role
GRANT USAGE ON SCHEMA nexus_performance TO nexus_app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nexus_performance TO nexus_app_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA nexus_performance TO nexus_app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nexus_performance TO nexus_app_role;

-- Grant read-only access to reporting role
GRANT USAGE ON SCHEMA nexus_performance TO nexus_readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_performance TO nexus_readonly_role;
GRANT EXECUTE ON FUNCTION nexus_performance.calculate_overall_performance_score TO nexus_readonly_role;

RAISE NOTICE 'NEXUS Performance Management Schema created successfully with:
- 11 core tables with comprehensive performance lifecycle management
- Goal setting and tracking with SMART criteria and progress monitoring
- Multi-source appraisal system with competency and behavioral assessment
- 360-degree feedback system with anonymity and confidentiality controls
- Performance improvement plans with structured review and outcome tracking
- Advanced analytics views for performance insights and talent management
- Configurable performance cycles and templates for different employee categories
- Row Level Security and audit trails for sensitive performance data protection
- Stored procedures for automated performance calculations and ranking generation
- GraphQL-optimized structure for modern frontend integration with real-time updates';

-- End of 05_nexus_performance_schema.sql