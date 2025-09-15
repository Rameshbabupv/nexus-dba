-- ======================================================================
-- NEXUS HRMS - Phase 9: Training & Development Sample Data
-- ======================================================================
-- Description: Comprehensive sample data for learning management and skill development
-- Version: 1.0
-- Created: 2024-09-14
-- Dependencies: Phase 9 Training Schema, Previous phases 1-8
-- ======================================================================

-- ======================================================================
-- 1. TRAINING CATEGORIES AND SKILL FRAMEWORK DATA
-- ======================================================================

-- Insert Training Categories
INSERT INTO training_category_master (category_id, category_code, category_name, category_description, parent_category_id, category_level, sort_order, company_id, created_by) VALUES
-- Main Categories
('11111111-1111-1111-1111-111111111101', 'TECH', 'Technical Training', 'All technology-related training programs', NULL, 1, 1, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111102', 'SOFT', 'Soft Skills Training', 'Communication, leadership, and interpersonal skills training', NULL, 1, 2, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111103', 'COMPLIANCE', 'Compliance Training', 'Mandatory compliance and regulatory training', NULL, 1, 3, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111104', 'LEADERSHIP', 'Leadership Development', 'Leadership and management training programs', NULL, 1, 4, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111105', 'PRODUCT', 'Product Training', 'Training on company products and solutions', NULL, 1, 5, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111106', 'ORIENTATION', 'Orientation & Onboarding', 'New employee orientation and onboarding programs', NULL, 1, 6, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Sub-categories for Technical Training
('11111111-1111-1111-1111-111111111111', 'TECH-DEV', 'Software Development', 'Programming and development training', '11111111-1111-1111-1111-111111111101', 2, 1, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111112', 'TECH-DB', 'Database Technologies', 'Database design and management training', '11111111-1111-1111-1111-111111111101', 2, 2, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111113', 'TECH-CLOUD', 'Cloud Technologies', 'Cloud computing and DevOps training', '11111111-1111-1111-1111-111111111101', 2, 3, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111114', 'TECH-QA', 'Quality Assurance', 'Testing and quality assurance training', '11111111-1111-1111-1111-111111111101', 2, 4, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Enhanced Skill Master Data
INSERT INTO skill_master (skill_id, skill_code, skill_name, skill_description, skill_category, skill_type, proficiency_levels, assessment_criteria, company_id, created_by) VALUES
-- Technical Skills
('22222222-2222-2222-2222-222222222201', 'REACT', 'React.js Development', 'Frontend development using React.js framework', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'Component creation, state management, hooks usage, performance optimization', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222202', 'SPRING_BOOT', 'Spring Boot Development', 'Backend development using Spring Boot framework', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'REST API development, dependency injection, data access, security implementation', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222203', 'POSTGRESQL', 'PostgreSQL Database', 'Database design and management using PostgreSQL', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'Schema design, query optimization, indexing, performance tuning', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222204', 'AWS_CLOUD', 'Amazon Web Services', 'Cloud infrastructure and services on AWS', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'Service configuration, architecture design, cost optimization, security best practices', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222205', 'DOCKER', 'Docker Containerization', 'Application containerization using Docker', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'Container creation, orchestration, deployment strategies, troubleshooting', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222206', 'SELENIUM', 'Selenium Test Automation', 'Automated testing using Selenium framework', 'TECHNICAL', 'HARD_SKILL', '["Beginner", "Intermediate", "Advanced", "Expert"]', 'Test script creation, framework design, CI/CD integration, reporting', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Soft Skills
('22222222-2222-2222-2222-222222222211', 'COMMUNICATION', 'Effective Communication', 'Verbal and written communication skills', 'BEHAVIORAL', 'SOFT_SKILL', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Clarity of expression, active listening, presentation skills, cross-cultural communication', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222212', 'TEAM_WORK', 'Team Collaboration', 'Working effectively in team environments', 'BEHAVIORAL', 'SOFT_SKILL', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Collaboration, conflict resolution, shared responsibility, team building', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222213', 'PROBLEM_SOLVING', 'Problem Solving', 'Analytical and creative problem-solving abilities', 'FUNCTIONAL', 'HYBRID', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Root cause analysis, creative thinking, solution evaluation, implementation planning', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222214', 'LEADERSHIP', 'Leadership Skills', 'Leading teams and driving organizational success', 'LEADERSHIP', 'SOFT_SKILL', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Vision setting, team motivation, decision making, strategic thinking', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222215', 'TIME_MANAGEMENT', 'Time Management', 'Efficient time and priority management', 'FUNCTIONAL', 'SOFT_SKILL', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Priority setting, planning, delegation, productivity optimization', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Domain Specific Skills
('22222222-2222-2222-2222-222222222221', 'HRMS_DOMAIN', 'HRMS Domain Knowledge', 'Understanding of HR management system functionalities', 'DOMAIN_SPECIFIC', 'HYBRID', '["Basic", "Intermediate", "Advanced", "Expert"]', 'HR processes, compliance requirements, system integration, user experience design', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('22222222-2222-2222-2222-222222222222', 'AGILE_SCRUM', 'Agile & Scrum Methodology', 'Agile project management and Scrum framework', 'FUNCTIONAL', 'HYBRID', '["Basic", "Intermediate", "Advanced", "Expert"]', 'Sprint planning, retrospectives, user story creation, velocity tracking', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Learning Paths
INSERT INTO learning_path_master (learning_path_id, path_code, path_name, path_description, category_id, target_audience, difficulty_level, estimated_duration_hours, prerequisites, learning_objectives, is_mandatory, is_sequential, completion_criteria, minimum_completion_percentage, minimum_score_required, validity_period_months, effective_from_date, company_id, created_by) VALUES
-- Technical Learning Paths
('33333333-3333-3333-3333-333333333301', 'LP-FULLSTACK', 'Full Stack Developer Path', 'Comprehensive learning path for full-stack development skills', '11111111-1111-1111-1111-111111111111', 'Software Engineers, Fresh Graduates', 'INTERMEDIATE', 120, 'Basic programming knowledge, Understanding of web technologies', 'Master React.js frontend and Spring Boot backend development, Build complete web applications, Understand modern development practices', false, true, 'ALL_COURSES', 100.00, 70.00, 12, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('33333333-3333-3333-3333-333333333302', 'LP-DEVOPS', 'DevOps Engineer Path', 'Complete DevOps skills development program', '11111111-1111-1111-1111-111111111113', 'System Administrators, Backend Developers', 'ADVANCED', 80, 'Linux system administration, Basic cloud knowledge', 'Master containerization, CI/CD pipelines, Infrastructure as Code, Monitoring and logging', false, true, 'PERCENTAGE_BASED', 90.00, 75.00, 12, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('33333333-3333-3333-3333-333333333303', 'LP-QA-AUTO', 'QA Automation Path', 'Test automation specialization program', '11111111-1111-1111-1111-111111111114', 'QA Engineers, Manual Testers', 'INTERMEDIATE', 60, 'Manual testing experience, Basic programming knowledge', 'Implement test automation frameworks, Design test strategies, Integrate testing in CI/CD pipelines', false, true, 'ALL_COURSES', 100.00, 70.00, 12, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Soft Skills and Leadership Paths
('33333333-3333-3333-3333-333333333304', 'LP-NEW-MANAGER', 'New Manager Development', 'Essential skills for new people managers', '11111111-1111-1111-1111-111111111104', 'Team Leads, New Managers', 'BEGINNER', 40, 'Team lead experience preferred', 'Develop leadership skills, Learn people management, Understand performance management, Master communication techniques', true, false, 'PERCENTAGE_BASED', 85.00, 70.00, 24, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('33333333-3333-3333-3333-333333333305', 'LP-ONBOARDING', 'Employee Onboarding Program', 'Comprehensive onboarding for new employees', '11111111-1111-1111-1111-111111111106', 'All New Employees', 'BEGINNER', 24, 'None', 'Understand company culture, Learn HRMS products, Complete compliance training, Build professional network', true, true, 'ALL_COURSES', 100.00, 80.00, 6, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- ======================================================================
-- 2. TRAINING PROVIDERS AND COURSES DATA
-- ======================================================================

-- Insert Training Providers
INSERT INTO training_provider_master (provider_id, provider_code, provider_name, provider_type, contact_person, email, phone, website, specializations, rating, is_preferred, company_id, created_by) VALUES
('44444444-4444-4444-4444-444444444401', 'INTERNAL', 'Internal Training Team', 'INTERNAL', 'Training Manager', 'training@systech-hrms.com', '+91-44-12345678', NULL, 'Technical training, Product training, Soft skills', 4.5, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('44444444-4444-4444-4444-444444444402', 'PLURALSIGHT', 'Pluralsight', 'ONLINE_PLATFORM', 'Account Manager', 'enterprise@pluralsight.com', '+1-888-368-6686', 'https://www.pluralsight.com', 'Technology training, Software development, Cloud computing', 4.7, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('44444444-4444-4444-4444-444444444403', 'UDEMY_BIZ', 'Udemy for Business', 'ONLINE_PLATFORM', 'Customer Success', 'business@udemy.com', '+1-415-702-3700', 'https://business.udemy.com', 'Technical skills, Business skills, Personal development', 4.3, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('44444444-4444-4444-4444-444444444404', 'AWS_TRAINING', 'AWS Training Center', 'EXTERNAL', 'Training Coordinator', 'training@aws.amazon.com', '+1-206-266-1000', 'https://aws.training', 'Cloud computing, AWS services, DevOps, Architecture', 4.8, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('44444444-4444-4444-4444-444444444405', 'LEADERSHIP_INST', 'Leadership Excellence Institute', 'EXTERNAL', 'Dr. Priya Sharma', 'info@leadershipexcellence.in', '+91-80-98765432', 'https://www.leadershipexcellence.in', 'Leadership development, Management training, Executive coaching', 4.6, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('44444444-4444-4444-4444-444444444406', 'TECH_INNOVATE', 'TechInnovate Solutions', 'CONSULTANT', 'Rajesh Kumar', 'contact@techinnovate.co.in', '+91-44-87654321', 'https://www.techinnovate.co.in', 'React.js, Spring Boot, Microservices, Test automation', 4.4, false, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Course Master Data
INSERT INTO course_master (
    course_id, course_code, course_title, course_description, short_description, category_id, provider_id,
    course_type, delivery_method, difficulty_level, duration_hours, duration_days, max_participants, min_participants,
    learning_objectives, course_outline, prerequisites, target_audience, materials_required,
    has_assessment, assessment_type, passing_score, max_attempts, provides_certificate, certificate_validity_months,
    cost_per_participant, effective_from_date, company_id, created_by
) VALUES
-- React.js Training Courses
('55555555-5555-5555-5555-555555555501', 'REACT-BASICS', 'React.js Fundamentals',
 'Comprehensive introduction to React.js development covering components, state management, and modern React features including hooks and context API.',
 'Learn React.js fundamentals and build dynamic web applications',
 '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444402',
 'ONLINE', 'INSTRUCTOR_LED', 'BEGINNER', 32.0, 8, 25, 5,
 'Understand React concepts and ecosystem, Create functional and class components, Manage component state and props, Implement React hooks, Build interactive UIs',
 'Day 1-2: React basics and JSX, Day 3-4: Components and props, Day 5-6: State and event handling, Day 7-8: Hooks and modern React patterns',
 'Basic JavaScript knowledge, HTML and CSS familiarity', 'Frontend developers, Web developers, Fresh graduates',
 'Computer with modern browser, Code editor, Node.js installed',
 true, 'MIXED', 70.00, 3, true, 12,
 25000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('55555555-5555-5555-5555-555555555502', 'REACT-ADV', 'Advanced React.js Development',
 'Advanced React.js concepts including performance optimization, testing, state management with Redux, and building scalable applications.',
 'Master advanced React.js patterns and build enterprise applications',
 '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444406',
 'BLENDED', 'INSTRUCTOR_LED', 'ADVANCED', 40.0, 10, 20, 5,
 'Implement advanced React patterns, Optimize application performance, Master state management with Redux, Write comprehensive tests, Build production-ready applications',
 'Day 1-2: Advanced component patterns, Day 3-4: Performance optimization, Day 5-6: Redux and state management, Day 7-8: Testing strategies, Day 9-10: Production deployment',
 'Solid React.js fundamentals, Experience with modern JavaScript ES6+', 'Experienced React developers, Senior frontend engineers',
 'Development environment with React setup, Testing frameworks installed',
 true, 'PROJECT', 75.00, 2, true, 12,
 45000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Spring Boot Training Courses
('55555555-5555-5555-5555-555555555503', 'SPRING-INTRO', 'Spring Boot Introduction',
 'Complete introduction to Spring Boot framework covering dependency injection, web development, data access, and security fundamentals.',
 'Learn Spring Boot and build robust backend applications',
 '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444402',
 'CLASSROOM', 'INSTRUCTOR_LED', 'INTERMEDIATE', 40.0, 10, 20, 6,
 'Understand Spring Boot architecture, Implement REST APIs, Configure data access with JPA, Implement basic security, Deploy Spring Boot applications',
 'Day 1-2: Spring Boot basics and auto-configuration, Day 3-4: Web development and REST APIs, Day 5-6: Data access with JPA, Day 7-8: Security fundamentals, Day 9-10: Testing and deployment',
 'Java programming experience, Understanding of web development concepts', 'Backend developers, Java developers, Full-stack developers',
 'Java development environment, IDE (IntelliJ/Eclipse), Database client',
 true, 'PRACTICAL', 70.00, 3, true, 12,
 35000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- DevOps and Cloud Training
('55555555-5555-5555-5555-555555555504', 'DOCKER-K8S', 'Docker and Kubernetes Mastery',
 'Comprehensive training on containerization with Docker and orchestration with Kubernetes for production deployments.',
 'Master containerization and orchestration technologies',
 '11111111-1111-1111-1111-111111111113', '44444444-4444-4444-4444-444444444404',
 'VIRTUAL_CLASSROOM', 'HANDS_ON', 'INTERMEDIATE', 32.0, 8, 15, 4,
 'Master Docker containerization, Implement Kubernetes orchestration, Design production-ready deployments, Implement monitoring and logging',
 'Day 1-2: Docker fundamentals and best practices, Day 3-4: Kubernetes basics and pod management, Day 5-6: Services and deployments, Day 7-8: Production patterns and monitoring',
 'Linux command line experience, Basic understanding of cloud concepts', 'DevOps engineers, System administrators, Backend developers',
 'Linux environment or VM, Docker installed, kubectl configured',
 true, 'HANDS_ON', 75.00, 2, true, 18,
 40000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('55555555-5555-5555-5555-555555555505', 'AWS-ESSENTIALS', 'AWS Cloud Essentials',
 'Introduction to Amazon Web Services covering core services, architecture patterns, and best practices for cloud deployment.',
 'Get started with AWS cloud services and architecture',
 '11111111-1111-1111-1111-111111111113', '44444444-4444-4444-4444-444444444404',
 'VIRTUAL_CLASSROOM', 'INSTRUCTOR_LED', 'BEGINNER', 24.0, 6, 25, 8,
 'Understand AWS core services, Design basic cloud architectures, Implement security best practices, Estimate costs and optimize spending',
 'Day 1-2: AWS overview and core services, Day 3-4: Compute and storage services, Day 5-6: Networking and security basics',
 'Basic understanding of cloud computing, Familiarity with web technologies', 'Developers, System administrators, IT professionals',
 'AWS account for hands-on labs, Computer with reliable internet',
 true, 'MIXED', 70.00, 3, true, 24,
 30000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- QA and Testing Courses
('55555555-5555-5555-5555-555555555506', 'SELENIUM-AUTO', 'Selenium Test Automation',
 'Complete guide to test automation using Selenium WebDriver, including framework design, best practices, and CI/CD integration.',
 'Automate web application testing with Selenium',
 '11111111-1111-1111-1111-111111111114', '44444444-4444-4444-4444-444444444406',
 'BLENDED', 'HANDS_ON', 'INTERMEDIATE', 32.0, 8, 18, 5,
 'Master Selenium WebDriver, Design test automation frameworks, Implement Page Object Model, Integrate with CI/CD pipelines, Generate test reports',
 'Day 1-2: Selenium basics and locators, Day 3-4: WebDriver advanced features, Day 5-6: Framework design patterns, Day 7-8: CI/CD integration and reporting',
 'Manual testing experience, Basic programming knowledge in Java or Python', 'QA engineers, Test automation engineers, Manual testers',
 'Programming IDE, Selenium WebDriver setup, Browser drivers',
 true, 'PRACTICAL', 75.00, 2, true, 12,
 28000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Soft Skills and Leadership Courses
('55555555-5555-5555-5555-555555555507', 'EFFECTIVE-COMM', 'Effective Communication Skills',
 'Enhance verbal and written communication skills for professional success, including presentation skills and cross-cultural communication.',
 'Master professional communication and presentation skills',
 '11111111-1111-1111-1111-111111111102', '44444444-4444-4444-4444-444444444405',
 'WORKSHOP', 'INSTRUCTOR_LED', 'BEGINNER', 16.0, 4, 30, 10,
 'Improve verbal and written communication, Master presentation techniques, Develop active listening skills, Learn cross-cultural communication',
 'Day 1: Communication fundamentals, Day 2: Presentation skills, Day 3: Written communication, Day 4: Cross-cultural and virtual communication',
 'None - suitable for all levels', 'All employees, Team leads, Client-facing roles',
 'Notebook for exercises, Access to presentation software',
 true, 'ASSIGNMENT', 70.00, 2, true, 24,
 15000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('55555555-5555-5555-5555-555555555508', 'LEADERSHIP-BASICS', 'Leadership Fundamentals',
 'Essential leadership skills for new managers and team leads, covering team building, motivation, and performance management.',
 'Develop essential leadership and people management skills',
 '11111111-1111-1111-1111-111111111104', '44444444-4444-4444-4444-444444444405',
 'WORKSHOP', 'INSTRUCTOR_LED', 'INTERMEDIATE', 24.0, 6, 25, 8,
 'Understand leadership styles, Master team building techniques, Learn performance management, Develop conflict resolution skills',
 'Day 1-2: Leadership fundamentals and styles, Day 3-4: Team building and motivation, Day 5-6: Performance management and feedback',
 'Team lead or supervisory experience preferred', 'Team leads, New managers, Senior individual contributors',
 'Leadership assessment tools, Case study materials',
 true, 'MIXED', 75.00, 2, true, 24,
 35000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

-- Compliance and Onboarding Courses
('55555555-5555-5555-5555-555555555509', 'COMPANY-INTRO', 'Company Introduction & Culture',
 'Comprehensive introduction to Systech HRMS, company culture, values, and organizational structure for new employees.',
 'Welcome to Systech HRMS - Learn our culture and values',
 '11111111-1111-1111-1111-111111111106', '44444444-4444-4444-4444-444444444401',
 'SEMINAR', 'INSTRUCTOR_LED', 'BEGINNER', 8.0, 2, 50, 5,
 'Understand company history and mission, Learn organizational structure, Embrace company values and culture, Meet key team members',
 'Day 1: Company overview and history, Values and culture, Organizational structure, Day 2: Product overview, Team introductions, Q&A session',
 'None - mandatory for all new employees', 'All new employees',
 'Welcome kit, Company handbook, Product demo access',
 true, 'QUIZ', 80.00, 2, true, 36,
 5000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('55555555-5555-5555-5555-555555555510', 'INFO-SECURITY', 'Information Security Awareness',
 'Essential cybersecurity training covering data protection, password security, phishing awareness, and compliance requirements.',
 'Protect company data and maintain security compliance',
 '11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444401',
 'WEBINAR', 'SELF_STUDY', 'BEGINNER', 4.0, 1, 100, 1,
 'Understand security threats, Learn password best practices, Recognize phishing attempts, Follow data protection protocols',
 'Module 1: Cybersecurity overview, Module 2: Password security, Module 3: Phishing and social engineering, Module 4: Data protection and compliance',
 'None - mandatory for all employees', 'All employees',
 'Computer with internet access, Company security guidelines',
 true, 'QUIZ', 85.00, 3, true, 12,
 2000.00, '2024-01-01', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- ======================================================================
-- 3. COURSE SKILL MAPPING DATA
-- ======================================================================

-- Map skills to courses
INSERT INTO course_skill_mapping (mapping_id, course_id, skill_id, skill_level_targeted, weightage_percentage, is_primary_skill) VALUES
-- React.js Fundamentals
('66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555501', '22222222-2222-2222-2222-222222222201', 'INTERMEDIATE', 100.00, true),
('66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555501', '22222222-2222-2222-2222-222222222213', 'INTERMEDIATE', 30.00, false),

-- Advanced React.js
('66666666-6666-6666-6666-666666666603', '55555555-5555-5555-5555-555555555502', '22222222-2222-2222-2222-222222222201', 'ADVANCED', 100.00, true),
('66666666-6666-6666-6666-666666666604', '55555555-5555-5555-5555-555555555502', '22222222-2222-2222-2222-222222222213', 'ADVANCED', 40.00, false),

-- Spring Boot Introduction
('66666666-6666-6666-6666-666666666605', '55555555-5555-5555-5555-555555555503', '22222222-2222-2222-2222-222222222202', 'INTERMEDIATE', 100.00, true),
('66666666-6666-6666-6666-666666666606', '55555555-5555-5555-5555-555555555503', '22222222-2222-2222-2222-222222222203', 'INTERMEDIATE', 50.00, false),

-- Docker and Kubernetes
('66666666-6666-6666-6666-666666666607', '55555555-5555-5555-5555-555555555504', '22222222-2222-2222-2222-222222222205', 'ADVANCED', 80.00, true),
('66666666-6666-6666-6666-666666666608', '55555555-5555-5555-5555-555555555504', '22222222-2222-2222-2222-222222222204', 'INTERMEDIATE', 60.00, false),

-- AWS Essentials
('66666666-6666-6666-6666-666666666609', '55555555-5555-5555-5555-555555555505', '22222222-2222-2222-2222-222222222204', 'INTERMEDIATE', 100.00, true),

-- Selenium Automation
('66666666-6666-6666-6666-666666666610', '55555555-5555-5555-5555-555555555506', '22222222-2222-2222-2222-222222222206', 'ADVANCED', 100.00, true),
('66666666-6666-6666-6666-666666666611', '55555555-5555-5555-5555-555555555506', '22222222-2222-2222-2222-222222222213', 'INTERMEDIATE', 30.00, false),

-- Communication Skills
('66666666-6666-6666-6666-666666666612', '55555555-5555-5555-5555-555555555507', '22222222-2222-2222-2222-222222222211', 'ADVANCED', 100.00, true),
('66666666-6666-6666-6666-666666666613', '55555555-5555-5555-5555-555555555507', '22222222-2222-2222-2222-222222222212', 'INTERMEDIATE', 40.00, false),

-- Leadership Fundamentals
('66666666-6666-6666-6666-666666666614', '55555555-5555-5555-5555-555555555508', '22222222-2222-2222-2222-222222222214', 'INTERMEDIATE', 100.00, true),
('66666666-6666-6666-6666-666666666615', '55555555-5555-5555-5555-555555555508', '22222222-2222-2222-2222-222222222211', 'INTERMEDIATE', 50.00, false),
('66666666-6666-6666-6666-666666666616', '55555555-5555-5555-5555-555555555508', '22222222-2222-2222-2222-222222222212', 'ADVANCED', 60.00, false);

-- ======================================================================
-- 4. LEARNING PATH COURSES MAPPING
-- ======================================================================

-- Map courses to learning paths
INSERT INTO learning_path_courses (path_course_id, learning_path_id, course_id, sequence_order, is_mandatory, weightage_percentage) VALUES
-- Full Stack Developer Path
('77777777-7777-7777-7777-777777777701', '33333333-3333-3333-3333-333333333301', '55555555-5555-5555-5555-555555555501', 1, true, 40.00),
('77777777-7777-7777-7777-777777777702', '33333333-3333-3333-3333-333333333301', '55555555-5555-5555-5555-555555555503', 2, true, 40.00),
('77777777-7777-7777-7777-777777777703', '33333333-3333-3333-3333-333333333301', '55555555-5555-5555-5555-555555555502', 3, false, 20.00),

-- DevOps Engineer Path
('77777777-7777-7777-7777-777777777704', '33333333-3333-3333-3333-333333333302', '55555555-5555-5555-5555-555555555505', 1, true, 30.00),
('77777777-7777-7777-7777-777777777705', '33333333-3333-3333-3333-333333333302', '55555555-5555-5555-5555-555555555504', 2, true, 70.00),

-- QA Automation Path
('77777777-7777-7777-7777-777777777706', '33333333-3333-3333-3333-333333333303', '55555555-5555-5555-5555-555555555506', 1, true, 100.00),

-- New Manager Development Path
('77777777-7777-7777-7777-777777777707', '33333333-3333-3333-3333-333333333304', '55555555-5555-5555-5555-555555555507', 1, true, 40.00),
('77777777-7777-7777-7777-777777777708', '33333333-3333-3333-3333-333333333304', '55555555-5555-5555-5555-555555555508', 2, true, 60.00),

-- Employee Onboarding Program
('77777777-7777-7777-7777-777777777709', '33333333-3333-3333-3333-333333333305', '55555555-5555-5555-5555-555555555509', 1, true, 60.00),
('77777777-7777-7777-7777-777777777710', '33333333-3333-3333-3333-333333333305', '55555555-5555-5555-5555-555555555510', 2, true, 40.00);

-- ======================================================================
-- 5. TRAINING SCHEDULE AND SESSION DATA
-- ======================================================================

-- Insert Training Schedules
INSERT INTO training_schedule (
    schedule_id, schedule_code, course_id, batch_name, instructor_employee_id,
    start_date, end_date, total_sessions, location_id, training_venue,
    max_participants, min_participants, status, registration_start_date,
    registration_end_date, enrollment_deadline, total_budget, cost_per_participant,
    company_id, created_by
) VALUES
-- October 2024 Schedules
('88888888-8888-8888-8888-888888888801', 'SCH-REACT-2024-001', '55555555-5555-5555-5555-555555555501', 'React Fundamentals - Batch Oct-1',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 '2024-10-07', '2024-10-18', 8,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'Training Room A, 2nd Floor',
 25, 5, 'OPEN_FOR_ENROLLMENT', '2024-09-20', '2024-10-04', '2024-10-04',
 625000.00, 25000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('88888888-8888-8888-8888-888888888802', 'SCH-SPRING-2024-001', '55555555-5555-5555-5555-555555555503', 'Spring Boot Introduction - Batch Oct-1',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'),
 '2024-10-14', '2024-10-25', 10,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'Training Room B, 2nd Floor',
 20, 6, 'OPEN_FOR_ENROLLMENT', '2024-09-25', '2024-10-11', '2024-10-11',
 700000.00, 35000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('88888888-8888-8888-8888-888888888803', 'SCH-DOCKER-2024-001', '55555555-5555-5555-5555-555555555504', 'Docker & Kubernetes - Batch Oct-1',
 NULL,
 '2024-10-21', '2024-11-01', 8,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'Virtual Training Room',
 15, 4, 'PLANNED', '2024-10-01', '2024-10-18', '2024-10-18',
 600000.00, 40000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('88888888-8888-8888-8888-888888888804', 'SCH-COMM-2024-001', '55555555-5555-5555-5555-555555555507', 'Communication Skills - Batch Oct-1',
 NULL,
 '2024-10-09', '2024-10-12', 4,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'Conference Room A, 3rd Floor',
 30, 10, 'OPEN_FOR_ENROLLMENT', '2024-09-15', '2024-10-06', '2024-10-06',
 450000.00, 15000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('88888888-8888-8888-8888-888888888805', 'SCH-ONBOARD-2024-001', '55555555-5555-5555-5555-555555555509', 'New Employee Orientation - Oct Batch',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP003'),
 '2024-10-01', '2024-10-02', 2,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'Orientation Hall, Ground Floor',
 50, 5, 'IN_PROGRESS', '2024-09-25', '2024-09-30', '2024-09-30',
 250000.00, 5000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- November 2024 Schedules
('88888888-8888-8888-8888-888888888806', 'SCH-LEADER-2024-001', '55555555-5555-5555-5555-555555555508', 'Leadership Fundamentals - Nov Batch',
 NULL,
 '2024-11-04', '2024-11-09', 6,
 (SELECT location_id FROM location_master WHERE location_name = 'Bangalore Branch'), 'Leadership Development Center',
 25, 8, 'PLANNED', '2024-10-10', '2024-11-01', '2024-11-01',
 875000.00, 35000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('88888888-8888-8888-8888-888888888807', 'SCH-SELENIUM-2024-001', '55555555-5555-5555-5555-555555555506', 'Selenium Automation - Nov Batch',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP004'),
 '2024-11-11', '2024-11-22', 8,
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'), 'QA Lab, 4th Floor',
 18, 5, 'PLANNED', '2024-10-15', '2024-11-08', '2024-11-08',
 504000.00, 28000.00,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 6. TRAINING ENROLLMENT DATA
-- ======================================================================

-- Insert Training Enrollments
INSERT INTO training_enrollment (
    enrollment_id, employee_id, schedule_id, learning_path_id, enrollment_date,
    enrollment_type, enrollment_reason, priority_level, approval_required,
    approved_by_employee_id, approval_date, approval_status, enrollment_status,
    training_cost, cost_center_id, company_id, created_by
) VALUES
-- React Fundamentals Enrollments
('99999999-9999-9999-9999-999999999901',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP005'), '88888888-8888-8888-8888-888888888801',
 '33333333-3333-3333-3333-333333333301', '2024-09-22',
 'DEVELOPMENT_PLAN', 'Skill development for full-stack role', 'HIGH', true,
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-09-23', 'APPROVED', 'ENROLLED',
 25000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('99999999-9999-9999-9999-999999999902',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP006'), '88888888-8888-8888-8888-888888888801',
 '33333333-3333-3333-3333-333333333301', '2024-09-23',
 'MANAGER_NOMINATED', 'Frontend skill enhancement', 'MEDIUM', true,
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-09-24', 'APPROVED', 'ENROLLED',
 25000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('99999999-9999-9999-9999-999999999903',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP007'), '88888888-8888-8888-8888-888888888801',
 NULL, '2024-09-24',
 'SELF_ENROLLED', 'Personal skill development', 'MEDIUM', false,
 NULL, NULL, 'APPROVED', 'ENROLLED',
 25000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Spring Boot Enrollments
('99999999-9999-9999-9999-999999999904',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP008'), '88888888-8888-8888-8888-888888888802',
 '33333333-3333-3333-3333-333333333301', '2024-09-26',
 'DEVELOPMENT_PLAN', 'Backend development skills', 'HIGH', true,
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-09-27', 'APPROVED', 'ENROLLED',
 35000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('99999999-9999-9999-9999-999999999905',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP009'), '88888888-8888-8888-8888-888888888802',
 NULL, '2024-09-28',
 'MANAGER_NOMINATED', 'Java Spring framework training', 'MEDIUM', true,
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'), '2024-09-29', 'APPROVED', 'ENROLLED',
 35000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Communication Skills Enrollments
('99999999-9999-9999-9999-999999999906',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP010'), '88888888-8888-8888-8888-888888888804',
 '33333333-3333-3333-3333-333333333304', '2024-09-20',
 'MANAGER_NOMINATED', 'Improve client communication', 'HIGH', true,
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-09-21', 'APPROVED', 'ENROLLED',
 15000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('99999999-9999-9999-9999-999999999907',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP011'), '88888888-8888-8888-8888-888888888804',
 NULL, '2024-09-21',
 'SELF_ENROLLED', 'Enhance presentation skills', 'MEDIUM', false,
 NULL, NULL, 'APPROVED', 'ENROLLED',
 15000.00, (SELECT department_id FROM department_master WHERE department_name = 'Human Resources'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- New Employee Orientation Enrollments
('99999999-9999-9999-9999-999999999908',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP012'), '88888888-8888-8888-8888-888888888805',
 '33333333-3333-3333-3333-333333333305', '2024-09-30',
 'MANDATORY', 'New employee onboarding', 'HIGH', false,
 NULL, NULL, 'APPROVED', 'IN_PROGRESS',
 5000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('99999999-9999-9999-9999-999999999909',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP013'), '88888888-8888-8888-8888-888888888805',
 '33333333-3333-3333-3333-333333333305', '2024-09-30',
 'MANDATORY', 'New employee onboarding', 'HIGH', false,
 NULL, NULL, 'APPROVED', 'IN_PROGRESS',
 5000.00, (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 7. CERTIFICATION MASTER AND EMPLOYEE CERTIFICATIONS
-- ======================================================================

-- Insert Certification Master Data
INSERT INTO certification_master (certification_id, certification_code, certification_name, certification_description, issuing_organization, certification_type, certification_category, validity_period_months, is_renewable, renewal_period_months, prerequisites, skills_covered, certification_level, certification_cost, is_active, company_id, created_by) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'AWS-SAA', 'AWS Solutions Architect Associate', 'Amazon Web Services certified solutions architect at associate level', 'Amazon Web Services', 'EXTERNAL', 'Cloud Computing', 36, true, 36, 'Basic cloud knowledge, 1 year hands-on AWS experience', 'AWS services, Architecture design, Security best practices', 'INTERMEDIATE', 15000.00, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab', 'ORACLE-JAVA', 'Oracle Certified Professional Java SE 11', 'Oracle certification for Java SE 11 development', 'Oracle Corporation', 'EXTERNAL', 'Programming', 0, false, NULL, 'Java programming experience', 'Java SE 11, Object-oriented programming, Collections, Streams', 'INTERMEDIATE', 25000.00, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac', 'REACT-CERT', 'React Developer Certification', 'Internal certification for React.js development proficiency', 'Systech HRMS', 'INTERNAL', 'Frontend Development', 24, true, 24, 'Completion of React fundamentals and advanced courses', 'React components, Hooks, State management, Testing', 'INTERMEDIATE', 0.00, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad', 'SPRING-CERT', 'Spring Boot Developer Certification', 'Internal certification for Spring Boot development skills', 'Systech HRMS', 'INTERNAL', 'Backend Development', 24, true, 24, 'Completion of Spring Boot introduction course', 'Spring Boot, REST APIs, JPA, Security', 'INTERMEDIATE', 0.00, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaae', 'LEADERSHIP-CERT', 'Leadership Excellence Certificate', 'Recognition for completing leadership development program', 'Systech HRMS', 'INTERNAL', 'Leadership', 36, true, 36, 'Management or team lead role, Completion of leadership courses', 'Leadership styles, Team building, Performance management, Communication', 'INTERMEDIATE', 0.00, true, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Employee Certifications
INSERT INTO employee_certification (employee_certification_id, employee_id, certification_id, achieved_date, certificate_number, score_obtained, grade_achieved, valid_from_date, valid_until_date, is_currently_valid, certificate_file_path, issuing_authority, training_enrollment_id, status, company_id) VALUES
-- Existing certifications for senior employees
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 '2023-06-15', 'AWS-SAA-2023-001234', 850.00, 'PASS', '2023-06-15', '2026-06-15', true,
 '/certificates/emp001_aws_saa.pdf', 'AWS Training Center', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbc',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab',
 '2022-03-20', 'OCP-JAVA11-2022-567890', 82.00, 'PASS', '2022-03-20', NULL, true,
 '/certificates/emp002_oracle_java.pdf', 'Oracle Testing Center', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbd',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP003'), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaae',
 '2023-12-10', 'LEAD-CERT-2023-001', 88.00, 'DISTINCTION', '2023-12-10', '2026-12-10', true,
 '/certificates/emp003_leadership.pdf', 'Systech Training Department', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'));

-- ======================================================================
-- 8. EMPLOYEE SKILL ASSESSMENTS
-- ======================================================================

-- Insert Current Skill Assessments for employees
INSERT INTO employee_skill_assessment (skill_assessment_id, employee_id, skill_id, assessment_date, assessment_type, assessed_by_employee_id, current_level, proficiency_score, assessment_method, evidence_description, assessment_notes, next_assessment_due_date, company_id) VALUES
-- Technical Skills Assessments
('cccccccc-cccc-cccc-cccc-cccccccccccc',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP005'), '22222222-2222-2222-2222-222222222201',
 '2024-09-15', 'MANAGER_ASSESSMENT', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 'BEGINNER', 4.5, 'Code Review and Project Evaluation', 'Basic React components created in recent projects', 'Shows potential, needs structured training', '2025-03-15',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('cccccccc-cccc-cccc-cccc-cccccccccccd',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP006'), '22222222-2222-2222-2222-222222222201',
 '2024-09-15', 'SELF_ASSESSMENT', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP006'),
 'INTERMEDIATE', 6.0, 'Self-evaluation with portfolio review', 'Built 2 React applications independently', 'Confident in basics, wants to learn advanced patterns', '2025-03-15',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('cccccccc-cccc-cccc-cccc-ccccccccccce',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP008'), '22222222-2222-2222-2222-222222222202',
 '2024-09-20', 'MANAGER_ASSESSMENT', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 'BEGINNER', 5.0, 'Technical Interview and Code Sample', 'Basic Java knowledge, new to Spring Boot', 'Good programming foundation, ready for Spring Boot training', '2025-03-20',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('cccccccc-cccc-cccc-cccc-ccccccccccff',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '22222222-2222-2222-2222-222222222204',
 '2024-09-10', 'FORMAL_TEST', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 'ADVANCED', 8.5, 'AWS Solutions Architect Certification', 'Certified AWS Solutions Architect with production experience', 'Expert level, mentoring others', '2025-09-10',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

-- Soft Skills Assessments
('cccccccc-cccc-cccc-cccc-cccccccccccg',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP010'), '22222222-2222-2222-2222-222222222211',
 '2024-09-18', 'PEER_ASSESSMENT', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 'INTERMEDIATE', 6.5, '360-degree feedback from team members', 'Good technical communication, needs improvement in client presentations', 'Recommended for communication skills training', '2025-03-18',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

('cccccccc-cccc-cccc-cccc-cccccccccccr',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP003'), '22222222-2222-2222-2222-222222222214',
 '2024-09-12', 'MANAGER_ASSESSMENT', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 'ADVANCED', 8.0, 'Leadership performance review and team feedback', 'Strong leadership skills demonstrated in project management', 'Natural leader, ready for senior management roles', '2025-03-12',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'));

-- ======================================================================
-- 9. SKILL DEVELOPMENT PLANS
-- ======================================================================

-- Insert Skill Development Plans
INSERT INTO skill_development_plan (development_plan_id, employee_id, skill_id, current_level, target_level, current_score, target_score, plan_start_date, target_completion_date, development_priority, development_methods, recommended_courses, learning_path_id, progress_percentage, status, created_by_employee_id, approved_by_employee_id, next_review_date, company_id) VALUES
-- React.js Development Plan for EMP005
('dddddddd-dddd-dddd-dddd-dddddddddddd',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP005'), '22222222-2222-2222-2222-222222222201',
 'BEGINNER', 'INTERMEDIATE', 4.5, 7.0, '2024-10-01', '2024-12-31', 'HIGH',
 'Formal training, Hands-on projects, Mentoring', 'React Fundamentals, Advanced React patterns',
 '33333333-3333-3333-3333-333333333301', 15.00, 'ACTIVE',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP005'), (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-11-01',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

-- Spring Boot Development Plan for EMP008
('dddddddd-dddd-dddd-dddd-ddddddddddde',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP008'), '22222222-2222-2222-2222-222222222202',
 'BEGINNER', 'INTERMEDIATE', 5.0, 7.5, '2024-10-14', '2025-01-31', 'HIGH',
 'Formal training, Practice projects, Code reviews', 'Spring Boot Introduction, REST API development',
 '33333333-3333-3333-3333-333333333301', 10.00, 'ACTIVE',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP008'), (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-11-15',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),

-- Communication Skills Development Plan for EMP010
('dddddddd-dddd-dddd-dddd-dddddddddddf',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP010'), '22222222-2222-2222-2222-222222222211',
 'INTERMEDIATE', 'ADVANCED', 6.5, 8.0, '2024-10-09', '2024-12-15', 'MEDIUM',
 'Communication workshop, Presentation practice, Client interaction training', 'Effective Communication Skills, Presentation mastery',
 '33333333-3333-3333-3333-333333333304', 20.00, 'ACTIVE',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP010'), (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'), '2024-11-09',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'));

-- ======================================================================
-- TRAINING & DEVELOPMENT SAMPLE DATA COMPLETED SUCCESSFULLY
-- ======================================================================

-- Verification Queries (Commented out for production use)
/*
-- Summary of training data created:
SELECT 'Training Categories' as entity, COUNT(*) as count FROM training_category_master
UNION ALL
SELECT 'Skills', COUNT(*) FROM skill_master
UNION ALL
SELECT 'Learning Paths', COUNT(*) FROM learning_path_master
UNION ALL
SELECT 'Training Providers', COUNT(*) FROM training_provider_master
UNION ALL
SELECT 'Courses', COUNT(*) FROM course_master
UNION ALL
SELECT 'Training Schedules', COUNT(*) FROM training_schedule
UNION ALL
SELECT 'Training Enrollments', COUNT(*) FROM training_enrollment
UNION ALL
SELECT 'Certifications', COUNT(*) FROM certification_master
UNION ALL
SELECT 'Employee Certifications', COUNT(*) FROM employee_certification
UNION ALL
SELECT 'Skill Assessments', COUNT(*) FROM employee_skill_assessment
UNION ALL
SELECT 'Development Plans', COUNT(*) FROM skill_development_plan;

-- Training effectiveness summary:
SELECT
    cm.course_title,
    COUNT(te.enrollment_id) as total_enrollments,
    COUNT(CASE WHEN te.enrollment_status = 'COMPLETED' THEN 1 END) as completed,
    COUNT(CASE WHEN te.enrollment_status = 'IN_PROGRESS' THEN 1 END) as in_progress,
    COUNT(CASE WHEN te.enrollment_status = 'ENROLLED' THEN 1 END) as enrolled,
    AVG(te.final_score) as avg_score
FROM course_master cm
LEFT JOIN training_schedule ts ON cm.course_id = ts.course_id
LEFT JOIN training_enrollment te ON ts.schedule_id = te.schedule_id
GROUP BY cm.course_id, cm.course_title
ORDER BY total_enrollments DESC;
*/