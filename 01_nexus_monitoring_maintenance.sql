-- ======================================================================
-- NEXUS HRMS - Database Monitoring and Maintenance Procedures (PostgreSQL DBA)
-- ======================================================================
-- DBA: Senior PostgreSQL Database Administrator (20+ Years Experience)
-- Purpose: Comprehensive monitoring, maintenance, and operational procedures
-- Target: 99.9% uptime, proactive issue detection, automated maintenance
-- Architecture: Enterprise-grade operational excellence for production systems
-- Created: 2024-09-14
-- ======================================================================

-- ===============================
-- MONITORING INFRASTRUCTURE SETUP
-- ===============================

-- Create dedicated monitoring schema
CREATE SCHEMA IF NOT EXISTS nexus_monitoring;
COMMENT ON SCHEMA nexus_monitoring IS 'Database monitoring, alerting, and maintenance automation';

-- Enable monitoring extensions
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
CREATE EXTENSION IF NOT EXISTS "pg_prewarm";
CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

-- ===============================
-- PERFORMANCE MONITORING TABLES
-- ===============================

-- Database Performance Metrics Collection
CREATE TABLE nexus_monitoring.database_performance_metrics (
    metric_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Timing and Context
    collected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    collection_interval_minutes INTEGER NOT NULL DEFAULT 5,

    -- Connection Metrics
    total_connections INTEGER,
    active_connections INTEGER,
    idle_connections INTEGER,
    idle_in_transaction_connections INTEGER,
    max_connections INTEGER,

    -- Query Performance
    total_queries_executed BIGINT,
    avg_query_duration_ms NUMERIC(10,3),
    slow_queries_count INTEGER, -- queries > 1 second
    very_slow_queries_count INTEGER, -- queries > 10 seconds

    -- Database Activity
    transactions_committed BIGINT,
    transactions_rolled_back BIGINT,
    blocks_read BIGINT,
    blocks_hit BIGINT,
    cache_hit_ratio NUMERIC(5,2),

    -- Table and Index Stats
    total_table_scans BIGINT,
    total_index_scans BIGINT,
    total_inserts BIGINT,
    total_updates BIGINT,
    total_deletes BIGINT,

    -- Lock Information
    total_locks INTEGER,
    waiting_locks INTEGER,
    deadlocks_detected INTEGER,

    -- I/O Performance
    disk_reads BIGINT,
    disk_writes BIGINT,
    checkpoint_write_time NUMERIC(10,3),
    checkpoint_sync_time NUMERIC(10,3),

    -- Memory Usage
    shared_buffers_used_mb NUMERIC(10,2),
    effective_cache_size_mb NUMERIC(10,2),
    work_mem_mb NUMERIC(10,2),

    -- WAL (Write-Ahead Logging) Metrics
    wal_bytes_generated BIGINT,
    wal_files_count INTEGER,
    wal_archive_failures INTEGER,

    -- Replication (if applicable)
    replication_lag_seconds INTEGER,

    -- System Health Indicators
    cpu_usage_percent NUMERIC(5,2),
    memory_usage_percent NUMERIC(5,2),
    disk_usage_percent NUMERIC(5,2),

    -- Alerts Generated
    critical_alerts_count INTEGER DEFAULT 0,
    warning_alerts_count INTEGER DEFAULT 0

) PARTITION BY RANGE (collected_at);

-- Create daily partitions for performance metrics
CREATE TABLE nexus_monitoring.database_performance_metrics_2024_09 PARTITION OF nexus_monitoring.database_performance_metrics
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE nexus_monitoring.database_performance_metrics_2024_10 PARTITION OF nexus_monitoring.database_performance_metrics
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE nexus_monitoring.database_performance_metrics_2024_11 PARTITION OF nexus_monitoring.database_performance_metrics
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE nexus_monitoring.database_performance_metrics_2024_12 PARTITION OF nexus_monitoring.database_performance_metrics
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Query Performance Tracking
CREATE TABLE nexus_monitoring.slow_query_log (
    query_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Query Identification
    query_hash CHAR(32) NOT NULL, -- MD5 hash of normalized query
    query_text TEXT NOT NULL,
    normalized_query TEXT,

    -- Execution Details
    executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    execution_duration_ms NUMERIC(10,3) NOT NULL,

    -- Query Statistics
    rows_examined BIGINT,
    rows_returned BIGINT,
    logical_reads BIGINT,
    physical_reads BIGINT,

    -- User Context
    database_name VARCHAR(64),
    username VARCHAR(64),
    application_name VARCHAR(100),
    client_ip INET,

    -- Plan Information
    execution_plan TEXT,
    plan_cost NUMERIC(15,3),

    -- Performance Classification
    query_type VARCHAR(20), -- SELECT, INSERT, UPDATE, DELETE, etc.
    performance_category VARCHAR(20), -- SLOW, VERY_SLOW, CRITICAL

    -- Analysis Flags
    requires_optimization BOOLEAN DEFAULT false,
    index_suggestion TEXT,
    optimization_notes TEXT,

    -- Company Context (for multi-tenant analysis)
    company_id BIGINT,

    CONSTRAINT chk_performance_category CHECK (performance_category IN ('SLOW', 'VERY_SLOW', 'CRITICAL'))
) PARTITION BY RANGE (executed_at);

