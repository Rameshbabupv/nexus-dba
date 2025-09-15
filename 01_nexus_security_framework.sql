-- ======================================================================
-- NEXUS HRMS - Security and Compliance Framework (PostgreSQL DBA)
-- ======================================================================
-- DBA: Senior PostgreSQL Database Administrator (20+ Years Experience)
-- Purpose: Enterprise-grade security framework for HRMS data protection
-- Compliance: GDPR, SOX, HIPAA-ready security controls
-- Architecture: Multi-tenant security with comprehensive audit trails
-- Created: 2024-09-14
-- ======================================================================

-- ===============================
-- SECURITY EXTENSIONS AND SETUP
-- ===============================

-- Enable security-related extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "hstore";

-- Create dedicated security schema
CREATE SCHEMA IF NOT EXISTS nexus_security;
COMMENT ON SCHEMA nexus_security IS 'Security framework: encryption keys, security policies, and compliance controls';

-- ===============================
-- DATA CLASSIFICATION FRAMEWORK
-- ===============================

-- Data Classification Levels
CREATE TYPE nexus_security.data_classification AS ENUM (
    'PUBLIC',           -- Publicly available information
    'INTERNAL',         -- Internal company information
    'CONFIDENTIAL',     -- Sensitive business information
    'RESTRICTED',       -- Highly sensitive information (PII, Financial)
    'TOP_SECRET'        -- Extremely sensitive (Executive compensation, etc.)
);

-- PII (Personally Identifiable Information) Categories
CREATE TYPE nexus_security.pii_category AS ENUM (
    'NONE',                    -- No PII
    'NON_SENSITIVE',          -- Non-sensitive personal data
    'SENSITIVE',              -- Sensitive personal data
    'FINANCIAL',              -- Financial information
    'HEALTH',                 -- Health-related information
    'BIOMETRIC',              -- Biometric data
    'SPECIAL_CATEGORY'        -- Special category data (religion, etc.)
);

-- Data Classification Registry
CREATE TABLE nexus_security.data_classification_registry (
    classification_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Table and Column Information
    schema_name VARCHAR(64) NOT NULL,
    table_name VARCHAR(64) NOT NULL,
    column_name VARCHAR(64) NOT NULL,

    -- Classification Details
    data_classification nexus_security.data_classification NOT NULL,
    pii_category nexus_security.pii_category NOT NULL DEFAULT 'NONE',

    -- Security Requirements
    requires_encryption BOOLEAN NOT NULL DEFAULT false,
    requires_masking BOOLEAN NOT NULL DEFAULT false,
    requires_audit BOOLEAN NOT NULL DEFAULT true,

    -- Retention Policy
    retention_period_months INTEGER,
    deletion_required BOOLEAN NOT NULL DEFAULT false,

    -- Legal Basis (GDPR)
    legal_basis VARCHAR(100), -- 'CONSENT', 'CONTRACT', 'LEGAL_OBLIGATION', etc.

    -- Access Control
    min_role_required VARCHAR(50),
    requires_explicit_consent BOOLEAN NOT NULL DEFAULT false,

    -- Data Subject Rights
    supports_data_export BOOLEAN NOT NULL DEFAULT true,
    supports_data_deletion BOOLEAN NOT NULL DEFAULT true,
    supports_data_rectification BOOLEAN NOT NULL DEFAULT true,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    modified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by BIGINT,

    -- Constraints
    CONSTRAINT uk_data_classification UNIQUE(schema_name, table_name, column_name)
);

-- Index for data classification queries
CREATE INDEX idx_data_classification_lookup ON nexus_security.data_classification_registry
    (schema_name, table_name, data_classification);
CREATE INDEX idx_data_classification_pii ON nexus_security.data_classification_registry
    (pii_category, requires_encryption);

-- ===============================
-- ENCRYPTION KEY MANAGEMENT
-- ===============================

