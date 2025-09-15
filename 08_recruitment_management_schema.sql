-- ======================================================================
-- NEXUS HRMS - Phase 8: Recruitment Management System Schema
-- ======================================================================
-- Description: Comprehensive recruitment and hiring management system
-- Version: 1.0
-- Created: 2024-09-14
-- Dependencies: Phase 1 (Company), Phase 2 (Organization), Phase 3 (Employee)
-- ======================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ======================================================================
-- 1. JOB REQUISITION AND POSTING TABLES
-- ======================================================================

-- Job Category Master
CREATE TABLE job_category_master (
    job_category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job Requisition
CREATE TABLE job_requisition (
    requisition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requisition_number VARCHAR(50) UNIQUE NOT NULL,
    job_title VARCHAR(200) NOT NULL,
    job_category_id UUID REFERENCES job_category_master(job_category_id),
    department_id UUID NOT NULL REFERENCES department_master(department_id),
    designation_id UUID NOT NULL REFERENCES designation_master(designation_id),
    location_id UUID REFERENCES location_master(location_id),
    reporting_to_employee_id UUID REFERENCES employee_master(employee_id),

    -- Position Details
    no_of_positions INTEGER NOT NULL CHECK (no_of_positions > 0),
    employment_type VARCHAR(20) CHECK (employment_type IN ('PERMANENT', 'CONTRACT', 'TEMPORARY', 'INTERNSHIP')),
    job_level VARCHAR(20) CHECK (job_level IN ('ENTRY', 'JUNIOR', 'SENIOR', 'LEAD', 'MANAGER', 'DIRECTOR', 'VP', 'CXO')),
    priority_level VARCHAR(10) CHECK (priority_level IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),

    -- Salary and Budget
    min_salary DECIMAL(12,2),
    max_salary DECIMAL(12,2),
    budget_approved BOOLEAN DEFAULT false,
    budget_amount DECIMAL(12,2),

    -- Timeline
    target_start_date DATE,
    expected_closure_date DATE,
    requisition_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Job Description
    job_summary TEXT NOT NULL,
    key_responsibilities TEXT,
    required_qualifications TEXT,
    preferred_qualifications TEXT,
    required_experience_years INTEGER,
    required_skills TEXT,

    -- Status and Approval
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'PUBLISHED', 'ON_HOLD', 'CANCELLED', 'CLOSED')),
    approval_status VARCHAR(20) DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    approved_by UUID REFERENCES employee_master(employee_id),
    approved_date TIMESTAMP,
    rejection_reason TEXT,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job Posting Channels
CREATE TABLE job_posting_channel (
    channel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_name VARCHAR(100) NOT NULL,
    channel_type VARCHAR(20) CHECK (channel_type IN ('INTERNAL', 'EXTERNAL', 'SOCIAL_MEDIA', 'JOB_BOARD', 'AGENCY', 'REFERRAL')),
    channel_url VARCHAR(500),
    cost_per_posting DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job Posting
CREATE TABLE job_posting (
    posting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requisition_id UUID NOT NULL REFERENCES job_requisition(requisition_id),
    channel_id UUID NOT NULL REFERENCES job_posting_channel(channel_id),
    posting_title VARCHAR(200) NOT NULL,
    posting_description TEXT,
    external_posting_id VARCHAR(100),
    posted_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    posting_cost DECIMAL(10,2),
    total_views INTEGER DEFAULT 0,
    total_applications INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'CLOSED', 'PAUSED')),
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================
-- 2. CANDIDATE MANAGEMENT TABLES
-- ======================================================================