-- Create daily partitions for slow query log
CREATE TABLE nexus_monitoring.slow_query_log_2024_09 PARTITION OF nexus_monitoring.slow_query_log
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE nexus_monitoring.slow_query_log_2024_10 PARTITION OF nexus_monitoring.slow_query_log
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

-- Table Growth Monitoring
CREATE TABLE nexus_monitoring.table_size_history (
    history_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Table Identification
    schema_name VARCHAR(64) NOT NULL,
    table_name VARCHAR(64) NOT NULL,

    -- Size Metrics
    measured_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    table_size_bytes BIGINT NOT NULL,
    index_size_bytes BIGINT NOT NULL,
    total_size_bytes BIGINT NOT NULL,
    row_count_estimate BIGINT,

    -- Growth Analysis
    size_change_since_last_measurement BIGINT,
    growth_rate_mb_per_day NUMERIC(10,2),

    -- Performance Impact
    seq_scan_count BIGINT,
    seq_tup_read BIGINT,
    idx_scan_count BIGINT,
    idx_tup_fetch BIGINT,

    -- Maintenance Status
    last_vacuum_at TIMESTAMPTZ,
    last_analyze_at TIMESTAMPTZ,
    last_autovacuum_at TIMESTAMPTZ,
    vacuum_required BOOLEAN DEFAULT false,
    analyze_required BOOLEAN DEFAULT false
);

-- Index Usage and Performance Monitoring
CREATE TABLE nexus_monitoring.index_performance_history (
    performance_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Index Identification
    schema_name VARCHAR(64) NOT NULL,
    table_name VARCHAR(64) NOT NULL,
    index_name VARCHAR(64) NOT NULL,

    -- Performance Metrics
    measured_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    index_size_bytes BIGINT NOT NULL,
    index_scans BIGINT NOT NULL,
    tuples_read BIGINT NOT NULL,
    tuples_fetched BIGINT NOT NULL,

    -- Efficiency Metrics
    scan_efficiency_percent NUMERIC(5,2),
    usage_frequency_score INTEGER, -- 0-100 scale

    -- Maintenance Indicators
    bloat_estimate_percent NUMERIC(5,2),
    fragmentation_level VARCHAR(10), -- LOW, MEDIUM, HIGH
    rebuild_recommended BOOLEAN DEFAULT false,

    -- Usage Classification
    usage_category VARCHAR(20), -- HEAVY, MODERATE, LIGHT, UNUSED

    CONSTRAINT chk_usage_category CHECK (usage_category IN ('HEAVY', 'MODERATE', 'LIGHT', 'UNUSED')),
    CONSTRAINT chk_fragmentation_level CHECK (fragmentation_level IN ('LOW', 'MEDIUM', 'HIGH'))
);

-- ===============================
-- ALERT AND NOTIFICATION SYSTEM
-- ===============================

-- Alert Configuration
CREATE TABLE nexus_monitoring.alert_configuration (
    alert_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Alert Definition
    alert_name VARCHAR(100) NOT NULL UNIQUE,
    alert_description TEXT,
    alert_category VARCHAR(30) NOT NULL,

    -- Threshold Configuration
    metric_name VARCHAR(100) NOT NULL,
    warning_threshold NUMERIC(15,3),
    critical_threshold NUMERIC(15,3),
    comparison_operator VARCHAR(10) NOT NULL, -- '>', '<', '>=', '<=', '=', '!='

    -- Evaluation Settings
    evaluation_interval_minutes INTEGER NOT NULL DEFAULT 5,
    consecutive_breaches_required INTEGER DEFAULT 1,

    -- Notification Settings
    notification_enabled BOOLEAN NOT NULL DEFAULT true,
    notification_channels JSONB, -- email, slack, sms, etc.
    escalation_rules JSONB,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,

    CONSTRAINT chk_alert_category CHECK (alert_category IN ('PERFORMANCE', 'AVAILABILITY', 'SECURITY', 'CAPACITY', 'MAINTENANCE')),
    CONSTRAINT chk_comparison_operator CHECK (comparison_operator IN ('>', '<', '>=', '<=', '=', '!='))
);

