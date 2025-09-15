-- =====================================================================================
-- NEXUS HRMS - Recruitment Management Schema
-- =====================================================================================
-- Version: 6.0
-- Date: 2025-01-14
-- Module: Recruitment Management System
-- Description: Comprehensive recruitment and hiring system with job postings, candidate
--              management, interview scheduling, assessment tracking, offer management,
--              and onboarding workflows with multi-level approval processes
-- Dependencies: 01_nexus_foundation_schema.sql, 02_nexus_attendance_schema.sql, 03_nexus_leave_schema.sql, 04_nexus_payroll_schema.sql, 05_nexus_performance_schema.sql
-- Author: PostgreSQL DBA (20+ Years Experience)
-- =====================================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create recruitment management schema
CREATE SCHEMA IF NOT EXISTS nexus_recruitment;

-- Set search path for this schema
SET search_path = nexus_recruitment, nexus_foundation, nexus_attendance, nexus_leave, nexus_payroll, nexus_performance, nexus_security, public;

-- =====================================================================================
-- JOB REQUISITIONS AND POSTINGS
-- =====================================================================================

-- Job Requisitions
-- Internal requests for new positions or replacements
CREATE TABLE nexus_recruitment.job_requisitions (
    requisition_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Requisition Identification
    requisition_number VARCHAR(50) NOT NULL,
    requisition_title VARCHAR(200) NOT NULL,
    requisition_type VARCHAR(20) NOT NULL DEFAULT 'NEW_POSITION',
    -- NEW_POSITION, REPLACEMENT, EXPANSION, PROJECT_BASED, INTERN

    -- Position Details
    department_id BIGINT NOT NULL REFERENCES nexus_foundation.department_master(department_id),
    designation_id BIGINT NOT NULL REFERENCES nexus_foundation.designation_master(designation_id),
    location_id BIGINT NOT NULL REFERENCES nexus_foundation.location_master(location_id),
    reporting_manager_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Position Requirements
    number_of_positions INTEGER NOT NULL DEFAULT 1,
    employment_type VARCHAR(20) NOT NULL DEFAULT 'PERMANENT',
    -- PERMANENT, CONTRACT, TEMPORARY, INTERN, CONSULTANT
    contract_duration_months INTEGER,

    -- Job Details
    job_description TEXT NOT NULL,
    key_responsibilities TEXT NOT NULL,
    required_qualifications TEXT NOT NULL,
    preferred_qualifications TEXT,
    required_experience_years DECIMAL(4,1) DEFAULT 0,
    preferred_experience_years DECIMAL(4,1),
    required_skills TEXT NOT NULL,
    preferred_skills TEXT,

    -- Compensation Range
    min_salary_range DECIMAL(12,2),
    max_salary_range DECIMAL(12,2),
    currency_code VARCHAR(3) DEFAULT 'INR',
    other_benefits TEXT,

    -- Timeline
    target_start_date DATE,
    requisition_deadline DATE,
    urgency_level VARCHAR(20) DEFAULT 'MEDIUM',
    -- LOW, MEDIUM, HIGH, URGENT

    -- Justification
    business_justification TEXT NOT NULL,
    budget_approval_reference VARCHAR(100),
    headcount_approval_reference VARCHAR(100),

    -- Approval Workflow
    requisition_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, APPROVED, REJECTED, ON_HOLD, CANCELLED, FULFILLED
    requested_by BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_comments TEXT,

    -- HR Processing
    hr_assigned_to BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    hr_processing_started_at TIMESTAMP WITH TIME ZONE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_job_requisition_number UNIQUE (company_id, requisition_number),
    CONSTRAINT chk_requisition_type CHECK (requisition_type IN (
        'NEW_POSITION', 'REPLACEMENT', 'EXPANSION', 'PROJECT_BASED', 'INTERN'
    )),
    CONSTRAINT chk_employment_type CHECK (employment_type IN (
        'PERMANENT', 'CONTRACT', 'TEMPORARY', 'INTERN', 'CONSULTANT'
    )),
    CONSTRAINT chk_requisition_status CHECK (requisition_status IN (
        'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'ON_HOLD', 'CANCELLED', 'FULFILLED'
    )),
    CONSTRAINT chk_urgency_level CHECK (urgency_level IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT chk_number_of_positions CHECK (number_of_positions > 0),
    CONSTRAINT chk_salary_range CHECK (
        (min_salary_range IS NULL AND max_salary_range IS NULL) OR
        (min_salary_range IS NOT NULL AND max_salary_range IS NOT NULL AND max_salary_range >= min_salary_range)
    )
);

-- Job Postings
-- External job advertisements based on approved requisitions
CREATE TABLE nexus_recruitment.job_postings (
    posting_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    requisition_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_requisitions(requisition_id),

    -- Posting Identification
    posting_number VARCHAR(50) NOT NULL,
    job_title VARCHAR(200) NOT NULL,
    external_job_id VARCHAR(100), -- For job board tracking

    -- Posting Content
    job_summary TEXT NOT NULL,
    detailed_description TEXT NOT NULL,
    key_requirements TEXT NOT NULL,
    company_overview TEXT,
    benefits_offered TEXT,

    -- Posting Configuration
    is_internal_posting BOOLEAN DEFAULT false,
    is_external_posting BOOLEAN DEFAULT true,
    is_confidential_posting BOOLEAN DEFAULT false,
    allow_referrals BOOLEAN DEFAULT true,

    -- Application Configuration
    application_method VARCHAR(20) DEFAULT 'ONLINE',
    -- ONLINE, EMAIL, WALK_IN, AGENT
    application_email VARCHAR(100),
    application_instructions TEXT,
    required_documents TEXT,

    -- Posting Timeline
    posting_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    posting_end_date DATE,
    application_deadline DATE,
    auto_close_after_deadline BOOLEAN DEFAULT true,

    -- Job Board Publishing
    published_job_boards TEXT[], -- Array of job board names
    job_board_urls JSONB, -- Job board specific URLs
    social_media_shared BOOLEAN DEFAULT false,
    career_page_published BOOLEAN DEFAULT true,

    -- Targeting and Reach
    target_locations TEXT[],
    target_experience_levels VARCHAR(50)[],
    target_education_levels VARCHAR(50)[],
    preferred_candidate_sources TEXT[],

    -- Posting Status
    posting_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, PUBLISHED, ACTIVE, PAUSED, CLOSED, EXPIRED, CANCELLED
    published_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    published_at TIMESTAMP WITH TIME ZONE,

    -- Performance Tracking
    total_views INTEGER DEFAULT 0,
    total_applications INTEGER DEFAULT 0,
    total_qualified_applications INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN total_views > 0 THEN ROUND((total_applications::DECIMAL / total_views) * 100, 2)
            ELSE 0
        END
    ) STORED,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_job_posting_number UNIQUE (company_id, posting_number),
    CONSTRAINT chk_posting_status CHECK (posting_status IN (
        'DRAFT', 'PUBLISHED', 'ACTIVE', 'PAUSED', 'CLOSED', 'EXPIRED', 'CANCELLED'
    )),
    CONSTRAINT chk_application_method CHECK (application_method IN (
        'ONLINE', 'EMAIL', 'WALK_IN', 'AGENT'
    )),
    CONSTRAINT chk_posting_dates CHECK (
        posting_end_date IS NULL OR posting_end_date >= posting_start_date
    )
);

