--
-- PostgreSQL database dump
--

\restrict yKu0GTW7teMdceOdBkqFRgWUgwoNcmHFYVa53IngeNrbcmZzTePeTjJAL2tX0Pr

-- Dumped from database version 15.14 (Homebrew)
-- Dumped by pg_dump version 15.14 (Homebrew)

-- Started on 2025-09-15 08:06:18 EDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS nexus_hrms;
--
-- TOC entry 4351 (class 1262 OID 20586)
-- Name: nexus_hrms; Type: DATABASE; Schema: -; Owner: rameshbabu
--

CREATE DATABASE nexus_hrms WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE nexus_hrms OWNER TO rameshbabu;

\unrestrict yKu0GTW7teMdceOdBkqFRgWUgwoNcmHFYVa53IngeNrbcmZzTePeTjJAL2tX0Pr
\connect nexus_hrms
\restrict yKu0GTW7teMdceOdBkqFRgWUgwoNcmHFYVa53IngeNrbcmZzTePeTjJAL2tX0Pr

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 11 (class 2615 OID 21173)
-- Name: nexus_audit; Type: SCHEMA; Schema: -; Owner: rameshbabu
--

CREATE SCHEMA nexus_audit;


ALTER SCHEMA nexus_audit OWNER TO rameshbabu;

--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA nexus_audit; Type: COMMENT; Schema: -; Owner: rameshbabu
--

COMMENT ON SCHEMA nexus_audit IS 'Audit trails, security logs, and compliance tracking';


--
-- TOC entry 12 (class 2615 OID 21174)
-- Name: nexus_config; Type: SCHEMA; Schema: -; Owner: rameshbabu
--

CREATE SCHEMA nexus_config;


ALTER SCHEMA nexus_config OWNER TO rameshbabu;

--
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA nexus_config; Type: COMMENT; Schema: -; Owner: rameshbabu
--

COMMENT ON SCHEMA nexus_config IS 'System configuration, parameters, and lookup data';


--
-- TOC entry 10 (class 2615 OID 21172)
-- Name: nexus_foundation; Type: SCHEMA; Schema: -; Owner: rameshbabu
--

CREATE SCHEMA nexus_foundation;


ALTER SCHEMA nexus_foundation OWNER TO rameshbabu;

--
-- TOC entry 4354 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA nexus_foundation; Type: COMMENT; Schema: -; Owner: rameshbabu
--

COMMENT ON SCHEMA nexus_foundation IS 'Core foundation schema for NEXUS HRMS - optimized for GraphQL and Spring Boot';


--
-- TOC entry 4 (class 3079 OID 20699)
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- TOC entry 4355 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- TOC entry 2 (class 3079 OID 20587)
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- TOC entry 4356 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- TOC entry 3 (class 3079 OID 20618)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 5 (class 3079 OID 21135)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 411 (class 1255 OID 21496)
-- Name: audit_trigger_function(); Type: FUNCTION; Schema: nexus_audit; Owner: rameshbabu
--

CREATE FUNCTION nexus_audit.audit_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_context RECORD;
    old_values JSONB;
    new_values JSONB;
    changed_fields JSONB;
BEGIN
    -- Get current user context
    SELECT * INTO user_context FROM nexus_foundation.get_current_user_context();

    -- Prepare audit data based on operation
    IF TG_OP = 'DELETE' THEN
        old_values := to_jsonb(OLD);
        new_values := NULL;
        changed_fields := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        old_values := to_jsonb(OLD);
        new_values := to_jsonb(NEW);
        -- Calculate changed fields
        SELECT jsonb_agg(key) INTO changed_fields
        FROM jsonb_each(old_values) o
        WHERE o.value IS DISTINCT FROM (new_values->o.key);
    ELSIF TG_OP = 'INSERT' THEN
        old_values := NULL;
        new_values := to_jsonb(NEW);
        changed_fields := NULL;
    END IF;

    -- Insert audit record
    INSERT INTO nexus_audit.audit_log (
        company_id, schema_name, table_name, operation_type, record_id,
        old_values, new_values, changed_fields,
        user_id, session_id, operation_timestamp
    ) VALUES (
        COALESCE(user_context.company_id,
                 CASE WHEN TG_OP = 'DELETE' THEN (OLD.company_id)::BIGINT
                      ELSE (NEW.company_id)::BIGINT END),
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN (OLD.company_id)::BIGINT
             ELSE (NEW.company_id)::BIGINT END,
        old_values,
        new_values,
        changed_fields,
        user_context.user_id,
        user_context.session_id,
        CURRENT_TIMESTAMP
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION nexus_audit.audit_trigger_function() OWNER TO rameshbabu;

--
-- TOC entry 412 (class 1255 OID 21574)
-- Name: get_current_user_context(); Type: FUNCTION; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE FUNCTION nexus_foundation.get_current_user_context() RETURNS TABLE(user_id bigint, company_id bigint, session_id text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY SELECT
        COALESCE(current_setting('app.current_user_id', true)::BIGINT, 0),
        COALESCE(current_setting('app.current_company_id', true)::BIGINT, 0),
        COALESCE(current_setting('app.current_session_id', true), '');
END;
$$;


ALTER FUNCTION nexus_foundation.get_current_user_context() OWNER TO rameshbabu;

--
-- TOC entry 410 (class 1255 OID 21494)
-- Name: update_hierarchy_path(); Type: FUNCTION; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE FUNCTION nexus_foundation.update_hierarchy_path() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent_path VARCHAR(1000);
BEGIN
    IF NEW.parent_location_id IS NULL THEN
        NEW.location_path := NEW.location_id::VARCHAR;
        NEW.location_level := 1;
    ELSE
        SELECT location_path, location_level + 1
        INTO parent_path, NEW.location_level
        FROM nexus_foundation.location_master
        WHERE location_id = NEW.parent_location_id;

        NEW.location_path := parent_path || '.' || NEW.location_id::VARCHAR;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION nexus_foundation.update_hierarchy_path() OWNER TO rameshbabu;

--
-- TOC entry 223 (class 1259 OID 21175)
-- Name: global_id_seq; Type: SEQUENCE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE SEQUENCE nexus_foundation.global_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 100;


ALTER TABLE nexus_foundation.global_id_seq OWNER TO rameshbabu;

SET default_tablespace = '';

--
-- TOC entry 238 (class 1259 OID 21506)
-- Name: audit_log; Type: TABLE; Schema: nexus_audit; Owner: rameshbabu
--

CREATE TABLE nexus_audit.audit_log (
    audit_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    schema_name character varying(64) NOT NULL,
    table_name character varying(64) NOT NULL,
    operation_type character varying(10) NOT NULL,
    record_id bigint,
    old_values jsonb,
    new_values jsonb,
    changed_fields jsonb,
    user_id bigint,
    session_id character varying(100),
    ip_address inet,
    user_agent text,
    operation_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_context jsonb,
    CONSTRAINT chk_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'SELECT'::character varying])::text[])))
)
PARTITION BY RANGE (operation_timestamp);


ALTER TABLE nexus_audit.audit_log OWNER TO rameshbabu;

SET default_table_access_method = heap;

--
-- TOC entry 239 (class 1259 OID 21575)
-- Name: audit_log_2025_09; Type: TABLE; Schema: nexus_audit; Owner: rameshbabu
--

CREATE TABLE nexus_audit.audit_log_2025_09 (
    audit_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    schema_name character varying(64) NOT NULL,
    table_name character varying(64) NOT NULL,
    operation_type character varying(10) NOT NULL,
    record_id bigint,
    old_values jsonb,
    new_values jsonb,
    changed_fields jsonb,
    user_id bigint,
    session_id character varying(100),
    ip_address inet,
    user_agent text,
    operation_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_context jsonb,
    CONSTRAINT chk_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'SELECT'::character varying])::text[])))
);