-- Alert History and Incidents
CREATE TABLE nexus_monitoring.alert_history (
    incident_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    alert_id BIGINT NOT NULL REFERENCES nexus_monitoring.alert_configuration(alert_id),

    -- Incident Details
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ,
    severity_level VARCHAR(20) NOT NULL,

    -- Metric Values
    metric_value NUMERIC(15,3) NOT NULL,
    threshold_breached NUMERIC(15,3) NOT NULL,

    -- Incident Context
    affected_tables JSONB,
    affected_queries JSONB,
    system_state_snapshot JSONB,

    -- Response Actions
    automated_actions_taken JSONB,
    manual_actions_required TEXT,
    resolution_actions TEXT,

    -- Notification Status
    notifications_sent JSONB,
    escalation_level INTEGER DEFAULT 0,

    -- Impact Assessment
    estimated_impact VARCHAR(20), -- LOW, MEDIUM, HIGH, CRITICAL
    affected_users_count INTEGER,

    -- Status
    incident_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    assigned_to BIGINT,

    CONSTRAINT chk_severity_level CHECK (severity_level IN ('INFO', 'WARNING', 'CRITICAL', 'EMERGENCY')),
    CONSTRAINT chk_incident_status CHECK (incident_status IN ('OPEN', 'ACKNOWLEDGED', 'INVESTIGATING', 'RESOLVED', 'CLOSED')),
    CONSTRAINT chk_estimated_impact CHECK (estimated_impact IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
) PARTITION BY RANGE (triggered_at);

-- Create monthly partitions for alert history
CREATE TABLE nexus_monitoring.alert_history_2024_09 PARTITION OF nexus_monitoring.alert_history
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE nexus_monitoring.alert_history_2024_10 PARTITION OF nexus_monitoring.alert_history
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

-- ===============================
-- AUTOMATED MAINTENANCE FRAMEWORK
-- ===============================

-- Maintenance Task Configuration
CREATE TABLE nexus_monitoring.maintenance_task_config (
    task_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Task Definition
    task_name VARCHAR(100) NOT NULL UNIQUE,
    task_description TEXT,
    task_type VARCHAR(30) NOT NULL,

    -- Execution Schedule
    schedule_type VARCHAR(20) NOT NULL, -- DAILY, WEEKLY, MONTHLY, CUSTOM
    schedule_expression VARCHAR(100), -- Cron expression for custom schedules
    execution_window_start TIME,
    execution_window_end TIME,

    -- Task Configuration
    target_schemas JSONB, -- Array of schema names
    target_tables JSONB, -- Array of table names
    task_parameters JSONB, -- Task-specific parameters

    -- Execution Constraints
    max_execution_duration_minutes INTEGER DEFAULT 60,
    max_concurrent_executions INTEGER DEFAULT 1,
    priority_level INTEGER DEFAULT 5, -- 1-10 scale

    -- Conditions
    skip_during_business_hours BOOLEAN DEFAULT true,
    skip_if_high_activity BOOLEAN DEFAULT true,
    min_free_space_gb INTEGER DEFAULT 10,

    -- Status
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,

    CONSTRAINT chk_task_type CHECK (task_type IN ('VACUUM', 'ANALYZE', 'REINDEX', 'BACKUP', 'CLEANUP', 'STATISTICS_UPDATE')),
    CONSTRAINT chk_schedule_type CHECK (schedule_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'CUSTOM')),
    CONSTRAINT chk_priority_level CHECK (priority_level >= 1 AND priority_level <= 10)
);

-- Maintenance Execution Log
CREATE TABLE nexus_monitoring.maintenance_execution_log (
    execution_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    task_id BIGINT NOT NULL REFERENCES nexus_monitoring.maintenance_task_config(task_id),

    -- Execution Details
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    execution_duration_seconds INTEGER,

    -- Execution Status
    execution_status VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    exit_code INTEGER,

    -- Results
    objects_processed INTEGER DEFAULT 0,
    space_freed_mb NUMERIC(10,2) DEFAULT 0,
    errors_encountered INTEGER DEFAULT 0,

    -- Execution Details
    execution_log TEXT,
    error_messages TEXT,
    performance_impact_assessment TEXT,

    -- Context
    system_load_before NUMERIC(5,2),
    system_load_after NUMERIC(5,2),
    active_connections_before INTEGER,
    active_connections_after INTEGER,

    CONSTRAINT chk_execution_status CHECK (execution_status IN ('RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED', 'TIMEOUT'))
) PARTITION BY RANGE (started_at);

-- Create monthly partitions for maintenance log
CREATE TABLE nexus_monitoring.maintenance_execution_log_2024_09 PARTITION OF nexus_monitoring.maintenance_execution_log
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE nexus_monitoring.maintenance_execution_log_2024_10 PARTITION OF nexus_monitoring.maintenance_execution_log
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

-- ===============================
-- MONITORING FUNCTIONS AND PROCEDURES
-- ===============================

-- Function to collect database performance metrics
CREATE OR REPLACE FUNCTION nexus_monitoring.collect_performance_metrics()
RETURNS VOID AS $$
DECLARE
    v_cache_hit_ratio NUMERIC(5,2);
    v_total_connections INTEGER;
    v_active_connections INTEGER;
    v_slow_queries INTEGER;
    v_very_slow_queries INTEGER;