-- Candidate Source
CREATE TABLE candidate_source (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL,
    source_type VARCHAR(20) CHECK (source_type IN ('DIRECT', 'REFERRAL', 'AGENCY', 'JOB_BOARD', 'SOCIAL_MEDIA', 'WALK_IN', 'CAMPUS', 'OTHER')),
    source_description TEXT,
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Candidate Master
CREATE TABLE candidate_master (
    candidate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_code VARCHAR(50) UNIQUE NOT NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(300) GENERATED ALWAYS AS (
        CASE
            WHEN middle_name IS NOT NULL THEN CONCAT(first_name, ' ', middle_name, ' ', last_name)
            ELSE CONCAT(first_name, ' ', last_name)
        END
    ) STORED,

    -- Contact Information
    email_primary VARCHAR(150) NOT NULL,
    email_secondary VARCHAR(150),
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),

    -- Address Information
    current_address TEXT,
    permanent_address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20),

    -- Professional Information
    current_company VARCHAR(200),
    current_designation VARCHAR(150),
    current_salary DECIMAL(12,2),
    expected_salary DECIMAL(12,2),
    total_experience_years DECIMAL(4,2),
    relevant_experience_years DECIMAL(4,2),
    notice_period_days INTEGER,

    -- Personal Details
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    nationality VARCHAR(100),
    marital_status VARCHAR(20) CHECK (marital_status IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED')),

    -- Documents and Links
    resume_file_path VARCHAR(500),
    portfolio_url VARCHAR(500),
    linkedin_profile VARCHAR(500),

    -- Source Information
    source_id UUID REFERENCES candidate_source(source_id),
    referrer_employee_id UUID REFERENCES employee_master(employee_id),

    -- Status
    overall_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (overall_status IN ('ACTIVE', 'BLACKLISTED', 'DO_NOT_CONTACT', 'HIRED')),
    blacklist_reason TEXT,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Candidate Education
CREATE TABLE candidate_education (
    education_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES candidate_master(candidate_id) ON DELETE CASCADE,
    degree_type VARCHAR(50) CHECK (degree_type IN ('HIGH_SCHOOL', 'DIPLOMA', 'BACHELOR', 'MASTER', 'DOCTORATE', 'CERTIFICATION')),
    degree_name VARCHAR(200) NOT NULL,
    specialization VARCHAR(200),
    institution_name VARCHAR(300) NOT NULL,
    university_name VARCHAR(300),
    completion_year INTEGER CHECK (completion_year >= 1950 AND completion_year <= EXTRACT(YEAR FROM CURRENT_DATE) + 10),
    percentage_or_gpa VARCHAR(20),
    grade VARCHAR(20),
    is_highest_qualification BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Candidate Experience
CREATE TABLE candidate_experience (
    experience_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES candidate_master(candidate_id) ON DELETE CASCADE,
    company_name VARCHAR(200) NOT NULL,
    designation VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT false,
    duration_months INTEGER,
    job_description TEXT,
    key_achievements TEXT,
    technologies_used TEXT,
    salary_amount DECIMAL(12,2),
    reason_for_leaving TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Candidate Skills
CREATE TABLE candidate_skill (
    skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES candidate_master(candidate_id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    skill_category VARCHAR(50) CHECK (skill_category IN ('TECHNICAL', 'FUNCTIONAL', 'BEHAVIORAL', 'LANGUAGE', 'CERTIFICATION')),
    proficiency_level VARCHAR(20) CHECK (proficiency_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    years_of_experience DECIMAL(4,2),
    certification_name VARCHAR(200),
    certification_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================
-- 3. APPLICATION AND TRACKING TABLES
-- ======================================================================

-- Job Application
CREATE TABLE job_application (
    application_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_number VARCHAR(50) UNIQUE NOT NULL,
    requisition_id UUID NOT NULL REFERENCES job_requisition(requisition_id),
    candidate_id UUID NOT NULL REFERENCES candidate_master(candidate_id),
    posting_id UUID REFERENCES job_posting(posting_id),

    -- Application Details
    application_date DATE DEFAULT CURRENT_DATE,
    cover_letter TEXT,
    expected_salary DECIMAL(12,2),
    notice_period_days INTEGER,
    available_from_date DATE,

    -- Status Tracking
    current_stage VARCHAR(30) DEFAULT 'APPLIED' CHECK (current_stage IN (
        'APPLIED', 'SCREENING', 'PHONE_INTERVIEW', 'TECHNICAL_TEST',
        'INTERVIEW_L1', 'INTERVIEW_L2', 'INTERVIEW_L3', 'FINAL_INTERVIEW',
        'REFERENCE_CHECK', 'OFFER_PENDING', 'OFFER_EXTENDED', 'OFFER_ACCEPTED',
        'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN', 'ON_HOLD'
    )),

    overall_status VARCHAR(20) DEFAULT 'IN_PROGRESS' CHECK (overall_status IN (
        'IN_PROGRESS', 'SELECTED', 'REJECTED', 'WITHDRAWN', 'ON_HOLD'
    )),

    -- Ratings and Feedback
    overall_rating DECIMAL(3,2) CHECK (overall_rating >= 0 AND overall_rating <= 10),
    technical_rating DECIMAL(3,2) CHECK (technical_rating >= 0 AND technical_rating <= 10),
    communication_rating DECIMAL(3,2) CHECK (communication_rating >= 0 AND communication_rating <= 10),
    cultural_fit_rating DECIMAL(3,2) CHECK (cultural_fit_rating >= 0 AND cultural_fit_rating <= 10),

    rejection_reason TEXT,
    internal_notes TEXT,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(requisition_id, candidate_id)
);

-- Application Stage History
CREATE TABLE application_stage_history (
    stage_history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES job_application(application_id) ON DELETE CASCADE,
    from_stage VARCHAR(30),
    to_stage VARCHAR(30) NOT NULL,
    stage_changed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stage_duration_hours INTEGER,
    changed_by UUID REFERENCES user_master(user_id),
    change_reason TEXT,
    comments TEXT,
    company_id UUID NOT NULL REFERENCES company_master(company_id)
);

-- ======================================================================
-- 4. INTERVIEW MANAGEMENT TABLES
-- ======================================================================

-- Interview Type Master
CREATE TABLE interview_type_master (
    interview_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL,
    type_description TEXT,
    typical_duration_minutes INTEGER,
    evaluation_criteria TEXT,
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Interview Schedule
CREATE TABLE interview_schedule (
    interview_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES job_application(application_id),
    interview_type_id UUID NOT NULL REFERENCES interview_type_master(interview_type_id),
    interview_round INTEGER NOT NULL DEFAULT 1,

    -- Schedule Details
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,

    -- Interview Details
    interview_mode VARCHAR(20) CHECK (interview_mode IN ('IN_PERSON', 'VIDEO_CALL', 'PHONE_CALL', 'ONLINE_TEST')),
    meeting_location VARCHAR(300),
    meeting_link VARCHAR(500),
    meeting_password VARCHAR(100),

    -- Status
    status VARCHAR(20) DEFAULT 'SCHEDULED' CHECK (status IN (
        'SCHEDULED', 'CONFIRMED', 'RESCHEDULED', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    )),

    -- Results
    interview_result VARCHAR(20) CHECK (interview_result IN ('PASS', 'FAIL', 'HOLD', 'PENDING')),
    overall_score DECIMAL(5,2),
    interviewer_feedback TEXT,
    candidate_feedback TEXT,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Interview Panel (Interviewers)
CREATE TABLE interview_panel (
    panel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID NOT NULL REFERENCES interview_schedule(interview_id) ON DELETE CASCADE,
    interviewer_employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    role_in_panel VARCHAR(20) CHECK (role_in_panel IN ('PRIMARY', 'SECONDARY', 'OBSERVER', 'TECHNICAL_EXPERT', 'HR_REPRESENTATIVE')),
    is_lead_interviewer BOOLEAN DEFAULT false,
    attendance_status VARCHAR(20) DEFAULT 'PENDING' CHECK (attendance_status IN ('PENDING', 'CONFIRMED', 'ATTENDED', 'ABSENT')),
    individual_feedback TEXT,
    individual_score DECIMAL(5,2),
    recommendation VARCHAR(20) CHECK (recommendation IN ('STRONGLY_RECOMMEND', 'RECOMMEND', 'NEUTRAL', 'NOT_RECOMMEND', 'STRONGLY_NOT_RECOMMEND')),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Interview Evaluation Criteria
CREATE TABLE interview_evaluation_criteria (
    criteria_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_type_id UUID NOT NULL REFERENCES interview_type_master(interview_type_id),
    criteria_name VARCHAR(200) NOT NULL,
    criteria_description TEXT,
    max_score DECIMAL(5,2) DEFAULT 10.00,
    weightage_percentage DECIMAL(5,2) DEFAULT 10.00,
    is_mandatory BOOLEAN DEFAULT false,
    sort_order INTEGER,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Interview Scores
CREATE TABLE interview_score (
    score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID NOT NULL REFERENCES interview_schedule(interview_id),
    interviewer_employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    criteria_id UUID NOT NULL REFERENCES interview_evaluation_criteria(criteria_id),
    score DECIMAL(5,2) NOT NULL,
    comments TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(interview_id, interviewer_employee_id, criteria_id)
);

-- ======================================================================
-- 5. OFFER MANAGEMENT TABLES
-- ======================================================================

-- Offer Letter
CREATE TABLE offer_letter (
    offer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_number VARCHAR(50) UNIQUE NOT NULL,
    application_id UUID NOT NULL REFERENCES job_application(application_id),

    -- Offer Details
    job_title VARCHAR(200) NOT NULL,
    department_id UUID NOT NULL REFERENCES department_master(department_id),
    designation_id UUID NOT NULL REFERENCES designation_master(designation_id),
    location_id UUID REFERENCES location_master(location_id),
    reporting_to_employee_id UUID REFERENCES employee_master(employee_id),

    -- Compensation
    annual_salary DECIMAL(12,2) NOT NULL,
    monthly_salary DECIMAL(12,2) NOT NULL,
    basic_salary DECIMAL(12,2),
    hra_amount DECIMAL(12,2),
    other_allowances DECIMAL(12,2),
    variable_pay_percentage DECIMAL(5,2),
    joining_bonus DECIMAL(12,2),

    -- Terms and Conditions
    employment_type VARCHAR(20) CHECK (employment_type IN ('PERMANENT', 'CONTRACT', 'TEMPORARY', 'INTERNSHIP')),
    probation_period_months INTEGER,
    notice_period_days INTEGER,

    -- Dates
    offer_date DATE DEFAULT CURRENT_DATE,
    offer_expiry_date DATE NOT NULL,
    expected_joining_date DATE,
    actual_joining_date DATE,

    -- Status
    offer_status VARCHAR(20) DEFAULT 'GENERATED' CHECK (offer_status IN (
        'GENERATED', 'SENT', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'WITHDRAWN', 'NEGOTIATING'
    )),

    -- Acceptance/Rejection
    candidate_response VARCHAR(20) CHECK (candidate_response IN ('ACCEPTED', 'DECLINED', 'NEGOTIATING')),
    response_date DATE,
    decline_reason TEXT,
    negotiation_comments TEXT,

    -- Documents
    offer_letter_path VARCHAR(500),
    appointment_letter_path VARCHAR(500),

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Offer Negotiation History
CREATE TABLE offer_negotiation_history (
    negotiation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID NOT NULL REFERENCES offer_letter(offer_id) ON DELETE CASCADE,
    negotiation_round INTEGER NOT NULL,
    negotiated_by VARCHAR(20) CHECK (negotiated_by IN ('CANDIDATE', 'COMPANY')),

    -- Negotiated Terms
    requested_salary DECIMAL(12,2),
    requested_joining_date DATE,
    other_requests TEXT,

    -- Company Response
    approved_salary DECIMAL(12,2),
    approved_joining_date DATE,
    company_response TEXT,

    negotiation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'COUNTER_OFFERED')),

    created_by UUID REFERENCES user_master(user_id)
);

-- ======================================================================
-- 6. RECRUITMENT ANALYTICS TABLES
-- ======================================================================

-- Recruitment Metrics Summary
CREATE TABLE recruitment_metrics_summary (
    metrics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES company_master(company_id),

    -- Time Period
    metrics_date DATE NOT NULL,
    metrics_type VARCHAR(20) CHECK (metrics_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),

    -- Volume Metrics
    total_requisitions INTEGER DEFAULT 0,
    active_requisitions INTEGER DEFAULT 0,
    closed_requisitions INTEGER DEFAULT 0,
    total_applications INTEGER DEFAULT 0,
    total_candidates INTEGER DEFAULT 0,

    -- Conversion Metrics
    screening_to_interview_rate DECIMAL(5,2),
    interview_to_offer_rate DECIMAL(5,2),
    offer_acceptance_rate DECIMAL(5,2),
    overall_conversion_rate DECIMAL(5,2),

    -- Time Metrics
    avg_time_to_fill_days DECIMAL(5,2),
    avg_time_to_hire_days DECIMAL(5,2),
    avg_interview_duration_days DECIMAL(5,2),

    -- Cost Metrics
    total_recruitment_cost DECIMAL(12,2),
    cost_per_hire DECIMAL(10,2),
    total_posting_cost DECIMAL(10,2),

    -- Quality Metrics
    avg_candidate_rating DECIMAL(3,2),
    new_hire_retention_90_days DECIMAL(5,2),

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(company_id, metrics_date, metrics_type)
);

-- Source Effectiveness
CREATE TABLE source_effectiveness (
    effectiveness_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID NOT NULL REFERENCES candidate_source(source_id),
    company_id UUID NOT NULL REFERENCES company_master(company_id),

    -- Time Period
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,

    -- Volume Metrics
    total_candidates INTEGER DEFAULT 0,
    total_applications INTEGER DEFAULT 0,
    shortlisted_candidates INTEGER DEFAULT 0,
    hired_candidates INTEGER DEFAULT 0,

    -- Effectiveness Metrics
    source_conversion_rate DECIMAL(5,2),
    quality_score DECIMAL(3,2),
    avg_time_to_hire DECIMAL(5,2),
    cost_per_candidate DECIMAL(10,2),

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(source_id, company_id, period_start_date, period_end_date)
);

-- ======================================================================
-- 7. INDEXES FOR PERFORMANCE OPTIMIZATION
-- ======================================================================

-- Job Requisition Indexes
CREATE INDEX idx_job_requisition_company ON job_requisition(company_id);
CREATE INDEX idx_job_requisition_department ON job_requisition(department_id);
CREATE INDEX idx_job_requisition_status ON job_requisition(status);
CREATE INDEX idx_job_requisition_date ON job_requisition(requisition_date);
CREATE INDEX idx_job_requisition_created_by ON job_requisition(created_by);

-- Candidate Master Indexes
CREATE INDEX idx_candidate_master_company ON candidate_master(company_id);
CREATE INDEX idx_candidate_master_email ON candidate_master(email_primary);
CREATE INDEX idx_candidate_master_phone ON candidate_master(phone_primary);
CREATE INDEX idx_candidate_master_status ON candidate_master(overall_status);
CREATE INDEX idx_candidate_master_source ON candidate_master(source_id);
CREATE INDEX idx_candidate_master_created_date ON candidate_master(created_date);

-- Job Application Indexes
CREATE INDEX idx_job_application_company ON job_application(company_id);
CREATE INDEX idx_job_application_requisition ON job_application(requisition_id);
CREATE INDEX idx_job_application_candidate ON job_application(candidate_id);
CREATE INDEX idx_job_application_stage ON job_application(current_stage);
CREATE INDEX idx_job_application_status ON job_application(overall_status);
CREATE INDEX idx_job_application_date ON job_application(application_date);

-- Interview Schedule Indexes
CREATE INDEX idx_interview_schedule_application ON interview_schedule(application_id);
CREATE INDEX idx_interview_schedule_date ON interview_schedule(scheduled_date);
CREATE INDEX idx_interview_schedule_status ON interview_schedule(status);
CREATE INDEX idx_interview_schedule_company ON interview_schedule(company_id);

-- Offer Letter Indexes
CREATE INDEX idx_offer_letter_application ON offer_letter(application_id);
CREATE INDEX idx_offer_letter_status ON offer_letter(offer_status);
CREATE INDEX idx_offer_letter_date ON offer_letter(offer_date);
CREATE INDEX idx_offer_letter_company ON offer_letter(company_id);

-- ======================================================================
-- 8. TRIGGERS AND BUSINESS LOGIC FUNCTIONS
-- ======================================================================

-- Function to update application stage history
CREATE OR REPLACE FUNCTION update_application_stage_history()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert stage history record when stage changes
    IF OLD.current_stage IS DISTINCT FROM NEW.current_stage THEN
        INSERT INTO application_stage_history (
            application_id, from_stage, to_stage, stage_changed_date,
            stage_duration_hours, changed_by, company_id
        ) VALUES (
            NEW.application_id,
            OLD.current_stage,
            NEW.current_stage,
            CURRENT_TIMESTAMP,
            CASE
                WHEN OLD.modified_date IS NOT NULL
                THEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - OLD.modified_date)) / 3600
                ELSE NULL
            END,
            NEW.modified_by,
            NEW.company_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for application stage history
CREATE TRIGGER trg_application_stage_history
    AFTER UPDATE ON job_application
    FOR EACH ROW
    EXECUTE FUNCTION update_application_stage_history();

-- Function to generate application numbers
CREATE OR REPLACE FUNCTION generate_application_number()
RETURNS TRIGGER AS $$
DECLARE
    company_code VARCHAR(10);
    next_sequence INTEGER;
BEGIN
    -- Get company code
    SELECT short_name INTO company_code
    FROM company_master
    WHERE company_id = NEW.company_id;

    -- Get next sequence number for the year
    SELECT COALESCE(MAX(CAST(RIGHT(application_number, 6) AS INTEGER)), 0) + 1
    INTO next_sequence
    FROM job_application
    WHERE company_id = NEW.company_id
    AND EXTRACT(YEAR FROM created_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate application number: COMP-APP-YYYY-NNNNNN
    NEW.application_number := UPPER(company_code) || '-APP-' ||
                             EXTRACT(YEAR FROM CURRENT_DATE) || '-' ||
                             LPAD(next_sequence::TEXT, 6, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for application number generation
CREATE TRIGGER trg_generate_application_number
    BEFORE INSERT ON job_application
    FOR EACH ROW
    WHEN (NEW.application_number IS NULL OR NEW.application_number = '')
    EXECUTE FUNCTION generate_application_number();

-- Function to generate requisition numbers
CREATE OR REPLACE FUNCTION generate_requisition_number()
RETURNS TRIGGER AS $$
DECLARE
    company_code VARCHAR(10);
    next_sequence INTEGER;
BEGIN
    -- Get company code
    SELECT short_name INTO company_code
    FROM company_master
    WHERE company_id = NEW.company_id;

    -- Get next sequence number for the year
    SELECT COALESCE(MAX(CAST(RIGHT(requisition_number, 6) AS INTEGER)), 0) + 1
    INTO next_sequence
    FROM job_requisition
    WHERE company_id = NEW.company_id
    AND EXTRACT(YEAR FROM created_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate requisition number: COMP-REQ-YYYY-NNNNNN
    NEW.requisition_number := UPPER(company_code) || '-REQ-' ||
                             EXTRACT(YEAR FROM CURRENT_DATE) || '-' ||
                             LPAD(next_sequence::TEXT, 6, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for requisition number generation
CREATE TRIGGER trg_generate_requisition_number
    BEFORE INSERT ON job_requisition
    FOR EACH ROW
    WHEN (NEW.requisition_number IS NULL OR NEW.requisition_number = '')
    EXECUTE FUNCTION generate_requisition_number();

-- Function to update modified timestamp
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for modified timestamp updates
CREATE TRIGGER trg_job_requisition_modified
    BEFORE UPDATE ON job_requisition
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_candidate_master_modified
    BEFORE UPDATE ON candidate_master
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_job_application_modified
    BEFORE UPDATE ON job_application
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_interview_schedule_modified
    BEFORE UPDATE ON interview_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_offer_letter_modified
    BEFORE UPDATE ON offer_letter
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

-- ======================================================================
-- 9. VIEWS FOR COMMON QUERIES
-- ======================================================================

-- Active Job Requisitions with Details
CREATE VIEW vw_active_requisitions AS
SELECT
    jr.requisition_id,
    jr.requisition_number,
    jr.job_title,
    jc.category_name as job_category,
    dm.department_name,
    des.designation_name,
    jr.no_of_positions,
    jr.employment_type,
    jr.min_salary,
    jr.max_salary,
    jr.status,
    jr.requisition_date,
    jr.expected_closure_date,
    emp.full_name as created_by_name,
    app_emp.full_name as approved_by_name,
    jr.created_date
FROM job_requisition jr
LEFT JOIN job_category_master jc ON jr.job_category_id = jc.job_category_id
LEFT JOIN department_master dm ON jr.department_id = dm.department_id
LEFT JOIN designation_master des ON jr.designation_id = des.designation_id
LEFT JOIN user_master um_created ON jr.created_by = um_created.user_id
LEFT JOIN employee_master emp ON um_created.employee_master_id = emp.employee_id
LEFT JOIN employee_master app_emp ON jr.approved_by = app_emp.employee_id
WHERE jr.status IN ('APPROVED', 'PUBLISHED');

-- Candidate Pipeline Summary
CREATE VIEW vw_candidate_pipeline AS
SELECT
    jr.requisition_id,
    jr.requisition_number,
    jr.job_title,
    COUNT(ja.application_id) as total_applications,
    COUNT(CASE WHEN ja.current_stage = 'APPLIED' THEN 1 END) as applied_count,
    COUNT(CASE WHEN ja.current_stage = 'SCREENING' THEN 1 END) as screening_count,
    COUNT(CASE WHEN ja.current_stage LIKE '%INTERVIEW%' THEN 1 END) as interview_count,
    COUNT(CASE WHEN ja.current_stage = 'OFFER_EXTENDED' THEN 1 END) as offer_count,
    COUNT(CASE WHEN ja.overall_status = 'SELECTED' THEN 1 END) as selected_count,
    COUNT(CASE WHEN ja.overall_status = 'REJECTED' THEN 1 END) as rejected_count
FROM job_requisition jr
LEFT JOIN job_application ja ON jr.requisition_id = ja.requisition_id
GROUP BY jr.requisition_id, jr.requisition_number, jr.job_title;

-- Interview Schedule Summary
CREATE VIEW vw_interview_summary AS
SELECT
    cm.candidate_id,
    cm.full_name as candidate_name,
    cm.email_primary,
    cm.phone_primary,
    jr.job_title,
    isch.interview_id,
    isch.scheduled_date,
    isch.scheduled_start_time,
    isch.interview_mode,
    isch.status as interview_status,
    isch.interview_result,
    isch.overall_score,
    STRING_AGG(emp.full_name, ', ') as interviewers
FROM interview_schedule isch
JOIN job_application ja ON isch.application_id = ja.application_id
JOIN candidate_master cm ON ja.candidate_id = cm.candidate_id
JOIN job_requisition jr ON ja.requisition_id = jr.requisition_id
LEFT JOIN interview_panel ip ON isch.interview_id = ip.interview_id
LEFT JOIN employee_master emp ON ip.interviewer_employee_id = emp.employee_id
GROUP BY cm.candidate_id, cm.full_name, cm.email_primary, cm.phone_primary,
         jr.job_title, isch.interview_id, isch.scheduled_date,
         isch.scheduled_start_time, isch.interview_mode, isch.status,
         isch.interview_result, isch.overall_score;

-- ======================================================================
-- RECRUITMENT MANAGEMENT SCHEMA COMPLETED
-- ======================================================================

-- Summary of tables created:
-- 1. Job Category Master, Job Requisition, Job Posting Channel, Job Posting
-- 2. Candidate Source, Candidate Master, Candidate Education, Experience, Skills
-- 3. Job Application, Application Stage History
-- 4. Interview Type, Interview Schedule, Interview Panel, Evaluation Criteria, Scores
-- 5. Offer Letter, Offer Negotiation History
-- 6. Recruitment Metrics Summary, Source Effectiveness
-- 7. Performance indexes (25 indexes)
-- 8. Business logic triggers and functions (6 functions)
-- 9. Management views (3 views)

-- Total Tables: 20 core tables
-- Total Views: 3 management views
-- Total Functions: 6 business logic functions
-- Total Triggers: 8 automated triggers
-- Total Indexes: 25 performance indexes