ALTER TABLE nexus_audit.audit_log_2025_09 OWNER TO rameshbabu;

--
-- TOC entry 240 (class 1259 OID 21585)
-- Name: audit_log_2025_10; Type: TABLE; Schema: nexus_audit; Owner: rameshbabu
--

CREATE TABLE nexus_audit.audit_log_2025_10 (
    audit_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    schema_name character varying(64) NOT NULL,
    table_name character varying(64) NOT NULL,
    operation_type character varying(10) NOT NULL,
    record_id bigint,
    old_values jsonb,
    new_values jsonb,
    changed_fields jsonb,
    user_id bigint,
    session_id character varying(100),
    ip_address inet,
    user_agent text,
    operation_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_context jsonb,
    CONSTRAINT chk_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'SELECT'::character varying])::text[])))
);


ALTER TABLE nexus_audit.audit_log_2025_10 OWNER TO rameshbabu;

--
-- TOC entry 241 (class 1259 OID 21595)
-- Name: audit_log_2025_11; Type: TABLE; Schema: nexus_audit; Owner: rameshbabu
--

CREATE TABLE nexus_audit.audit_log_2025_11 (
    audit_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    schema_name character varying(64) NOT NULL,
    table_name character varying(64) NOT NULL,
    operation_type character varying(10) NOT NULL,
    record_id bigint,
    old_values jsonb,
    new_values jsonb,
    changed_fields jsonb,
    user_id bigint,
    session_id character varying(100),
    ip_address inet,
    user_agent text,
    operation_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    business_context jsonb,
    CONSTRAINT chk_operation_type CHECK (((operation_type)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'SELECT'::character varying])::text[])))
);


ALTER TABLE nexus_audit.audit_log_2025_11 OWNER TO rameshbabu;

--
-- TOC entry 235 (class 1259 OID 21452)
-- Name: system_parameter; Type: TABLE; Schema: nexus_config; Owner: rameshbabu
--

CREATE TABLE nexus_config.system_parameter (
    parameter_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint,
    parameter_category character varying(50) NOT NULL,
    parameter_key character varying(100) NOT NULL,
    parameter_value text,
    parameter_data_type character varying(20) DEFAULT 'STRING'::character varying NOT NULL,
    parameter_description text,
    is_encrypted boolean DEFAULT false NOT NULL,
    is_system_parameter boolean DEFAULT false NOT NULL,
    is_user_configurable boolean DEFAULT true NOT NULL,
    validation_regex character varying(500),
    min_value numeric(15,2),
    max_value numeric(15,2),
    allowed_values jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_parameter_data_type CHECK (((parameter_data_type)::text = ANY ((ARRAY['STRING'::character varying, 'INTEGER'::character varying, 'DECIMAL'::character varying, 'BOOLEAN'::character varying, 'DATE'::character varying, 'JSON'::character varying])::text[])))
);


ALTER TABLE nexus_config.system_parameter OWNER TO rameshbabu;

--
-- TOC entry 229 (class 1259 OID 21214)
-- Name: city_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.city_master (
    city_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    state_id bigint NOT NULL,
    city_name character varying(100) NOT NULL,
    postal_code character varying(20),
    latitude numeric(10,8),
    longitude numeric(11,8),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_latitude_range CHECK (((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric))),
    CONSTRAINT chk_longitude_range CHECK (((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))
);


ALTER TABLE nexus_foundation.city_master OWNER TO rameshbabu;

--
-- TOC entry 224 (class 1259 OID 21176)
-- Name: company_id_seq; Type: SEQUENCE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE SEQUENCE nexus_foundation.company_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 10;


ALTER TABLE nexus_foundation.company_id_seq OWNER TO rameshbabu;

--
-- TOC entry 230 (class 1259 OID 21233)
-- Name: company_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.company_master (
    company_id bigint DEFAULT nextval('nexus_foundation.company_id_seq'::regclass) NOT NULL,
    company_code character varying(20) NOT NULL,
    company_name character varying(200) NOT NULL,
    company_short_name character varying(50) NOT NULL,
    company_type character varying(20) DEFAULT 'PRIVATE_LIMITED'::character varying NOT NULL,
    legal_name character varying(300),
    registration_number character varying(50),
    tax_identification_number character varying(50),
    pan_number character varying(20),
    gst_number character varying(50),
    cin_number character varying(50),
    registered_address text NOT NULL,
    registered_city_id bigint,
    registered_postal_code character varying(20),
    registered_country_id bigint NOT NULL,
    communication_address text,
    communication_city_id bigint,
    communication_postal_code character varying(20),
    communication_country_id bigint,
    primary_phone character varying(20),
    secondary_phone character varying(20),
    primary_email character varying(150) NOT NULL,
    secondary_email character varying(150),
    website_url character varying(200),
    industry_type character varying(100),
    business_description text,
    employee_strength_range character varying(20),
    annual_turnover_range character varying(20),
    financial_year_start_month integer DEFAULT 4 NOT NULL,
    financial_year_end_month integer DEFAULT 3 NOT NULL,
    default_currency_code character(3) DEFAULT 'INR'::bpchar NOT NULL,
    default_timezone character varying(50) DEFAULT 'Asia/Kolkata'::character varying NOT NULL,
    default_language character varying(10) DEFAULT 'en'::character varying NOT NULL,
    date_format character varying(20) DEFAULT 'DD-MM-YYYY'::character varying NOT NULL,
    time_format character varying(10) DEFAULT '24_HOUR'::character varying NOT NULL,
    max_employees_allowed integer DEFAULT 1000,
    is_multi_location boolean DEFAULT false NOT NULL,
    is_multi_currency boolean DEFAULT false NOT NULL,
    subscription_plan character varying(50) DEFAULT 'STANDARD'::character varying NOT NULL,
    license_type character varying(20) DEFAULT 'PERPETUAL'::character varying NOT NULL,
    subscription_start_date date,
    subscription_end_date date,
    max_concurrent_users integer DEFAULT 50,
    company_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    is_trial boolean DEFAULT false NOT NULL,
    trial_end_date date,
    is_demo boolean DEFAULT false NOT NULL,
    company_logo_path character varying(500),
    brand_color_primary character varying(7),
    brand_color_secondary character varying(7),
    enable_biometric_integration boolean DEFAULT false NOT NULL,
    enable_mobile_app boolean DEFAULT true NOT NULL,
    enable_self_service boolean DEFAULT true NOT NULL,
    enable_workflow_approvals boolean DEFAULT true NOT NULL,
    data_retention_policy_months integer DEFAULT 84,
    enable_audit_logging boolean DEFAULT true NOT NULL,
    enable_data_encryption boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_company_status CHECK (((company_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'SUSPENDED'::character varying, 'TERMINATED'::character varying])::text[]))),
    CONSTRAINT chk_company_type CHECK (((company_type)::text = ANY ((ARRAY['PRIVATE_LIMITED'::character varying, 'PUBLIC_LIMITED'::character varying, 'PARTNERSHIP'::character varying, 'PROPRIETORSHIP'::character varying, 'LLP'::character varying, 'NGO'::character varying, 'GOVERNMENT'::character varying])::text[]))),
    CONSTRAINT chk_financial_year_months CHECK ((((financial_year_start_month >= 1) AND (financial_year_start_month <= 12)) AND ((financial_year_end_month >= 1) AND (financial_year_end_month <= 12)) AND (financial_year_start_month <> financial_year_end_month))),
    CONSTRAINT chk_max_employees CHECK ((max_employees_allowed > 0)),
    CONSTRAINT chk_max_users CHECK ((max_concurrent_users > 0)),
    CONSTRAINT chk_subscription_plan CHECK (((subscription_plan)::text = ANY ((ARRAY['BASIC'::character varying, 'STANDARD'::character varying, 'PREMIUM'::character varying, 'ENTERPRISE'::character varying])::text[])))
)
WITH (fillfactor='90');
ALTER TABLE ONLY nexus_foundation.company_master ALTER COLUMN company_status SET STATISTICS 1000;