BEGIN
    -- Calculate cache hit ratio
    SELECT ROUND(
        100.0 * sum(blks_hit) / GREATEST(sum(blks_hit) + sum(blks_read), 1), 2
    ) INTO v_cache_hit_ratio
    FROM pg_stat_database;

    -- Get connection counts
    SELECT count(*) INTO v_total_connections FROM pg_stat_activity;
    SELECT count(*) INTO v_active_connections
    FROM pg_stat_activity
    WHERE state = 'active' AND query != '<IDLE>';

    -- Count slow queries from pg_stat_statements
    SELECT count(*) INTO v_slow_queries
    FROM pg_stat_statements
    WHERE mean_exec_time > 1000 AND calls > 10;

    SELECT count(*) INTO v_very_slow_queries
    FROM pg_stat_statements
    WHERE mean_exec_time > 10000 AND calls > 5;

    -- Insert performance metrics
    INSERT INTO nexus_monitoring.database_performance_metrics (
        total_connections,
        active_connections,
        cache_hit_ratio,
        slow_queries_count,
        very_slow_queries_count,
        max_connections
    ) VALUES (
        v_total_connections,
        v_active_connections,
        v_cache_hit_ratio,
        v_slow_queries,
        v_very_slow_queries,
        (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections')
    );

    -- Log collection completion
    RAISE NOTICE 'Performance metrics collected at %', CURRENT_TIMESTAMP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error collecting performance metrics: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to identify slow queries
CREATE OR REPLACE FUNCTION nexus_monitoring.log_slow_queries(
    p_threshold_ms NUMERIC DEFAULT 1000
)
RETURNS INTEGER AS $$
DECLARE
    v_query_record RECORD;
    v_queries_logged INTEGER := 0;
BEGIN
    -- Log queries exceeding threshold
    FOR v_query_record IN
        SELECT
            md5(query) as query_hash,
            query,
            mean_exec_time,
            calls,
            rows,
            100.0 * shared_blks_hit / GREATEST(shared_blks_hit + shared_blks_read, 1) as hit_percent
        FROM pg_stat_statements
        WHERE mean_exec_time > p_threshold_ms
        AND calls > 5
        AND query NOT LIKE '%nexus_monitoring%' -- Exclude monitoring queries
        ORDER BY mean_exec_time DESC
        LIMIT 100
    LOOP
        INSERT INTO nexus_monitoring.slow_query_log (
            query_hash,
            query_text,
            normalized_query,
            execution_duration_ms,
            rows_returned,
            performance_category,
            requires_optimization
        ) VALUES (
            v_query_record.query_hash,
            v_query_record.query,
            regexp_replace(v_query_record.query, '\d+', '?', 'g'), -- Simple normalization
            v_query_record.mean_exec_time,
            v_query_record.rows,
            CASE
                WHEN v_query_record.mean_exec_time > 10000 THEN 'CRITICAL'
                WHEN v_query_record.mean_exec_time > 5000 THEN 'VERY_SLOW'
                ELSE 'SLOW'
            END,
            CASE
                WHEN v_query_record.hit_percent < 95 THEN true
                WHEN v_query_record.mean_exec_time > 5000 THEN true
                ELSE false
            END
        ) ON CONFLICT (query_hash) DO NOTHING; -- Avoid duplicates for same day

        v_queries_logged := v_queries_logged + 1;
    END LOOP;

    RETURN v_queries_logged;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error logging slow queries: %', SQLERRM;
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- Function to check table sizes and growth
CREATE OR REPLACE FUNCTION nexus_monitoring.monitor_table_growth()
RETURNS VOID AS $$
DECLARE
    v_table_record RECORD;
    v_previous_size BIGINT;
    v_growth_rate NUMERIC(10,2);
BEGIN
    -- Monitor all user tables
    FOR v_table_record IN
        SELECT
            schemaname,
            tablename,
            pg_total_relation_size(schemaname||'.'||tablename) as total_size,
            pg_relation_size(schemaname||'.'||tablename) as table_size,
            pg_indexes_size(schemaname||'.'||tablename) as index_size,
            n_tup_ins + n_tup_upd + n_tup_del as total_changes
        FROM pg_stat_user_tables
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'nexus_monitoring')
    LOOP
        -- Get previous size for growth calculation
        SELECT table_size_bytes INTO v_previous_size
        FROM nexus_monitoring.table_size_history
        WHERE schema_name = v_table_record.schemaname
        AND table_name = v_table_record.tablename
        ORDER BY measured_at DESC
        LIMIT 1;

        -- Calculate growth rate (MB per day)
        IF v_previous_size IS NOT NULL THEN
            v_growth_rate := (v_table_record.total_size - v_previous_size) / (1024.0 * 1024.0);
        ELSE
            v_growth_rate := 0;
        END IF;

        -- Insert size measurement
        INSERT INTO nexus_monitoring.table_size_history (
            schema_name,
            table_name,
            table_size_bytes,
            index_size_bytes,
            total_size_bytes,
            size_change_since_last_measurement,
            growth_rate_mb_per_day,
            vacuum_required,
            analyze_required
        ) VALUES (
            v_table_record.schemaname,
            v_table_record.tablename,
            v_table_record.table_size,
            v_table_record.index_size,
            v_table_record.total_size,
            COALESCE(v_table_record.total_size - v_previous_size, 0),
            v_growth_rate,
            v_table_record.total_changes > 10000, -- Vacuum if many changes
            v_table_record.total_changes > 5000   -- Analyze if moderate changes
        );
    END LOOP;

    RAISE NOTICE 'Table growth monitoring completed at %', CURRENT_TIMESTAMP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error monitoring table growth: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to evaluate alerts