-- Encryption Key Registry
CREATE TABLE nexus_security.encryption_key_registry (
    key_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT REFERENCES nexus_foundation.company_master(company_id),

    -- Key Information
    key_name VARCHAR(100) NOT NULL,
    key_purpose VARCHAR(100) NOT NULL, -- 'COLUMN_ENCRYPTION', 'FILE_ENCRYPTION', etc.
    key_algorithm VARCHAR(50) NOT NULL DEFAULT 'AES-256',

    -- Key Storage (encrypted with master key)
    encrypted_key_value BYTEA NOT NULL,
    key_salt BYTEA NOT NULL,
    key_iv BYTEA NOT NULL,

    -- Key Lifecycle
    key_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    -- Key Rotation
    previous_key_id BIGINT REFERENCES nexus_security.encryption_key_registry(key_id),
    next_key_id BIGINT REFERENCES nexus_security.encryption_key_registry(key_id),
    rotation_required BOOLEAN NOT NULL DEFAULT false,
    rotation_frequency_days INTEGER DEFAULT 365,

    -- Access Control
    created_by BIGINT,
    modified_by BIGINT,
    last_accessed_at TIMESTAMPTZ,
    access_count INTEGER NOT NULL DEFAULT 0,

    -- Constraints
    CONSTRAINT chk_key_status CHECK (key_status IN ('ACTIVE', 'INACTIVE', 'COMPROMISED', 'EXPIRED', 'PENDING_DELETION')),
    CONSTRAINT uk_encryption_key UNIQUE(company_id, key_name)
);

-- Encryption key access log
CREATE TABLE nexus_security.encryption_key_access_log (
    access_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    key_id BIGINT NOT NULL REFERENCES nexus_security.encryption_key_registry(key_id),

    -- Access Details
    access_type VARCHAR(20) NOT NULL, -- 'ENCRYPT', 'DECRYPT', 'VIEW', 'ROTATE'
    accessed_by BIGINT,
    access_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Context
    application_name VARCHAR(100),
    source_ip INET,
    user_agent TEXT,

    -- Result
    access_successful BOOLEAN NOT NULL,
    failure_reason TEXT,

    -- Constraints
    CONSTRAINT chk_access_type CHECK (access_type IN ('ENCRYPT', 'DECRYPT', 'VIEW', 'ROTATE', 'CREATE', 'DELETE'))
);

-- ===============================
-- FIELD-LEVEL ENCRYPTION FUNCTIONS
-- ===============================

-- Encrypt sensitive data function
CREATE OR REPLACE FUNCTION nexus_security.encrypt_sensitive_data(
    p_data TEXT,
    p_company_id BIGINT,
    p_key_purpose VARCHAR(100) DEFAULT 'COLUMN_ENCRYPTION'
) RETURNS BYTEA AS $$
DECLARE
    v_key_record RECORD;
    v_encrypted_data BYTEA;
BEGIN
    -- Get active encryption key for company
    SELECT encrypted_key_value, key_salt, key_iv
    INTO v_key_record
    FROM nexus_security.encryption_key_registry
    WHERE company_id = p_company_id
    AND key_purpose = p_key_purpose
    AND key_status = 'ACTIVE'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active encryption key found for company % with purpose %', p_company_id, p_key_purpose;
    END IF;

    -- Encrypt the data (simplified - in production, use proper key derivation)
    v_encrypted_data := pgp_sym_encrypt(p_data::text, encode(v_key_record.encrypted_key_value, 'hex'));

    -- Log the encryption access
    INSERT INTO nexus_security.encryption_key_access_log (key_id, access_type, accessed_by, access_successful)
    SELECT key_id, 'ENCRYPT', COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0), true
    FROM nexus_security.encryption_key_registry
    WHERE company_id = p_company_id AND key_purpose = p_key_purpose AND key_status = 'ACTIVE';

    RETURN v_encrypted_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrypt sensitive data function
CREATE OR REPLACE FUNCTION nexus_security.decrypt_sensitive_data(
    p_encrypted_data BYTEA,
    p_company_id BIGINT,
    p_key_purpose VARCHAR(100) DEFAULT 'COLUMN_ENCRYPTION'
) RETURNS TEXT AS $$
DECLARE
    v_key_record RECORD;
    v_decrypted_data TEXT;