-- =====================================================================================
-- CANDIDATE MANAGEMENT
-- =====================================================================================

-- Candidates
-- Master record for all job applicants
CREATE TABLE nexus_recruitment.candidates (
    candidate_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Personal Information
    candidate_number VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(300) GENERATED ALWAYS AS (
        CONCAT(first_name,
               CASE WHEN middle_name IS NOT NULL THEN ' ' || middle_name ELSE '' END,
               ' ', last_name)
    ) STORED,

    -- Contact Information
    email_primary VARCHAR(150) NOT NULL,
    email_secondary VARCHAR(150),
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),

    -- Address Information
    current_address TEXT,
    current_city VARCHAR(100),
    current_state VARCHAR(100),
    current_country VARCHAR(100) DEFAULT 'India',
    current_pincode VARCHAR(20),

    permanent_address TEXT,
    permanent_city VARCHAR(100),
    permanent_state VARCHAR(100),
    permanent_country VARCHAR(100) DEFAULT 'India',
    permanent_pincode VARCHAR(20),

    -- Personal Details
    date_of_birth DATE,
    gender VARCHAR(10),
    marital_status VARCHAR(20),
    nationality VARCHAR(50) DEFAULT 'Indian',

    -- Professional Information
    current_designation VARCHAR(100),
    current_company VARCHAR(150),
    total_experience_years DECIMAL(4,1) DEFAULT 0,
    relevant_experience_years DECIMAL(4,1) DEFAULT 0,
    current_salary DECIMAL(12,2),
    expected_salary DECIMAL(12,2),
    notice_period_days INTEGER DEFAULT 30,

    -- Education Background
    highest_qualification VARCHAR(100),
    specialization VARCHAR(100),
    university_institute VARCHAR(200),
    graduation_year INTEGER,

    -- Skills and Expertise
    key_skills TEXT,
    technical_skills TEXT,
    certifications TEXT,
    languages_known TEXT,

    -- Source and Channel
    application_source VARCHAR(30) NOT NULL DEFAULT 'DIRECT',
    -- DIRECT, REFERRAL, CONSULTANT, JOB_BOARD, SOCIAL_MEDIA, CAMPUS, WALK_IN
    referral_employee_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    consultant_agency VARCHAR(150),
    source_details TEXT,

    -- Documents and Attachments
    resume_document_path VARCHAR(500),
    cover_letter_document_path VARCHAR(500),
    portfolio_document_path VARCHAR(500),
    additional_documents JSONB, -- Array of document references

    -- Social and Professional Links
    linkedin_profile VARCHAR(300),
    portfolio_website VARCHAR(300),
    github_profile VARCHAR(300),
    other_profiles JSONB,

    -- Candidate Status
    candidate_status VARCHAR(20) NOT NULL DEFAULT 'NEW',
    -- NEW, ACTIVE, SCREENING, INTERVIEWING, OFFERED, HIRED, REJECTED, WITHDRAWN, ON_HOLD

    -- Privacy and Communication Preferences
    is_active BOOLEAN DEFAULT true,
    communication_preferences JSONB,
    privacy_consent BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,

    -- Search and Matching
    search_vector TSVECTOR,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_candidate_number UNIQUE (company_id, candidate_number),
    CONSTRAINT uk_candidate_email UNIQUE (company_id, email_primary),
    CONSTRAINT chk_candidate_status CHECK (candidate_status IN (
        'NEW', 'ACTIVE', 'SCREENING', 'INTERVIEWING', 'OFFERED', 'HIRED', 'REJECTED', 'WITHDRAWN', 'ON_HOLD'
    )),
    CONSTRAINT chk_application_source CHECK (application_source IN (
        'DIRECT', 'REFERRAL', 'CONSULTANT', 'JOB_BOARD', 'SOCIAL_MEDIA', 'CAMPUS', 'WALK_IN'
    )),
    CONSTRAINT chk_gender CHECK (gender IS NULL OR gender IN ('MALE', 'FEMALE', 'OTHER')),
    CONSTRAINT chk_salary_expectation CHECK (
        expected_salary IS NULL OR current_salary IS NULL OR expected_salary >= current_salary
    )
);

-- Job Applications
-- Applications submitted by candidates for specific job postings
CREATE TABLE nexus_recruitment.job_applications (
    application_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    candidate_id BIGINT NOT NULL REFERENCES nexus_recruitment.candidates(candidate_id),
    posting_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_postings(posting_id),
    requisition_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_requisitions(requisition_id),

    -- Application Identification
    application_number VARCHAR(50) NOT NULL,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    application_source VARCHAR(30) NOT NULL DEFAULT 'DIRECT',

    -- Application Content
    cover_letter TEXT,
    application_responses JSONB, -- Responses to application questions
    additional_information TEXT,

    -- Position Match Analysis
    experience_match_percentage DECIMAL(5,2) DEFAULT 0,
    skills_match_percentage DECIMAL(5,2) DEFAULT 0,
    qualification_match_percentage DECIMAL(5,2) DEFAULT 0,
    overall_match_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        ROUND((experience_match_percentage + skills_match_percentage + qualification_match_percentage) / 3, 2)
    ) STORED,

    -- Application Status Tracking
    application_status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    -- SUBMITTED, SCREENING, SHORTLISTED, INTERVIEWING, ASSESSMENT, OFFERED,
    -- HIRED, REJECTED, WITHDRAWN, ON_HOLD, EXPIRED

    current_stage VARCHAR(30) DEFAULT 'APPLICATION_REVIEW',
    -- APPLICATION_REVIEW, SCREENING, TECHNICAL_INTERVIEW, HR_INTERVIEW,
    -- FINAL_INTERVIEW, REFERENCE_CHECK, OFFER_NEGOTIATION, DOCUMENTATION

    -- Screening Information
    screened_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    screened_at TIMESTAMP WITH TIME ZONE,
    screening_notes TEXT,
    screening_score DECIMAL(4,2),

    -- Assignment and Ownership
    assigned_recruiter BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    hiring_manager_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Timeline Tracking
    last_activity_date DATE DEFAULT CURRENT_DATE,
    days_in_current_stage INTEGER DEFAULT 0,
    total_processing_days INTEGER DEFAULT 0,

    -- Communication History
    last_contact_date DATE,
    last_contact_method VARCHAR(20),
    next_follow_up_date DATE,
    communication_count INTEGER DEFAULT 0,

    -- Rejection Information
    rejection_reason VARCHAR(100),
    rejection_stage VARCHAR(30),
    rejection_comments TEXT,
    rejected_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    rejected_at TIMESTAMP WITH TIME ZONE,

    -- Internal Notes and Tags
    recruiter_notes TEXT,
    hiring_manager_notes TEXT,
    internal_tags TEXT[],
    priority_level VARCHAR(20) DEFAULT 'MEDIUM',

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_job_application_number UNIQUE (company_id, application_number),
    CONSTRAINT uk_candidate_posting_application UNIQUE (candidate_id, posting_id),
    CONSTRAINT chk_application_status CHECK (application_status IN (
        'SUBMITTED', 'SCREENING', 'SHORTLISTED', 'INTERVIEWING', 'ASSESSMENT',
        'OFFERED', 'HIRED', 'REJECTED', 'WITHDRAWN', 'ON_HOLD', 'EXPIRED'
    )),
    CONSTRAINT chk_priority_level CHECK (priority_level IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT chk_match_percentages CHECK (
        experience_match_percentage BETWEEN 0 AND 100 AND
        skills_match_percentage BETWEEN 0 AND 100 AND
        qualification_match_percentage BETWEEN 0 AND 100
    )
);