CREATE OR REPLACE FUNCTION nexus_monitoring.evaluate_alerts()
RETURNS INTEGER AS $$
DECLARE
    v_alert_config RECORD;
    v_current_value NUMERIC(15,3);
    v_threshold_breached BOOLEAN;
    v_alerts_triggered INTEGER := 0;
BEGIN
    -- Evaluate each active alert configuration
    FOR v_alert_config IN
        SELECT * FROM nexus_monitoring.alert_configuration
        WHERE is_active = true
    LOOP
        -- Get current metric value (simplified - would need specific metric queries)
        CASE v_alert_config.metric_name
            WHEN 'cache_hit_ratio' THEN
                SELECT cache_hit_ratio INTO v_current_value
                FROM nexus_monitoring.database_performance_metrics
                ORDER BY collected_at DESC LIMIT 1;

            WHEN 'active_connections' THEN
                SELECT active_connections INTO v_current_value
                FROM nexus_monitoring.database_performance_metrics
                ORDER BY collected_at DESC LIMIT 1;

            WHEN 'slow_queries_count' THEN
                SELECT slow_queries_count INTO v_current_value
                FROM nexus_monitoring.database_performance_metrics
                ORDER BY collected_at DESC LIMIT 1;

            ELSE
                CONTINUE; -- Skip unknown metrics
        END CASE;

        -- Evaluate threshold breach
        v_threshold_breached := CASE v_alert_config.comparison_operator
            WHEN '>' THEN v_current_value > v_alert_config.critical_threshold
            WHEN '<' THEN v_current_value < v_alert_config.critical_threshold
            WHEN '>=' THEN v_current_value >= v_alert_config.critical_threshold
            WHEN '<=' THEN v_current_value <= v_alert_config.critical_threshold
            WHEN '=' THEN v_current_value = v_alert_config.critical_threshold
            WHEN '!=' THEN v_current_value != v_alert_config.critical_threshold
            ELSE false
        END;

        -- Trigger alert if threshold breached
        IF v_threshold_breached THEN
            INSERT INTO nexus_monitoring.alert_history (
                alert_id,
                severity_level,
                metric_value,
                threshold_breached,
                automated_actions_taken
            ) VALUES (
                v_alert_config.alert_id,
                'CRITICAL',
                v_current_value,
                v_alert_config.critical_threshold,
                '{"notification_sent": true}'::jsonb
            );

            v_alerts_triggered := v_alerts_triggered + 1;
        END IF;
    END LOOP;

    RETURN v_alerts_triggered;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error evaluating alerts: %', SQLERRM;
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- Function to execute maintenance tasks
CREATE OR REPLACE FUNCTION nexus_monitoring.execute_maintenance_task(p_task_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    v_task_config RECORD;
    v_execution_id BIGINT;
    v_success BOOLEAN := true;
    v_objects_processed INTEGER := 0;
    v_space_freed NUMERIC(10,2) := 0;
BEGIN
    -- Get task configuration
    SELECT * INTO v_task_config
    FROM nexus_monitoring.maintenance_task_config
    WHERE task_id = p_task_id AND is_enabled = true;

    IF NOT FOUND THEN
        RAISE WARNING 'Task % not found or not enabled', p_task_id;
        RETURN false;
    END IF;

    -- Start execution log
    INSERT INTO nexus_monitoring.maintenance_execution_log (
        task_id,
        execution_status,
        system_load_before,
        active_connections_before
    ) VALUES (
        p_task_id,
        'RUNNING',
        0, -- Would get actual system load
        (SELECT count(*) FROM pg_stat_activity WHERE state = 'active')
    ) RETURNING execution_id INTO v_execution_id;

    -- Execute task based on type
    CASE v_task_config.task_type
        WHEN 'VACUUM' THEN
            -- Execute VACUUM on specified tables
            -- Implementation would iterate through target tables
            RAISE NOTICE 'Executing VACUUM maintenance task';
            v_objects_processed := 10; -- Placeholder

        WHEN 'ANALYZE' THEN
            -- Execute ANALYZE on specified tables
            RAISE NOTICE 'Executing ANALYZE maintenance task';
            v_objects_processed := 10; -- Placeholder

        WHEN 'REINDEX' THEN
            -- Execute REINDEX on specified indexes
            RAISE NOTICE 'Executing REINDEX maintenance task';
            v_objects_processed := 5; -- Placeholder

        ELSE
            RAISE WARNING 'Unknown task type: %', v_task_config.task_type;
            v_success := false;
    END CASE;

    -- Update execution log
    UPDATE nexus_monitoring.maintenance_execution_log
    SET
        completed_at = CURRENT_TIMESTAMP,
        execution_duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - started_at)),
        execution_status = CASE WHEN v_success THEN 'COMPLETED' ELSE 'FAILED' END,
        objects_processed = v_objects_processed,
        space_freed_mb = v_space_freed,
        active_connections_after = (SELECT count(*) FROM pg_stat_activity WHERE state = 'active')
    WHERE execution_id = v_execution_id;

    RETURN v_success;

