# NEXUS HRMS - Spring Boot Database Integration Guidelines

**Document Version:** 1.0
**Date:** 2025-01-14
**Author:** Database Architect (20+ Years Experience)
**Target Audience:** Spring Boot Development Team
**System:** NEXUS HRMS (Monolithic Modular Architecture)
**Technology Stack:** Spring Boot 3.x + GraphQL + PostgreSQL + HikariCP

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Database Connection Configuration](#database-connection-configuration)
4. [JPA Entity Mapping Guidelines](#jpa-entity-mapping-guidelines)
5. [GraphQL Integration Patterns](#graphql-integration-patterns)
6. [Performance Optimization Guidelines](#performance-optimization-guidelines)
7. [Security Implementation](#security-implementation)
8. [Query Optimization Strategies](#query-optimization-strategies)
9. [Transaction Management](#transaction-management)
10. [Error Handling and Resilience](#error-handling-and-resilience)
11. [Monitoring and Observability](#monitoring-and-observability)
12. [Testing Strategies](#testing-strategies)
13. [Deployment Considerations](#deployment-considerations)
14. [Migration and Data Handling](#migration-and-data-handling)
15. [Best Practices Checklist](#best-practices-checklist)

---

## Executive Summary

This document provides comprehensive database integration guidelines for the NEXUS HRMS Spring Boot development team. The guidelines are based on 20+ years of enterprise database architecture experience and are specifically optimized for the PostgreSQL foundation schema with GraphQL access patterns.

### Key Integration Points:
- **Performance Target:** Sub-100ms query response times for 95% of operations
- **Scalability:** Support for 500+ concurrent users and 100K+ employee records
- **Security:** Multi-tenant Row Level Security (RLS) with field-level encryption
- **Reliability:** 99.9% uptime with automated failover and recovery

---

## Architecture Overview

### Database Architecture Pattern
```
┌─────────────────────────────────────────────────────────────┐
│                    NEXUS Spring Boot Application            │
├─────────────────────────────────────────────────────────────┤
│  GraphQL Layer (Query/Mutation/Subscription Resolvers)     │
├─────────────────────────────────────────────────────────────┤
│  Service Layer (Business Logic + Security Context)         │
├─────────────────────────────────────────────────────────────┤
│  Repository Layer (JPA/Hibernate + Custom Queries)         │
├─────────────────────────────────────────────────────────────┤
│  HikariCP Connection Pool (Optimized Configuration)        │
├─────────────────────────────────────────────────────────────┤
│              PostgreSQL Database Cluster                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Primary   │  │  Read Replica │  │  Read Replica │        │
│  │  (Write)    │  │   (Read)     │  │   (Read)     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure Recommendation
```
nexus-backend/
├── nexus-core/                    # Common configurations
│   ├── database-config/           # HikariCP and JPA configuration
│   ├── security-context/          # Multi-tenant security context
│   └── performance-monitoring/    # Database performance metrics
├── nexus-employee-service/        # Employee management module
├── nexus-attendance-service/      # Attendance tracking module
├── nexus-leave-service/          # Leave management module
├── nexus-payroll-service/        # Payroll processing module
└── nexus-shared-entities/        # Common JPA entities
```

---

## Database Connection Configuration

### HikariCP Optimal Configuration

```yaml
# application.yml
spring:
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    url: jdbc:postgresql://localhost:5432/nexus_hrms?currentSchema=nexus_foundation
    username: ${DB_USERNAME:nexus_app_user}
    password: ${DB_PASSWORD}
    hikari:
      # Connection Pool Sizing (Critical for Performance)
      maximum-pool-size: 40              # For 500 concurrent users
      minimum-idle: 10                   # Always keep connections ready
      connection-timeout: 20000          # 20 seconds max wait
      idle-timeout: 300000               # 5 minutes idle before close
      max-lifetime: 900000               # 15 minutes max connection life
      leak-detection-threshold: 60000    # 60 seconds leak detection

      # Performance Optimization
      connection-init-sql: |
        SET application_name = 'NEXUS-HRMS-${spring.application.name}';
        SET search_path = nexus_foundation, nexus_security, nexus_monitoring;
        SET timezone = 'UTC';
        SET statement_timeout = '30s';
        SET lock_timeout = '10s';

      # Connection Properties for PostgreSQL
      data-source-properties:
        cachePrepStmts: true
        prepStmtCacheSize: 500
        prepStmtCacheSqlLimit: 2048
        useServerPrepStmts: true
        useLocalSessionState: true
        rewriteBatchedStatements: true
        cacheResultSetMetadata: true
        cacheServerConfiguration: true
        elideSetAutoCommits: true
        maintainTimeStats: false

  # JPA Configuration
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: validate                 # Never auto-create in production
      naming:
        physical-strategy: org.hibernate.boot.model.naming.SnakeCasePhysicalNamingStrategy
        implicit-strategy: org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy
    properties:
      hibernate:
        # Performance Optimization
        jdbc.batch_size: 50
        jdbc.batch_versioned_data: true
        order_inserts: true
        order_updates: true
        generate_statistics: false        # Disable in production

        # Query Optimization
        default_batch_fetch_size: 16
        max_fetch_depth: 3

        # Caching Strategy
        cache.use_second_level_cache: true
        cache.use_query_cache: true
        cache.region.factory_class: org.hibernate.cache.jcache.JCacheRegionFactory

        # SQL Logging (Development Only)
        show_sql: false
        format_sql: false
        use_sql_comments: false
```

### Read/Write Split Configuration

```yaml
# Multiple DataSource Configuration for Read/Write Split
spring:
  datasource:
    primary:
      hikari:
        jdbc-url: jdbc:postgresql://primary-db:5432/nexus_hrms
        maximum-pool-size: 20
        pool-name: PrimaryPool
    readonly:
      hikari:
        jdbc-url: jdbc:postgresql://readonly-replica:5432/nexus_hrms
        maximum-pool-size: 30
        pool-name: ReadOnlyPool
        read-only: true
```

---

## JPA Entity Mapping Guidelines

### Base Entity Pattern

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;                    // BIGINT primary key (NOT UUID for performance)

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "last_modified_at")
    private Instant lastModifiedAt;

    @CreatedBy
    @Column(name = "created_by", length = 100, updatable = false)
    private String createdBy;

    @LastModifiedBy
    @Column(name = "last_modified_by", length = 100)
    private String lastModifiedBy;

    @Version
    @Column(name = "version")
    private Long version;               // Optimistic locking

    // Getters and setters
}
```

### Multi-Tenant Security Context

```java
@Entity
@Table(name = "company_master", schema = "nexus_foundation")
@org.hibernate.annotations.Where(clause = "company_status != 'DELETED'")
public class CompanyMaster extends BaseEntity {

    @Column(name = "company_id", insertable = false, updatable = false)
    private Long companyId;             // Matches BIGINT primary key

    @Column(name = "company_code", unique = true, nullable = false, length = 20)
    private String companyCode;

    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;

    @Enumerated(EnumType.STRING)
    @Column(name = "company_status", nullable = false, length = 20)
    private CompanyStatus companyStatus;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "tax_identification_number", length = 50)
    private String taxIdentificationNumber;  // Encrypted field

    // GraphQL-optimized relationships
    @OneToMany(mappedBy = "company", fetch = FetchType.LAZY)
    @BatchSize(size = 20)               // Batch loading for GraphQL
    private List<EmployeeMaster> employees;
}
```

### Performance-Optimized Entity Relationships

```java
@Entity
@Table(name = "employee_master", schema = "nexus_foundation")
@NamedEntityGraphs({
    @NamedEntityGraph(
        name = "Employee.withBasicDetails",
        attributeNodes = {
            @NamedAttributeNode("department"),
            @NamedAttributeNode("designation"),
            @NamedAttributeNode("company")
        }
    ),
    @NamedEntityGraph(
        name = "Employee.withFullProfile",
        attributeNodes = {
            @NamedAttributeNode(value = "department", subgraph = "dept.withLocation"),
            @NamedAttributeNode("designation"),
            @NamedAttributeNode("reportingManager"),
            @NamedAttributeNode("employeeContacts")
        },
        subgraphs = {
            @NamedSubgraph(
                name = "dept.withLocation",
                attributeNodes = @NamedAttributeNode("location")
            )
        }
    )
})
public class EmployeeMaster extends BaseEntity {

    @Column(name = "employee_id", insertable = false, updatable = false)
    private Long employeeId;

    @Column(name = "employee_code", unique = true, nullable = false, length = 20)
    private String employeeCode;

    // Multi-tenant security
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private CompanyMaster company;

    // Optimized relationships for GraphQL
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    @NotFound(action = NotFoundAction.IGNORE)
    private DepartmentMaster department;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "designation_id")
    private DesignationMaster designation;

    // Self-referencing relationship with careful fetching
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporting_manager_id")
    private EmployeeMaster reportingManager;

    @OneToMany(mappedBy = "reportingManager", fetch = FetchType.LAZY)
    @BatchSize(size = 25)
    private List<EmployeeMaster> subordinates;
}
```

---

## GraphQL Integration Patterns

### Repository Layer for GraphQL Optimization

```java
@Repository
public interface EmployeeRepository extends JpaRepository<EmployeeMaster, Long>,
                                          JpaSpecificationExecutor<EmployeeMaster> {

    // GraphQL cursor-based pagination
    @Query("""
        SELECT e FROM EmployeeMaster e
        WHERE e.company.companyId = :companyId
        AND e.employeeId > :cursor
        AND e.employeeStatus IN :statuses
        ORDER BY e.employeeId ASC
        """)
    List<EmployeeMaster> findByCompanyIdAndCursor(
        @Param("companyId") Long companyId,
        @Param("cursor") Long cursor,
        @Param("statuses") List<EmployeeStatus> statuses,
        Pageable pageable
    );

    // GraphQL field-level filtering with covering index usage
    @Query("""
        SELECT new com.nexus.dto.EmployeeBasicDto(
            e.employeeId, e.employeeCode, e.firstName, e.lastName,
            e.emailOfficial, e.mobileNumber, d.departmentName,
            des.designationName, e.employeeStatus
        )
        FROM EmployeeMaster e
        LEFT JOIN e.department d
        LEFT JOIN e.designation des
        WHERE e.company.companyId = :companyId
        AND (:departmentIds IS NULL OR e.department.departmentId IN :departmentIds)
        AND (:searchTerm IS NULL OR LOWER(e.firstName || ' ' || e.lastName) LIKE LOWER(:searchTerm))
        ORDER BY e.employeeCode
        """)
    List<EmployeeBasicDto> findEmployeeBasicInfo(
        @Param("companyId") Long companyId,
        @Param("departmentIds") List<Long> departmentIds,
        @Param("searchTerm") String searchTerm,
        Pageable pageable
    );

    // Batch loading for GraphQL N+1 problem resolution
    @Query("SELECT e FROM EmployeeMaster e WHERE e.employeeId IN :employeeIds")
    @EntityGraph(value = "Employee.withBasicDetails", type = EntityGraph.EntityGraphType.LOAD)
    List<EmployeeMaster> findByEmployeeIdInWithBasicDetails(@Param("employeeIds") List<Long> employeeIds);
}
```

### GraphQL DataLoader Implementation

```java
@Component
public class EmployeeDataLoader {

    private final EmployeeRepository employeeRepository;
    private final SecurityContextService securityContext;

    @Bean
    public DataLoader<Long, EmployeeMaster> employeeDataLoader() {
        return DataLoader.newMappedDataLoader((Set<Long> employeeIds) ->
            CompletableFuture.supplyAsync(() -> {
                Long companyId = securityContext.getCurrentCompanyId();
                return employeeRepository.findByEmployeeIdInWithBasicDetails(new ArrayList<>(employeeIds))
                    .stream()
                    .filter(emp -> emp.getCompany().getCompanyId().equals(companyId))
                    .collect(Collectors.toMap(
                        EmployeeMaster::getEmployeeId,
                        emp -> emp
                    ));
            }),
            DataLoaderOptions.newOptions()
                .setBatchingEnabled(true)
                .setMaxBatchSize(100)
                .setCachingEnabled(true)
        );
    }
}
```

### GraphQL Query Complexity Analysis

```java
@Component
public class QueryComplexityInstrumentation extends SimpleInstrumentation {

    private static final int MAX_QUERY_COMPLEXITY = 1000;
    private static final int MAX_QUERY_DEPTH = 15;

    @Override
    public InstrumentationContext<ExecutionResult> beginExecution(InstrumentationExecutionParameters parameters) {

        QueryComplexityInfo complexityInfo = QueryComplexityInfo.newQueryComplexityInfo()
            .maximumQueryComplexity(MAX_QUERY_COMPLEXITY)
            .maximumQueryDepth(MAX_QUERY_DEPTH)
            .fieldComplexityCalculator(JavaScalarFieldComplexityCalculator.newCalculator()
                .scalarCost(1)
                .objectCost(2)
                .listFactor(10)
                .introspectionCost(1000)  // Discourage introspection in production
                .createComplexityCalculator())
            .build();

        return new SimpleInstrumentationContext<>();
    }
}
```

---

## Performance Optimization Guidelines

### Query Performance Patterns

```java
@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final EntityManager entityManager;

    // Use projection DTOs for list views to reduce data transfer
    public List<EmployeeListDto> getEmployeesForDashboard(EmployeeFilterDto filter) {

        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<EmployeeListDto> query = cb.createQuery(EmployeeListDto.class);
        Root<EmployeeMaster> root = query.from(EmployeeMaster.class);

        // Join only necessary tables
        Join<EmployeeMaster, DepartmentMaster> deptJoin = root.join("department", JoinType.LEFT);
        Join<EmployeeMaster, DesignationMaster> desigJoin = root.join("designation", JoinType.LEFT);

        // Use constructor expression for projection
        query.select(cb.construct(EmployeeListDto.class,
            root.get("employeeId"),
            root.get("employeeCode"),
            root.get("firstName"),
            root.get("lastName"),
            root.get("emailOfficial"),
            deptJoin.get("departmentName"),
            desigJoin.get("designationName"),
            root.get("employeeStatus")
        ));

        // Build dynamic predicates
        List<Predicate> predicates = new ArrayList<>();
        predicates.add(cb.equal(root.get("company").get("companyId"), getCurrentCompanyId()));

        if (filter.getDepartmentIds() != null && !filter.getDepartmentIds().isEmpty()) {
            predicates.add(root.get("department").get("departmentId").in(filter.getDepartmentIds()));
        }

        if (StringUtils.hasText(filter.getSearchTerm())) {
            String searchPattern = "%" + filter.getSearchTerm().toLowerCase() + "%";
            predicates.add(cb.like(
                cb.lower(cb.concat(cb.concat(root.get("firstName"), " "), root.get("lastName"))),
                searchPattern
            ));
        }

        query.where(predicates.toArray(new Predicate[0]));
        query.orderBy(cb.asc(root.get("employeeCode")));

        TypedQuery<EmployeeListDto> typedQuery = entityManager.createQuery(query);

        // Implement cursor-based pagination for GraphQL
        if (filter.getAfterCursor() != null) {
            typedQuery.setParameter("cursor", filter.getAfterCursor());
        }

        typedQuery.setMaxResults(filter.getLimit());

        return typedQuery.getResultList();
    }

    // Batch processing for bulk operations
    @Transactional
    public void updateEmployeeStatusBatch(List<Long> employeeIds, EmployeeStatus newStatus) {

        String jpql = """
            UPDATE EmployeeMaster e
            SET e.employeeStatus = :newStatus,
                e.lastModifiedAt = :currentTime,
                e.lastModifiedBy = :currentUser
            WHERE e.employeeId IN :employeeIds
            AND e.company.companyId = :companyId
            """;

        entityManager.createQuery(jpql)
            .setParameter("newStatus", newStatus)
            .setParameter("currentTime", Instant.now())
            .setParameter("currentUser", getCurrentUser())
            .setParameter("employeeIds", employeeIds)
            .setParameter("companyId", getCurrentCompanyId())
            .executeUpdate();
    }
}
```

### Caching Strategy Implementation

```java
@Configuration
@EnableCaching
public class CacheConfiguration {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(10000)
            .expireAfterWrite(30, TimeUnit.MINUTES)
            .recordStats());
        return cacheManager;
    }

    @Bean
    public CacheManager redisCacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofHours(1))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));

        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .build();
    }
}

@Service
public class MasterDataService {

    // Cache master data that rarely changes
    @Cacheable(value = "departments", key = "#companyId")
    public List<DepartmentMaster> getDepartmentsByCompany(Long companyId) {
        return departmentRepository.findByCompanyIdAndStatus(companyId, Status.ACTIVE);
    }

    // Cache with custom key generator for complex objects
    @Cacheable(value = "employeeHierarchy", key = "#companyId + '_' + #managerId")
    public List<EmployeeHierarchyDto> getEmployeeHierarchy(Long companyId, Long managerId) {
        // Complex hierarchical query with recursive CTE
        return employeeRepository.findEmployeeHierarchy(companyId, managerId);
    }

    // Cache eviction on updates
    @CacheEvict(value = {"departments", "employeeHierarchy"}, key = "#department.company.companyId")
    public DepartmentMaster updateDepartment(DepartmentMaster department) {
        return departmentRepository.save(department);
    }
}
```

---

## Security Implementation

### Multi-Tenant Security Context

```java
@Component
public class SecurityContextService {

    private static final String COMPANY_ID_HEADER = "X-Company-ID";
    private static final String USER_ID_HEADER = "X-User-ID";

    public void setSecurityContext(Long companyId, Long userId, List<String> roles) {

        // Set PostgreSQL Row Level Security context
        String securitySql = """
            SELECT set_config('app.current_company_id', ?, false),
                   set_config('app.current_user_id', ?, false),
                   set_config('app.current_roles', ?, false)
            """;

        entityManager.createNativeQuery(securitySql)
            .setParameter(1, companyId.toString())
            .setParameter(2, userId.toString())
            .setParameter(3, String.join(",", roles))
            .executeUpdate();
    }

    public Long getCurrentCompanyId() {
        String companyId = (String) entityManager.createNativeQuery(
            "SELECT current_setting('app.current_company_id', true)"
        ).getSingleResult();

        return companyId != null && !companyId.isEmpty() ? Long.valueOf(companyId) : null;
    }

    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public void validateCompanyAccess(Long requestedCompanyId) {
        Long currentCompanyId = getCurrentCompanyId();
        if (!Objects.equals(currentCompanyId, requestedCompanyId)) {
            throw new AccessDeniedException("Access denied to company: " + requestedCompanyId);
        }
    }
}
```

### Field-Level Encryption Implementation

```java
@Converter
public class EncryptedStringConverter implements AttributeConverter<String, String> {

    private final AESUtil aesUtil;

    public EncryptedStringConverter(AESUtil aesUtil) {
        this.aesUtil = aesUtil;
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) return null;

        // Get encryption key based on data classification
        String encryptionKey = getEncryptionKey();
        return aesUtil.encrypt(attribute, encryptionKey);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;

        String encryptionKey = getEncryptionKey();
        return aesUtil.decrypt(dbData, encryptionKey);
    }

    private String getEncryptionKey() {
        // Retrieve key from secure key management service
        return keyManagementService.getEncryptionKey("PII_DATA");
    }
}

@Entity
public class EmployeeMaster extends BaseEntity {

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "social_security_number")
    private String socialSecurityNumber;    // Encrypted

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "bank_account_number")
    private String bankAccountNumber;       // Encrypted

    @Convert(converter = DataMaskingConverter.class)
    @Column(name = "mobile_number")
    private String mobileNumber;            // Masked in logs
}
```

### Audit Trail Implementation

```java
@EntityListeners(AuditListener.class)
@Entity
public class EmployeeMaster extends BaseEntity {
    // Entity fields
}

@Component
public class AuditListener {

    @Autowired
    private AuditService auditService;

    @PostPersist
    public void onPostPersist(Object entity) {
        auditService.logDataChange(
            AuditAction.CREATE,
            entity.getClass().getSimpleName(),
            getEntityId(entity),
            null,  // No previous state
            getCurrentState(entity)
        );
    }

    @PostUpdate
    public void onPostUpdate(Object entity) {
        auditService.logDataChange(
            AuditAction.UPDATE,
            entity.getClass().getSimpleName(),
            getEntityId(entity),
            getPreviousState(entity),
            getCurrentState(entity)
        );
    }

    @PostRemove
    public void onPostRemove(Object entity) {
        auditService.logDataChange(
            AuditAction.DELETE,
            entity.getClass().getSimpleName(),
            getEntityId(entity),
            getCurrentState(entity),
            null  // No new state
        );
    }
}
```

---

## Query Optimization Strategies

### Index Usage Guidelines

```java
@Service
public class QueryOptimizationService {

    // Use covering indexes for frequently accessed data
    @Query("""
        SELECT new com.nexus.dto.EmployeeDashboardDto(
            e.employeeId, e.employeeCode, e.firstName, e.lastName,
            e.emailOfficial, e.employeeStatus, e.joiningDate
        )
        FROM EmployeeMaster e
        WHERE e.company.companyId = :companyId
        AND e.employeeStatus IN ('ACTIVE', 'ON_LEAVE')
        ORDER BY e.employeeCode
        """)
    // Uses: idx_employee_master_dashboard_covering
    List<EmployeeDashboardDto> getActiveEmployeesForDashboard(@Param("companyId") Long companyId);

    // Use partial indexes for status-based queries
    @Query("""
        SELECT COUNT(e) FROM EmployeeMaster e
        WHERE e.company.companyId = :companyId
        AND e.employeeStatus = 'ACTIVE'
        """)
    // Uses: idx_employee_master_active_status
    Long countActiveEmployees(@Param("companyId") Long companyId);

    // Use GIN indexes for full-text search
    @Query(value = """
        SELECT * FROM nexus_foundation.employee_master e
        WHERE e.company_id = :companyId
        AND e.search_vector @@ plainto_tsquery('english', :searchTerm)
        ORDER BY ts_rank(e.search_vector, plainto_tsquery('english', :searchTerm)) DESC
        """, nativeQuery = true)
    // Uses: idx_employee_master_search_vector_gin
    List<EmployeeMaster> searchEmployeesByText(
        @Param("companyId") Long companyId,
        @Param("searchTerm") String searchTerm
    );
}
```

### Batch Processing Guidelines

```java
@Service
@Transactional
public class BatchProcessingService {

    private static final int BATCH_SIZE = 1000;

    public void processBulkEmployeeUpdates(List<EmployeeUpdateDto> updates) {

        for (int i = 0; i < updates.size(); i += BATCH_SIZE) {
            int endIndex = Math.min(i + BATCH_SIZE, updates.size());
            List<EmployeeUpdateDto> batch = updates.subList(i, endIndex);

            processBatch(batch);

            // Flush and clear persistence context to avoid memory issues
            entityManager.flush();
            entityManager.clear();

            // Progress logging
            log.info("Processed batch {}/{}", (i / BATCH_SIZE) + 1, (updates.size() / BATCH_SIZE) + 1);
        }
    }

    private void processBatch(List<EmployeeUpdateDto> batch) {

        // Use batch updates for better performance
        String updateSql = """
            UPDATE nexus_foundation.employee_master
            SET salary_amount = :salaryAmount,
                last_modified_at = :modifiedAt,
                last_modified_by = :modifiedBy
            WHERE employee_id = :employeeId
            AND company_id = :companyId
            """;

        Query query = entityManager.createNativeQuery(updateSql);

        for (EmployeeUpdateDto update : batch) {
            query.setParameter("salaryAmount", update.getSalaryAmount())
                 .setParameter("modifiedAt", Instant.now())
                 .setParameter("modifiedBy", getCurrentUser())
                 .setParameter("employeeId", update.getEmployeeId())
                 .setParameter("companyId", getCurrentCompanyId())
                 .addBatch();
        }

        query.executeBatch();
    }
}
```

---

## Transaction Management

### Transaction Configuration

```java
@Configuration
@EnableTransactionManagement
public class TransactionConfiguration {

    @Bean
    public PlatformTransactionManager transactionManager(EntityManagerFactory entityManagerFactory) {
        JpaTransactionManager transactionManager = new JpaTransactionManager();
        transactionManager.setEntityManagerFactory(entityManagerFactory);
        transactionManager.setDefaultTimeout(30); // 30 seconds default timeout
        return transactionManager;
    }

    @Bean
    public TransactionTemplate transactionTemplate(PlatformTransactionManager transactionManager) {
        TransactionTemplate template = new TransactionTemplate(transactionManager);
        template.setTimeout(60); // 60 seconds for batch operations
        template.setIsolationLevel(TransactionDefinition.ISOLATION_READ_COMMITTED);
        return template;
    }
}
```

### Service-Level Transaction Management

```java
@Service
public class PayrollProcessingService {

    // Read-only transactions for reporting
    @Transactional(readOnly = true, timeout = 120)
    public PayrollReportDto generatePayrollReport(Long companyId, LocalDate payrollMonth) {
        // Long-running read operations
        return payrollRepository.generateReport(companyId, payrollMonth);
    }

    // Write transactions with appropriate isolation
    @Transactional(isolation = Isolation.READ_COMMITTED, timeout = 300)
    public void processMonthlyPayroll(Long companyId, LocalDate payrollMonth) {

        try {
            // Step 1: Validate payroll period
            validatePayrollPeriod(companyId, payrollMonth);

            // Step 2: Calculate payroll for all employees
            List<PayrollCalculationDto> calculations = calculatePayrollForAllEmployees(companyId, payrollMonth);

            // Step 3: Save payroll records in batches
            savePayrollRecordsBatch(calculations);

            // Step 4: Update payroll status
            updatePayrollStatus(companyId, payrollMonth, PayrollStatus.PROCESSED);

        } catch (Exception e) {
            log.error("Payroll processing failed for company {} and month {}", companyId, payrollMonth, e);
            throw new PayrollProcessingException("Failed to process payroll", e);
        }
    }

    // Requires new transaction for independent operations
    @Transactional(propagation = Propagation.REQUIRES_NEW, timeout = 30)
    public void logPayrollAuditEvent(PayrollAuditEvent event) {
        auditRepository.save(event);
    }
}
```

---

## Error Handling and Resilience

### Database Connection Resilience

```java
@Configuration
public class DatabaseResilienceConfiguration {

    @Bean
    public RetryTemplate databaseRetryTemplate() {
        RetryTemplate retryTemplate = new RetryTemplate();

        // Define retry policy
        SimpleRetryPolicy retryPolicy = new SimpleRetryPolicy();
        retryPolicy.setMaxAttempts(3);
        retryTemplate.setRetryPolicy(retryPolicy);

        // Define backoff policy
        ExponentialBackOffPolicy backOffPolicy = new ExponentialBackOffPolicy();
        backOffPolicy.setInitialInterval(1000);    // 1 second
        backOffPolicy.setMaxInterval(10000);       // 10 seconds
        backOffPolicy.setMultiplier(2.0);
        retryTemplate.setBackOffPolicy(backOffPolicy);

        return retryTemplate;
    }

    @Bean
    public CircuitBreaker databaseCircuitBreaker() {
        return CircuitBreaker.ofDefaults("database")
            .toBuilder()
            .failureRateThreshold(50)              // 50% failure rate
            .waitDurationInOpenState(Duration.ofSeconds(30))
            .slidingWindowSize(10)
            .minimumNumberOfCalls(5)
            .build();
    }
}

@Service
public class ResilientEmployeeService {

    private final RetryTemplate retryTemplate;
    private final CircuitBreaker circuitBreaker;

    public Optional<EmployeeMaster> findEmployeeWithResilience(Long employeeId) {

        return circuitBreaker.executeSupplier(() ->
            retryTemplate.execute(context -> {
                try {
                    return employeeRepository.findById(employeeId);
                } catch (DataAccessException e) {
                    log.warn("Database access failed, attempt {}: {}",
                        context.getRetryCount() + 1, e.getMessage());
                    throw e;
                }
            })
        );
    }
}
```

### Global Exception Handling

```java
@ControllerAdvice
public class DatabaseExceptionHandler {

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDataIntegrityViolation(DataIntegrityViolationException e) {

        String message = "Data integrity constraint violation";
        String details = extractConstraintViolationDetails(e);

        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(Instant.now())
            .status(HttpStatus.BAD_REQUEST.value())
            .error("Data Integrity Violation")
            .message(message)
            .details(details)
            .build();

        log.error("Data integrity violation: {}", details, e);
        return ResponseEntity.badRequest().body(errorResponse);
    }

    @ExceptionHandler(QueryTimeoutException.class)
    public ResponseEntity<ErrorResponse> handleQueryTimeout(QueryTimeoutException e) {

        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(Instant.now())
            .status(HttpStatus.REQUEST_TIMEOUT.value())
            .error("Query Timeout")
            .message("Database query took too long to execute")
            .details("Please refine your search criteria or contact support")
            .build();

        log.error("Query timeout occurred", e);
        return ResponseEntity.status(HttpStatus.REQUEST_TIMEOUT).body(errorResponse);
    }

    @ExceptionHandler(CannotAcquireLockException.class)
    public ResponseEntity<ErrorResponse> handleLockAcquisitionException(CannotAcquireLockException e) {

        ErrorResponse errorResponse = ErrorResponse.builder()
            .timestamp(Instant.now())
            .status(HttpStatus.CONFLICT.value())
            .error("Concurrent Modification")
            .message("The record is currently being modified by another user")
            .details("Please refresh the data and try again")
            .build();

        log.warn("Lock acquisition failed", e);
        return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
    }
}
```

---

## Monitoring and Observability

### Database Performance Monitoring

```java
@Component
public class DatabaseMetricsCollector {

    private final MeterRegistry meterRegistry;
    private final DataSource dataSource;

    @EventListener
    public void handleConnectionPoolMetrics(ApplicationReadyEvent event) {

        if (dataSource instanceof HikariDataSource) {
            HikariDataSource hikariDataSource = (HikariDataSource) dataSource;

            // Connection pool metrics
            Gauge.builder("hikari.connections.active")
                .register(meterRegistry, hikariDataSource, HikariDataSource::getHikariPoolMXBean)
                .map(mxBean -> mxBean.getActiveConnections());

            Gauge.builder("hikari.connections.idle")
                .register(meterRegistry, hikariDataSource, HikariDataSource::getHikariPoolMXBean)
                .map(mxBean -> mxBean.getIdleConnections());

            Gauge.builder("hikari.connections.total")
                .register(meterRegistry, hikariDataSource, HikariDataSource::getHikariPoolMXBean)
                .map(mxBean -> mxBean.getTotalConnections());
        }
    }

    @Scheduled(fixedDelay = 60000) // Every minute
    public void collectDatabaseMetrics() {

        try (Connection connection = dataSource.getConnection()) {

            // Collect slow queries
            String slowQueriesSql = """
                SELECT query, calls, mean_time, total_time
                FROM pg_stat_statements
                WHERE mean_time > 1000
                ORDER BY mean_time DESC
                LIMIT 10
                """;

            try (PreparedStatement stmt = connection.prepareStatement(slowQueriesSql);
                 ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {
                    String query = rs.getString("query");
                    long meanTime = rs.getLong("mean_time");

                    // Record slow query metric
                    Timer.Sample sample = Timer.start(meterRegistry);
                    sample.stop(Timer.builder("database.query.slow")
                        .tag("query_hash", String.valueOf(query.hashCode()))
                        .register(meterRegistry));
                }
            }

            // Collect connection metrics
            String connectionSql = """
                SELECT state, count(*) as connection_count
                FROM pg_stat_activity
                WHERE datname = current_database()
                GROUP BY state
                """;

            try (PreparedStatement stmt = connection.prepareStatement(connectionSql);
                 ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {
                    String state = rs.getString("state");
                    int count = rs.getInt("connection_count");

                    Gauge.builder("database.connections")
                        .tag("state", state)
                        .register(meterRegistry, () -> count);
                }
            }

        } catch (SQLException e) {
            log.error("Failed to collect database metrics", e);
        }
    }
}
```

### Query Performance Interceptor

```java
@Component
public class QueryPerformanceInterceptor implements Interceptor {

    private static final long SLOW_QUERY_THRESHOLD_MS = 1000;
    private final MeterRegistry meterRegistry;

    @Override
    public boolean onLoad(Object entity, Serializable id, Object[] state, String[] propertyNames, Type[] types) {
        Timer.Sample sample = Timer.start(meterRegistry);
        return false;
    }

    @Override
    public boolean onFlushDirty(Object entity, Serializable id, Object[] currentState, Object[] previousState,
                               String[] propertyNames, Type[] types) {

        Timer.Sample sample = Timer.start(meterRegistry);
        // Record update operation metrics
        sample.stop(Timer.builder("database.operation")
            .tag("operation", "update")
            .tag("entity", entity.getClass().getSimpleName())
            .register(meterRegistry));

        return false;
    }

    @Override
    public boolean onSave(Object entity, Serializable id, Object[] state, String[] propertyNames, Type[] types) {

        Timer.Sample sample = Timer.start(meterRegistry);
        sample.stop(Timer.builder("database.operation")
            .tag("operation", "insert")
            .tag("entity", entity.getClass().getSimpleName())
            .register(meterRegistry));

        return false;
    }
}
```

---

## Testing Strategies

### Repository Layer Testing

```java
@DataJpaTest
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.datasource.url=jdbc:h2:mem:testdb",
    "spring.jpa.show-sql=true"
})
class EmployeeRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private EmployeeRepository employeeRepository;

    private CompanyMaster testCompany;
    private DepartmentMaster testDepartment;

    @BeforeEach
    void setUp() {
        testCompany = createTestCompany();
        testDepartment = createTestDepartment(testCompany);
        entityManager.persistAndFlush(testCompany);
        entityManager.persistAndFlush(testDepartment);
    }

    @Test
    void findByCompanyIdAndCursor_ShouldReturnEmployeesAfterCursor() {
        // Given
        List<EmployeeMaster> employees = createTestEmployees(testCompany, testDepartment, 10);
        employees.forEach(emp -> entityManager.persistAndFlush(emp));

        Long cursor = employees.get(4).getEmployeeId();
        List<EmployeeStatus> statuses = Arrays.asList(EmployeeStatus.ACTIVE, EmployeeStatus.ON_LEAVE);
        Pageable pageable = PageRequest.of(0, 5);

        // When
        List<EmployeeMaster> result = employeeRepository.findByCompanyIdAndCursor(
            testCompany.getCompanyId(), cursor, statuses, pageable);

        // Then
        assertThat(result).hasSize(5);
        assertThat(result).allMatch(emp -> emp.getEmployeeId() > cursor);
        assertThat(result).allMatch(emp -> statuses.contains(emp.getEmployeeStatus()));
    }

    @Test
    void findEmployeeBasicInfo_ShouldReturnProjectedData() {
        // Given
        EmployeeMaster employee = createTestEmployee(testCompany, testDepartment);
        entityManager.persistAndFlush(employee);

        // When
        List<EmployeeBasicDto> result = employeeRepository.findEmployeeBasicInfo(
            testCompany.getCompanyId(), null, null, PageRequest.of(0, 10));

        // Then
        assertThat(result).hasSize(1);
        EmployeeBasicDto dto = result.get(0);
        assertThat(dto.getEmployeeId()).isEqualTo(employee.getEmployeeId());
        assertThat(dto.getEmployeeCode()).isEqualTo(employee.getEmployeeCode());
        assertThat(dto.getDepartmentName()).isEqualTo(testDepartment.getDepartmentName());
    }

    @Test
    @Sql(scripts = "/test-data/large-employee-dataset.sql")
    void findByEmployeeIdInWithBasicDetails_ShouldHandleBatchLoading() {
        // Given
        List<Long> employeeIds = Arrays.asList(1L, 2L, 3L, 4L, 5L);

        // When
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        List<EmployeeMaster> result = employeeRepository.findByEmployeeIdInWithBasicDetails(employeeIds);
        stopWatch.stop();

        // Then
        assertThat(result).hasSize(5);
        assertThat(stopWatch.getTotalTimeMillis()).isLessThan(100); // Should be fast with proper indexing

        // Verify entity graph loading
        result.forEach(emp -> {
            assertThat(Hibernate.isInitialized(emp.getDepartment())).isTrue();
            assertThat(Hibernate.isInitialized(emp.getDesignation())).isTrue();
            assertThat(Hibernate.isInitialized(emp.getCompany())).isTrue();
        });
    }
}
```

### Service Layer Integration Testing

```java
@SpringBootTest
@Transactional
@Rollback
class EmployeeServiceIntegrationTest {

    @Autowired
    private EmployeeService employeeService;

    @Autowired
    private SecurityContextService securityContextService;

    @MockBean
    private AuditService auditService;

    @Test
    void getEmployeesForDashboard_ShouldApplySecurityContext() {
        // Given
        Long companyId = 1L;
        Long userId = 100L;
        securityContextService.setSecurityContext(companyId, userId, Arrays.asList("HR_USER"));

        EmployeeFilterDto filter = EmployeeFilterDto.builder()
            .departmentIds(Arrays.asList(1L, 2L))
            .searchTerm("John")
            .limit(10)
            .build();

        // When
        List<EmployeeListDto> result = employeeService.getEmployeesForDashboard(filter);

        // Then
        assertThat(result).isNotNull();
        assertThat(result).allMatch(emp -> emp.getEmployeeId() != null);

        // Verify security context was applied
        verify(auditService).logDataAccess(eq("EMPLOYEE_SEARCH"), any(), eq(companyId), eq(userId));
    }

    @Test
    @WithMockUser(roles = {"ADMIN"})
    void updateEmployeeStatusBatch_ShouldUpdateMultipleEmployees() {
        // Given
        List<Long> employeeIds = Arrays.asList(1L, 2L, 3L);
        EmployeeStatus newStatus = EmployeeStatus.INACTIVE;

        // When
        employeeService.updateEmployeeStatusBatch(employeeIds, newStatus);

        // Then
        List<EmployeeMaster> updatedEmployees = employeeRepository.findAllById(employeeIds);
        assertThat(updatedEmployees).allMatch(emp -> emp.getEmployeeStatus() == newStatus);
        assertThat(updatedEmployees).allMatch(emp -> emp.getLastModifiedAt() != null);
    }
}
```

### Performance Testing

```java
@SpringBootTest
@TestPropertySource(properties = {
    "spring.jpa.show-sql=false",
    "logging.level.org.hibernate.SQL=WARN"
})
class EmployeeRepositoryPerformanceTest {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Test
    @Timeout(value = 5, unit = TimeUnit.SECONDS)
    void findEmployeeBasicInfo_ShouldCompleteWithinTimeLimit() {
        // Given
        Long companyId = 1L;
        Pageable pageable = PageRequest.of(0, 100);

        // When & Then
        assertTimeout(Duration.ofSeconds(5), () -> {
            List<EmployeeBasicDto> result = employeeRepository.findEmployeeBasicInfo(
                companyId, null, null, pageable);
            assertThat(result).isNotNull();
        });
    }

    @Test
    void batchProcessing_ShouldHandleLargeDatasets() {
        // Given
        int batchSize = 1000;
        int totalRecords = 10000;

        // When
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();

        for (int i = 0; i < totalRecords; i += batchSize) {
            List<Long> employeeIds = LongStream.range(i, Math.min(i + batchSize, totalRecords))
                .boxed()
                .collect(Collectors.toList());

            List<EmployeeMaster> batch = employeeRepository.findByEmployeeIdInWithBasicDetails(employeeIds);
            // Process batch
        }

        stopWatch.stop();

        // Then
        long avgTimePerBatch = stopWatch.getTotalTimeMillis() / (totalRecords / batchSize);
        assertThat(avgTimePerBatch).isLessThan(1000); // Less than 1 second per batch
    }
}
```

---

## Deployment Considerations

### Environment-Specific Configuration

```yaml
# application-prod.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 50
      minimum-idle: 15
      leak-detection-threshold: 30000

  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        generate_statistics: false
        show_sql: false
        format_sql: false

# Health checks and monitoring
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus,hikaricp
  endpoint:
    health:
      show-details: always
  metrics:
    export:
      prometheus:
        enabled: true

# Database health check
  health:
    db:
      enabled: true
    hikaricp:
      enabled: true
```

### Database Migration Strategy

```java
@Component
public class DatabaseMigrationValidator {

    @EventListener
    public void validateDatabaseSchema(ApplicationReadyEvent event) {

        // Validate critical indexes exist
        validateCriticalIndexes();

        // Validate RLS policies are active
        validateRowLevelSecurity();

        // Validate partition tables are created
        validatePartitionTables();

        // Validate encryption keys are accessible
        validateEncryptionConfiguration();

        log.info("Database schema validation completed successfully");
    }

    private void validateCriticalIndexes() {
        String indexCheckSql = """
            SELECT schemaname, tablename, indexname
            FROM pg_indexes
            WHERE schemaname = 'nexus_foundation'
            AND indexname IN (
                'idx_employee_master_company_status',
                'idx_employee_master_dashboard_covering',
                'idx_attendance_records_employee_date',
                'idx_leave_applications_employee_period'
            )
            """;

        List<Map<String, Object>> indexes = jdbcTemplate.queryForList(indexCheckSql);

        if (indexes.size() < 4) {
            throw new IllegalStateException("Critical database indexes are missing");
        }
    }

    private void validateRowLevelSecurity() {
        String rlsCheckSql = """
            SELECT schemaname, tablename, rowsecurity
            FROM pg_tables
            WHERE schemaname = 'nexus_foundation'
            AND rowsecurity = false
            """;

        List<Map<String, Object>> tablesWithoutRLS = jdbcTemplate.queryForList(rlsCheckSql);

        if (!tablesWithoutRLS.isEmpty()) {
            log.warn("Tables without RLS enabled: {}", tablesWithoutRLS);
        }
    }
}
```

---

## Migration and Data Handling

### MongoDB to PostgreSQL Migration

```java
@Service
public class DataMigrationService {

    private final MongoTemplate mongoTemplate;
    private final JdbcTemplate postgresTemplate;
    private final EntityManager entityManager;

    @Transactional
    public void migrateEmployeeData() {

        log.info("Starting employee data migration from MongoDB to PostgreSQL");

        // Batch process to avoid memory issues
        int batchSize = 1000;
        int skip = 0;
        int totalMigrated = 0;

        while (true) {
            // Fetch batch from MongoDB
            Query query = new Query().skip(skip).limit(batchSize);
            List<Document> mongoDocs = mongoTemplate.find(query, Document.class, "employees");

            if (mongoDocs.isEmpty()) {
                break;
            }

            // Transform and insert into PostgreSQL
            List<EmployeeMaster> employees = transformMongoToPostgres(mongoDocs);
            batchInsertEmployees(employees);

            totalMigrated += mongoDocs.size();
            skip += batchSize;

            // Progress logging
            if (totalMigrated % 10000 == 0) {
                log.info("Migrated {} employee records", totalMigrated);
            }

            // Clear persistence context to avoid memory buildup
            entityManager.clear();
        }

        log.info("Employee data migration completed. Total records migrated: {}", totalMigrated);
    }

    private List<EmployeeMaster> transformMongoToPostgres(List<Document> mongoDocs) {

        return mongoDocs.stream().map(doc -> {
            EmployeeMaster employee = new EmployeeMaster();

            // Map MongoDB ObjectId to PostgreSQL BIGINT
            employee.setEmployeeCode(doc.getString("employeeCode"));
            employee.setFirstName(doc.getString("firstName"));
            employee.setLastName(doc.getString("lastName"));
            employee.setEmailOfficial(doc.getString("emailOfficial"));

            // Transform enum values
            String status = doc.getString("status");
            employee.setEmployeeStatus(EmployeeStatus.valueOf(status.toUpperCase()));

            // Handle nested objects
            Document personalInfo = doc.get("personalInfo", Document.class);
            if (personalInfo != null) {
                employee.setDateOfBirth(convertToLocalDate(personalInfo.getDate("dateOfBirth")));
                employee.setGender(Gender.valueOf(personalInfo.getString("gender").toUpperCase()));
            }

            // Set audit fields
            employee.setCreatedAt(convertToInstant(doc.getDate("createdAt")));
            employee.setCreatedBy("MIGRATION");

            return employee;
        }).collect(Collectors.toList());
    }

    private void batchInsertEmployees(List<EmployeeMaster> employees) {

        String insertSql = """
            INSERT INTO nexus_foundation.employee_master (
                employee_code, first_name, last_name, email_official,
                employee_status, date_of_birth, gender, company_id,
                created_at, created_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;

        postgresTemplate.batchUpdate(insertSql, new BatchPreparedStatementSetter() {

            @Override
            public void setValues(PreparedStatement ps, int i) throws SQLException {
                EmployeeMaster emp = employees.get(i);
                ps.setString(1, emp.getEmployeeCode());
                ps.setString(2, emp.getFirstName());
                ps.setString(3, emp.getLastName());
                ps.setString(4, emp.getEmailOfficial());
                ps.setString(5, emp.getEmployeeStatus().name());
                ps.setDate(6, Date.valueOf(emp.getDateOfBirth()));
                ps.setString(7, emp.getGender().name());
                ps.setLong(8, emp.getCompany().getCompanyId());
                ps.setTimestamp(9, Timestamp.from(emp.getCreatedAt()));
                ps.setString(10, emp.getCreatedBy());
            }

            @Override
            public int getBatchSize() {
                return employees.size();
            }
        });
    }
}
```

---

## Best Practices Checklist

### Development Phase Checklist

#### ✅ Database Configuration
- [ ] HikariCP connection pool properly sized (40 max for 500 users)
- [ ] PostgreSQL dialect configured correctly
- [ ] Snake case naming strategy implemented
- [ ] Connection properties optimized for PostgreSQL
- [ ] Read/write split configured for read replicas

#### ✅ Entity Design
- [ ] BIGINT primary keys used (not UUIDs)
- [ ] BaseEntity pattern implemented with audit fields
- [ ] Multi-tenant security context integrated
- [ ] Field-level encryption for sensitive data
- [ ] Optimistic locking with @Version
- [ ] Named entity graphs for GraphQL optimization

#### ✅ Repository Layer
- [ ] Cursor-based pagination for GraphQL
- [ ] Projection DTOs for list views
- [ ] Batch loading methods implemented
- [ ] Custom queries use covering indexes
- [ ] Full-text search with GIN indexes
- [ ] Specification pattern for dynamic filtering

#### ✅ Service Layer
- [ ] Multi-tenant security validation
- [ ] Batch processing for bulk operations
- [ ] Caching strategy implemented
- [ ] Transaction boundaries properly defined
- [ ] Error handling with resilience patterns
- [ ] Audit logging integrated

#### ✅ GraphQL Integration
- [ ] DataLoader for N+1 problem resolution
- [ ] Query complexity analysis implemented
- [ ] Field-level authorization
- [ ] Cursor-based pagination support
- [ ] Subscription scalability considered

#### ✅ Performance Optimization
- [ ] Database indexes aligned with query patterns
- [ ] Query execution plans analyzed
- [ ] Batch size optimization (50-1000 records)
- [ ] Connection pool monitoring
- [ ] Query timeout configuration
- [ ] Second-level cache configured

#### ✅ Security Implementation
- [ ] Row Level Security (RLS) policies active
- [ ] Field-level encryption for PII data
- [ ] Data masking for sensitive fields
- [ ] Audit trail for all data changes
- [ ] SQL injection prevention
- [ ] Access control validation

#### ✅ Monitoring and Observability
- [ ] Database performance metrics collection
- [ ] Slow query detection and alerting
- [ ] Connection pool metrics
- [ ] Custom business metrics
- [ ] Health check endpoints
- [ ] Application performance monitoring

#### ✅ Testing Strategy
- [ ] Repository layer unit tests
- [ ] Service layer integration tests
- [ ] Performance benchmarking tests
- [ ] Security access control tests
- [ ] Data migration validation tests
- [ ] Load testing for scalability

### Production Deployment Checklist

#### ✅ Infrastructure
- [ ] Database cluster with read replicas
- [ ] Connection pooling properly configured
- [ ] Backup and recovery procedures tested
- [ ] Monitoring and alerting system active
- [ ] SSL/TLS encryption enabled
- [ ] Network security configured

#### ✅ Configuration Management
- [ ] Environment-specific configurations
- [ ] Sensitive data externalized
- [ ] Database migration scripts validated
- [ ] Application properties optimized
- [ ] Logging configuration appropriate
- [ ] Health check endpoints configured

#### ✅ Security Hardening
- [ ] Database access restricted
- [ ] Application user privileges minimal
- [ ] Encryption keys properly managed
- [ ] Audit logging enabled
- [ ] GDPR compliance validated
- [ ] Security scanning completed

#### ✅ Performance Validation
- [ ] Load testing completed
- [ ] Query performance validated
- [ ] Database statistics updated
- [ ] Index usage analyzed
- [ ] Memory usage optimized
- [ ] Response time targets met

### Ongoing Maintenance Checklist

#### ✅ Weekly Tasks
- [ ] Monitor slow query reports
- [ ] Review connection pool metrics
- [ ] Check database growth trends
- [ ] Validate backup integrity
- [ ] Review security audit logs

#### ✅ Monthly Tasks
- [ ] Analyze query execution plans
- [ ] Update database statistics
- [ ] Review index usage patterns
- [ ] Performance trend analysis
- [ ] Capacity planning review

#### ✅ Quarterly Tasks
- [ ] Database performance tuning
- [ ] Security compliance review
- [ ] Disaster recovery testing
- [ ] Technology stack updates
- [ ] Documentation updates

---

**Document Ends**

**Next Steps for Development Team:**
1. **Review and Validate**: Technical team should review all guidelines and validate against current architecture
2. **Implementation Planning**: Create detailed implementation plan with timelines
3. **Environment Setup**: Configure development environment with all recommended settings
4. **Pilot Implementation**: Start with one module (Employee Management) as proof of concept
5. **Performance Testing**: Establish baseline performance metrics before full implementation
6. **Team Training**: Conduct training sessions on PostgreSQL best practices and GraphQL optimization

**Contact Information:**
For any clarifications or additional guidance on these database integration guidelines, please consult with the Database Architecture team.

---

**Document Version:** 1.0
**Last Updated:** 2025-01-14
**Next Review Date:** 2025-04-14