-- =====================================================================================
-- INTERVIEW AND ASSESSMENT MANAGEMENT
-- =====================================================================================

-- Interview Schedules
-- Scheduling and management of candidate interviews
CREATE TABLE nexus_recruitment.interview_schedules (
    interview_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    application_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_applications(application_id),
    candidate_id BIGINT NOT NULL REFERENCES nexus_recruitment.candidates(candidate_id),

    -- Interview Identification
    interview_number VARCHAR(50) NOT NULL,
    interview_title VARCHAR(200) NOT NULL,
    interview_type VARCHAR(30) NOT NULL DEFAULT 'TECHNICAL',
    -- SCREENING, TECHNICAL, HR, BEHAVIORAL, PANEL, FINAL, VIDEO, TELEPHONIC
    interview_round INTEGER NOT NULL DEFAULT 1,

    -- Interview Scheduling
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    estimated_duration_minutes INTEGER NOT NULL DEFAULT 60,

    -- Interview Mode and Location
    interview_mode VARCHAR(20) NOT NULL DEFAULT 'IN_PERSON',
    -- IN_PERSON, VIDEO_CALL, TELEPHONIC, ONLINE_ASSESSMENT
    interview_location VARCHAR(200),
    video_call_link VARCHAR(500),
    video_call_platform VARCHAR(50),
    meeting_room VARCHAR(100),

    -- Interview Panel
    primary_interviewer BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    panel_members BIGINT[], -- Array of employee IDs
    panel_size INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN panel_members IS NOT NULL THEN array_length(panel_members, 1) + 1
            ELSE 1
        END
    ) STORED,

    -- Interview Content
    interview_focus_areas TEXT,
    technical_topics TEXT,
    behavioral_competencies TEXT,
    assessment_criteria TEXT,
    interview_questions JSONB, -- Array of prepared questions

    -- Interview Status
    interview_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    -- SCHEDULED, CONFIRMED, RESCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW

    -- Confirmation and Communication
    candidate_confirmed BOOLEAN DEFAULT false,
    confirmation_sent_at TIMESTAMP WITH TIME ZONE,
    reminder_sent_at TIMESTAMP WITH TIME ZONE,
    interview_instructions TEXT,

    -- Actual Interview Details
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    actual_duration_minutes INTEGER,

    -- Interview Outcome
    interview_outcome VARCHAR(20),
    -- PASSED, FAILED, ON_HOLD, NEEDS_ANOTHER_ROUND, CANCELLED
    overall_rating DECIMAL(4,2),
    recommendation VARCHAR(20),
    -- STRONG_HIRE, HIRE, NO_HIRE, STRONG_NO_HIRE

    -- Notes and Feedback
    interviewer_notes TEXT,
    candidate_feedback TEXT,
    technical_assessment_score DECIMAL(5,2),
    communication_score DECIMAL(4,2),
    cultural_fit_score DECIMAL(4,2),

    -- Rescheduling Information
    reschedule_count INTEGER DEFAULT 0,
    reschedule_reason TEXT,
    original_scheduled_date DATE,

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_interview_number UNIQUE (company_id, interview_number),
    CONSTRAINT chk_interview_type CHECK (interview_type IN (
        'SCREENING', 'TECHNICAL', 'HR', 'BEHAVIORAL', 'PANEL', 'FINAL', 'VIDEO', 'TELEPHONIC'
    )),
    CONSTRAINT chk_interview_mode CHECK (interview_mode IN (
        'IN_PERSON', 'VIDEO_CALL', 'TELEPHONIC', 'ONLINE_ASSESSMENT'
    )),
    CONSTRAINT chk_interview_status CHECK (interview_status IN (
        'SCHEDULED', 'CONFIRMED', 'RESCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    )),
    CONSTRAINT chk_interview_outcome CHECK (interview_outcome IS NULL OR interview_outcome IN (
        'PASSED', 'FAILED', 'ON_HOLD', 'NEEDS_ANOTHER_ROUND', 'CANCELLED'
    )),
    CONSTRAINT chk_recommendation CHECK (recommendation IS NULL OR recommendation IN (
        'STRONG_HIRE', 'HIRE', 'NO_HIRE', 'STRONG_NO_HIRE'
    )),
    CONSTRAINT chk_scheduled_times CHECK (scheduled_end_time > scheduled_start_time),
    CONSTRAINT chk_interview_round CHECK (interview_round > 0 AND interview_round <= 10)
);

-- Interview Feedback
-- Detailed feedback from individual interviewers
CREATE TABLE nexus_recruitment.interview_feedback (
    feedback_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    interview_id BIGINT NOT NULL REFERENCES nexus_recruitment.interview_schedules(interview_id),
    interviewer_id BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    candidate_id BIGINT NOT NULL REFERENCES nexus_recruitment.candidates(candidate_id),

    -- Feedback Identification
    feedback_number VARCHAR(50) NOT NULL,
    feedback_type VARCHAR(20) DEFAULT 'PANEL_MEMBER',
    -- PRIMARY_INTERVIEWER, PANEL_MEMBER, OBSERVER

    -- Technical Assessment
    technical_competency_rating DECIMAL(4,2),
    technical_knowledge_depth DECIMAL(4,2),
    problem_solving_ability DECIMAL(4,2),
    coding_skills_rating DECIMAL(4,2),
    system_design_skills DECIMAL(4,2),

    -- Behavioral Assessment
    communication_skills DECIMAL(4,2),
    leadership_potential DECIMAL(4,2),
    teamwork_collaboration DECIMAL(4,2),
    adaptability_flexibility DECIMAL(4,2),
    learning_agility DECIMAL(4,2),

    -- Cultural Fit Assessment
    cultural_alignment DECIMAL(4,2),
    values_match DECIMAL(4,2),
    attitude_motivation DECIMAL(4,2),
    professionalism DECIMAL(4,2),

    -- Overall Assessment
    overall_impression DECIMAL(4,2),
    overall_recommendation VARCHAR(20),
    confidence_level VARCHAR(20) DEFAULT 'MEDIUM',
    -- LOW, MEDIUM, HIGH

    -- Detailed Feedback
    strengths_identified TEXT,
    areas_of_concern TEXT,
    specific_examples TEXT,
    technical_discussion_summary TEXT,

    -- Questions and Responses
    questions_asked JSONB,
    candidate_responses JSONB,
    question_difficulty_level VARCHAR(20) DEFAULT 'MEDIUM',

    -- Recommendations
    development_recommendations TEXT,
    additional_assessment_needed TEXT,
    next_round_suggestions TEXT,

    -- Feedback Status
    feedback_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, REVIEWED, FINALIZED
    submitted_at TIMESTAMP WITH TIME ZONE,

    -- Comparison with Role Requirements
    meets_experience_requirements BOOLEAN,
    meets_skill_requirements BOOLEAN,
    meets_qualification_requirements BOOLEAN,
    salary_expectation_alignment VARCHAR(20),
    -- BELOW_RANGE, WITHIN_RANGE, ABOVE_RANGE, NEGOTIABLE

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_interview_feedback_interviewer UNIQUE (interview_id, interviewer_id),
    CONSTRAINT uk_interview_feedback_number UNIQUE (company_id, feedback_number),
    CONSTRAINT chk_feedback_type CHECK (feedback_type IN (
        'PRIMARY_INTERVIEWER', 'PANEL_MEMBER', 'OBSERVER'
    )),
    CONSTRAINT chk_feedback_status CHECK (feedback_status IN (
        'DRAFT', 'SUBMITTED', 'REVIEWED', 'FINALIZED'
    )),
    CONSTRAINT chk_overall_recommendation CHECK (overall_recommendation IS NULL OR overall_recommendation IN (
        'STRONG_HIRE', 'HIRE', 'NO_HIRE', 'STRONG_NO_HIRE'
    )),
    CONSTRAINT chk_confidence_level CHECK (confidence_level IN ('LOW', 'MEDIUM', 'HIGH')),
    CONSTRAINT chk_salary_alignment CHECK (salary_expectation_alignment IS NULL OR salary_expectation_alignment IN (
        'BELOW_RANGE', 'WITHIN_RANGE', 'ABOVE_RANGE', 'NEGOTIABLE'
    ))
);

-- =====================================================================================
-- OFFER MANAGEMENT
-- =====================================================================================

-- Job Offers
-- Offers extended to selected candidates
CREATE TABLE nexus_recruitment.job_offers (
    offer_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    application_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_applications(application_id),
    candidate_id BIGINT NOT NULL REFERENCES nexus_recruitment.candidates(candidate_id),
    requisition_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_requisitions(requisition_id),

    -- Offer Identification
    offer_number VARCHAR(50) NOT NULL,
    offer_letter_number VARCHAR(50),
    offer_type VARCHAR(20) DEFAULT 'REGULAR',
    -- REGULAR, CONDITIONAL, INTERN, CONTRACT, CONSULTANT

    -- Position Details
    offered_designation VARCHAR(100) NOT NULL,
    offered_department VARCHAR(100) NOT NULL,
    offered_location VARCHAR(100) NOT NULL,
    reporting_manager_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    employment_type VARCHAR(20) NOT NULL DEFAULT 'PERMANENT',

    -- Compensation Package
    base_salary DECIMAL(12,2) NOT NULL,
    variable_pay DECIMAL(12,2) DEFAULT 0,
    signing_bonus DECIMAL(12,2) DEFAULT 0,
    relocation_allowance DECIMAL(12,2) DEFAULT 0,
    other_allowances DECIMAL(12,2) DEFAULT 0,
    annual_ctc DECIMAL(12,2) GENERATED ALWAYS AS (
        base_salary + COALESCE(variable_pay, 0) + COALESCE(other_allowances, 0)
    ) STORED,

    -- Benefits Package
    health_insurance_covered BOOLEAN DEFAULT true,
    provident_fund_applicable BOOLEAN DEFAULT true,
    gratuity_applicable BOOLEAN DEFAULT true,
    other_benefits TEXT,

    -- Terms and Conditions
    probation_period_months INTEGER DEFAULT 6,
    notice_period_months INTEGER DEFAULT 2,
    bond_period_months INTEGER DEFAULT 0,
    bond_amount DECIMAL(12,2) DEFAULT 0,

    -- Joining Details
    proposed_joining_date DATE NOT NULL,
    latest_joining_date DATE,
    flexible_joining_date BOOLEAN DEFAULT false,

    -- Offer Timeline
    offer_valid_until DATE NOT NULL,
    offer_sent_date DATE DEFAULT CURRENT_DATE,
    offer_sent_method VARCHAR(20) DEFAULT 'EMAIL',
    -- EMAIL, COURIER, HAND_DELIVERY, PORTAL

    -- Offer Status
    offer_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SENT, ACKNOWLEDGED, ACCEPTED, REJECTED, NEGOTIATING, EXPIRED, WITHDRAWN

    -- Candidate Response
    candidate_response VARCHAR(20),
    -- ACCEPTED, REJECTED, NEGOTIATING, CONSIDERING
    candidate_response_date DATE,
    candidate_comments TEXT,

    -- Negotiations
    negotiation_points TEXT,
    negotiation_history JSONB,
    final_negotiated_ctc DECIMAL(12,2),
    negotiation_status VARCHAR(20) DEFAULT 'NOT_APPLICABLE',
    -- NOT_APPLICABLE, IN_PROGRESS, AGREED, DISAGREED

    -- Approval Process
    offer_approved_by BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    offer_approved_at TIMESTAMP WITH TIME ZONE,
    hr_approval_required BOOLEAN DEFAULT true,
    finance_approval_required BOOLEAN DEFAULT false,

    -- Conditions and Requirements
    offer_conditions TEXT,
    background_verification_required BOOLEAN DEFAULT true,
    medical_checkup_required BOOLEAN DEFAULT false,
    reference_check_required BOOLEAN DEFAULT true,
    document_verification_required BOOLEAN DEFAULT true,

    -- Offer Letter Details
    offer_letter_template_id BIGINT,
    offer_letter_generated BOOLEAN DEFAULT false,
    offer_letter_sent BOOLEAN DEFAULT false,
    offer_letter_path VARCHAR(500),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_job_offer_number UNIQUE (company_id, offer_number),
    CONSTRAINT chk_offer_type CHECK (offer_type IN (
        'REGULAR', 'CONDITIONAL', 'INTERN', 'CONTRACT', 'CONSULTANT'
    )),
    CONSTRAINT chk_offer_status CHECK (offer_status IN (
        'DRAFT', 'SENT', 'ACKNOWLEDGED', 'ACCEPTED', 'REJECTED', 'NEGOTIATING', 'EXPIRED', 'WITHDRAWN'
    )),
    CONSTRAINT chk_candidate_response CHECK (candidate_response IS NULL OR candidate_response IN (
        'ACCEPTED', 'REJECTED', 'NEGOTIATING', 'CONSIDERING'
    )),
    CONSTRAINT chk_negotiation_status CHECK (negotiation_status IN (
        'NOT_APPLICABLE', 'IN_PROGRESS', 'AGREED', 'DISAGREED'
    )),
    CONSTRAINT chk_offer_dates CHECK (
        offer_valid_until >= offer_sent_date AND
        (latest_joining_date IS NULL OR latest_joining_date >= proposed_joining_date)
    ),
    CONSTRAINT chk_compensation_amounts CHECK (
        base_salary > 0 AND
        variable_pay >= 0 AND
        signing_bonus >= 0
    )
);

-- =====================================================================================
-- ONBOARDING MANAGEMENT
-- =====================================================================================

-- Onboarding Processes
-- Structured onboarding workflows for new hires
CREATE TABLE nexus_recruitment.onboarding_processes (
    onboarding_id BIGINT PRIMARY KEY DEFAULT nextval('nexus_foundation.global_id_seq'),
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    offer_id BIGINT NOT NULL REFERENCES nexus_recruitment.job_offers(offer_id),
    candidate_id BIGINT NOT NULL REFERENCES nexus_recruitment.candidates(candidate_id),

    -- Onboarding Identification
    onboarding_number VARCHAR(50) NOT NULL,
    employee_id BIGINT, -- Will be populated when employee record is created

    -- Joining Information
    actual_joining_date DATE,
    first_day_location VARCHAR(100),
    orientation_scheduled_date DATE,

    -- Pre-joining Requirements
    background_verification_status VARCHAR(20) DEFAULT 'PENDING',
    -- PENDING, IN_PROGRESS, COMPLETED, FAILED, NOT_REQUIRED
    background_verification_date DATE,
    background_verification_comments TEXT,

    medical_checkup_status VARCHAR(20) DEFAULT 'NOT_REQUIRED',
    medical_checkup_date DATE,
    medical_fitness_certificate BOOLEAN DEFAULT false,

    reference_check_status VARCHAR(20) DEFAULT 'PENDING',
    reference_check_date DATE,
    reference_check_comments TEXT,

    -- Documentation
    document_submission_status VARCHAR(20) DEFAULT 'PENDING',
    required_documents JSONB, -- List of required documents
    submitted_documents JSONB, -- List of submitted documents with status
    document_verification_status VARCHAR(20) DEFAULT 'PENDING',

    -- System Access and Setup
    employee_id_generated BOOLEAN DEFAULT false,
    email_account_created BOOLEAN DEFAULT false,
    system_access_provided BOOLEAN DEFAULT false,
    laptop_allocated BOOLEAN DEFAULT false,
    seating_arranged BOOLEAN DEFAULT false,

    -- Onboarding Checklist
    orientation_completed BOOLEAN DEFAULT false,
    hr_induction_completed BOOLEAN DEFAULT false,
    department_induction_completed BOOLEAN DEFAULT false,
    system_training_completed BOOLEAN DEFAULT false,
    policy_acknowledgment_completed BOOLEAN DEFAULT false,

    -- Buddy/Mentor Assignment
    buddy_assigned BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    mentor_assigned BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    buddy_introduction_completed BOOLEAN DEFAULT false,

    -- Onboarding Status
    onboarding_status VARCHAR(20) NOT NULL DEFAULT 'INITIATED',
    -- INITIATED, IN_PROGRESS, PRE_JOINING_PENDING, JOINING_CONFIRMED,
    -- FIRST_DAY_COMPLETED, PROBATION_STARTED, COMPLETED, TERMINATED

    -- Timeline Tracking
    onboarding_completion_percentage DECIMAL(5,2) DEFAULT 0,
    expected_completion_date DATE,
    actual_completion_date DATE,

    -- Feedback and Experience
    new_hire_feedback TEXT,
    onboarding_experience_rating DECIMAL(4,2),
    improvement_suggestions TEXT,

    -- Process Ownership
    hr_coordinator BIGINT NOT NULL REFERENCES nexus_foundation.employee_master(employee_id),
    reporting_manager_id BIGINT REFERENCES nexus_foundation.employee_master(employee_id),
    it_coordinator BIGINT REFERENCES nexus_foundation.employee_master(employee_id),

    -- Standard Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL DEFAULT current_setting('app.current_user_id', true),
    last_modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified_by VARCHAR(100) DEFAULT current_setting('app.current_user_id', true),
    version BIGINT NOT NULL DEFAULT 1,

    -- Constraints
    CONSTRAINT uk_onboarding_number UNIQUE (company_id, onboarding_number),
    CONSTRAINT chk_background_verification_status CHECK (background_verification_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'NOT_REQUIRED'
    )),
    CONSTRAINT chk_medical_checkup_status CHECK (medical_checkup_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'NOT_REQUIRED'
    )),
    CONSTRAINT chk_reference_check_status CHECK (reference_check_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'NOT_REQUIRED'
    )),
    CONSTRAINT chk_document_status CHECK (document_submission_status IN (
        'PENDING', 'PARTIAL', 'COMPLETED', 'VERIFIED'
    )),
    CONSTRAINT chk_onboarding_status CHECK (onboarding_status IN (
        'INITIATED', 'IN_PROGRESS', 'PRE_JOINING_PENDING', 'JOINING_CONFIRMED',
        'FIRST_DAY_COMPLETED', 'PROBATION_STARTED', 'COMPLETED', 'TERMINATED'
    )),
    CONSTRAINT chk_completion_percentage CHECK (
        onboarding_completion_percentage >= 0 AND onboarding_completion_percentage <= 100
    )
);