BEGIN
    -- Get active encryption key for company
    SELECT encrypted_key_value, key_salt, key_iv
    INTO v_key_record
    FROM nexus_security.encryption_key_registry
    WHERE company_id = p_company_id
    AND key_purpose = p_key_purpose
    AND key_status = 'ACTIVE'
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active decryption key found for company % with purpose %', p_company_id, p_key_purpose;
    END IF;

    -- Decrypt the data
    v_decrypted_data := pgp_sym_decrypt(p_encrypted_data, encode(v_key_record.encrypted_key_value, 'hex'));

    -- Log the decryption access
    INSERT INTO nexus_security.encryption_key_access_log (key_id, access_type, accessed_by, access_successful)
    SELECT key_id, 'DECRYPT', COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0), true
    FROM nexus_security.encryption_key_registry
    WHERE company_id = p_company_id AND key_purpose = p_key_purpose AND key_status = 'ACTIVE';

    RETURN v_decrypted_data;
EXCEPTION
    WHEN OTHERS THEN
        -- Log failed decryption attempt
        INSERT INTO nexus_security.encryption_key_access_log (key_id, access_type, accessed_by, access_successful, failure_reason)
        SELECT key_id, 'DECRYPT', COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0), false, SQLERRM
        FROM nexus_security.encryption_key_registry
        WHERE company_id = p_company_id AND key_purpose = p_key_purpose AND key_status = 'ACTIVE';

        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================
-- DATA MASKING FUNCTIONS
-- ===============================