ALTER TABLE nexus_foundation.company_master OWNER TO rameshbabu;

--
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE company_master; Type: COMMENT; Schema: nexus_foundation; Owner: rameshbabu
--

COMMENT ON TABLE nexus_foundation.company_master IS 'Multi-tenant company master table with comprehensive business configuration';


--
-- TOC entry 227 (class 1259 OID 21179)
-- Name: country_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.country_master (
    country_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    country_code character(2) NOT NULL,
    country_code_3 character(3) NOT NULL,
    country_name character varying(100) NOT NULL,
    dial_code character varying(10),
    currency_code character(3),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_country_code_3_format CHECK ((country_code_3 ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT chk_country_code_format CHECK ((country_code ~ '^[A-Z]{2}$'::text))
);


ALTER TABLE nexus_foundation.country_master OWNER TO rameshbabu;

--
-- TOC entry 225 (class 1259 OID 21177)
-- Name: location_id_seq; Type: SEQUENCE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE SEQUENCE nexus_foundation.location_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 50;


ALTER TABLE nexus_foundation.location_id_seq OWNER TO rameshbabu;

--
-- TOC entry 231 (class 1259 OID 21300)
-- Name: location_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.location_master (
    location_id bigint DEFAULT nextval('nexus_foundation.location_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    location_code character varying(20) NOT NULL,
    location_name character varying(150) NOT NULL,
    location_type character varying(20) DEFAULT 'OFFICE'::character varying NOT NULL,
    parent_location_id bigint,
    location_level integer DEFAULT 1 NOT NULL,
    location_path character varying(500),
    address_line_1 character varying(200) NOT NULL,
    address_line_2 character varying(200),
    city_id bigint,
    postal_code character varying(20),
    country_id bigint NOT NULL,
    latitude numeric(10,8),
    longitude numeric(11,8),
    primary_phone character varying(20),
    secondary_phone character varying(20),
    email_address character varying(150),
    is_head_office boolean DEFAULT false NOT NULL,
    is_production_unit boolean DEFAULT false NOT NULL,
    seating_capacity integer,
    parking_available boolean DEFAULT false NOT NULL,
    default_working_hours jsonb,
    timezone character varying(50),
    facilities jsonb,
    location_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    operational_from_date date,
    operational_to_date date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_location_level CHECK (((location_level > 0) AND (location_level <= 10))),
    CONSTRAINT chk_location_status CHECK (((location_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'TEMPORARILY_CLOSED'::character varying, 'PERMANENTLY_CLOSED'::character varying])::text[]))),
    CONSTRAINT chk_location_type CHECK (((location_type)::text = ANY ((ARRAY['HEAD_OFFICE'::character varying, 'BRANCH_OFFICE'::character varying, 'WAREHOUSE'::character varying, 'FACTORY'::character varying, 'RETAIL_STORE'::character varying, 'SERVICE_CENTER'::character varying, 'REMOTE'::character varying])::text[]))),
    CONSTRAINT chk_seating_capacity CHECK (((seating_capacity IS NULL) OR (seating_capacity > 0)))
);
ALTER TABLE ONLY nexus_foundation.location_master ALTER COLUMN location_status SET STATISTICS 1000;


ALTER TABLE nexus_foundation.location_master OWNER TO rameshbabu;

--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE location_master; Type: COMMENT; Schema: nexus_foundation; Owner: rameshbabu
--

COMMENT ON TABLE nexus_foundation.location_master IS 'Hierarchical location management with geographic data';


--
-- TOC entry 233 (class 1259 OID 21384)
-- Name: role_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.role_master (
    role_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    role_code character varying(50) NOT NULL,
    role_name character varying(150) NOT NULL,
    role_description text,
    parent_role_id bigint,
    role_level integer DEFAULT 1 NOT NULL,
    role_path character varying(1000),
    is_system_role boolean DEFAULT false NOT NULL,
    is_assignable boolean DEFAULT true NOT NULL,
    max_assignees integer,
    module_permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    role_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    effective_from_date date DEFAULT CURRENT_DATE NOT NULL,
    effective_to_date date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_max_assignees CHECK (((max_assignees IS NULL) OR (max_assignees > 0))),
    CONSTRAINT chk_role_level CHECK (((role_level > 0) AND (role_level <= 10))),
    CONSTRAINT chk_role_status CHECK (((role_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'DEPRECATED'::character varying])::text[])))
);


ALTER TABLE nexus_foundation.role_master OWNER TO rameshbabu;

--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE role_master; Type: COMMENT; Schema: nexus_foundation; Owner: rameshbabu
--

COMMENT ON TABLE nexus_foundation.role_master IS 'Hierarchical role-based access control system';


--
-- TOC entry 228 (class 1259 OID 21196)
-- Name: state_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.state_master (
    state_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    country_id bigint NOT NULL,
    state_code character varying(10) NOT NULL,
    state_name character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint
);


ALTER TABLE nexus_foundation.state_master OWNER TO rameshbabu;

--
-- TOC entry 226 (class 1259 OID 21178)
-- Name: user_id_seq; Type: SEQUENCE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE SEQUENCE nexus_foundation.user_id_seq
    START WITH 10000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 100;


ALTER TABLE nexus_foundation.user_id_seq OWNER TO rameshbabu;

--
-- TOC entry 232 (class 1259 OID 21346)
-- Name: user_master; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.user_master (
    user_id bigint DEFAULT nextval('nexus_foundation.user_id_seq'::regclass) NOT NULL,
    company_id bigint NOT NULL,
    username character varying(50) NOT NULL,
    email_address character varying(150) NOT NULL,
    password_hash character varying(255),
    external_auth_provider character varying(50),
    external_user_id character varying(100),
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    last_name character varying(100) NOT NULL,
    display_name character varying(200),
    profile_image_path character varying(500),
    preferred_language character varying(10) DEFAULT 'en'::character varying NOT NULL,
    preferred_timezone character varying(50),
    preferred_date_format character varying(20),
    preferred_theme character varying(20) DEFAULT 'LIGHT'::character varying,
    user_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    is_system_user boolean DEFAULT false NOT NULL,
    is_service_account boolean DEFAULT false NOT NULL,
    force_password_change boolean DEFAULT false NOT NULL,
    password_last_changed_at timestamp with time zone,
    last_login_at timestamp with time zone,
    last_login_ip inet,
    failed_login_attempts integer DEFAULT 0 NOT NULL,
    account_locked_until timestamp with time zone,
    mfa_enabled boolean DEFAULT false NOT NULL,
    mfa_secret character varying(100),
    backup_codes jsonb,
    concurrent_session_limit integer DEFAULT 3,
    session_timeout_minutes integer DEFAULT 480,
    employee_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_failed_attempts CHECK (((failed_login_attempts >= 0) AND (failed_login_attempts <= 10))),
    CONSTRAINT chk_session_limit CHECK (((concurrent_session_limit > 0) AND (concurrent_session_limit <= 10))),
    CONSTRAINT chk_session_timeout CHECK (((session_timeout_minutes > 0) AND (session_timeout_minutes <= 1440))),
    CONSTRAINT chk_user_status CHECK (((user_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'LOCKED'::character varying, 'SUSPENDED'::character varying, 'PENDING_ACTIVATION'::character varying])::text[])))
)
WITH (fillfactor='85');
ALTER TABLE ONLY nexus_foundation.user_master ALTER COLUMN user_status SET STATISTICS 1000;


ALTER TABLE nexus_foundation.user_master OWNER TO rameshbabu;

--
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE user_master; Type: COMMENT; Schema: nexus_foundation; Owner: rameshbabu
--