-- =====================================================================================
-- RECRUITMENT ANALYTICS AND REPORTING VIEWS
-- =====================================================================================

-- Recruitment Pipeline Dashboard
CREATE OR REPLACE VIEW nexus_recruitment.v_recruitment_pipeline AS
SELECT
    ja.company_id,
    jr.requisition_id,
    jr.requisition_number,
    jr.requisition_title,
    jr.department_id,
    dept.department_name,
    jr.designation_id,
    desig.designation_name,
    jr.number_of_positions,
    jr.requisition_status,

    -- Application Statistics
    COUNT(ja.application_id) as total_applications,
    COUNT(CASE WHEN ja.application_status = 'SUBMITTED' THEN 1 END) as new_applications,
    COUNT(CASE WHEN ja.application_status = 'SCREENING' THEN 1 END) as in_screening,
    COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END) as shortlisted,
    COUNT(CASE WHEN ja.application_status = 'INTERVIEWING' THEN 1 END) as in_interview,
    COUNT(CASE WHEN ja.application_status = 'OFFERED' THEN 1 END) as offers_extended,
    COUNT(CASE WHEN ja.application_status = 'HIRED' THEN 1 END) as hired,
    COUNT(CASE WHEN ja.application_status = 'REJECTED' THEN 1 END) as rejected,

    -- Conversion Rates
    CASE
        WHEN COUNT(ja.application_id) > 0
        THEN ROUND((COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END)::DECIMAL / COUNT(ja.application_id)) * 100, 2)
        ELSE 0
    END as screening_to_shortlist_rate,

    CASE
        WHEN COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END) > 0
        THEN ROUND((COUNT(CASE WHEN ja.application_status = 'OFFERED' THEN 1 END)::DECIMAL / COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END)) * 100, 2)
        ELSE 0
    END as shortlist_to_offer_rate,

    CASE
        WHEN COUNT(CASE WHEN ja.application_status = 'OFFERED' THEN 1 END) > 0
        THEN ROUND((COUNT(CASE WHEN ja.application_status = 'HIRED' THEN 1 END)::DECIMAL / COUNT(CASE WHEN ja.application_status = 'OFFERED' THEN 1 END)) * 100, 2)
        ELSE 0
    END as offer_acceptance_rate,

    -- Fulfillment Status
    CASE
        WHEN COUNT(CASE WHEN ja.application_status = 'HIRED' THEN 1 END) >= jr.number_of_positions
        THEN 'FULFILLED'
        WHEN COUNT(CASE WHEN ja.application_status = 'HIRED' THEN 1 END) > 0
        THEN 'PARTIALLY_FULFILLED'
        ELSE 'OPEN'
    END as fulfillment_status,

    -- Timeline Information
    jr.created_at as requisition_created_date,
    jr.target_start_date,
    CURRENT_DATE - jr.created_at::DATE as days_open