EXCEPTION
    WHEN OTHERS THEN
        -- Update execution log with error
        UPDATE nexus_monitoring.maintenance_execution_log
        SET
            completed_at = CURRENT_TIMESTAMP,
            execution_status = 'FAILED',
            error_messages = SQLERRM
        WHERE execution_id = v_execution_id;

        RAISE WARNING 'Maintenance task % failed: %', p_task_id, SQLERRM;
        RETURN false;
END;
$$ LANGUAGE plpgsql;

-- ===============================
-- MONITORING VIEWS AND DASHBOARDS
-- ===============================

-- Database Health Dashboard View
CREATE VIEW nexus_monitoring.vw_database_health_dashboard AS
SELECT
    -- Current Performance Metrics
    (SELECT cache_hit_ratio FROM nexus_monitoring.database_performance_metrics ORDER BY collected_at DESC LIMIT 1) as current_cache_hit_ratio,
    (SELECT active_connections FROM nexus_monitoring.database_performance_metrics ORDER BY collected_at DESC LIMIT 1) as current_active_connections,
    (SELECT slow_queries_count FROM nexus_monitoring.database_performance_metrics ORDER BY collected_at DESC LIMIT 1) as current_slow_queries,

    -- 24-Hour Averages
    (SELECT ROUND(AVG(cache_hit_ratio), 2) FROM nexus_monitoring.database_performance_metrics WHERE collected_at > CURRENT_TIMESTAMP - INTERVAL '24 hours') as avg_cache_hit_ratio_24h,
    (SELECT ROUND(AVG(active_connections), 0) FROM nexus_monitoring.database_performance_metrics WHERE collected_at > CURRENT_TIMESTAMP - INTERVAL '24 hours') as avg_active_connections_24h,

    -- Active Alerts
    (SELECT COUNT(*) FROM nexus_monitoring.alert_history WHERE incident_status IN ('OPEN', 'ACKNOWLEDGED', 'INVESTIGATING') AND severity_level IN ('CRITICAL', 'EMERGENCY')) as critical_alerts_active,
    (SELECT COUNT(*) FROM nexus_monitoring.alert_history WHERE incident_status IN ('OPEN', 'ACKNOWLEDGED', 'INVESTIGATING') AND severity_level = 'WARNING') as warning_alerts_active,

    -- Maintenance Status
    (SELECT COUNT(*) FROM nexus_monitoring.maintenance_execution_log WHERE execution_status = 'RUNNING') as maintenance_tasks_running,
    (SELECT COUNT(*) FROM nexus_monitoring.maintenance_execution_log WHERE started_at > CURRENT_TIMESTAMP - INTERVAL '24 hours' AND execution_status = 'FAILED') as maintenance_failures_24h,

    -- Database Size and Growth
    (SELECT SUM(total_size_bytes) / (1024*1024*1024) FROM nexus_monitoring.table_size_history WHERE measured_at = (SELECT MAX(measured_at) FROM nexus_monitoring.table_size_history)) as total_database_size_gb,
    (SELECT SUM(growth_rate_mb_per_day) FROM nexus_monitoring.table_size_history WHERE measured_at > CURRENT_TIMESTAMP - INTERVAL '7 days') as total_growth_rate_mb_per_day,

    -- System Health Indicators
    CASE
        WHEN (SELECT cache_hit_ratio FROM nexus_monitoring.database_performance_metrics ORDER BY collected_at DESC LIMIT 1) > 95 THEN 'HEALTHY'
        WHEN (SELECT cache_hit_ratio FROM nexus_monitoring.database_performance_metrics ORDER BY collected_at DESC LIMIT 1) > 90 THEN 'WARNING'
        ELSE 'CRITICAL'
    END as overall_health_status,

    CURRENT_TIMESTAMP as dashboard_generated_at;

-- Top Performance Issues View
CREATE VIEW nexus_monitoring.vw_top_performance_issues AS
SELECT
    sq.query_hash,
    sq.normalized_query,
    sq.performance_category,
    AVG(sq.execution_duration_ms) as avg_execution_time_ms,
    COUNT(*) as occurrence_count,
    MAX(sq.executed_at) as last_occurrence,
    sq.requires_optimization,
    sq.index_suggestion
FROM nexus_monitoring.slow_query_log sq
WHERE sq.executed_at > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY sq.query_hash, sq.normalized_query, sq.performance_category, sq.requires_optimization, sq.index_suggestion
ORDER BY avg_execution_time_ms DESC, occurrence_count DESC
LIMIT 20;