COMMENT ON TABLE nexus_foundation.user_master IS 'User authentication and profile management with security features';


--
-- TOC entry 234 (class 1259 OID 21418)
-- Name: user_role_assignment; Type: TABLE; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TABLE nexus_foundation.user_role_assignment (
    assignment_id bigint DEFAULT nextval('nexus_foundation.global_id_seq'::regclass) NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    assigned_by bigint,
    assignment_reason text,
    effective_from_date date DEFAULT CURRENT_DATE NOT NULL,
    effective_to_date date,
    assignment_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    modified_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by bigint,
    CONSTRAINT chk_assignment_dates CHECK (((effective_to_date IS NULL) OR (effective_to_date > effective_from_date))),
    CONSTRAINT chk_assignment_status CHECK (((assignment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'REVOKED'::character varying])::text[])))
);


ALTER TABLE nexus_foundation.user_role_assignment OWNER TO rameshbabu;

--
-- TOC entry 236 (class 1259 OID 21483)
-- Name: vw_company_statistics; Type: VIEW; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE VIEW nexus_foundation.vw_company_statistics AS
 SELECT cm.company_id,
    cm.company_name,
    cm.company_status,
    cm.subscription_plan,
    cm.max_employees_allowed,
    ( SELECT count(*) AS count
           FROM nexus_foundation.location_master lm
          WHERE ((lm.company_id = cm.company_id) AND ((lm.location_status)::text = 'ACTIVE'::text))) AS active_locations,
    ( SELECT count(*) AS count
           FROM nexus_foundation.user_master um
          WHERE ((um.company_id = cm.company_id) AND ((um.user_status)::text = 'ACTIVE'::text))) AS active_users,
    cm.created_at AS company_created_at,
    cm.subscription_end_date,
        CASE
            WHEN (cm.subscription_end_date IS NULL) THEN true
            WHEN (cm.subscription_end_date > CURRENT_DATE) THEN true
            ELSE false
        END AS is_subscription_active,
        CASE
            WHEN (cm.subscription_end_date IS NOT NULL) THEN (cm.subscription_end_date - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_until_expiry
   FROM nexus_foundation.company_master cm
  WHERE ((cm.company_status)::text = 'ACTIVE'::text);


ALTER TABLE nexus_foundation.vw_company_statistics OWNER TO rameshbabu;

--
-- TOC entry 237 (class 1259 OID 21488)
-- Name: vw_user_authentication; Type: VIEW; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE VIEW nexus_foundation.vw_user_authentication AS
 SELECT um.user_id,
    um.company_id,
    um.username,
    um.email_address,
    um.password_hash,
    um.user_status,
    um.failed_login_attempts,
    um.account_locked_until,
    um.mfa_enabled,
    cm.company_code,
    cm.company_name,
    cm.company_status,
        CASE
            WHEN ((um.account_locked_until IS NOT NULL) AND (um.account_locked_until > CURRENT_TIMESTAMP)) THEN true
            ELSE false
        END AS is_account_locked,
        CASE
            WHEN (um.password_last_changed_at IS NULL) THEN true
            WHEN (um.password_last_changed_at < (CURRENT_TIMESTAMP - '90 days'::interval)) THEN true
            ELSE false
        END AS requires_password_change
   FROM (nexus_foundation.user_master um
     JOIN nexus_foundation.company_master cm ON ((um.company_id = cm.company_id)))
  WHERE (((um.user_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'LOCKED'::character varying])::text[])) AND ((cm.company_status)::text = 'ACTIVE'::text));


ALTER TABLE nexus_foundation.vw_user_authentication OWNER TO rameshbabu;

--
-- TOC entry 3953 (class 0 OID 0)
-- Name: audit_log_2025_09; Type: TABLE ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log ATTACH PARTITION nexus_audit.audit_log_2025_09 FOR VALUES FROM ('2025-09-01 00:00:00-04') TO ('2025-10-01 00:00:00-04');


--
-- TOC entry 3954 (class 0 OID 0)
-- Name: audit_log_2025_10; Type: TABLE ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log ATTACH PARTITION nexus_audit.audit_log_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00-04') TO ('2025-11-01 00:00:00-04');


--
-- TOC entry 3955 (class 0 OID 0)
-- Name: audit_log_2025_11; Type: TABLE ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log ATTACH PARTITION nexus_audit.audit_log_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00-04') TO ('2025-12-01 00:00:00-05');


--
-- TOC entry 4343 (class 0 OID 21575)
-- Dependencies: 239
-- Data for Name: audit_log_2025_09; Type: TABLE DATA; Schema: nexus_audit; Owner: rameshbabu
--

COPY nexus_audit.audit_log_2025_09 (audit_id, company_id, schema_name, table_name, operation_type, record_id, old_values, new_values, changed_fields, user_id, session_id, ip_address, user_agent, operation_timestamp, business_context) FROM stdin;
1000200	0	nexus_foundation	company_master	INSERT	21	\N	{"is_demo": false, "is_trial": false, "cin_number": null, "company_id": 21, "created_at": "2025-09-15T00:24:18.339943-04:00", "created_by": 1, "gst_number": "29AABCS1234C1Z5", "legal_name": "SysTech Solutions Private Limited", "pan_number": "AABCS1234C", "date_format": "DD-MM-YYYY", "modified_at": "2025-09-15T00:24:18.339943-04:00", "modified_by": null, "time_format": "24_HOUR", "website_url": null, "company_code": "SYSTECH001", "company_name": "SysTech Solutions Private Limited", "company_type": "PRIVATE_LIMITED", "license_type": "PERPETUAL", "industry_type": "Information Technology", "primary_email": "info@systechsolutions.com", "primary_phone": "+91-80-12345678", "company_status": "ACTIVE", "trial_end_date": null, "secondary_email": null, "secondary_phone": null, "default_language": "en", "default_timezone": "Asia/Kolkata", "company_logo_path": null, "enable_mobile_app": true, "is_multi_currency": false, "is_multi_location": false, "subscription_plan": "STANDARD", "company_short_name": "SysTech Solutions", "registered_address": "123 Tech Park, Electronic City, Bangalore, Karnataka - 560100", "registered_city_id": null, "brand_color_primary": null, "enable_self_service": true, "registration_number": "U72900KA2020PTC138234", "business_description": null, "enable_audit_logging": true, "max_concurrent_users": 50, "annual_turnover_range": null, "brand_color_secondary": null, "communication_address": null, "communication_city_id": null, "default_currency_code": "INR", "max_employees_allowed": 1000, "registered_country_id": 1000001, "subscription_end_date": null, "enable_data_encryption": true, "registered_postal_code": null, "employee_strength_range": null, "subscription_start_date": null, "communication_country_id": null, "financial_year_end_month": 3, "communication_postal_code": null, "enable_workflow_approvals": true, "tax_identification_number": null, "financial_year_start_month": 4, "data_retention_policy_months": 84, "enable_biometric_integration": false}	\N	0		\N	\N	2025-09-15 00:24:18.339943-04	\N
1000300	0	nexus_foundation	location_master	INSERT	21	\N	{"city_id": 1000010, "latitude": null, "timezone": null, "longitude": null, "company_id": 21, "country_id": 1000001, "created_at": "2025-09-15T00:24:27.761582-04:00", "created_by": 1, "facilities": null, "location_id": 1000, "modified_at": "2025-09-15T00:24:27.761582-04:00", "modified_by": null, "postal_code": null, "email_address": null, "location_code": "HO_BLR", "location_name": "Head Office - Bangalore", "location_path": "1000", "location_type": "HEAD_OFFICE", "primary_phone": null, "address_line_1": "123 Tech Park, Electronic City", "address_line_2": null, "is_head_office": true, "location_level": 1, "location_status": "ACTIVE", "secondary_phone": null, "seating_capacity": null, "parking_available": false, "is_production_unit": false, "parent_location_id": null, "operational_to_date": null, "default_working_hours": null, "operational_from_date": null}	\N	0		\N	\N	2025-09-15 00:24:27.761582-04	\N
1000301	0	nexus_foundation	user_master	INSERT	21	\N	{"user_id": 10000, "username": "admin", "last_name": "Administrator", "company_id": 21, "created_at": "2025-09-15T00:24:27.761582-04:00", "created_by": 1, "first_name": "System", "mfa_secret": null, "employee_id": null, "mfa_enabled": false, "middle_name": null, "modified_at": "2025-09-15T00:24:27.761582-04:00", "modified_by": null, "user_status": "ACTIVE", "backup_codes": null, "display_name": "System Administrator", "email_address": "admin@systechsolutions.com", "last_login_at": null, "last_login_ip": null, "password_hash": null, "is_system_user": false, "preferred_theme": "LIGHT", "external_user_id": null, "is_service_account": false, "preferred_language": "en", "preferred_timezone": null, "profile_image_path": null, "account_locked_until": null, "failed_login_attempts": 0, "force_password_change": false, "preferred_date_format": null, "external_auth_provider": null, "session_timeout_minutes": 480, "concurrent_session_limit": 3, "password_last_changed_at": null}	\N	0		\N	\N	2025-09-15 00:24:27.761582-04	\N
\.