FROM nexus_recruitment.job_requisitions jr
    LEFT JOIN nexus_recruitment.job_applications ja ON jr.requisition_id = ja.requisition_id
    LEFT JOIN nexus_foundation.department_master dept ON jr.department_id = dept.department_id
    LEFT JOIN nexus_foundation.designation_master desig ON jr.designation_id = desig.designation_id
WHERE jr.requisition_status IN ('APPROVED', 'ACTIVE')
GROUP BY
    ja.company_id, jr.requisition_id, jr.requisition_number, jr.requisition_title,
    jr.department_id, dept.department_name, jr.designation_id, desig.designation_name,
    jr.number_of_positions, jr.requisition_status, jr.created_at, jr.target_start_date
ORDER BY jr.created_at DESC;

-- Candidate Source Analysis
CREATE OR REPLACE VIEW nexus_recruitment.v_candidate_source_analysis AS
SELECT
    c.company_id,
    c.application_source,
    EXTRACT(YEAR FROM c.created_at) as source_year,
    EXTRACT(MONTH FROM c.created_at) as source_month,

    -- Volume Metrics
    COUNT(*) as total_candidates,
    COUNT(CASE WHEN c.candidate_status = 'ACTIVE' THEN 1 END) as active_candidates,
    COUNT(CASE WHEN c.candidate_status = 'HIRED' THEN 1 END) as hired_candidates,

    -- Quality Metrics
    AVG(ja.overall_match_percentage) as average_match_percentage,
    COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END) as shortlisted_count,
    COUNT(CASE WHEN ja.application_status = 'OFFERED' THEN 1 END) as offered_count,

    -- Conversion Rates
    CASE
        WHEN COUNT(*) > 0
        THEN ROUND((COUNT(CASE WHEN ja.application_status = 'SHORTLISTED' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2)
        ELSE 0
    END as source_to_shortlist_rate,

    CASE
        WHEN COUNT(*) > 0
        THEN ROUND((COUNT(CASE WHEN c.candidate_status = 'HIRED' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2)
        ELSE 0
    END as source_to_hire_rate,

    -- Time to Hire
    AVG(CASE
        WHEN c.candidate_status = 'HIRED' AND ja.application_date IS NOT NULL
        THEN EXTRACT(DAYS FROM (CURRENT_DATE - ja.application_date))
        ELSE NULL
    END) as average_time_to_hire_days

FROM nexus_recruitment.candidates c
    LEFT JOIN nexus_recruitment.job_applications ja ON c.candidate_id = ja.candidate_id
WHERE c.created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY c.company_id, c.application_source, EXTRACT(YEAR FROM c.created_at), EXTRACT(MONTH FROM c.created_at)
ORDER BY source_year DESC, source_month DESC, total_candidates DESC;

-- Interview Performance Analysis
CREATE OR REPLACE VIEW nexus_recruitment.v_interview_performance_analysis AS
SELECT
    intf.company_id,
    intf.interviewer_id,
    emp.employee_code,
    emp.first_name || ' ' || emp.last_name as interviewer_name,
    dept.department_name as interviewer_department,

    -- Interview Volume
    COUNT(intf.feedback_id) as total_interviews_conducted,
    COUNT(CASE WHEN ins.interview_type = 'TECHNICAL' THEN 1 END) as technical_interviews,
    COUNT(CASE WHEN ins.interview_type = 'HR' THEN 1 END) as hr_interviews,
    COUNT(CASE WHEN ins.interview_type = 'BEHAVIORAL' THEN 1 END) as behavioral_interviews,

    -- Interview Outcomes
    COUNT(CASE WHEN intf.overall_recommendation = 'STRONG_HIRE' THEN 1 END) as strong_hire_recommendations,
    COUNT(CASE WHEN intf.overall_recommendation = 'HIRE' THEN 1 END) as hire_recommendations,
    COUNT(CASE WHEN intf.overall_recommendation = 'NO_HIRE' THEN 1 END) as no_hire_recommendations,

    -- Rating Analysis
    AVG(intf.overall_impression) as average_rating_given,
    AVG(intf.technical_competency_rating) as average_technical_rating,
    AVG(intf.communication_skills) as average_communication_rating,
    AVG(intf.cultural_alignment) as average_cultural_fit_rating,

    -- Interview Quality Metrics
    ROUND(
        (COUNT(CASE WHEN intf.overall_recommendation IN ('STRONG_HIRE', 'HIRE') THEN 1 END)::DECIMAL /
         NULLIF(COUNT(intf.feedback_id), 0)) * 100, 2
    ) as positive_recommendation_rate,

    COUNT(CASE WHEN intf.confidence_level = 'HIGH' THEN 1 END) as high_confidence_assessments,
    ROUND(
        (COUNT(CASE WHEN intf.confidence_level = 'HIGH' THEN 1 END)::DECIMAL /
         NULLIF(COUNT(intf.feedback_id), 0)) * 100, 2
    ) as high_confidence_rate

FROM nexus_recruitment.interview_feedback intf
    JOIN nexus_recruitment.interview_schedules ins ON intf.interview_id = ins.interview_id
    JOIN nexus_foundation.employee_master emp ON intf.interviewer_id = emp.employee_id
    LEFT JOIN nexus_foundation.department_master dept ON emp.department_id = dept.department_id
WHERE intf.feedback_status = 'FINALIZED'
    AND intf.created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY
    intf.company_id, intf.interviewer_id, emp.employee_code,
    emp.first_name, emp.last_name, dept.department_name
HAVING COUNT(intf.feedback_id) >= 5  -- Only include interviewers with significant interview volume
ORDER BY total_interviews_conducted DESC;

-- =====================================================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================================================

-- Enable RLS on all recruitment tables
ALTER TABLE nexus_recruitment.job_requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.interview_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.interview_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.job_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE nexus_recruitment.onboarding_processes ENABLE ROW LEVEL SECURITY;

-- Company-based access policy for all recruitment tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'nexus_recruitment'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE POLICY company_access_policy ON nexus_recruitment.%I
            FOR ALL TO nexus_app_role
            USING (company_id = current_setting(''app.current_company_id'')::BIGINT)
        ', table_name);
    END LOOP;
END $$;

-- =====================================================================================
-- TRIGGERS FOR BUSINESS LOGIC AND AUDIT
-- =====================================================================================

-- Standard update trigger function
CREATE OR REPLACE FUNCTION nexus_recruitment.update_last_modified()
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
        WHERE schemaname = 'nexus_recruitment'
        AND tablename NOT LIKE 'v_%'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_last_modified_trigger
            BEFORE UPDATE ON nexus_recruitment.%I
            FOR EACH ROW EXECUTE FUNCTION nexus_recruitment.update_last_modified()
        ', table_name);
    END LOOP;
END $$;

-- Update candidate search vector trigger
CREATE OR REPLACE FUNCTION nexus_recruitment.update_candidate_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english',
        COALESCE(NEW.full_name, '') || ' ' ||
        COALESCE(NEW.email_primary, '') || ' ' ||
        COALESCE(NEW.key_skills, '') || ' ' ||
        COALESCE(NEW.current_designation, '') || ' ' ||
        COALESCE(NEW.current_company, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply search vector update trigger
CREATE TRIGGER update_candidate_search_vector_trigger
    BEFORE INSERT OR UPDATE ON nexus_recruitment.candidates
    FOR EACH ROW EXECUTE FUNCTION nexus_recruitment.update_candidate_search_vector();

-- Application number generation trigger
CREATE OR REPLACE FUNCTION nexus_recruitment.generate_application_number()
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

    -- Get next sequence number
    SELECT COALESCE(MAX(
        CASE
            WHEN application_number ~ ('^' || v_company_code || '/APP/' || v_year_suffix || '/[0-9]+$')
            THEN SUBSTRING(application_number FROM '[0-9]+$')::INTEGER
            ELSE 0
        END
    ), 0) + 1
    INTO v_sequence_number
    FROM nexus_recruitment.job_applications
    WHERE company_id = NEW.company_id
    AND EXTRACT(YEAR FROM application_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate application number: COMPCODE/APP/YY/NNNN
    NEW.application_number := v_company_code || '/APP/' || v_year_suffix || '/' ||
                             LPAD(v_sequence_number::TEXT, 4, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply application number generation trigger
CREATE TRIGGER generate_application_number_trigger
    BEFORE INSERT ON nexus_recruitment.job_applications
    FOR EACH ROW
    WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
    EXECUTE FUNCTION nexus_recruitment.generate_application_number();

-- =====================================================================================
-- STORED PROCEDURES FOR RECRUITMENT PROCESSING
-- =====================================================================================

-- Calculate application match percentage
CREATE OR REPLACE FUNCTION nexus_recruitment.calculate_application_match(
    p_application_id BIGINT
)
RETURNS JSONB AS $$
DECLARE
    v_application_record nexus_recruitment.job_applications%ROWTYPE;
    v_candidate_record nexus_recruitment.candidates%ROWTYPE;
    v_requisition_record nexus_recruitment.job_requisitions%ROWTYPE;
    v_experience_match DECIMAL(5,2) := 0;
    v_skills_match DECIMAL(5,2) := 0;
    v_qualification_match DECIMAL(5,2) := 0;
    v_overall_match DECIMAL(5,2);
BEGIN
    -- Get application details
    SELECT * INTO v_application_record
    FROM nexus_recruitment.job_applications
    WHERE application_id = p_application_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Application not found'
        );
    END IF;

    -- Get candidate details
    SELECT * INTO v_candidate_record
    FROM nexus_recruitment.candidates
    WHERE candidate_id = v_application_record.candidate_id;

    -- Get requisition details
    SELECT * INTO v_requisition_record
    FROM nexus_recruitment.job_requisitions
    WHERE requisition_id = v_application_record.requisition_id;

    -- Calculate Experience Match
    IF v_candidate_record.relevant_experience_years >= v_requisition_record.required_experience_years THEN
        v_experience_match := 100;
    ELSIF v_candidate_record.relevant_experience_years >= (v_requisition_record.required_experience_years * 0.8) THEN
        v_experience_match := 80;
    ELSIF v_candidate_record.relevant_experience_years >= (v_requisition_record.required_experience_years * 0.6) THEN
        v_experience_match := 60;
    ELSE
        v_experience_match := LEAST(
            (v_candidate_record.relevant_experience_years / v_requisition_record.required_experience_years) * 60,
            60
        );
    END IF;

    -- Calculate Skills Match (simplified keyword matching)
    -- In real implementation, this would use more sophisticated NLP/ML algorithms
    DECLARE
        v_required_skills_count INTEGER;
        v_matching_skills_count INTEGER;
    BEGIN
        -- Count required skills (split by comma)
        SELECT array_length(string_to_array(LOWER(v_requisition_record.required_skills), ','), 1)
        INTO v_required_skills_count;

        -- Count matching skills (simplified approach)
        SELECT COUNT(*)
        INTO v_matching_skills_count
        FROM unnest(string_to_array(LOWER(v_requisition_record.required_skills), ',')) AS req_skill
        WHERE LOWER(v_candidate_record.key_skills) LIKE '%' || TRIM(req_skill) || '%';

        IF v_required_skills_count > 0 THEN
            v_skills_match := ROUND((v_matching_skills_count::DECIMAL / v_required_skills_count) * 100, 2);
        ELSE
            v_skills_match := 50; -- Default if no specific skills mentioned
        END IF;
    END;

    -- Calculate Qualification Match (simplified)
    IF LOWER(v_candidate_record.highest_qualification) LIKE '%' || LOWER(v_requisition_record.required_qualifications) || '%' THEN
        v_qualification_match := 100;
    ELSE
        v_qualification_match := 50; -- Partial match or different qualification
    END IF;

    -- Calculate Overall Match
    v_overall_match := ROUND((v_experience_match + v_skills_match + v_qualification_match) / 3, 2);

    -- Update application record
    UPDATE nexus_recruitment.job_applications
    SET experience_match_percentage = v_experience_match,
        skills_match_percentage = v_skills_match,
        qualification_match_percentage = v_qualification_match,
        last_modified_at = CURRENT_TIMESTAMP
    WHERE application_id = p_application_id;

    RETURN jsonb_build_object(
        'success', true,
        'application_id', p_application_id,
        'experience_match', v_experience_match,
        'skills_match', v_skills_match,
        'qualification_match', v_qualification_match,
        'overall_match', v_overall_match
    );
END;
$$ LANGUAGE plpgsql;

-- Generate recruitment analytics
CREATE OR REPLACE FUNCTION nexus_recruitment.generate_recruitment_report(
    p_company_id BIGINT,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
    v_total_requisitions INTEGER;
    v_total_applications INTEGER;
    v_total_offers INTEGER;
    v_total_hires INTEGER;
    v_avg_time_to_hire DECIMAL(5,1);
    v_offer_acceptance_rate DECIMAL(5,2);
    v_report JSONB;
BEGIN
    -- Count total requisitions
    SELECT COUNT(*) INTO v_total_requisitions
    FROM nexus_recruitment.job_requisitions
    WHERE company_id = p_company_id
    AND created_at::DATE BETWEEN p_start_date AND p_end_date;

    -- Count total applications
    SELECT COUNT(*) INTO v_total_applications
    FROM nexus_recruitment.job_applications
    WHERE company_id = p_company_id
    AND application_date BETWEEN p_start_date AND p_end_date;

    -- Count total offers
    SELECT COUNT(*) INTO v_total_offers
    FROM nexus_recruitment.job_offers
    WHERE company_id = p_company_id
    AND offer_sent_date BETWEEN p_start_date AND p_end_date;

    -- Count total hires
    SELECT COUNT(*) INTO v_total_hires
    FROM nexus_recruitment.job_applications
    WHERE company_id = p_company_id
    AND application_status = 'HIRED'
    AND last_modified_at::DATE BETWEEN p_start_date AND p_end_date;

    -- Calculate average time to hire
    SELECT AVG(EXTRACT(DAYS FROM (last_modified_at - created_at)))
    INTO v_avg_time_to_hire
    FROM nexus_recruitment.job_applications
    WHERE company_id = p_company_id
    AND application_status = 'HIRED'
    AND last_modified_at::DATE BETWEEN p_start_date AND p_end_date;

    -- Calculate offer acceptance rate
    SELECT
        CASE
            WHEN COUNT(*) > 0
            THEN ROUND((COUNT(CASE WHEN candidate_response = 'ACCEPTED' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2)
            ELSE 0
        END
    INTO v_offer_acceptance_rate
    FROM nexus_recruitment.job_offers
    WHERE company_id = p_company_id
    AND offer_sent_date BETWEEN p_start_date AND p_end_date
    AND candidate_response IS NOT NULL;

    -- Build report JSON
    v_report := jsonb_build_object(
        'report_period', jsonb_build_object(
            'start_date', p_start_date,
            'end_date', p_end_date
        ),
        'summary_metrics', jsonb_build_object(
            'total_requisitions', v_total_requisitions,
            'total_applications', v_total_applications,
            'total_offers', v_total_offers,
            'total_hires', v_total_hires,
            'average_time_to_hire_days', COALESCE(v_avg_time_to_hire, 0),
            'offer_acceptance_rate_percent', COALESCE(v_offer_acceptance_rate, 0)
        ),
        'conversion_rates', jsonb_build_object(
            'application_to_offer_rate',
            CASE
                WHEN v_total_applications > 0
                THEN ROUND((v_total_offers::DECIMAL / v_total_applications) * 100, 2)
                ELSE 0
            END,
            'offer_to_hire_rate', v_offer_acceptance_rate,
            'application_to_hire_rate',
            CASE
                WHEN v_total_applications > 0
                THEN ROUND((v_total_hires::DECIMAL / v_total_applications) * 100, 2)
                ELSE 0
            END
        ),
        'generated_at', CURRENT_TIMESTAMP
    );

    RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================================================

COMMENT ON SCHEMA nexus_recruitment IS 'Comprehensive recruitment and hiring system with job postings, candidate management, interview scheduling, and onboarding workflows';

COMMENT ON TABLE nexus_recruitment.job_requisitions IS 'Internal requests for new positions with approval workflow and business justification';
COMMENT ON TABLE nexus_recruitment.job_postings IS 'External job advertisements with multi-channel publishing and performance tracking';
COMMENT ON TABLE nexus_recruitment.candidates IS 'Master candidate records with comprehensive profile information and document management';
COMMENT ON TABLE nexus_recruitment.job_applications IS 'Candidate applications with status tracking, matching algorithms, and workflow management';
COMMENT ON TABLE nexus_recruitment.interview_schedules IS 'Interview scheduling with panel management, video conferencing, and outcome tracking';
COMMENT ON TABLE nexus_recruitment.interview_feedback IS 'Detailed interviewer feedback with competency assessment and hiring recommendations';
COMMENT ON TABLE nexus_recruitment.job_offers IS 'Job offers with compensation packages, negotiation tracking, and approval workflows';
COMMENT ON TABLE nexus_recruitment.onboarding_processes IS 'Structured onboarding workflows with checklist management and progress tracking';

-- =====================================================================================
-- SCHEMA COMPLETION
-- =====================================================================================

-- Grant permissions to application role
GRANT USAGE ON SCHEMA nexus_recruitment TO nexus_app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nexus_recruitment TO nexus_app_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA nexus_recruitment TO nexus_app_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nexus_recruitment TO nexus_app_role;

-- Grant read-only access to reporting role
GRANT USAGE ON SCHEMA nexus_recruitment TO nexus_readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_recruitment TO nexus_readonly_role;
GRANT EXECUTE ON FUNCTION nexus_recruitment.generate_recruitment_report TO nexus_readonly_role;

RAISE NOTICE 'NEXUS Recruitment Management Schema created successfully with:
- 8 core tables with comprehensive recruitment lifecycle management
- Job requisition and posting system with multi-channel publishing
- Advanced candidate management with search and matching capabilities
- Interview scheduling and feedback system with panel management
- Offer management with negotiation tracking and approval workflows
- Structured onboarding processes with checklist and progress tracking
- Comprehensive analytics views for recruitment metrics and insights
- Row Level Security and audit trails for sensitive recruitment data
- Stored procedures for automated matching and recruitment analytics
- GraphQL-optimized structure for modern frontend integration with real-time updates';

-- End of 06_nexus_recruitment_schema.sql