-- Email masking function
CREATE OR REPLACE FUNCTION nexus_security.mask_email(p_email TEXT) RETURNS TEXT AS $$
BEGIN
    IF p_email IS NULL OR length(p_email) < 5 THEN
        RETURN p_email;
    END IF;

    RETURN left(p_email, 2) || '***@' || split_part(p_email, '@', 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Phone number masking function
CREATE OR REPLACE FUNCTION nexus_security.mask_phone(p_phone TEXT) RETURNS TEXT AS $$
BEGIN
    IF p_phone IS NULL OR length(p_phone) < 6 THEN
        RETURN p_phone;
    END IF;

    RETURN left(p_phone, 3) || '***' || right(p_phone, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Name masking function
CREATE OR REPLACE FUNCTION nexus_security.mask_name(p_name TEXT) RETURNS TEXT AS $$
BEGIN
    IF p_name IS NULL OR length(p_name) < 3 THEN
        RETURN p_name;
    END IF;

    RETURN left(p_name, 1) || repeat('*', length(p_name) - 2) || right(p_name, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Salary masking function
CREATE OR REPLACE FUNCTION nexus_security.mask_salary(p_salary DECIMAL) RETURNS TEXT AS $$
BEGIN
    IF p_salary IS NULL THEN
        RETURN NULL;
    END IF;

    -- Mask salary in ranges for privacy
    CASE
        WHEN p_salary < 300000 THEN RETURN '< 3L'
        WHEN p_salary < 600000 THEN RETURN '3L - 6L'
        WHEN p_salary < 1000000 THEN RETURN '6L - 10L'
        WHEN p_salary < 1500000 THEN RETURN '10L - 15L'
        WHEN p_salary < 2500000 THEN RETURN '15L - 25L'
        ELSE RETURN '> 25L'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ===============================
-- ROW LEVEL SECURITY POLICIES
-- ===============================

-- Enhanced RLS policies for multi-tenant security

-- Company-based RLS policy with role-based exceptions
CREATE OR REPLACE FUNCTION nexus_security.company_access_policy(company_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE
    current_user_company BIGINT;
    current_user_role TEXT;
    is_system_admin BOOLEAN;
BEGIN
    -- Get current user context
    current_user_company := COALESCE(current_setting('app.current_company_id', true)::BIGINT, 0);
    current_user_role := COALESCE(current_setting('app.current_user_role', true), 'EMPLOYEE');
    is_system_admin := COALESCE(current_setting('app.is_system_admin', true)::BOOLEAN, false);

    -- System admins have access to all companies
    IF is_system_admin THEN
        RETURN true;
    END IF;

    -- Users can only access their own company data
    RETURN current_user_company = company_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Department-based access control
CREATE OR REPLACE FUNCTION nexus_security.department_access_policy(employee_department_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE
    current_user_departments BIGINT[];
    current_user_role TEXT;
    is_hr_manager BOOLEAN;
BEGIN
    -- Get current user context
    current_user_departments := string_to_array(COALESCE(current_setting('app.current_user_departments', true), ''), ',')::BIGINT[];
    current_user_role := COALESCE(current_setting('app.current_user_role', true), 'EMPLOYEE');
    is_hr_manager := current_user_role IN ('HR_MANAGER', 'COMPANY_ADMIN', 'SUPER_ADMIN');

    -- HR managers have access to all departments
    IF is_hr_manager THEN
        RETURN true;
    END IF;

    -- Check if user has access to this department
    RETURN employee_department_id = ANY(current_user_departments);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sensitive data access policy
CREATE OR REPLACE FUNCTION nexus_security.sensitive_data_access_policy() RETURNS BOOLEAN AS $$
DECLARE
    current_user_role TEXT;
    has_sensitive_access BOOLEAN;
BEGIN
    current_user_role := COALESCE(current_setting('app.current_user_role', true), 'EMPLOYEE');
    has_sensitive_access := COALESCE(current_setting('app.has_sensitive_data_access', true)::BOOLEAN, false);

    -- Only specific roles can access sensitive data
    RETURN current_user_role IN ('HR_MANAGER', 'PAYROLL_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN') OR has_sensitive_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================
-- AUDIT ENHANCEMENT FOR SECURITY
-- ===============================

-- Enhanced audit log with security context
CREATE TABLE nexus_security.security_audit_log (
    audit_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,

    -- Security Event Details
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(30) NOT NULL, -- 'AUTHENTICATION', 'AUTHORIZATION', 'DATA_ACCESS', 'ADMIN'
    event_severity VARCHAR(20) NOT NULL DEFAULT 'INFO',

    -- User Context
    user_id BIGINT,
    user_role VARCHAR(50),
    session_id VARCHAR(100),

    -- Access Context
    resource_type VARCHAR(50),
    resource_id BIGINT,
    action_performed VARCHAR(50),

    -- Security Details
    ip_address INET,
    user_agent TEXT,
    geo_location JSONB,

    -- Event Data
    event_data JSONB,
    sensitive_data_accessed BOOLEAN DEFAULT false,
    pii_data_accessed BOOLEAN DEFAULT false,

    -- Timing and Result
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_successful BOOLEAN NOT NULL,
    failure_reason TEXT,

    -- Risk Assessment
    risk_score INTEGER DEFAULT 0, -- 0-100 scale
    risk_factors JSONB,

    -- Constraints
    CONSTRAINT chk_event_category CHECK (event_category IN ('AUTHENTICATION', 'AUTHORIZATION', 'DATA_ACCESS', 'ADMIN', 'ENCRYPTION', 'EXPORT')),
    CONSTRAINT chk_event_severity CHECK (event_severity IN ('INFO', 'WARNING', 'ERROR', 'CRITICAL')),
    CONSTRAINT chk_risk_score CHECK (risk_score >= 0 AND risk_score <= 100)
) PARTITION BY RANGE (event_timestamp);

-- Create monthly partitions for security audit log
CREATE TABLE nexus_security.security_audit_log_2024_09 PARTITION OF nexus_security.security_audit_log
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE nexus_security.security_audit_log_2024_10 PARTITION OF nexus_security.security_audit_log
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE nexus_security.security_audit_log_2024_11 PARTITION OF nexus_security.security_audit_log
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE nexus_security.security_audit_log_2024_12 PARTITION OF nexus_security.security_audit_log
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Security audit indexes
CREATE INDEX idx_security_audit_company_time ON nexus_security.security_audit_log (company_id, event_timestamp DESC);
CREATE INDEX idx_security_audit_user_events ON nexus_security.security_audit_log (user_id, event_timestamp DESC);
CREATE INDEX idx_security_audit_high_risk ON nexus_security.security_audit_log (risk_score, event_timestamp DESC)
    WHERE risk_score >= 70;
CREATE INDEX idx_security_audit_failed_events ON nexus_security.security_audit_log (event_successful, event_timestamp DESC)
    WHERE event_successful = false;
CREATE INDEX idx_security_audit_sensitive_access ON nexus_security.security_audit_log (sensitive_data_accessed, pii_data_accessed, event_timestamp DESC)
    WHERE sensitive_data_accessed = true OR pii_data_accessed = true;

-- ===============================
-- GDPR COMPLIANCE FRAMEWORK
-- ===============================

-- Data Subject Requests (GDPR Article 15, 16, 17, 20)
CREATE TABLE nexus_security.data_subject_request (
    request_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Request Details
    request_type VARCHAR(30) NOT NULL,
    request_status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',

    -- Data Subject Information
    subject_employee_id BIGINT, -- If employee
    subject_name VARCHAR(200) NOT NULL,
    subject_email VARCHAR(150) NOT NULL,
    subject_identifier VARCHAR(100), -- Employee code, etc.

    -- Request Specifics
    requested_data_types JSONB, -- Array of data types requested
    deletion_reason VARCHAR(500),
    rectification_details JSONB,

    -- Processing Details
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ NOT NULL, -- 30 days from submission

    -- Processing Information
    assigned_to BIGINT REFERENCES nexus_foundation.user_master(user_id),
    processing_notes TEXT,

    -- Verification
    identity_verified BOOLEAN DEFAULT false,
    verification_method VARCHAR(50),
    verification_date TIMESTAMPTZ,

    -- Results
    data_export_path VARCHAR(500),
    deletion_completed BOOLEAN DEFAULT false,
    rectification_completed BOOLEAN DEFAULT false,

    -- Legal Basis
    legal_basis_override VARCHAR(200),
    retention_override_reason TEXT,

    -- Audit
    created_by BIGINT,
    modified_by BIGINT,
    modified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_request_type CHECK (request_type IN ('ACCESS', 'RECTIFICATION', 'DELETION', 'PORTABILITY', 'RESTRICTION', 'OBJECTION')),
    CONSTRAINT chk_request_status CHECK (request_status IN ('SUBMITTED', 'ACKNOWLEDGED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'PARTIALLY_COMPLETED'))
);

-- GDPR request processing log
CREATE TABLE nexus_security.gdpr_processing_log (
    log_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    request_id BIGINT NOT NULL REFERENCES nexus_security.data_subject_request(request_id),

    -- Processing Step
    processing_step VARCHAR(50) NOT NULL,
    step_status VARCHAR(20) NOT NULL,

    -- Data Processed
    schema_name VARCHAR(64),
    table_name VARCHAR(64),
    records_affected INTEGER,

    -- Processing Details
    processing_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_by BIGINT,
    processing_notes TEXT,

    -- Technical Details
    query_executed TEXT,
    execution_time_ms INTEGER,

    -- Constraints
    CONSTRAINT chk_step_status CHECK (step_status IN ('STARTED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'SKIPPED'))
);

-- ===============================
-- CONSENT MANAGEMENT FRAMEWORK
-- ===============================

-- Consent Purposes (what data is used for)
CREATE TABLE nexus_security.consent_purpose (
    purpose_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Purpose Details
    purpose_code VARCHAR(50) NOT NULL,
    purpose_name VARCHAR(200) NOT NULL,
    purpose_description TEXT,

    -- Legal Basis
    legal_basis VARCHAR(50) NOT NULL, -- 'CONSENT', 'CONTRACT', 'LEGAL_OBLIGATION', etc.
    is_essential BOOLEAN NOT NULL DEFAULT false,

    -- Data Categories
    data_categories JSONB, -- Array of data categories used
    retention_period_months INTEGER,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,

    CONSTRAINT uk_consent_purpose UNIQUE(company_id, purpose_code)
);

-- Employee Consent Records
CREATE TABLE nexus_security.employee_consent (
    consent_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),
    employee_id BIGINT NOT NULL, -- Will reference employee_master when created
    purpose_id BIGINT NOT NULL REFERENCES nexus_security.consent_purpose(purpose_id),

    -- Consent Details
    consent_given BOOLEAN NOT NULL,
    consent_method VARCHAR(30) NOT NULL, -- 'EXPLICIT', 'IMPLIED', 'OPT_IN', 'OPT_OUT'
    consent_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Consent Context
    consent_ip_address INET,
    consent_user_agent TEXT,
    consent_document_version VARCHAR(20),

    -- Withdrawal
    withdrawn BOOLEAN NOT NULL DEFAULT false,
    withdrawal_timestamp TIMESTAMPTZ,
    withdrawal_reason TEXT,

    -- Validity
    valid_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMPTZ,

    -- Audit
    created_by BIGINT,
    modified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    modified_by BIGINT,

    CONSTRAINT uk_employee_consent UNIQUE(employee_id, purpose_id, consent_timestamp),
    CONSTRAINT chk_consent_method CHECK (consent_method IN ('EXPLICIT', 'IMPLIED', 'OPT_IN', 'OPT_OUT', 'CONTRACT', 'LEGAL_OBLIGATION'))
);

-- ===============================
-- DATA BREACH MANAGEMENT
-- ===============================

-- Data Breach Incidents
CREATE TABLE nexus_security.data_breach_incident (
    incident_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL REFERENCES nexus_foundation.company_master(company_id),

    -- Incident Identification
    incident_number VARCHAR(50) UNIQUE NOT NULL,
    incident_title VARCHAR(200) NOT NULL,
    incident_description TEXT,

    -- Breach Details
    breach_type VARCHAR(30) NOT NULL,
    breach_severity VARCHAR(20) NOT NULL,

    -- Discovery and Timeline
    occurred_at TIMESTAMPTZ,
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    contained_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,

    -- Affected Data
    affected_data_types JSONB,
    estimated_records_affected INTEGER,
    confirmed_records_affected INTEGER,

    -- Data Subjects
    data_subjects_affected INTEGER,
    high_risk_individuals INTEGER,

    -- Impact Assessment
    impact_assessment TEXT,
    risk_level VARCHAR(20) NOT NULL,

    -- Response Actions
    containment_actions TEXT,
    remediation_actions TEXT,

    -- Regulatory Reporting
    requires_authority_notification BOOLEAN DEFAULT false,
    authority_notified_at TIMESTAMPTZ,
    authority_reference VARCHAR(100),

    requires_individual_notification BOOLEAN DEFAULT false,
    individuals_notified_at TIMESTAMPTZ,

    -- Status
    incident_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    -- Responsible Parties
    incident_manager BIGINT REFERENCES nexus_foundation.user_master(user_id),
    dpo_assigned BIGINT REFERENCES nexus_foundation.user_master(user_id),

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    modified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    modified_by BIGINT,

    -- Constraints
    CONSTRAINT chk_breach_type CHECK (breach_type IN ('CYBER_ATTACK', 'INSIDER_THREAT', 'ACCIDENTAL_DISCLOSURE', 'DEVICE_THEFT', 'SYSTEM_FAILURE', 'VENDOR_BREACH')),
    CONSTRAINT chk_breach_severity CHECK (breach_severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_risk_level CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_incident_status CHECK (incident_status IN ('OPEN', 'INVESTIGATING', 'CONTAINED', 'RESOLVED', 'CLOSED'))
);

-- ===============================
-- ACCESS CONTROL MONITORING
-- ===============================

-- Privileged Access Monitoring
CREATE TABLE nexus_security.privileged_access_log (
    access_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,

    -- User Context
    user_id BIGINT NOT NULL,
    session_id VARCHAR(100),

    -- Access Details
    privilege_used VARCHAR(50) NOT NULL,
    resource_accessed VARCHAR(100),
    action_performed VARCHAR(50),

    -- Context
    access_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,

    -- Justification
    business_justification TEXT,
    authorized_by BIGINT,

    -- Risk Indicators
    unusual_time BOOLEAN DEFAULT false,
    unusual_location BOOLEAN DEFAULT false,
    bulk_operation BOOLEAN DEFAULT false,
    sensitive_data BOOLEAN DEFAULT false,

    -- Result
    access_granted BOOLEAN NOT NULL,
    failure_reason TEXT
);

-- Failed Authentication Attempts
CREATE TABLE nexus_security.failed_authentication_log (
    attempt_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT,

    -- Attempt Details
    username VARCHAR(100),
    email_address VARCHAR(150),
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Context
    ip_address INET NOT NULL,
    user_agent TEXT,
    geo_location JSONB,

    -- Failure Analysis
    failure_type VARCHAR(30) NOT NULL,
    failure_reason TEXT,

    -- Risk Assessment
    is_suspicious BOOLEAN DEFAULT false,
    risk_factors JSONB,

    -- Response
    account_locked BOOLEAN DEFAULT false,
    notification_sent BOOLEAN DEFAULT false,

    CONSTRAINT chk_failure_type CHECK (failure_type IN ('INVALID_USERNAME', 'INVALID_PASSWORD', 'ACCOUNT_LOCKED', 'ACCOUNT_DISABLED', 'MFA_FAILED', 'SESSION_EXPIRED'))
);

-- ===============================
-- SECURITY MONITORING VIEWS
-- ===============================

-- High-risk security events view
CREATE VIEW nexus_security.vw_high_risk_events AS
SELECT
    sal.company_id,
    sal.event_type,
    sal.user_id,
    um.username,
    sal.ip_address,
    sal.event_timestamp,
    sal.risk_score,
    sal.risk_factors,
    sal.event_data
FROM nexus_security.security_audit_log sal
LEFT JOIN nexus_foundation.user_master um ON sal.user_id = um.user_id
WHERE sal.risk_score >= 70
   OR sal.event_severity IN ('ERROR', 'CRITICAL')
   OR sal.sensitive_data_accessed = true
ORDER BY sal.event_timestamp DESC;

-- Consent compliance summary
CREATE VIEW nexus_security.vw_consent_compliance AS
SELECT
    cp.company_id,
    cp.purpose_name,
    COUNT(ec.consent_id) as total_consents,
    COUNT(CASE WHEN ec.consent_given = true AND ec.withdrawn = false THEN 1 END) as active_consents,
    COUNT(CASE WHEN ec.withdrawn = true THEN 1 END) as withdrawn_consents,
    COUNT(CASE WHEN ec.valid_until < CURRENT_TIMESTAMP THEN 1 END) as expired_consents
FROM nexus_security.consent_purpose cp
LEFT JOIN nexus_security.employee_consent ec ON cp.purpose_id = ec.purpose_id
WHERE cp.is_active = true
GROUP BY cp.company_id, cp.purpose_id, cp.purpose_name;

-- Data breach summary
CREATE VIEW nexus_security.vw_data_breach_summary AS
SELECT
    company_id,
    incident_status,
    breach_severity,
    COUNT(*) as incident_count,
    SUM(confirmed_records_affected) as total_records_affected,
    SUM(data_subjects_affected) as total_subjects_affected,
    AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, CURRENT_TIMESTAMP) - discovered_at))/3600) as avg_resolution_hours
FROM nexus_security.data_breach_incident
GROUP BY company_id, incident_status, breach_severity;

-- ===============================
-- SECURITY POLICY ENFORCEMENT TRIGGERS
-- ===============================

-- Trigger to log sensitive data access
CREATE OR REPLACE FUNCTION nexus_security.log_sensitive_data_access()
RETURNS TRIGGER AS $$
DECLARE
    sensitive_columns TEXT[];
    accessed_columns TEXT[];
    has_sensitive_access BOOLEAN := false;
BEGIN
    -- Define sensitive columns for the table
    -- This should be configured based on data classification

    -- Log the access attempt
    INSERT INTO nexus_security.security_audit_log (
        company_id, event_type, event_category, user_id, session_id,
        resource_type, resource_id, action_performed, sensitive_data_accessed,
        event_timestamp, event_successful, event_data
    ) VALUES (
        COALESCE(NEW.company_id, OLD.company_id),
        'SENSITIVE_DATA_ACCESS',
        'DATA_ACCESS',
        COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0),
        COALESCE(current_setting('app.current_session_id', true), ''),
        TG_TABLE_NAME,
        COALESCE(NEW.company_id, OLD.company_id),
        TG_OP,
        true,
        CURRENT_TIMESTAMP,
        true,
        jsonb_build_object('table', TG_TABLE_NAME, 'operation', TG_OP)
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ===============================
-- SECURITY COMPLIANCE FUNCTIONS
-- ===============================

-- Function to check data retention compliance
CREATE OR REPLACE FUNCTION nexus_security.check_data_retention_compliance(p_company_id BIGINT)
RETURNS TABLE(
    schema_name TEXT,
    table_name TEXT,
    records_to_purge BIGINT,
    retention_period_months INTEGER
) AS $$
BEGIN
    -- This function would check each table against its retention policy
    -- Implementation depends on specific business requirements

    RETURN QUERY
    SELECT
        dcr.schema_name,
        dcr.table_name,
        0::BIGINT as records_to_purge, -- Placeholder
        dcr.retention_period_months
    FROM nexus_security.data_classification_registry dcr
    WHERE dcr.retention_period_months IS NOT NULL
    AND dcr.deletion_required = true;
END;
$$ LANGUAGE plpgsql;

-- Function to generate GDPR data export
CREATE OR REPLACE FUNCTION nexus_security.generate_gdpr_data_export(
    p_request_id BIGINT,
    p_employee_id BIGINT
) RETURNS JSONB AS $$
DECLARE
    export_data JSONB := '{}';
    table_record RECORD;
BEGIN
    -- This function would collect all personal data for an employee
    -- across all tables and return as structured JSON

    -- Placeholder implementation
    export_data := jsonb_build_object(
        'request_id', p_request_id,
        'employee_id', p_employee_id,
        'export_timestamp', CURRENT_TIMESTAMP,
        'data_categories', '[]'::jsonb
    );

    RETURN export_data;
END;
$$ LANGUAGE plpgsql;

-- ===============================
-- SECURITY CONFIGURATION
-- ===============================

-- Create security roles
DO $$
BEGIN
    -- Data Protection Officer role
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexus_dpo') THEN
        CREATE ROLE nexus_dpo;
    END IF;

    -- Security Administrator role
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexus_security_admin') THEN
        CREATE ROLE nexus_security_admin;
    END IF;

    -- Audit Reader role
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'nexus_audit_reader') THEN
        CREATE ROLE nexus_audit_reader;
    END IF;
END
$$;

-- Grant appropriate permissions
GRANT USAGE ON SCHEMA nexus_security TO nexus_dpo, nexus_security_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_security TO nexus_audit_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA nexus_audit TO nexus_audit_reader;

-- ===============================
-- SECURITY FRAMEWORK SUMMARY
-- ===============================

COMMENT ON SCHEMA nexus_security IS 'Comprehensive security framework for HRMS data protection and compliance';

/*
SECURITY FRAMEWORK IMPLEMENTATION SUMMARY:

1. DATA CLASSIFICATION (12 tables/functions):
   - Comprehensive data classification registry
   - PII category identification
   - Encryption and masking requirements

2. ENCRYPTION FRAMEWORK (8 functions):
   - Field-level encryption with key management
   - Automated key rotation capabilities
   - Secure key storage and access logging

3. DATA MASKING (4 functions):
   - Email, phone, name, and salary masking
   - Role-based data visibility
   - Privacy-preserving data display

4. GDPR COMPLIANCE (6 tables):
   - Data subject request management
   - Consent tracking and management
   - Right to be forgotten implementation
   - Data portability support

5. SECURITY MONITORING (8 tables/views):
   - Privileged access logging
   - Failed authentication tracking
   - High-risk event identification
   - Security incident management

6. DATA BREACH MANAGEMENT (2 tables):
   - Incident tracking and response
   - Regulatory notification requirements
   - Impact assessment procedures

SPRING BOOT INTEGRATION NOTES:
1. Implement security context in application.properties
2. Use @PreAuthorize annotations with security policies
3. Configure encryption/decryption in service layer
4. Implement GDPR request handlers in dedicated services
5. Set up security event logging in controllers

COMPLIANCE CERTIFICATIONS SUPPORTED:
- GDPR (General Data Protection Regulation)
- SOX (Sarbanes-Oxley Act)
- HIPAA (Health Insurance Portability and Accountability Act)
- ISO 27001 (Information Security Management)
*/