--
-- TOC entry 4344 (class 0 OID 21585)
-- Dependencies: 240
-- Data for Name: audit_log_2025_10; Type: TABLE DATA; Schema: nexus_audit; Owner: rameshbabu
--

COPY nexus_audit.audit_log_2025_10 (audit_id, company_id, schema_name, table_name, operation_type, record_id, old_values, new_values, changed_fields, user_id, session_id, ip_address, user_agent, operation_timestamp, business_context) FROM stdin;
\.


--
-- TOC entry 4345 (class 0 OID 21595)
-- Dependencies: 241
-- Data for Name: audit_log_2025_11; Type: TABLE DATA; Schema: nexus_audit; Owner: rameshbabu
--

COPY nexus_audit.audit_log_2025_11 (audit_id, company_id, schema_name, table_name, operation_type, record_id, old_values, new_values, changed_fields, user_id, session_id, ip_address, user_agent, operation_timestamp, business_context) FROM stdin;
\.


--
-- TOC entry 4342 (class 0 OID 21452)
-- Dependencies: 235
-- Data for Name: system_parameter; Type: TABLE DATA; Schema: nexus_config; Owner: rameshbabu
--

COPY nexus_config.system_parameter (parameter_id, company_id, parameter_category, parameter_key, parameter_value, parameter_data_type, parameter_description, is_encrypted, is_system_parameter, is_user_configurable, validation_regex, min_value, max_value, allowed_values, is_active, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- TOC entry 4336 (class 0 OID 21214)
-- Dependencies: 229
-- Data for Name: city_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.city_master (city_id, state_id, city_name, postal_code, latitude, longitude, is_active, created_at, created_by, modified_at, modified_by) FROM stdin;
1000010	1000005	Bangalore	560001	\N	\N	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000011	1000006	Mumbai	400001	\N	\N	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000012	1000007	Chennai	600001	\N	\N	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000013	1000008	New Delhi	110001	\N	\N	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000014	1000009	Kolkata	700001	\N	\N	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
\.


--
-- TOC entry 4337 (class 0 OID 21233)
-- Dependencies: 230
-- Data for Name: company_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.company_master (company_id, company_code, company_name, company_short_name, company_type, legal_name, registration_number, tax_identification_number, pan_number, gst_number, cin_number, registered_address, registered_city_id, registered_postal_code, registered_country_id, communication_address, communication_city_id, communication_postal_code, communication_country_id, primary_phone, secondary_phone, primary_email, secondary_email, website_url, industry_type, business_description, employee_strength_range, annual_turnover_range, financial_year_start_month, financial_year_end_month, default_currency_code, default_timezone, default_language, date_format, time_format, max_employees_allowed, is_multi_location, is_multi_currency, subscription_plan, license_type, subscription_start_date, subscription_end_date, max_concurrent_users, company_status, is_trial, trial_end_date, is_demo, company_logo_path, brand_color_primary, brand_color_secondary, enable_biometric_integration, enable_mobile_app, enable_self_service, enable_workflow_approvals, data_retention_policy_months, enable_audit_logging, enable_data_encryption, created_at, created_by, modified_at, modified_by) FROM stdin;
21	SYSTECH001	SysTech Solutions Private Limited	SysTech Solutions	PRIVATE_LIMITED	SysTech Solutions Private Limited	U72900KA2020PTC138234	\N	AABCS1234C	29AABCS1234C1Z5	\N	123 Tech Park, Electronic City, Bangalore, Karnataka - 560100	\N	\N	1000001	\N	\N	\N	\N	+91-80-12345678	\N	info@systechsolutions.com	\N	\N	Information Technology	\N	\N	\N	4	3	INR	Asia/Kolkata	en	DD-MM-YYYY	24_HOUR	1000	f	f	STANDARD	PERPETUAL	\N	\N	50	ACTIVE	f	\N	f	\N	\N	\N	f	t	t	t	84	t	t	2025-09-15 00:24:18.339943-04	1	2025-09-15 00:24:18.339943-04	\N
\.


--
-- TOC entry 4334 (class 0 OID 21179)
-- Dependencies: 227
-- Data for Name: country_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.country_master (country_id, country_code, country_code_3, country_name, dial_code, currency_code, is_active, created_at, created_by, modified_at, modified_by) FROM stdin;
1000000	US	USA	United States	+1	USD	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000001	IN	IND	India	+91	INR	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000002	UK	GBR	United Kingdom	+44	GBP	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000003	CA	CAN	Canada	+1	CAD	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000004	AU	AUS	Australia	+61	AUD	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
\.


--
-- TOC entry 4338 (class 0 OID 21300)
-- Dependencies: 231
-- Data for Name: location_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.location_master (location_id, company_id, location_code, location_name, location_type, parent_location_id, location_level, location_path, address_line_1, address_line_2, city_id, postal_code, country_id, latitude, longitude, primary_phone, secondary_phone, email_address, is_head_office, is_production_unit, seating_capacity, parking_available, default_working_hours, timezone, facilities, location_status, operational_from_date, operational_to_date, created_at, created_by, modified_at, modified_by) FROM stdin;
1000	21	HO_BLR	Head Office - Bangalore	HEAD_OFFICE	\N	1	1000	123 Tech Park, Electronic City	\N	1000010	\N	1000001	\N	\N	\N	\N	\N	t	f	\N	f	\N	\N	\N	ACTIVE	\N	\N	2025-09-15 00:24:27.761582-04	1	2025-09-15 00:24:27.761582-04	\N
\.


--
-- TOC entry 4340 (class 0 OID 21384)
-- Dependencies: 233
-- Data for Name: role_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.role_master (role_id, company_id, role_code, role_name, role_description, parent_role_id, role_level, role_path, is_system_role, is_assignable, max_assignees, module_permissions, role_status, effective_from_date, effective_to_date, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- TOC entry 4335 (class 0 OID 21196)
-- Dependencies: 228
-- Data for Name: state_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.state_master (state_id, country_id, state_code, state_name, is_active, created_at, created_by, modified_at, modified_by) FROM stdin;
1000005	1000001	KA	Karnataka	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000006	1000001	MH	Maharashtra	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000007	1000001	TN	Tamil Nadu	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000008	1000001	DL	Delhi	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
1000009	1000001	WB	West Bengal	t	2025-09-15 00:23:44.55678-04	1	2025-09-15 00:23:44.55678-04	\N
\.


--
-- TOC entry 4339 (class 0 OID 21346)
-- Dependencies: 232
-- Data for Name: user_master; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.user_master (user_id, company_id, username, email_address, password_hash, external_auth_provider, external_user_id, first_name, middle_name, last_name, display_name, profile_image_path, preferred_language, preferred_timezone, preferred_date_format, preferred_theme, user_status, is_system_user, is_service_account, force_password_change, password_last_changed_at, last_login_at, last_login_ip, failed_login_attempts, account_locked_until, mfa_enabled, mfa_secret, backup_codes, concurrent_session_limit, session_timeout_minutes, employee_id, created_at, created_by, modified_at, modified_by) FROM stdin;
10000	21	admin	admin@systechsolutions.com	\N	\N	\N	System	\N	Administrator	System Administrator	\N	en	\N	\N	LIGHT	ACTIVE	f	f	f	\N	\N	\N	0	\N	f	\N	\N	3	480	\N	2025-09-15 00:24:27.761582-04	1	2025-09-15 00:24:27.761582-04	\N
\.


--
-- TOC entry 4341 (class 0 OID 21418)
-- Dependencies: 234
-- Data for Name: user_role_assignment; Type: TABLE DATA; Schema: nexus_foundation; Owner: rameshbabu
--

COPY nexus_foundation.user_role_assignment (assignment_id, user_id, role_id, assigned_by, assignment_reason, effective_from_date, effective_to_date, assignment_status, created_at, created_by, modified_at, modified_by) FROM stdin;
\.


--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 224
-- Name: company_id_seq; Type: SEQUENCE SET; Schema: nexus_foundation; Owner: rameshbabu
--

SELECT pg_catalog.setval('nexus_foundation.company_id_seq', 30, true);


--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 223
-- Name: global_id_seq; Type: SEQUENCE SET; Schema: nexus_foundation; Owner: rameshbabu
--

SELECT pg_catalog.setval('nexus_foundation.global_id_seq', 1000399, true);


--
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 225
-- Name: location_id_seq; Type: SEQUENCE SET; Schema: nexus_foundation; Owner: rameshbabu
--

SELECT pg_catalog.setval('nexus_foundation.location_id_seq', 1049, true);


--
-- TOC entry 4366 (class 0 OID 0)
-- Dependencies: 226
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: nexus_foundation; Owner: rameshbabu
--

SELECT pg_catalog.setval('nexus_foundation.user_id_seq', 10099, true);


--
-- TOC entry 4143 (class 2606 OID 21513)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id, operation_timestamp);


--
-- TOC entry 4145 (class 2606 OID 21582)
-- Name: audit_log_2025_09 audit_log_2025_09_pkey; Type: CONSTRAINT; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log_2025_09
    ADD CONSTRAINT audit_log_2025_09_pkey PRIMARY KEY (audit_id, operation_timestamp);


--
-- TOC entry 4147 (class 2606 OID 21592)
-- Name: audit_log_2025_10 audit_log_2025_10_pkey; Type: CONSTRAINT; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log_2025_10
    ADD CONSTRAINT audit_log_2025_10_pkey PRIMARY KEY (audit_id, operation_timestamp);


--
-- TOC entry 4149 (class 2606 OID 21602)
-- Name: audit_log_2025_11 audit_log_2025_11_pkey; Type: CONSTRAINT; Schema: nexus_audit; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_audit.audit_log_2025_11
    ADD CONSTRAINT audit_log_2025_11_pkey PRIMARY KEY (audit_id, operation_timestamp);


--
-- TOC entry 4139 (class 2606 OID 21467)
-- Name: system_parameter system_parameter_pkey; Type: CONSTRAINT; Schema: nexus_config; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_config.system_parameter
    ADD CONSTRAINT system_parameter_pkey PRIMARY KEY (parameter_id);


--
-- TOC entry 4141 (class 2606 OID 21469)
-- Name: system_parameter uk_system_parameter; Type: CONSTRAINT; Schema: nexus_config; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_config.system_parameter
    ADD CONSTRAINT uk_system_parameter UNIQUE (company_id, parameter_category, parameter_key);


--
-- TOC entry 4090 (class 2606 OID 21224)
-- Name: city_master city_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.city_master
    ADD CONSTRAINT city_master_pkey PRIMARY KEY (city_id);


--
-- TOC entry 4095 (class 2606 OID 21274)
-- Name: company_master company_master_company_code_key; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_company_code_key UNIQUE (company_code);


--
-- TOC entry 4097 (class 2606 OID 21272)
-- Name: company_master company_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_pkey PRIMARY KEY (company_id);


--
-- TOC entry 4076 (class 2606 OID 21193)
-- Name: country_master country_master_country_code_3_key; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.country_master
    ADD CONSTRAINT country_master_country_code_3_key UNIQUE (country_code_3);


--
-- TOC entry 4078 (class 2606 OID 21191)
-- Name: country_master country_master_country_code_key; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.country_master
    ADD CONSTRAINT country_master_country_code_key UNIQUE (country_code);


--
-- TOC entry 4080 (class 2606 OID 21189)
-- Name: country_master country_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.country_master
    ADD CONSTRAINT country_master_pkey PRIMARY KEY (country_id);


--
-- TOC entry 4108 (class 2606 OID 21319)
-- Name: location_master location_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT location_master_pkey PRIMARY KEY (location_id);


--
-- TOC entry 4126 (class 2606 OID 21402)
-- Name: role_master role_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.role_master
    ADD CONSTRAINT role_master_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4086 (class 2606 OID 21204)
-- Name: state_master state_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.state_master
    ADD CONSTRAINT state_master_pkey PRIMARY KEY (state_id);


--
-- TOC entry 4110 (class 2606 OID 21321)
-- Name: location_master uk_location_company_code; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT uk_location_company_code UNIQUE (company_id, location_code);


--
-- TOC entry 4128 (class 2606 OID 21404)
-- Name: role_master uk_role_company_code; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.role_master
    ADD CONSTRAINT uk_role_company_code UNIQUE (company_id, role_code);


--
-- TOC entry 4088 (class 2606 OID 21206)
-- Name: state_master uk_state_country_code; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.state_master
    ADD CONSTRAINT uk_state_country_code UNIQUE (country_id, state_code);


--
-- TOC entry 4117 (class 2606 OID 21373)
-- Name: user_master uk_user_company_email; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_master
    ADD CONSTRAINT uk_user_company_email UNIQUE (company_id, email_address);


--
-- TOC entry 4119 (class 2606 OID 21371)
-- Name: user_master uk_user_company_username; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_master
    ADD CONSTRAINT uk_user_company_username UNIQUE (company_id, username);


--
-- TOC entry 4133 (class 2606 OID 21433)
-- Name: user_role_assignment uk_user_role_assignment; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_role_assignment
    ADD CONSTRAINT uk_user_role_assignment UNIQUE (user_id, role_id, effective_from_date);


--
-- TOC entry 4121 (class 2606 OID 21369)
-- Name: user_master user_master_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_master
    ADD CONSTRAINT user_master_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4135 (class 2606 OID 21431)
-- Name: user_role_assignment user_role_assignment_pkey; Type: CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_role_assignment
    ADD CONSTRAINT user_role_assignment_pkey PRIMARY KEY (assignment_id);


--
-- TOC entry 4136 (class 1259 OID 21476)
-- Name: idx_system_parameter_category; Type: INDEX; Schema: nexus_config; Owner: rameshbabu
--

CREATE INDEX idx_system_parameter_category ON nexus_config.system_parameter USING btree (parameter_category, is_active);


--
-- TOC entry 4137 (class 1259 OID 21475)
-- Name: idx_system_parameter_lookup; Type: INDEX; Schema: nexus_config; Owner: rameshbabu
--

CREATE INDEX idx_system_parameter_lookup ON nexus_config.system_parameter USING btree (company_id, parameter_category, parameter_key) WHERE (is_active = true);


--
-- TOC entry 4091 (class 1259 OID 21231)
-- Name: idx_city_master_name_gin; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_city_master_name_gin ON nexus_foundation.city_master USING gin (city_name public.gin_trgm_ops);


--
-- TOC entry 4092 (class 1259 OID 21232)
-- Name: idx_city_master_postal; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_city_master_postal ON nexus_foundation.city_master USING btree (postal_code) WHERE (postal_code IS NOT NULL);


--
-- TOC entry 4093 (class 1259 OID 21230)
-- Name: idx_city_master_state; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_city_master_state ON nexus_foundation.city_master USING btree (state_id) WHERE (is_active = true);


--
-- TOC entry 4098 (class 1259 OID 21299)
-- Name: idx_company_master_location; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_company_master_location ON nexus_foundation.company_master USING btree (registered_country_id, registered_city_id);


--
-- TOC entry 4099 (class 1259 OID 21297)
-- Name: idx_company_master_name_gin; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_company_master_name_gin ON nexus_foundation.company_master USING gin (((((company_name)::text || ' '::text) || (company_short_name)::text)) public.gin_trgm_ops);


--
-- TOC entry 4100 (class 1259 OID 21298)
-- Name: idx_company_master_primary_email; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE UNIQUE INDEX idx_company_master_primary_email ON nexus_foundation.company_master USING btree (lower((primary_email)::text)) WHERE ((company_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4101 (class 1259 OID 21295)
-- Name: idx_company_master_status; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_company_master_status ON nexus_foundation.company_master USING btree (company_status) WHERE ((company_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4102 (class 1259 OID 21296)
-- Name: idx_company_master_subscription; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_company_master_subscription ON nexus_foundation.company_master USING btree (subscription_end_date, company_status) WHERE (subscription_end_date IS NOT NULL);


--
-- TOC entry 4081 (class 1259 OID 21194)
-- Name: idx_country_master_code; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE UNIQUE INDEX idx_country_master_code ON nexus_foundation.country_master USING btree (country_code) WHERE (is_active = true);


--
-- TOC entry 4082 (class 1259 OID 21195)
-- Name: idx_country_master_name_gin; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_country_master_name_gin ON nexus_foundation.country_master USING gin (country_name public.gin_trgm_ops);


--
-- TOC entry 4103 (class 1259 OID 21342)
-- Name: idx_location_master_company; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_location_master_company ON nexus_foundation.location_master USING btree (company_id, location_status) WHERE ((location_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4104 (class 1259 OID 21344)
-- Name: idx_location_master_geographic; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_location_master_geographic ON nexus_foundation.location_master USING btree (country_id, city_id);


--
-- TOC entry 4105 (class 1259 OID 21343)
-- Name: idx_location_master_hierarchy; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_location_master_hierarchy ON nexus_foundation.location_master USING btree (parent_location_id, location_level);


--
-- TOC entry 4106 (class 1259 OID 21345)
-- Name: idx_location_master_path_gin; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_location_master_path_gin ON nexus_foundation.location_master USING gin (location_path public.gin_trgm_ops);


--
-- TOC entry 4122 (class 1259 OID 21417)
-- Name: idx_role_master_assignable; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_role_master_assignable ON nexus_foundation.role_master USING btree (company_id, is_assignable) WHERE ((is_assignable = true) AND ((role_status)::text = 'ACTIVE'::text));


--
-- TOC entry 4123 (class 1259 OID 21415)
-- Name: idx_role_master_company; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_role_master_company ON nexus_foundation.role_master USING btree (company_id, role_status) WHERE ((role_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4124 (class 1259 OID 21416)
-- Name: idx_role_master_hierarchy; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_role_master_hierarchy ON nexus_foundation.role_master USING btree (parent_role_id, role_level);


--
-- TOC entry 4083 (class 1259 OID 21212)
-- Name: idx_state_master_country; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_state_master_country ON nexus_foundation.state_master USING btree (country_id) WHERE (is_active = true);


--
-- TOC entry 4084 (class 1259 OID 21213)
-- Name: idx_state_master_name_gin; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_state_master_name_gin ON nexus_foundation.state_master USING gin (state_name public.gin_trgm_ops);


--
-- TOC entry 4111 (class 1259 OID 21380)
-- Name: idx_user_master_email_login; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE UNIQUE INDEX idx_user_master_email_login ON nexus_foundation.user_master USING btree (company_id, lower((email_address)::text)) WHERE ((user_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4112 (class 1259 OID 21381)
-- Name: idx_user_master_external_auth; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_master_external_auth ON nexus_foundation.user_master USING btree (external_auth_provider, external_user_id) WHERE (external_auth_provider IS NOT NULL);


--
-- TOC entry 4113 (class 1259 OID 21382)
-- Name: idx_user_master_failed_logins; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_master_failed_logins ON nexus_foundation.user_master USING btree (failed_login_attempts, account_locked_until) WHERE (failed_login_attempts > 0);


--
-- TOC entry 4114 (class 1259 OID 21383)
-- Name: idx_user_master_last_login; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_master_last_login ON nexus_foundation.user_master USING btree (last_login_at) WHERE (last_login_at IS NOT NULL);


--
-- TOC entry 4115 (class 1259 OID 21379)
-- Name: idx_user_master_login; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE UNIQUE INDEX idx_user_master_login ON nexus_foundation.user_master USING btree (company_id, lower((username)::text)) WHERE ((user_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4129 (class 1259 OID 21451)
-- Name: idx_user_role_assignment_dates; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_role_assignment_dates ON nexus_foundation.user_role_assignment USING btree (effective_from_date, effective_to_date);


--
-- TOC entry 4130 (class 1259 OID 21450)
-- Name: idx_user_role_assignment_role; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_role_assignment_role ON nexus_foundation.user_role_assignment USING btree (role_id, assignment_status);


--
-- TOC entry 4131 (class 1259 OID 21449)
-- Name: idx_user_role_assignment_user; Type: INDEX; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE INDEX idx_user_role_assignment_user ON nexus_foundation.user_role_assignment USING btree (user_id, assignment_status) WHERE ((assignment_status)::text = 'ACTIVE'::text);


--
-- TOC entry 4150 (class 0 OID 0)
-- Name: audit_log_2025_09_pkey; Type: INDEX ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER INDEX nexus_audit.audit_log_pkey ATTACH PARTITION nexus_audit.audit_log_2025_09_pkey;


--
-- TOC entry 4151 (class 0 OID 0)
-- Name: audit_log_2025_10_pkey; Type: INDEX ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER INDEX nexus_audit.audit_log_pkey ATTACH PARTITION nexus_audit.audit_log_2025_10_pkey;


--
-- TOC entry 4152 (class 0 OID 0)
-- Name: audit_log_2025_11_pkey; Type: INDEX ATTACH; Schema: nexus_audit; Owner: rameshbabu
--

ALTER INDEX nexus_audit.audit_log_pkey ATTACH PARTITION nexus_audit.audit_log_2025_11_pkey;


--
-- TOC entry 4170 (class 2620 OID 21497)
-- Name: company_master trg_audit_company_master; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_audit_company_master AFTER INSERT OR DELETE OR UPDATE ON nexus_foundation.company_master FOR EACH ROW EXECUTE FUNCTION nexus_audit.audit_trigger_function();


--
-- TOC entry 4171 (class 2620 OID 21498)
-- Name: location_master trg_audit_location_master; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_audit_location_master AFTER INSERT OR DELETE OR UPDATE ON nexus_foundation.location_master FOR EACH ROW EXECUTE FUNCTION nexus_audit.audit_trigger_function();


--
-- TOC entry 4174 (class 2620 OID 21500)
-- Name: role_master trg_audit_role_master; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_audit_role_master AFTER INSERT OR DELETE OR UPDATE ON nexus_foundation.role_master FOR EACH ROW EXECUTE FUNCTION nexus_audit.audit_trigger_function();


--
-- TOC entry 4173 (class 2620 OID 21499)
-- Name: user_master trg_audit_user_master; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_audit_user_master AFTER INSERT OR DELETE OR UPDATE ON nexus_foundation.user_master FOR EACH ROW EXECUTE FUNCTION nexus_audit.audit_trigger_function();


--
-- TOC entry 4175 (class 2620 OID 21501)
-- Name: user_role_assignment trg_audit_user_role_assignment; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_audit_user_role_assignment AFTER INSERT OR DELETE OR UPDATE ON nexus_foundation.user_role_assignment FOR EACH ROW EXECUTE FUNCTION nexus_audit.audit_trigger_function();


--
-- TOC entry 4172 (class 2620 OID 21495)
-- Name: location_master trg_location_hierarchy_path; Type: TRIGGER; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE TRIGGER trg_location_hierarchy_path BEFORE INSERT OR UPDATE ON nexus_foundation.location_master FOR EACH ROW EXECUTE FUNCTION nexus_foundation.update_hierarchy_path();


--
-- TOC entry 4169 (class 2606 OID 21470)
-- Name: system_parameter system_parameter_company_id_fkey; Type: FK CONSTRAINT; Schema: nexus_config; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_config.system_parameter
    ADD CONSTRAINT system_parameter_company_id_fkey FOREIGN KEY (company_id) REFERENCES nexus_foundation.company_master(company_id);


--
-- TOC entry 4154 (class 2606 OID 21225)
-- Name: city_master city_master_state_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.city_master
    ADD CONSTRAINT city_master_state_id_fkey FOREIGN KEY (state_id) REFERENCES nexus_foundation.state_master(state_id);


--
-- TOC entry 4155 (class 2606 OID 21285)
-- Name: company_master company_master_communication_city_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_communication_city_id_fkey FOREIGN KEY (communication_city_id) REFERENCES nexus_foundation.city_master(city_id);


--
-- TOC entry 4156 (class 2606 OID 21290)
-- Name: company_master company_master_communication_country_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_communication_country_id_fkey FOREIGN KEY (communication_country_id) REFERENCES nexus_foundation.country_master(country_id);


--
-- TOC entry 4157 (class 2606 OID 21275)
-- Name: company_master company_master_registered_city_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_registered_city_id_fkey FOREIGN KEY (registered_city_id) REFERENCES nexus_foundation.city_master(city_id);


--
-- TOC entry 4158 (class 2606 OID 21280)
-- Name: company_master company_master_registered_country_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.company_master
    ADD CONSTRAINT company_master_registered_country_id_fkey FOREIGN KEY (registered_country_id) REFERENCES nexus_foundation.country_master(country_id);


--
-- TOC entry 4159 (class 2606 OID 21332)
-- Name: location_master location_master_city_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT location_master_city_id_fkey FOREIGN KEY (city_id) REFERENCES nexus_foundation.city_master(city_id);


--
-- TOC entry 4160 (class 2606 OID 21322)
-- Name: location_master location_master_company_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT location_master_company_id_fkey FOREIGN KEY (company_id) REFERENCES nexus_foundation.company_master(company_id);


--
-- TOC entry 4161 (class 2606 OID 21337)
-- Name: location_master location_master_country_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT location_master_country_id_fkey FOREIGN KEY (country_id) REFERENCES nexus_foundation.country_master(country_id);


--
-- TOC entry 4162 (class 2606 OID 21327)
-- Name: location_master location_master_parent_location_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.location_master
    ADD CONSTRAINT location_master_parent_location_id_fkey FOREIGN KEY (parent_location_id) REFERENCES nexus_foundation.location_master(location_id);


--
-- TOC entry 4164 (class 2606 OID 21405)
-- Name: role_master role_master_company_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.role_master
    ADD CONSTRAINT role_master_company_id_fkey FOREIGN KEY (company_id) REFERENCES nexus_foundation.company_master(company_id);


--
-- TOC entry 4165 (class 2606 OID 21410)
-- Name: role_master role_master_parent_role_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.role_master
    ADD CONSTRAINT role_master_parent_role_id_fkey FOREIGN KEY (parent_role_id) REFERENCES nexus_foundation.role_master(role_id);


--
-- TOC entry 4153 (class 2606 OID 21207)
-- Name: state_master state_master_country_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.state_master
    ADD CONSTRAINT state_master_country_id_fkey FOREIGN KEY (country_id) REFERENCES nexus_foundation.country_master(country_id);


--
-- TOC entry 4163 (class 2606 OID 21374)
-- Name: user_master user_master_company_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_master
    ADD CONSTRAINT user_master_company_id_fkey FOREIGN KEY (company_id) REFERENCES nexus_foundation.company_master(company_id);


--
-- TOC entry 4166 (class 2606 OID 21444)
-- Name: user_role_assignment user_role_assignment_assigned_by_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_role_assignment
    ADD CONSTRAINT user_role_assignment_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES nexus_foundation.user_master(user_id);


--
-- TOC entry 4167 (class 2606 OID 21439)
-- Name: user_role_assignment user_role_assignment_role_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_role_assignment
    ADD CONSTRAINT user_role_assignment_role_id_fkey FOREIGN KEY (role_id) REFERENCES nexus_foundation.role_master(role_id);


--
-- TOC entry 4168 (class 2606 OID 21434)
-- Name: user_role_assignment user_role_assignment_user_id_fkey; Type: FK CONSTRAINT; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE ONLY nexus_foundation.user_role_assignment
    ADD CONSTRAINT user_role_assignment_user_id_fkey FOREIGN KEY (user_id) REFERENCES nexus_foundation.user_master(user_id) ON DELETE CASCADE;


--
-- TOC entry 4327 (class 3256 OID 21502)
-- Name: location_master company_isolation_policy; Type: POLICY; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE POLICY company_isolation_policy ON nexus_foundation.location_master USING ((company_id = (current_setting('app.current_company_id'::text))::bigint));


--
-- TOC entry 4329 (class 3256 OID 21504)
-- Name: role_master company_isolation_policy; Type: POLICY; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE POLICY company_isolation_policy ON nexus_foundation.role_master USING ((company_id = (current_setting('app.current_company_id'::text))::bigint));


--
-- TOC entry 4328 (class 3256 OID 21503)
-- Name: user_master company_isolation_policy; Type: POLICY; Schema: nexus_foundation; Owner: rameshbabu
--

CREATE POLICY company_isolation_policy ON nexus_foundation.user_master USING ((company_id = (current_setting('app.current_company_id'::text))::bigint));


--
-- TOC entry 4322 (class 0 OID 21233)
-- Dependencies: 230
-- Name: company_master; Type: ROW SECURITY; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE nexus_foundation.company_master ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4323 (class 0 OID 21300)
-- Dependencies: 231
-- Name: location_master; Type: ROW SECURITY; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE nexus_foundation.location_master ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4325 (class 0 OID 21384)
-- Dependencies: 233
-- Name: role_master; Type: ROW SECURITY; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE nexus_foundation.role_master ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4324 (class 0 OID 21346)
-- Dependencies: 232
-- Name: user_master; Type: ROW SECURITY; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE nexus_foundation.user_master ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4326 (class 0 OID 21418)
-- Dependencies: 234
-- Name: user_role_assignment; Type: ROW SECURITY; Schema: nexus_foundation; Owner: rameshbabu
--

ALTER TABLE nexus_foundation.user_role_assignment ENABLE ROW LEVEL SECURITY;

-- Completed on 2025-09-15 08:06:18 EDT

--
-- PostgreSQL database dump complete
--

\unrestrict yKu0GTW7teMdceOdBkqFRgWUgwoNcmHFYVa53IngeNrbcmZzTePeTjJAL2tX0Pr

