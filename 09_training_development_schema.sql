-- ======================================================================
-- NEXUS HRMS - Phase 9: Training & Development System Schema
-- ======================================================================
-- Description: Comprehensive learning management and skill development system
-- Version: 1.0
-- Created: 2024-09-14
-- Dependencies: Phase 1 (Company), Phase 2 (Organization), Phase 3 (Employee), Phase 7 (Performance)
-- ======================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ======================================================================
-- 1. TRAINING CATEGORY AND SKILL FRAMEWORK TABLES
-- ======================================================================

-- Training Category Master
CREATE TABLE training_category_master (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    parent_category_id UUID REFERENCES training_category_master(category_id),
    category_level INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Skill Master (Enhanced from Performance Management)
CREATE TABLE skill_master (
    skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    skill_code VARCHAR(20) UNIQUE NOT NULL,
    skill_name VARCHAR(150) NOT NULL,
    skill_description TEXT,
    skill_category VARCHAR(50) CHECK (skill_category IN ('TECHNICAL', 'FUNCTIONAL', 'BEHAVIORAL', 'LEADERSHIP', 'LANGUAGE', 'CERTIFICATION', 'DOMAIN_SPECIFIC')),
    skill_type VARCHAR(20) CHECK (skill_type IN ('HARD_SKILL', 'SOFT_SKILL', 'HYBRID')),
    proficiency_levels JSONB, -- ["Beginner", "Intermediate", "Advanced", "Expert"]
    assessment_criteria TEXT,
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Learning Path Master
CREATE TABLE learning_path_master (
    learning_path_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    path_code VARCHAR(30) UNIQUE NOT NULL,
    path_name VARCHAR(200) NOT NULL,
    path_description TEXT,
    category_id UUID REFERENCES training_category_master(category_id),
    target_audience VARCHAR(100), -- "New Joiners", "Middle Management", "Senior Leaders", etc.
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    estimated_duration_hours INTEGER,
    prerequisites TEXT,
    learning_objectives TEXT,

    -- Path Configuration
    is_mandatory BOOLEAN DEFAULT false,
    is_sequential BOOLEAN DEFAULT true, -- Must complete courses in order
    completion_criteria VARCHAR(20) CHECK (completion_criteria IN ('ALL_COURSES', 'PERCENTAGE_BASED', 'SCORE_BASED')),
    minimum_completion_percentage DECIMAL(5,2),
    minimum_score_required DECIMAL(5,2),

    -- Validity and Status
    validity_period_months INTEGER,
    is_active BOOLEAN DEFAULT true,
    effective_from_date DATE,
    effective_to_date DATE,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================
-- 2. COURSE AND CONTENT MANAGEMENT TABLES
-- ======================================================================

-- Training Provider Master
CREATE TABLE training_provider_master (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_code VARCHAR(20) UNIQUE NOT NULL,
    provider_name VARCHAR(200) NOT NULL,
    provider_type VARCHAR(20) CHECK (provider_type IN ('INTERNAL', 'EXTERNAL', 'ONLINE_PLATFORM', 'CONSULTANT', 'VENDOR')),
    contact_person VARCHAR(150),
    email VARCHAR(150),
    phone VARCHAR(20),
    website VARCHAR(300),
    address TEXT,
    specializations TEXT,
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    is_preferred BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Course Master
CREATE TABLE course_master (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_code VARCHAR(30) UNIQUE NOT NULL,
    course_title VARCHAR(300) NOT NULL,
    course_description TEXT,
    short_description VARCHAR(500),
    category_id UUID REFERENCES training_category_master(category_id),
    provider_id UUID REFERENCES training_provider_master(provider_id),

    -- Course Details
    course_type VARCHAR(20) CHECK (course_type IN ('CLASSROOM', 'ONLINE', 'BLENDED', 'WORKSHOP', 'SEMINAR', 'WEBINAR', 'SELF_PACED')),
    delivery_method VARCHAR(20) CHECK (delivery_method IN ('INSTRUCTOR_LED', 'SELF_STUDY', 'VIRTUAL_CLASSROOM', 'HANDS_ON', 'SIMULATION')),
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),

    -- Duration and Scheduling
    duration_hours DECIMAL(5,2) NOT NULL,
    duration_days INTEGER,
    max_participants INTEGER,
    min_participants INTEGER,

    -- Content and Resources
    learning_objectives TEXT,
    course_outline TEXT,
    prerequisites TEXT,
    target_audience TEXT,
    materials_required TEXT,
    course_content_url VARCHAR(500),
    thumbnail_image_path VARCHAR(500),

    -- Assessment Configuration
    has_assessment BOOLEAN DEFAULT false,
    assessment_type VARCHAR(20) CHECK (assessment_type IN ('QUIZ', 'ASSIGNMENT', 'PROJECT', 'PRACTICAL', 'ORAL', 'MIXED')),
    passing_score DECIMAL(5,2),
    max_attempts INTEGER DEFAULT 3,

    -- Certification
    provides_certificate BOOLEAN DEFAULT false,
    certificate_template_path VARCHAR(500),
    certificate_validity_months INTEGER,

    -- Pricing
    cost_per_participant DECIMAL(10,2),
    currency_code VARCHAR(3) DEFAULT 'INR',

    -- Status and Validity
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    effective_from_date DATE,
    effective_to_date DATE,

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Course Skills Mapping
CREATE TABLE course_skill_mapping (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES course_master(course_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skill_master(skill_id),
    skill_level_targeted VARCHAR(20) CHECK (skill_level_targeted IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    weightage_percentage DECIMAL(5,2) DEFAULT 100.00,
    is_primary_skill BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(course_id, skill_id)
);

-- Learning Path Courses
CREATE TABLE learning_path_courses (
    path_course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    learning_path_id UUID NOT NULL REFERENCES learning_path_master(learning_path_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES course_master(course_id),
    sequence_order INTEGER NOT NULL,
    is_mandatory BOOLEAN DEFAULT true,
    prerequisite_course_id UUID REFERENCES course_master(course_id),
    weightage_percentage DECIMAL(5,2) DEFAULT 100.00,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(learning_path_id, course_id),
    UNIQUE(learning_path_id, sequence_order)
);

-- ======================================================================
-- 3. TRAINING SCHEDULE AND SESSION MANAGEMENT
-- ======================================================================

-- Training Schedule
CREATE TABLE training_schedule (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_code VARCHAR(50) UNIQUE NOT NULL,
    course_id UUID NOT NULL REFERENCES course_master(course_id),
    batch_name VARCHAR(150),

    -- Instructor Information
    instructor_employee_id UUID REFERENCES employee_master(employee_id),
    external_instructor_name VARCHAR(200),
    external_instructor_email VARCHAR(150),
    external_instructor_phone VARCHAR(20),

    -- Schedule Details
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_sessions INTEGER DEFAULT 1,
    location_id UUID REFERENCES location_master(location_id),
    training_venue VARCHAR(300),
    virtual_meeting_link VARCHAR(500),
    virtual_meeting_password VARCHAR(100),

    -- Capacity and Status
    max_participants INTEGER NOT NULL,
    min_participants INTEGER DEFAULT 1,
    enrolled_count INTEGER DEFAULT 0,
    waitlist_count INTEGER DEFAULT 0,

    -- Schedule Status
    status VARCHAR(20) DEFAULT 'PLANNED' CHECK (status IN (
        'PLANNED', 'OPEN_FOR_ENROLLMENT', 'ENROLLMENT_CLOSED', 'IN_PROGRESS',
        'COMPLETED', 'CANCELLED', 'POSTPONED'
    )),

    -- Registration
    registration_start_date DATE,
    registration_end_date DATE,
    enrollment_deadline DATE,

    -- Cost and Budget
    total_budget DECIMAL(12,2),
    cost_per_participant DECIMAL(10,2),

    -- Feedback and Evaluation
    feedback_form_template TEXT,
    overall_rating DECIMAL(3,2),

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Training Sessions
CREATE TABLE training_session (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES training_schedule(schedule_id) ON DELETE CASCADE,
    session_number INTEGER NOT NULL,
    session_title VARCHAR(200),
    session_description TEXT,

    -- Session Timing
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INTEGER,

    -- Session Details
    session_type VARCHAR(20) CHECK (session_type IN ('THEORY', 'PRACTICAL', 'ASSESSMENT', 'DISCUSSION', 'BREAK', 'Q_AND_A')),
    session_mode VARCHAR(20) CHECK (session_mode IN ('IN_PERSON', 'VIRTUAL', 'HYBRID')),

    -- Location and Resources
    room_or_venue VARCHAR(200),
    virtual_link VARCHAR(500),
    session_materials TEXT,
    required_resources TEXT,

    -- Session Status
    status VARCHAR(20) DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'POSTPONED')),
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,

    -- Session Outcomes
    topics_covered TEXT,
    session_notes TEXT,
    homework_assigned TEXT,

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(schedule_id, session_number)
);

-- ======================================================================
-- 4. ENROLLMENT AND PARTICIPATION TRACKING
-- ======================================================================

-- Training Enrollment
CREATE TABLE training_enrollment (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_number VARCHAR(50) UNIQUE NOT NULL,
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    schedule_id UUID NOT NULL REFERENCES training_schedule(schedule_id),
    learning_path_id UUID REFERENCES learning_path_master(learning_path_id),

    -- Enrollment Details
    enrollment_date DATE DEFAULT CURRENT_DATE,
    enrollment_type VARCHAR(20) CHECK (enrollment_type IN ('SELF_ENROLLED', 'MANAGER_NOMINATED', 'HR_ASSIGNED', 'MANDATORY', 'DEVELOPMENT_PLAN')),
    enrollment_reason TEXT,
    priority_level VARCHAR(10) CHECK (priority_level IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),

    -- Approval Workflow
    nomination_by_employee_id UUID REFERENCES employee_master(employee_id),
    approval_required BOOLEAN DEFAULT false,
    approved_by_employee_id UUID REFERENCES employee_master(employee_id),
    approval_date DATE,
    approval_status VARCHAR(20) DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    rejection_reason TEXT,

    -- Status Tracking
    enrollment_status VARCHAR(20) DEFAULT 'ENROLLED' CHECK (enrollment_status IN (
        'ENROLLED', 'WAITLISTED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED',
        'DROPPED_OUT', 'NO_SHOW', 'CANCELLED'
    )),

    -- Progress Tracking
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    sessions_attended INTEGER DEFAULT 0,
    total_sessions INTEGER,

    -- Completion and Assessment
    completion_date DATE,
    final_score DECIMAL(5,2),
    grade VARCHAR(5),
    certificate_issued BOOLEAN DEFAULT false,
    certificate_number VARCHAR(100),
    certificate_issue_date DATE,
    certificate_expiry_date DATE,

    -- Feedback
    participant_feedback TEXT,
    participant_rating DECIMAL(3,2),
    trainer_feedback TEXT,

    -- Cost Tracking
    training_cost DECIMAL(10,2),
    cost_center_id UUID REFERENCES department_master(department_id),

    -- Metadata
    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(employee_id, schedule_id)
);

-- Session Attendance
CREATE TABLE session_attendance (
    attendance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES training_enrollment(enrollment_id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES training_session(session_id),
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),

    -- Attendance Details
    attendance_status VARCHAR(20) DEFAULT 'SCHEDULED' CHECK (attendance_status IN (
        'SCHEDULED', 'PRESENT', 'ABSENT', 'LATE', 'PARTIAL', 'EXCUSED'
    )),
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    duration_attended_minutes INTEGER,

    -- Participation Tracking
    participation_level VARCHAR(20) CHECK (participation_level IN ('POOR', 'FAIR', 'GOOD', 'EXCELLENT')),
    session_notes TEXT,
    homework_submitted BOOLEAN DEFAULT false,
    homework_score DECIMAL(5,2),

    -- Late arrival tracking
    late_arrival_minutes INTEGER DEFAULT 0,
    early_departure_minutes INTEGER DEFAULT 0,
    absence_reason TEXT,

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(enrollment_id, session_id)
);

-- ======================================================================
-- 5. ASSESSMENT AND EVALUATION TABLES
-- ======================================================================

-- Training Assessment
CREATE TABLE training_assessment (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_code VARCHAR(30) UNIQUE NOT NULL,
    course_id UUID NOT NULL REFERENCES course_master(course_id),
    assessment_title VARCHAR(200) NOT NULL,
    assessment_description TEXT,

    -- Assessment Configuration
    assessment_type VARCHAR(20) CHECK (assessment_type IN ('PRE_TRAINING', 'DURING_TRAINING', 'POST_TRAINING', 'FINAL_EXAM')),
    assessment_format VARCHAR(20) CHECK (assessment_format IN ('MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_BLANKS', 'ESSAY', 'PRACTICAL', 'MIXED')),

    -- Timing and Attempts
    time_limit_minutes INTEGER,
    max_attempts INTEGER DEFAULT 1,
    passing_score DECIMAL(5,2) NOT NULL,

    -- Question Configuration
    total_questions INTEGER,
    questions_config JSONB, -- Configuration for question types and weightage

    -- Status
    is_active BOOLEAN DEFAULT true,

    created_by UUID NOT NULL REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES user_master(user_id),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Assessment Questions
CREATE TABLE assessment_question (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES training_assessment(assessment_id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) CHECK (question_type IN ('MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_BLANK', 'ESSAY', 'PRACTICAL')),

    -- Question Options (for MCQ, True/False)
    options JSONB, -- Array of options with correct answer indicator
    correct_answer TEXT,
    explanation TEXT,

    -- Scoring
    points DECIMAL(5,2) DEFAULT 1.00,
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('EASY', 'MEDIUM', 'HARD')),

    -- Question Metadata
    skill_tested VARCHAR(200),
    topic_area VARCHAR(200),

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(assessment_id, question_number)
);

-- Employee Assessment Attempts
CREATE TABLE employee_assessment_attempt (
    attempt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES training_enrollment(enrollment_id),
    assessment_id UUID NOT NULL REFERENCES training_assessment(assessment_id),
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),

    -- Attempt Details
    attempt_number INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes INTEGER,

    -- Scores and Results
    total_score DECIMAL(5,2),
    percentage_score DECIMAL(5,2),
    grade VARCHAR(5),
    status VARCHAR(20) CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'ABANDONED', 'TIME_EXPIRED')),
    passed BOOLEAN,

    -- Attempt Configuration
    time_limit_minutes INTEGER,
    total_questions INTEGER,
    questions_attempted INTEGER,

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(enrollment_id, assessment_id, attempt_number)
);

-- Employee Assessment Answers
CREATE TABLE employee_assessment_answer (
    answer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES employee_assessment_attempt(attempt_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES assessment_question(question_id),

    -- Answer Details
    employee_answer TEXT,
    is_correct BOOLEAN,
    points_earned DECIMAL(5,2) DEFAULT 0.00,
    time_spent_seconds INTEGER,

    -- Answer Metadata
    answer_sequence INTEGER,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(attempt_id, question_id)
);

-- ======================================================================
-- 6. SKILL DEVELOPMENT AND COMPETENCY TRACKING
-- ======================================================================

-- Employee Skill Assessment (Current Skills)
CREATE TABLE employee_skill_assessment (
    skill_assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    skill_id UUID NOT NULL REFERENCES skill_master(skill_id),

    -- Assessment Details
    assessment_date DATE DEFAULT CURRENT_DATE,
    assessment_type VARCHAR(20) CHECK (assessment_type IN ('SELF_ASSESSMENT', 'MANAGER_ASSESSMENT', 'PEER_ASSESSMENT', 'TRAINING_BASED', 'FORMAL_TEST')),
    assessed_by_employee_id UUID REFERENCES employee_master(employee_id),

    -- Skill Level
    current_level VARCHAR(20) CHECK (current_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    proficiency_score DECIMAL(5,2) CHECK (proficiency_score >= 0 AND proficiency_score <= 10),

    -- Assessment Evidence
    assessment_method VARCHAR(100),
    evidence_description TEXT,
    assessment_notes TEXT,

    -- Validation
    validated_by_employee_id UUID REFERENCES employee_master(employee_id),
    validation_date DATE,
    validation_status VARCHAR(20) DEFAULT 'PENDING' CHECK (validation_status IN ('PENDING', 'VALIDATED', 'REJECTED')),

    -- Next Assessment
    next_assessment_due_date DATE,

    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(employee_id, skill_id, assessment_date)
);

-- Skill Development Plan
CREATE TABLE skill_development_plan (
    development_plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    skill_id UUID NOT NULL REFERENCES skill_master(skill_id),

    -- Current and Target Levels
    current_level VARCHAR(20) CHECK (current_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    target_level VARCHAR(20) CHECK (target_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    current_score DECIMAL(5,2),
    target_score DECIMAL(5,2),

    -- Plan Details
    plan_start_date DATE DEFAULT CURRENT_DATE,
    target_completion_date DATE NOT NULL,
    development_priority VARCHAR(10) CHECK (development_priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),

    -- Development Strategy
    development_methods TEXT, -- Training, Mentoring, Job Rotation, etc.
    recommended_courses TEXT,
    learning_path_id UUID REFERENCES learning_path_master(learning_path_id),
    mentor_employee_id UUID REFERENCES employee_master(employee_id),

    -- Progress Tracking
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    last_assessment_date DATE,
    latest_score DECIMAL(5,2),

    -- Plan Status
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('DRAFT', 'ACTIVE', 'ON_HOLD', 'COMPLETED', 'CANCELLED')),
    completion_date DATE,

    -- Reviews and Updates
    created_by_employee_id UUID REFERENCES employee_master(employee_id),
    approved_by_employee_id UUID REFERENCES employee_master(employee_id),
    last_reviewed_date DATE,
    next_review_date DATE,

    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(employee_id, skill_id, plan_start_date)
);

-- ======================================================================
-- 7. CERTIFICATION AND COMPLIANCE TRACKING
-- ======================================================================

-- Certification Master
CREATE TABLE certification_master (
    certification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_code VARCHAR(30) UNIQUE NOT NULL,
    certification_name VARCHAR(200) NOT NULL,
    certification_description TEXT,

    -- Certification Details
    issuing_organization VARCHAR(200) NOT NULL,
    certification_type VARCHAR(20) CHECK (certification_type IN ('INTERNAL', 'EXTERNAL', 'PROFESSIONAL', 'COMPLIANCE', 'TECHNICAL')),
    certification_category VARCHAR(50),

    -- Validity and Requirements
    validity_period_months INTEGER,
    is_renewable BOOLEAN DEFAULT true,
    renewal_period_months INTEGER,
    prerequisites TEXT,

    -- Associated Skills
    skills_covered TEXT,
    certification_level VARCHAR(20) CHECK (certification_level IN ('FOUNDATION', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),

    -- Cost and Provider
    certification_cost DECIMAL(10,2),
    provider_id UUID REFERENCES training_provider_master(provider_id),

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_mandatory_for_roles TEXT, -- JSON array of designation IDs

    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employee Certification
CREATE TABLE employee_certification (
    employee_certification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employee_master(employee_id),
    certification_id UUID NOT NULL REFERENCES certification_master(certification_id),

    -- Certification Achievement
    achieved_date DATE NOT NULL,
    certificate_number VARCHAR(100),
    score_obtained DECIMAL(5,2),
    grade_achieved VARCHAR(10),

    -- Validity and Renewal
    valid_from_date DATE NOT NULL,
    valid_until_date DATE,
    is_currently_valid BOOLEAN DEFAULT true,
    renewal_due_date DATE,

    -- Certification Evidence
    certificate_file_path VARCHAR(500),
    verification_url VARCHAR(500),
    issuing_authority VARCHAR(200),

    -- Training Connection
    training_enrollment_id UUID REFERENCES training_enrollment(enrollment_id),

    -- Renewal History
    renewal_count INTEGER DEFAULT 0,
    last_renewal_date DATE,
    next_renewal_due DATE,

    -- Status and Tracking
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED', 'SUSPENDED', 'PENDING_RENEWAL')),
    compliance_status VARCHAR(20) DEFAULT 'COMPLIANT' CHECK (compliance_status IN ('COMPLIANT', 'NON_COMPLIANT', 'GRACE_PERIOD', 'EXPIRED')),

    -- Notifications
    reminder_sent_date DATE,
    expiry_notification_sent BOOLEAN DEFAULT false,

    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(employee_id, certification_id, achieved_date)
);

-- ======================================================================
-- 8. TRAINING ANALYTICS AND REPORTING TABLES
-- ======================================================================

-- Training Metrics Summary
CREATE TABLE training_metrics_summary (
    metrics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES company_master(company_id),

    -- Time Period
    metrics_date DATE NOT NULL,
    metrics_type VARCHAR(20) CHECK (metrics_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),

    -- Training Volume Metrics
    total_courses_conducted INTEGER DEFAULT 0,
    total_enrollments INTEGER DEFAULT 0,
    total_completions INTEGER DEFAULT 0,
    total_training_hours DECIMAL(10,2) DEFAULT 0.00,
    total_participants INTEGER DEFAULT 0,

    -- Performance Metrics
    average_completion_rate DECIMAL(5,2),
    average_satisfaction_rating DECIMAL(3,2),
    average_effectiveness_score DECIMAL(3,2),
    dropout_rate DECIMAL(5,2),

    -- Cost Metrics
    total_training_cost DECIMAL(12,2) DEFAULT 0.00,
    cost_per_employee DECIMAL(10,2),
    cost_per_training_hour DECIMAL(8,2),

    -- Compliance Metrics
    compliance_training_completion_rate DECIMAL(5,2),
    mandatory_training_completion_rate DECIMAL(5,2),
    certification_achievement_rate DECIMAL(5,2),

    -- Skill Development Metrics
    skills_assessments_completed INTEGER DEFAULT 0,
    average_skill_improvement DECIMAL(5,2),
    development_plans_created INTEGER DEFAULT 0,
    development_plans_completed INTEGER DEFAULT 0,

    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(company_id, metrics_date, metrics_type)
);

-- Training Effectiveness Analysis
CREATE TABLE training_effectiveness_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES course_master(course_id),
    schedule_id UUID REFERENCES training_schedule(schedule_id),

    -- Analysis Period
    analysis_date DATE DEFAULT CURRENT_DATE,
    analysis_period_start DATE,
    analysis_period_end DATE,

    -- Participation Metrics
    total_enrolled INTEGER DEFAULT 0,
    total_completed INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2),
    dropout_rate DECIMAL(5,2),
    average_attendance_rate DECIMAL(5,2),

    -- Learning Effectiveness
    average_pre_training_score DECIMAL(5,2),
    average_post_training_score DECIMAL(5,2),
    average_improvement_score DECIMAL(5,2),
    learning_effectiveness_index DECIMAL(5,2),

    -- Satisfaction Metrics
    average_participant_rating DECIMAL(3,2),
    trainer_effectiveness_rating DECIMAL(3,2),
    content_quality_rating DECIMAL(3,2),
    venue_facility_rating DECIMAL(3,2),

    -- Business Impact
    skill_improvement_percentage DECIMAL(5,2),
    performance_improvement_correlation DECIMAL(5,2),
    roi_percentage DECIMAL(8,2),

    -- Recommendations
    effectiveness_status VARCHAR(20) CHECK (effectiveness_status IN ('EXCELLENT', 'GOOD', 'AVERAGE', 'NEEDS_IMPROVEMENT', 'POOR')),
    improvement_recommendations TEXT,

    -- Cost Analysis
    total_cost DECIMAL(12,2),
    cost_per_participant DECIMAL(10,2),
    cost_effectiveness_ratio DECIMAL(8,2),

    company_id UUID NOT NULL REFERENCES company_master(company_id),
    created_by UUID REFERENCES user_master(user_id),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(course_id, analysis_date)
);

-- ======================================================================
-- 9. INDEXES FOR PERFORMANCE OPTIMIZATION
-- ======================================================================

-- Training Category Indexes
CREATE INDEX idx_training_category_company ON training_category_master(company_id);
CREATE INDEX idx_training_category_parent ON training_category_master(parent_category_id);
CREATE INDEX idx_training_category_active ON training_category_master(is_active);

-- Skill Master Indexes
CREATE INDEX idx_skill_master_company ON skill_master(company_id);
CREATE INDEX idx_skill_master_category ON skill_master(skill_category);
CREATE INDEX idx_skill_master_active ON skill_master(is_active);

-- Course Master Indexes
CREATE INDEX idx_course_master_company ON course_master(company_id);
CREATE INDEX idx_course_master_category ON course_master(category_id);
CREATE INDEX idx_course_master_provider ON course_master(provider_id);
CREATE INDEX idx_course_master_type ON course_master(course_type);
CREATE INDEX idx_course_master_active ON course_master(is_active);

-- Training Schedule Indexes
CREATE INDEX idx_training_schedule_company ON training_schedule(company_id);
CREATE INDEX idx_training_schedule_course ON training_schedule(course_id);
CREATE INDEX idx_training_schedule_dates ON training_schedule(start_date, end_date);
CREATE INDEX idx_training_schedule_status ON training_schedule(status);
CREATE INDEX idx_training_schedule_instructor ON training_schedule(instructor_employee_id);

-- Training Enrollment Indexes
CREATE INDEX idx_training_enrollment_company ON training_enrollment(company_id);
CREATE INDEX idx_training_enrollment_employee ON training_enrollment(employee_id);
CREATE INDEX idx_training_enrollment_schedule ON training_enrollment(schedule_id);
CREATE INDEX idx_training_enrollment_status ON training_enrollment(enrollment_status);
CREATE INDEX idx_training_enrollment_completion ON training_enrollment(completion_date);

-- Assessment Indexes
CREATE INDEX idx_training_assessment_course ON training_assessment(course_id);
CREATE INDEX idx_employee_assessment_attempt_enrollment ON employee_assessment_attempt(enrollment_id);
CREATE INDEX idx_employee_assessment_attempt_employee ON employee_assessment_attempt(employee_id);

-- Skill Assessment Indexes
CREATE INDEX idx_employee_skill_assessment_employee ON employee_skill_assessment(employee_id);
CREATE INDEX idx_employee_skill_assessment_skill ON employee_skill_assessment(skill_id);
CREATE INDEX idx_employee_skill_assessment_date ON employee_skill_assessment(assessment_date);

-- Certification Indexes
CREATE INDEX idx_employee_certification_employee ON employee_certification(employee_id);
CREATE INDEX idx_employee_certification_cert ON employee_certification(certification_id);
CREATE INDEX idx_employee_certification_validity ON employee_certification(valid_until_date);
CREATE INDEX idx_employee_certification_status ON employee_certification(status);

-- ======================================================================
-- 10. TRIGGERS AND BUSINESS LOGIC FUNCTIONS
-- ======================================================================

-- Function to update enrollment counts in training schedule
CREATE OR REPLACE FUNCTION update_enrollment_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Update enrolled count when enrollment status changes
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.enrollment_status IS DISTINCT FROM NEW.enrollment_status) THEN
        UPDATE training_schedule
        SET enrolled_count = (
            SELECT COUNT(*)
            FROM training_enrollment
            WHERE schedule_id = COALESCE(NEW.schedule_id, OLD.schedule_id)
            AND enrollment_status IN ('ENROLLED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED')
        ),
        waitlist_count = (
            SELECT COUNT(*)
            FROM training_enrollment
            WHERE schedule_id = COALESCE(NEW.schedule_id, OLD.schedule_id)
            AND enrollment_status = 'WAITLISTED'
        )
        WHERE schedule_id = COALESCE(NEW.schedule_id, OLD.schedule_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for enrollment count updates
CREATE TRIGGER trg_update_enrollment_counts
    AFTER INSERT OR UPDATE OR DELETE ON training_enrollment
    FOR EACH ROW
    EXECUTE FUNCTION update_enrollment_counts();

-- Function to calculate training progress
CREATE OR REPLACE FUNCTION calculate_training_progress()
RETURNS TRIGGER AS $$
DECLARE
    total_sessions_count INTEGER;
    attended_sessions_count INTEGER;
    progress_pct DECIMAL(5,2);
BEGIN
    -- Get total sessions for the schedule
    SELECT total_sessions INTO total_sessions_count
    FROM training_schedule
    WHERE schedule_id = NEW.schedule_id;

    -- Count attended sessions for this enrollment
    SELECT COUNT(*) INTO attended_sessions_count
    FROM session_attendance sa
    JOIN training_session ts ON sa.session_id = ts.session_id
    WHERE sa.enrollment_id = NEW.enrollment_id
    AND sa.attendance_status IN ('PRESENT', 'PARTIAL');

    -- Calculate progress percentage
    IF total_sessions_count > 0 THEN
        progress_pct := (attended_sessions_count::DECIMAL / total_sessions_count::DECIMAL) * 100;
    ELSE
        progress_pct := 0;
    END IF;

    -- Update enrollment progress
    UPDATE training_enrollment
    SET progress_percentage = progress_pct,
        sessions_attended = attended_sessions_count,
        total_sessions = total_sessions_count,
        modified_date = CURRENT_TIMESTAMP
    WHERE enrollment_id = NEW.enrollment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for training progress calculation
CREATE TRIGGER trg_calculate_training_progress
    AFTER INSERT OR UPDATE ON session_attendance
    FOR EACH ROW
    EXECUTE FUNCTION calculate_training_progress();

-- Function to generate enrollment numbers
CREATE OR REPLACE FUNCTION generate_enrollment_number()
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
    SELECT COALESCE(MAX(CAST(RIGHT(enrollment_number, 6) AS INTEGER)), 0) + 1
    INTO next_sequence
    FROM training_enrollment
    WHERE company_id = NEW.company_id
    AND EXTRACT(YEAR FROM created_date) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generate enrollment number: COMP-TRN-YYYY-NNNNNN
    NEW.enrollment_number := UPPER(company_code) || '-TRN-' ||
                             EXTRACT(YEAR FROM CURRENT_DATE) || '-' ||
                             LPAD(next_sequence::TEXT, 6, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for enrollment number generation
CREATE TRIGGER trg_generate_enrollment_number
    BEFORE INSERT ON training_enrollment
    FOR EACH ROW
    WHEN (NEW.enrollment_number IS NULL OR NEW.enrollment_number = '')
    EXECUTE FUNCTION generate_enrollment_number();

-- Function to update skill assessment based on training completion
CREATE OR REPLACE FUNCTION update_skill_after_training()
RETURNS TRIGGER AS $$
DECLARE
    course_skill RECORD;
    current_assessment RECORD;
    new_level VARCHAR(20);
    new_score DECIMAL(5,2);
BEGIN
    -- Only process when training is completed
    IF NEW.enrollment_status = 'COMPLETED' AND OLD.enrollment_status != 'COMPLETED' THEN

        -- Get all skills associated with the completed course
        FOR course_skill IN
            SELECT csm.skill_id, csm.skill_level_targeted, cm.course_title
            FROM course_skill_mapping csm
            JOIN course_master cm ON csm.course_id = cm.course_id
            JOIN training_schedule ts ON cm.course_id = ts.course_id
            WHERE ts.schedule_id = NEW.schedule_id
        LOOP
            -- Get current skill assessment if exists
            SELECT * INTO current_assessment
            FROM employee_skill_assessment
            WHERE employee_id = NEW.employee_id
            AND skill_id = course_skill.skill_id
            ORDER BY assessment_date DESC
            LIMIT 1;

            -- Determine new skill level and score based on training completion
            IF NEW.final_score IS NOT NULL THEN
                -- Base improvement on final score
                CASE
                    WHEN NEW.final_score >= 90 THEN
                        new_level := course_skill.skill_level_targeted;
                        new_score := LEAST(COALESCE(current_assessment.proficiency_score, 0) + 2.0, 10.0);
                    WHEN NEW.final_score >= 75 THEN
                        new_level := course_skill.skill_level_targeted;
                        new_score := LEAST(COALESCE(current_assessment.proficiency_score, 0) + 1.5, 10.0);
                    WHEN NEW.final_score >= 60 THEN
                        new_level := course_skill.skill_level_targeted;
                        new_score := LEAST(COALESCE(current_assessment.proficiency_score, 0) + 1.0, 10.0);
                    ELSE
                        new_level := COALESCE(current_assessment.current_level, 'BEGINNER');
                        new_score := LEAST(COALESCE(current_assessment.proficiency_score, 0) + 0.5, 10.0);
                END CASE;
            ELSE
                -- Default improvement for completion without score
                new_level := course_skill.skill_level_targeted;
                new_score := LEAST(COALESCE(current_assessment.proficiency_score, 0) + 1.0, 10.0);
            END IF;

            -- Insert new skill assessment
            INSERT INTO employee_skill_assessment (
                employee_id, skill_id, assessment_type, assessed_by_employee_id,
                current_level, proficiency_score, assessment_method,
                evidence_description, assessment_notes, next_assessment_due_date,
                company_id
            ) VALUES (
                NEW.employee_id, course_skill.skill_id, 'TRAINING_BASED', NEW.created_by,
                new_level, new_score, 'Training Completion',
                'Skill updated based on completion of training: ' || course_skill.course_title,
                'Final Score: ' || COALESCE(NEW.final_score::TEXT, 'N/A') || ', Grade: ' || COALESCE(NEW.grade, 'N/A'),
                CURRENT_DATE + INTERVAL '6 months',
                NEW.company_id
            );

        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for skill assessment update after training
CREATE TRIGGER trg_update_skill_after_training
    AFTER UPDATE ON training_enrollment
    FOR EACH ROW
    EXECUTE FUNCTION update_skill_after_training();

-- Function to update modified timestamp
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for modified timestamp updates
CREATE TRIGGER trg_training_category_modified
    BEFORE UPDATE ON training_category_master
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_skill_master_modified
    BEFORE UPDATE ON skill_master
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_learning_path_modified
    BEFORE UPDATE ON learning_path_master
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_course_master_modified
    BEFORE UPDATE ON course_master
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_training_schedule_modified
    BEFORE UPDATE ON training_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trg_training_enrollment_modified
    BEFORE UPDATE ON training_enrollment
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

-- ======================================================================
-- 11. VIEWS FOR COMMON QUERIES
-- ======================================================================

-- Active Training Schedules with Details
CREATE VIEW vw_active_training_schedules AS
SELECT
    ts.schedule_id,
    ts.schedule_code,
    cm.course_title,
    cm.course_type,
    cm.duration_hours,
    ts.start_date,
    ts.end_date,
    ts.max_participants,
    ts.enrolled_count,
    ts.waitlist_count,
    CASE
        WHEN ts.enrolled_count >= ts.max_participants THEN 'FULL'
        WHEN ts.enrollment_deadline < CURRENT_DATE THEN 'CLOSED'
        ELSE 'AVAILABLE'
    END as enrollment_availability,
    ts.status,
    emp.full_name as instructor_name,
    lm.location_name,
    ts.training_venue
FROM training_schedule ts
JOIN course_master cm ON ts.course_id = cm.course_id
LEFT JOIN employee_master emp ON ts.instructor_employee_id = emp.employee_id
LEFT JOIN location_master lm ON ts.location_id = lm.location_id
WHERE ts.status IN ('PLANNED', 'OPEN_FOR_ENROLLMENT', 'IN_PROGRESS')
AND cm.is_active = true;

-- Employee Training Summary
CREATE VIEW vw_employee_training_summary AS
SELECT
    em.employee_id,
    em.employee_code,
    em.full_name,
    COUNT(te.enrollment_id) as total_enrollments,
    COUNT(CASE WHEN te.enrollment_status = 'COMPLETED' THEN 1 END) as completed_trainings,
    COUNT(CASE WHEN te.enrollment_status = 'IN_PROGRESS' THEN 1 END) as ongoing_trainings,
    SUM(CASE WHEN te.enrollment_status = 'COMPLETED' THEN cm.duration_hours ELSE 0 END) as total_training_hours,
    AVG(CASE WHEN te.enrollment_status = 'COMPLETED' AND te.final_score IS NOT NULL THEN te.final_score END) as average_score,
    COUNT(ec.employee_certification_id) as total_certifications,
    COUNT(CASE WHEN ec.status = 'ACTIVE' THEN 1 END) as active_certifications
FROM employee_master em
LEFT JOIN training_enrollment te ON em.employee_id = te.employee_id
LEFT JOIN training_schedule ts ON te.schedule_id = ts.schedule_id
LEFT JOIN course_master cm ON ts.course_id = cm.course_id
LEFT JOIN employee_certification ec ON em.employee_id = ec.employee_id
GROUP BY em.employee_id, em.employee_code, em.full_name;

-- Training Effectiveness Dashboard
CREATE VIEW vw_training_effectiveness_dashboard AS
SELECT
    cm.course_id,
    cm.course_title,
    cm.course_type,
    tcm.category_name as training_category,
    COUNT(DISTINCT ts.schedule_id) as total_schedules,
    COUNT(te.enrollment_id) as total_enrollments,
    COUNT(CASE WHEN te.enrollment_status = 'COMPLETED' THEN 1 END) as total_completions,
    ROUND(
        (COUNT(CASE WHEN te.enrollment_status = 'COMPLETED' THEN 1 END)::DECIMAL /
         NULLIF(COUNT(te.enrollment_id), 0)) * 100, 2
    ) as completion_rate,
    AVG(te.final_score) as average_score,
    AVG(te.participant_rating) as average_satisfaction,
    SUM(ts.total_budget) as total_investment
FROM course_master cm
LEFT JOIN training_category_master tcm ON cm.category_id = tcm.category_id
LEFT JOIN training_schedule ts ON cm.course_id = ts.course_id
LEFT JOIN training_enrollment te ON ts.schedule_id = te.schedule_id
WHERE cm.is_active = true
GROUP BY cm.course_id, cm.course_title, cm.course_type, tcm.category_name;

-- ======================================================================
-- TRAINING & DEVELOPMENT SCHEMA COMPLETED
-- ======================================================================

-- Summary of tables created:
-- 1. Training Categories, Skills, Learning Paths (3 tables)
-- 2. Training Providers, Courses, Course-Skill Mapping, Path Courses (4 tables)
-- 3. Training Schedules and Sessions (2 tables)
-- 4. Enrollment and Attendance Tracking (2 tables)
-- 5. Assessments, Questions, Attempts, Answers (4 tables)
-- 6. Skill Assessment and Development Plans (2 tables)
-- 7. Certification Management (2 tables)
-- 8. Training Analytics and Reporting (2 tables)
-- 9. Performance indexes (30 indexes)

-- Total Tables: 21 core tables
-- Total Indexes: 30 performance indexes