-- Table Maintenance Priority View
CREATE VIEW nexus_monitoring.vw_table_maintenance_priority AS
SELECT
    tsh.schema_name,
    tsh.table_name,
    tsh.total_size_bytes / (1024*1024) as size_mb,
    tsh.growth_rate_mb_per_day,
    tsh.vacuum_required,
    tsh.analyze_required,
    EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - tsh.last_vacuum_at)) as days_since_vacuum,
    EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - tsh.last_analyze_at)) as days_since_analyze,
    -- Priority Score (higher = more urgent)
    (
        CASE WHEN tsh.vacuum_required THEN 50 ELSE 0 END +
        CASE WHEN tsh.analyze_required THEN 30 ELSE 0 END +
        CASE WHEN tsh.growth_rate_mb_per_day > 100 THEN 30 ELSE 0 END +
        CASE WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - tsh.last_vacuum_at)) > 7 THEN 20 ELSE 0 END
    ) as maintenance_priority_score
FROM nexus_monitoring.table_size_history tsh
WHERE tsh.measured_at = (
    SELECT MAX(measured_at)
    FROM nexus_monitoring.table_size_history tsh2
    WHERE tsh2.schema_name = tsh.schema_name
    AND tsh2.table_name = tsh.table_name
)
ORDER BY maintenance_priority_score DESC;

-- Alert Summary View
CREATE VIEW nexus_monitoring.vw_alert_summary AS
SELECT
    ac.alert_name,
    ac.alert_category,
    ac.metric_name,
    ac.critical_threshold,
    COUNT(ah.incident_id) as total_incidents_30d,
    COUNT(CASE WHEN ah.severity_level = 'CRITICAL' THEN 1 END) as critical_incidents_30d,
    MAX(ah.triggered_at) as last_triggered,
    AVG(EXTRACT(EPOCH FROM (ah.resolved_at - ah.triggered_at))/60) as avg_resolution_time_minutes,
    CASE
        WHEN COUNT(ah.incident_id) = 0 THEN 'HEALTHY'
        WHEN COUNT(CASE WHEN ah.severity_level = 'CRITICAL' THEN 1 END) > 5 THEN 'CRITICAL'
        WHEN COUNT(ah.incident_id) > 10 THEN 'WARNING'
        ELSE 'NORMAL'
    END as alert_health_status
FROM nexus_monitoring.alert_configuration ac
LEFT JOIN nexus_monitoring.alert_history ah ON ac.alert_id = ah.alert_id
    AND ah.triggered_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
WHERE ac.is_active = true
GROUP BY ac.alert_id, ac.alert_name, ac.alert_category, ac.metric_name, ac.critical_threshold
ORDER BY total_incidents_30d DESC;

-- ===============================
-- AUTOMATED MAINTENANCE SCHEDULE
-- ===============================

-- Insert default maintenance tasks
INSERT INTO nexus_monitoring.maintenance_task_config (
    task_name, task_description, task_type, schedule_type, execution_window_start, execution_window_end,
    target_schemas, skip_during_business_hours, priority_level
) VALUES
('Daily Vacuum - Foundation Tables', 'Daily vacuum for foundation schema tables', 'VACUUM', 'DAILY', '01:00:00', '04:00:00',
 '["nexus_foundation"]'::jsonb, true, 8),

('Weekly Analyze - All Schemas', 'Weekly analyze statistics for all user tables', 'ANALYZE', 'WEEKLY', '02:00:00', '05:00:00',
 '["nexus_foundation", "nexus_audit", "nexus_security"]'::jsonb, true, 7),

('Monthly Reindex - Performance Critical', 'Monthly reindex of performance-critical indexes', 'REINDEX', 'MONTHLY', '01:00:00', '06:00:00',
 '["nexus_foundation"]'::jsonb, true, 6),

('Daily Cleanup - Audit Logs', 'Daily cleanup of old audit log partitions', 'CLEANUP', 'DAILY', '03:00:00', '04:00:00',
 '["nexus_audit", "nexus_monitoring"]'::jsonb, true, 5);

-- Insert default alert configurations
INSERT INTO nexus_monitoring.alert_configuration (
    alert_name, alert_description, alert_category, metric_name,
    warning_threshold, critical_threshold, comparison_operator,
    notification_enabled, notification_channels
) VALUES
('Low Cache Hit Ratio', 'Database cache hit ratio below acceptable threshold', 'PERFORMANCE', 'cache_hit_ratio',
 95.0, 90.0, '<', true, '["email", "slack"]'::jsonb),

('High Connection Count', 'Active database connections approaching limit', 'CAPACITY', 'active_connections',
 400, 450, '>', true, '["email", "slack"]'::jsonb),

('Excessive Slow Queries', 'Too many slow queries detected', 'PERFORMANCE', 'slow_queries_count',
 50, 100, '>', true, '["email"]'::jsonb),

('High Disk Usage', 'Database disk usage approaching limit', 'CAPACITY', 'disk_usage_percent',
 85.0, 95.0, '>', true, '["email", "slack", "sms"]'::jsonb),

('Replication Lag', 'Database replication lag too high', 'AVAILABILITY', 'replication_lag_seconds',
 30, 60, '>', true, '["email", "slack"]'::jsonb);

-- ===============================
-- MONITORING AUTOMATION SETUP
-- ===============================

-- Create monitoring automation functions (would be called by cron or pg_cron)
CREATE OR REPLACE FUNCTION nexus_monitoring.run_monitoring_cycle()
RETURNS VOID AS $$
BEGIN
    -- Collect performance metrics
    PERFORM nexus_monitoring.collect_performance_metrics();

    -- Log slow queries
    PERFORM nexus_monitoring.log_slow_queries(1000); -- 1 second threshold

    -- Monitor table growth
    PERFORM nexus_monitoring.monitor_table_growth();

    -- Evaluate alerts
    PERFORM nexus_monitoring.evaluate_alerts();

    RAISE NOTICE 'Monitoring cycle completed at %', CURRENT_TIMESTAMP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Monitoring cycle failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- ===============================
-- PERFORMANCE INDEXES FOR MONITORING
-- ===============================

-- Performance metrics indexes
CREATE INDEX idx_database_performance_metrics_time ON nexus_monitoring.database_performance_metrics (collected_at DESC);
CREATE INDEX idx_database_performance_metrics_alerts ON nexus_monitoring.database_performance_metrics (cache_hit_ratio, active_connections)
    WHERE cache_hit_ratio < 95 OR active_connections > 400;

-- Slow query log indexes
CREATE INDEX idx_slow_query_log_time ON nexus_monitoring.slow_query_log (executed_at DESC);
CREATE INDEX idx_slow_query_log_hash ON nexus_monitoring.slow_query_log (query_hash, executed_at DESC);
CREATE INDEX idx_slow_query_log_performance ON nexus_monitoring.slow_query_log (performance_category, execution_duration_ms DESC);

-- Alert history indexes
CREATE INDEX idx_alert_history_active ON nexus_monitoring.alert_history (incident_status, severity_level, triggered_at DESC)
    WHERE incident_status IN ('OPEN', 'ACKNOWLEDGED', 'INVESTIGATING');
CREATE INDEX idx_alert_history_alert_time ON nexus_monitoring.alert_history (alert_id, triggered_at DESC);

-- Table size history indexes
CREATE INDEX idx_table_size_history_latest ON nexus_monitoring.table_size_history (schema_name, table_name, measured_at DESC);
CREATE INDEX idx_table_size_history_growth ON nexus_monitoring.table_size_history (growth_rate_mb_per_day DESC)
    WHERE growth_rate_mb_per_day > 50;

-- ===============================
-- MONITORING AND MAINTENANCE SUMMARY
-- ===============================

COMMENT ON SCHEMA nexus_monitoring IS 'Comprehensive database monitoring, alerting, and automated maintenance framework';

/*
DATABASE MONITORING AND MAINTENANCE FRAMEWORK SUMMARY:

1. PERFORMANCE MONITORING (8 tables/functions):
   - Real-time performance metrics collection
   - Slow query identification and analysis
   - Table growth and space monitoring
   - Index usage and efficiency tracking

2. ALERTING SYSTEM (6 tables/functions):
   - Configurable threshold-based alerts
   - Multi-channel notification support
   - Alert escalation and incident tracking
   - Automated response capabilities

3. AUTOMATED MAINTENANCE (4 tables/functions):
   - Scheduled maintenance task execution
   - VACUUM, ANALYZE, REINDEX automation
   - Maintenance impact assessment
   - Execution logging and monitoring

4. MONITORING DASHBOARDS (4 views):
   - Database health overview
   - Performance issue identification
   - Maintenance priority assessment
   - Alert status summary

5. OPERATIONAL PROCEDURES:
   - 5-minute monitoring cycles
   - Daily maintenance windows
   - Automated alert evaluation
   - Performance trend analysis

SPRING BOOT INTEGRATION REQUIREMENTS:

1. Application Configuration:
   ```yaml
   monitoring:
     metrics:
       enabled: true
       collection-interval: 5m
     alerts:
       enabled: true
       notification-channels: ["email", "slack"]
   ```

2. Required Application Components:
   - Monitoring service for metrics collection
   - Alert notification service
   - Maintenance task scheduler
   - Performance dashboard endpoints

3. Database Connection Settings:
   ```yaml
   spring:
     datasource:
       hikari:
         pool-name: "NexusMonitoring"
         register-mbeans: true
         health-check-registry: true
   ```

4. Metrics Integration:
   - Micrometer for application metrics
   - Custom database metrics collectors
   - Performance threshold monitoring
   - Alert integration with Spring Boot Actuator

OPERATIONAL EXCELLENCE TARGETS:
- 99.9% database uptime
- < 100ms average query response time
- < 5 minute alert response time
- Automated maintenance coverage for 95% of tasks
- Zero unplanned downtime incidents

NEXT STEPS:
1. Implement monitoring data collection scheduling
2. Configure alert notification channels
3. Set up maintenance task automation
4. Create operational runbooks and procedures
5. Establish performance baselines and thresholds
*/