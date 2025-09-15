-- ======================================================================
-- NEXUS HRMS - Phase 8: Recruitment Management Sample Data
-- ======================================================================
-- Description: Comprehensive sample data for recruitment and hiring system
-- Version: 1.0
-- Created: 2024-09-14
-- Dependencies: Phase 8 Recruitment Schema, Previous phases 1-7
-- ======================================================================

-- ======================================================================
-- 1. JOB CATEGORY AND REQUISITION SAMPLE DATA
-- ======================================================================

-- Insert Job Categories
INSERT INTO job_category_master (job_category_id, category_code, category_name, category_description, company_id, created_by) VALUES
('11111111-1111-1111-1111-111111111101', 'IT-DEV', 'Software Development', 'Software developers, programmers, and development roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111102', 'IT-QA', 'Quality Assurance', 'Software testing and quality assurance roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111103', 'IT-DEVOPS', 'DevOps & Infrastructure', 'DevOps engineers, system administrators, infrastructure roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111104', 'IT-DATA', 'Data & Analytics', 'Data scientists, analysts, and data engineering roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111105', 'IT-MGMT', 'Technology Management', 'Technical leadership and management roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111106', 'HR', 'Human Resources', 'HR specialists, recruiters, and people operations', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111107', 'FIN', 'Finance & Accounting', 'Financial analysts, accountants, and finance roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111108', 'SALES', 'Sales & Marketing', 'Sales representatives, marketing specialists', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111109', 'OPS', 'Operations', 'Business operations and administrative roles', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('11111111-1111-1111-1111-111111111110', 'INTERN', 'Internships', 'Internship and trainee positions', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Job Requisitions
INSERT INTO job_requisition (
    requisition_id, job_title, job_category_id, department_id, designation_id, location_id,
    reporting_to_employee_id, no_of_positions, employment_type, job_level, priority_level,
    min_salary, max_salary, budget_approved, budget_amount, target_start_date, expected_closure_date,
    job_summary, key_responsibilities, required_qualifications, preferred_qualifications,
    required_experience_years, required_skills, status, approval_status, approved_by, approved_date,
    company_id, created_by
) VALUES
-- Senior Full Stack Developer
('22222222-2222-2222-2222-222222222201',
 'Senior Full Stack Developer',
 '11111111-1111-1111-1111-111111111101',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'Senior Software Engineer'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 2, 'PERMANENT', 'SENIOR', 'HIGH',
 1200000.00, 1800000.00, true, 3600000.00,
 '2024-10-01', '2024-09-30',
 'We are seeking experienced Full Stack Developers to join our growing development team and work on cutting-edge HRMS solutions.',
 'Develop scalable web applications using React and Spring Boot, Design and implement RESTful APIs, Collaborate with cross-functional teams, Mentor junior developers, Code review and quality assurance',
 'Bachelor''s degree in Computer Science or related field, 5+ years of full stack development experience, Strong proficiency in React.js and Java Spring Boot, Experience with PostgreSQL and MongoDB',
 'Experience with microservices architecture, Knowledge of DevOps practices, Previous HRMS or enterprise software experience, AWS/Cloud platform experience',
 5, 'React.js, Spring Boot, PostgreSQL, MongoDB, REST APIs, Git, Agile methodologies',
 'APPROVED', 'APPROVED',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 '2024-09-10 10:00:00',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- React.js Developer
('22222222-2222-2222-2222-222222222202',
 'React.js Developer',
 '11111111-1111-1111-1111-111111111101',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'Software Engineer'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'),
 3, 'PERMANENT', 'JUNIOR', 'MEDIUM',
 600000.00, 1000000.00, true, 3000000.00,
 '2024-10-15', '2024-10-15',
 'Looking for talented React.js developers to build modern, responsive user interfaces for our NEXUS HRMS platform.',
 'Develop responsive web applications using React.js, Implement Material UI components, Work with GraphQL APIs, Write unit and integration tests, Participate in agile development processes',
 'Bachelor''s degree in Computer Science, 2+ years of React.js development experience, Strong JavaScript and TypeScript skills, Experience with HTML5, CSS3, and responsive design',
 'Experience with Material UI, GraphQL experience, Knowledge of testing frameworks (Jest, React Testing Library), Understanding of modern build tools',
 2, 'React.js, TypeScript, Material UI, GraphQL, Jest, Git, HTML5, CSS3',
 'PUBLISHED', 'APPROVED',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 '2024-09-12 14:30:00',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- QA Automation Engineer
('22222222-2222-2222-2222-222222222203',
 'QA Automation Engineer',
 '11111111-1111-1111-1111-111111111102',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'Quality Analyst'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP003'),
 2, 'PERMANENT', 'SENIOR', 'HIGH',
 800000.00, 1300000.00, true, 2600000.00,
 '2024-09-25', '2024-10-05',
 'Seeking experienced QA Automation Engineers to ensure the quality and reliability of our HRMS platform through comprehensive testing strategies.',
 'Design and implement automated test frameworks, Create and maintain test scripts, Perform API testing, Collaborate with development teams, Conduct performance testing',
 'Bachelor''s degree in Computer Science or related field, 4+ years of QA automation experience, Strong knowledge of Selenium WebDriver, Experience with REST API testing',
 'Experience with Cypress or Playwright, Knowledge of performance testing tools, CI/CD pipeline experience, HRMS or enterprise software testing experience',
 4, 'Selenium WebDriver, TestNG, REST API Testing, Java, Python, Jenkins, Git',
 'APPROVED', 'APPROVED',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 '2024-09-11 11:15:00',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- DevOps Engineer
('22222222-2222-2222-2222-222222222204',
 'DevOps Engineer',
 '11111111-1111-1111-1111-111111111103',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'DevOps Engineer'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 1, 'PERMANENT', 'SENIOR', 'URGENT',
 1000000.00, 1600000.00, true, 1600000.00,
 '2024-09-20', '2024-09-25',
 'We need a skilled DevOps Engineer to manage our cloud infrastructure and implement robust CI/CD pipelines for our NEXUS platform.',
 'Design and maintain CI/CD pipelines, Manage cloud infrastructure on AWS, Implement containerization with Docker and Kubernetes, Monitor system performance, Ensure security best practices',
 'Bachelor''s degree in Computer Science, 3+ years of DevOps experience, Strong AWS knowledge, Experience with Docker and Kubernetes, Jenkins/GitLab CI experience',
 'Terraform or CloudFormation experience, Monitoring tools experience (Prometheus, Grafana), Security compliance knowledge, Previous experience with microservices deployment',
 3, 'AWS, Docker, Kubernetes, Jenkins, Terraform, Linux, Git, Monitoring tools',
 'PUBLISHED', 'APPROVED',
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 '2024-09-08 09:30:00',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- HR Business Partner
('22222222-2222-2222-2222-222222222205',
 'HR Business Partner',
 '11111111-1111-1111-1111-111111111106',
 (SELECT department_id FROM department_master WHERE department_name = 'Human Resources'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'HR Manager'),
 (SELECT location_id FROM location_master WHERE location_name = 'Bangalore Branch'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'),
 1, 'PERMANENT', 'MANAGER', 'MEDIUM',
 900000.00, 1400000.00, true, 1400000.00,
 '2024-10-10', '2024-11-01',
 'Looking for an experienced HR Business Partner to support our Bangalore operations and drive strategic HR initiatives.',
 'Partner with business leaders on HR strategy, Manage employee relations and performance issues, Drive talent acquisition and retention programs, Implement HR policies and procedures, Support organizational development',
 'MBA in HR or related field, 6+ years of HR experience, Strong knowledge of employment law, Experience in IT industry preferred, Excellent communication skills',
 'SHRM or HRCI certification, Experience with HRMS systems, Change management experience, Previous business partner role experience',
 6, 'Strategic HR planning, Employee relations, Performance management, Employment law, HRMS systems',
 'PENDING_APPROVAL', 'PENDING',
 NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Data Scientist
('22222222-2222-2222-2222-222222222206',
 'Data Scientist',
 '11111111-1111-1111-1111-111111111104',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'Data Scientist'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 1, 'PERMANENT', 'SENIOR', 'HIGH',
 1100000.00, 1700000.00, true, 1700000.00,
 '2024-10-05', '2024-10-20',
 'Seeking a talented Data Scientist to develop analytics and machine learning capabilities for our NEXUS HRMS platform.',
 'Develop predictive models for HR analytics, Analyze employee data for insights, Create data visualization dashboards, Implement machine learning algorithms, Collaborate with product teams',
 'Master''s degree in Data Science or related field, 4+ years of data science experience, Strong Python and R skills, Experience with machine learning frameworks, SQL expertise',
 'PhD in quantitative field, Experience with cloud ML platforms, Knowledge of HR analytics, Experience with real-time data processing, Deep learning experience',
 4, 'Python, R, SQL, TensorFlow, Scikit-learn, Pandas, Tableau, Machine Learning, Statistics',
 'DRAFT', 'PENDING',
 NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'),
 (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 2. JOB POSTING CHANNELS AND POSTINGS
-- ======================================================================

-- Insert Job Posting Channels
INSERT INTO job_posting_channel (channel_id, channel_name, channel_type, channel_url, cost_per_posting, company_id, created_by) VALUES
('33333333-3333-3333-3333-333333333301', 'Naukri.com', 'JOB_BOARD', 'https://www.naukri.com', 15000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333302', 'LinkedIn Jobs', 'JOB_BOARD', 'https://www.linkedin.com/jobs', 20000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333303', 'Indeed', 'JOB_BOARD', 'https://www.indeed.com', 12000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333304', 'Company Website', 'INTERNAL', 'https://www.systech-hrms.com/careers', 0.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333305', 'Employee Referral', 'REFERRAL', NULL, 25000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333306', 'AngelList', 'JOB_BOARD', 'https://angel.co', 10000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333307', 'Glassdoor', 'JOB_BOARD', 'https://www.glassdoor.com', 18000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin')),
('33333333-3333-3333-3333-333333333308', 'Facebook Jobs', 'SOCIAL_MEDIA', 'https://www.facebook.com/jobs', 5000.00, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'admin'));

-- Insert Job Postings
INSERT INTO job_posting (posting_id, requisition_id, channel_id, posting_title, posting_description, posted_date, expiry_date, posting_cost, total_views, total_applications, status, company_id, created_by) VALUES
-- Senior Full Stack Developer postings
('44444444-4444-4444-4444-444444444401', '22222222-2222-2222-2222-222222222201', '33333333-3333-3333-3333-333333333301', 'Senior Full Stack Developer - HRMS Platform', 'Join our team to build next-generation HRMS solutions using React and Spring Boot', '2024-09-12', '2024-10-12', 15000.00, 245, 18, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444402', '22222222-2222-2222-2222-222222222201', '33333333-3333-3333-3333-333333333302', 'Senior Full Stack Developer', 'Exciting opportunity to work on cutting-edge HRMS technology with modern tech stack', '2024-09-12', '2024-10-12', 20000.00, 189, 12, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444403', '22222222-2222-2222-2222-222222222201', '33333333-3333-3333-3333-333333333304', 'Senior Full Stack Developer', 'Internal posting for senior development role', '2024-09-10', '2024-10-10', 0.00, 67, 5, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- React.js Developer postings
('44444444-4444-4444-4444-444444444404', '22222222-2222-2222-2222-222222222202', '33333333-3333-3333-3333-333333333301', 'React.js Developer - Frontend Specialist', 'Build modern, responsive UIs for enterprise HRMS platform', '2024-09-14', '2024-10-14', 15000.00, 156, 24, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444405', '22222222-2222-2222-2222-222222222202', '33333333-3333-3333-3333-333333333302', 'React.js Frontend Developer', 'Work with latest React technologies in a growing tech company', '2024-09-14', '2024-10-14', 20000.00, 203, 31, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444406', '22222222-2222-2222-2222-222222222202', '33333333-3333-3333-3333-333333333306', 'React.js Developer', 'Join our startup-like environment in building innovative HRMS solutions', '2024-09-14', '2024-10-14', 10000.00, 89, 15, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- QA Automation Engineer postings
('44444444-4444-4444-4444-444444444407', '22222222-2222-2222-2222-222222222203', '33333333-3333-3333-3333-333333333301', 'QA Automation Engineer - Enterprise Testing', 'Lead automation testing efforts for mission-critical HRMS platform', '2024-09-13', '2024-10-13', 15000.00, 134, 16, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444408', '22222222-2222-2222-2222-222222222203', '33333333-3333-3333-3333-333333333302', 'Senior QA Automation Engineer', 'Drive quality excellence in fast-paced development environment', '2024-09-13', '2024-10-13', 20000.00, 98, 11, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- DevOps Engineer postings
('44444444-4444-4444-4444-444444444409', '22222222-2222-2222-2222-222222222204', '33333333-3333-3333-3333-333333333301', 'DevOps Engineer - Cloud Infrastructure', 'Urgent requirement for experienced DevOps engineer', '2024-09-09', '2024-10-09', 15000.00, 178, 22, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444410', '22222222-2222-2222-2222-222222222204', '33333333-3333-3333-3333-333333333302', 'DevOps Engineer - AWS Specialist', 'Shape our cloud infrastructure and deployment strategies', '2024-09-09', '2024-10-09', 20000.00, 145, 19, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),
('44444444-4444-4444-4444-444444444411', '22222222-2222-2222-2222-222222222204', '33333333-3333-3333-3333-333333333303', 'Senior DevOps Engineer', 'Lead DevOps transformation in growing technology company', '2024-09-09', '2024-10-09', 12000.00, 112, 14, 'ACTIVE', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 3. CANDIDATE SOURCES AND CANDIDATES
-- ======================================================================

-- Insert Candidate Sources
INSERT INTO candidate_source (source_id, source_name, source_type, source_description, company_id) VALUES
('55555555-5555-5555-5555-555555555501', 'Naukri.com Applications', 'JOB_BOARD', 'Candidates applying through Naukri job board', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555502', 'LinkedIn Applications', 'JOB_BOARD', 'Candidates applying through LinkedIn', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555503', 'Employee Referrals', 'REFERRAL', 'Candidates referred by current employees', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555504', 'Direct Applications', 'DIRECT', 'Candidates applying directly through company website', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555505', 'Recruitment Agency', 'AGENCY', 'Candidates sourced through recruitment agencies', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555506', 'Indeed Applications', 'JOB_BOARD', 'Candidates applying through Indeed', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555507', 'Campus Recruitment', 'CAMPUS', 'Fresh graduates from campus hiring drives', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('55555555-5555-5555-5555-555555555508', 'AngelList', 'JOB_BOARD', 'Startup-focused candidates from AngelList', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'));

-- Insert Candidate Master Data
INSERT INTO candidate_master (
    candidate_id, candidate_code, first_name, middle_name, last_name,
    email_primary, email_secondary, phone_primary, phone_secondary,
    current_address, permanent_address, city, state, country, pincode,
    current_company, current_designation, current_salary, expected_salary,
    total_experience_years, relevant_experience_years, notice_period_days,
    date_of_birth, gender, nationality, marital_status,
    resume_file_path, portfolio_url, linkedin_profile,
    source_id, referrer_employee_id, overall_status,
    company_id, created_by
) VALUES
-- Senior Full Stack Developer Candidates
('66666666-6666-6666-6666-666666666601', 'CAND001', 'Arjun', 'Kumar', 'Sharma',
 'arjun.sharma@email.com', 'arjun.k.sharma@gmail.com', '+91-9876543210', '+91-9876543211',
 '123 Tech Park, Whitefield, Bangalore 560066', '456 MG Road, Bangalore 560001', 'Bangalore', 'Karnataka', 'India', '560066',
 'TechCorp Solutions', 'Senior Software Engineer', 1650000.00, 1800000.00,
 6.5, 5.8, 60,
 '1990-05-15', 'MALE', 'Indian', 'MARRIED',
 '/resumes/arjun_sharma_resume.pdf', 'https://portfolio.arjunsharma.dev', 'https://linkedin.com/in/arjunsharma',
 '55555555-5555-5555-5555-555555555501', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666602', 'CAND002', 'Priya', NULL, 'Patel',
 'priya.patel@techmail.com', NULL, '+91-9876543220', NULL,
 '789 IT Corridor, Chennai 600032', '789 IT Corridor, Chennai 600032', 'Chennai', 'Tamil Nadu', 'India', '600032',
 'InnovateTech Pvt Ltd', 'Full Stack Developer', 1450000.00, 1700000.00,
 5.2, 4.9, 45,
 '1992-08-22', 'FEMALE', 'Indian', 'SINGLE',
 '/resumes/priya_patel_resume.pdf', NULL, 'https://linkedin.com/in/priyapatel92',
 '55555555-5555-5555-5555-555555555502', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666603', 'CAND003', 'Rahul', 'Singh', 'Chauhan',
 'rahul.chauhan@devworld.com', 'rahulsingh.dev@gmail.com', '+91-9876543230', '+91-9876543231',
 '321 Software City, Pune 411014', '654 Civil Lines, Lucknow 226001', 'Pune', 'Maharashtra', 'India', '411014',
 'DevWorld Technologies', 'Lead Developer', 1750000.00, 1900000.00,
 7.1, 6.5, 90,
 '1988-12-10', 'MALE', 'Indian', 'MARRIED',
 '/resumes/rahul_chauhan_resume.pdf', 'https://github.com/rahulchauhan', 'https://linkedin.com/in/rahulsinghchauhan',
 '55555555-5555-5555-5555-555555555503', (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP002'), 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- React.js Developer Candidates
('66666666-6666-6666-6666-666666666604', 'CAND004', 'Sneha', NULL, 'Reddy',
 'sneha.reddy@frontend.dev', NULL, '+91-9876543240', NULL,
 '159 Hi-Tech City, Hyderabad 500081', '753 Jubilee Hills, Hyderabad 500033', 'Hyderabad', 'Telangana', 'India', '500081',
 'FrontendMasters Inc', 'React Developer', 850000.00, 1100000.00,
 3.5, 3.2, 30,
 '1994-03-18', 'FEMALE', 'Indian', 'SINGLE',
 '/resumes/sneha_reddy_resume.pdf', 'https://sneha-portfolio.netlify.app', 'https://linkedin.com/in/snehareddy94',
 '55555555-5555-5555-5555-555555555501', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666605', 'CAND005', 'Vikram', 'Kumar', 'Joshi',
 'vikram.joshi@reactdev.com', 'vikramjoshi.coder@gmail.com', '+91-9876543250', '+91-9876543251',
 '246 Sector 5, Salt Lake, Kolkata 700091', '135 Park Street, Kolkata 700016', 'Kolkata', 'West Bengal', 'India', '700091',
 'ReactMasters Solutions', 'Frontend Developer', 720000.00, 950000.00,
 2.8, 2.5, 30,
 '1995-07-25', 'MALE', 'Indian', 'SINGLE',
 '/resumes/vikram_joshi_resume.pdf', 'https://vikramjoshi.dev', 'https://linkedin.com/in/vikramjoshi95',
 '55555555-5555-5555-5555-555555555502', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666606', 'CAND006', 'Anita', NULL, 'Gupta',
 'anita.gupta@webdev.io', NULL, '+91-9876543260', NULL,
 '369 Cyber City, Gurgaon 122002', '741 Green Park, New Delhi 110016', 'Gurgaon', 'Haryana', 'India', '122002',
 'WebDev Solutions', 'UI Developer', 680000.00, 900000.00,
 2.2, 2.0, 15,
 '1996-11-12', 'FEMALE', 'Indian', 'SINGLE',
 '/resumes/anita_gupta_resume.pdf', NULL, 'https://linkedin.com/in/anitaguptadev',
 '55555555-5555-5555-5555-555555555506', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- QA Automation Engineer Candidates
('66666666-6666-6666-6666-666666666607', 'CAND007', 'Suresh', 'Babu', 'Nair',
 'suresh.nair@qaexpert.com', 'sureshbabu.qa@gmail.com', '+91-9876543270', '+91-9876543271',
 '852 Technopark, Thiruvananthapuram 695581', '963 MG Road, Kochi 682035', 'Thiruvananthapuram', 'Kerala', 'India', '695581',
 'QualityFirst Technologies', 'Senior QA Engineer', 1180000.00, 1350000.00,
 5.3, 4.8, 45,
 '1989-04-20', 'MALE', 'Indian', 'MARRIED',
 '/resumes/suresh_nair_resume.pdf', NULL, 'https://linkedin.com/in/sureshnairqa',
 '55555555-5555-5555-5555-555555555501', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666608', 'CAND008', 'Meera', NULL, 'Shah',
 'meera.shah@automation.dev', NULL, '+91-9876543280', NULL,
 '147 SG Highway, Ahmedabad 380015', '258 CG Road, Ahmedabad 380009', 'Ahmedabad', 'Gujarat', 'India', '380015',
 'AutomationPro Systems', 'Test Automation Engineer', 1050000.00, 1250000.00,
 4.2, 3.9, 60,
 '1991-09-14', 'FEMALE', 'Indian', 'MARRIED',
 '/resumes/meera_shah_resume.pdf', NULL, 'https://linkedin.com/in/meerashah91',
 '55555555-5555-5555-5555-555555555502', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- DevOps Engineer Candidates
('66666666-6666-6666-6666-666666666609', 'CAND009', 'Karthik', NULL, 'Subramanian',
 'karthik.subramanian@devops.tech', 'karthiks.cloud@gmail.com', '+91-9876543290', '+91-9876543291',
 '357 OMR, Chennai 600096', '468 T Nagar, Chennai 600017', 'Chennai', 'Tamil Nadu', 'India', '600096',
 'CloudOps Technologies', 'DevOps Engineer', 1320000.00, 1550000.00,
 4.8, 4.5, 45,
 '1990-01-28', 'MALE', 'Indian', 'SINGLE',
 '/resumes/karthik_subramanian_resume.pdf', 'https://karthik-devops.github.io', 'https://linkedin.com/in/karthiksubramanian90',
 '55555555-5555-5555-5555-555555555501', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666610', 'CAND010', 'Deepak', 'Kumar', 'Agarwal',
 'deepak.agarwal@cloudeng.com', NULL, '+91-9876543300', NULL,
 '579 Sector 62, Noida 201309', '680 CP, New Delhi 110001', 'Noida', 'Uttar Pradesh', 'India', '201309',
 'CloudEngineers Pvt Ltd', 'Senior DevOps Engineer', 1480000.00, 1650000.00,
 5.7, 5.2, 60,
 '1987-06-05', 'MALE', 'Indian', 'MARRIED',
 '/resumes/deepak_agarwal_resume.pdf', NULL, 'https://linkedin.com/in/deepakagarwal87',
 '55555555-5555-5555-5555-555555555505', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Additional candidates for higher application numbers
('66666666-6666-6666-6666-666666666611', 'CAND011', 'Ravi', NULL, 'Krishnan',
 'ravi.krishnan@techie.com', NULL, '+91-9876543310', NULL,
 'Plot 42, HITEC City, Hyderabad 500081', 'Plot 42, HITEC City, Hyderabad 500081', 'Hyderabad', 'Telangana', 'India', '500081',
 'TechieWorld Solutions', 'Software Engineer', 950000.00, 1200000.00,
 3.8, 3.5, 30,
 '1993-02-14', 'MALE', 'Indian', 'SINGLE',
 '/resumes/ravi_krishnan_resume.pdf', NULL, 'https://linkedin.com/in/ravikrishnan93',
 '55555555-5555-5555-5555-555555555504', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('66666666-6666-6666-6666-666666666612', 'CAND012', 'Lakshmi', NULL, 'Iyer',
 'lakshmi.iyer@codecraft.in', NULL, '+91-9876543320', NULL,
 'Electronic City Phase 1, Bangalore 560100', 'Jayanagar 4th Block, Bangalore 560011', 'Bangalore', 'Karnataka', 'India', '560100',
 'CodeCraft Technologies', 'Frontend Specialist', 780000.00, 1000000.00,
 2.5, 2.3, 30,
 '1995-10-30', 'FEMALE', 'Indian', 'SINGLE',
 '/resumes/lakshmi_iyer_resume.pdf', 'https://lakshmi-dev.netlify.app', 'https://linkedin.com/in/lakshmiiyer95',
 '55555555-5555-5555-5555-555555555508', NULL, 'ACTIVE',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 4. CANDIDATE EDUCATION DATA
-- ======================================================================

-- Insert Education records for all candidates
INSERT INTO candidate_education (education_id, candidate_id, degree_type, degree_name, specialization, institution_name, university_name, completion_year, percentage_or_gpa, grade, is_highest_qualification) VALUES
-- Arjun Sharma (CAND001)
('77777777-7777-7777-7777-777777777701', '66666666-6666-6666-6666-666666666601', 'BACHELOR', 'Bachelor of Technology', 'Computer Science and Engineering', 'National Institute of Technology', 'NIT Karnataka', 2013, '8.2 CGPA', 'First Class', true),
('77777777-7777-7777-7777-777777777702', '66666666-6666-6666-6666-666666666601', 'HIGH_SCHOOL', 'Higher Secondary Certificate', 'Science', 'Delhi Public School', 'CBSE Board', 2009, '92%', 'A+', false),

-- Priya Patel (CAND002)
('77777777-7777-7777-7777-777777777703', '66666666-6666-6666-6666-666666666602', 'MASTER', 'Master of Computer Applications', 'Software Engineering', 'Anna University', 'Anna University', 2017, '8.6 CGPA', 'First Class', true),
('77777777-7777-7777-7777-777777777704', '66666666-6666-6666-6666-666666666602', 'BACHELOR', 'Bachelor of Computer Applications', 'Computer Applications', 'Madras University', 'University of Madras', 2015, '8.1 CGPA', 'First Class', false),

-- Rahul Chauhan (CAND003)
('77777777-7777-7777-7777-777777777705', '66666666-6666-6666-6666-666666666603', 'BACHELOR', 'Bachelor of Engineering', 'Information Technology', 'Indian Institute of Technology', 'IIT Kanpur', 2012, '8.9 CGPA', 'First Class with Distinction', true),
('77777777-7777-7777-7777-777777777706', '66666666-6666-6666-6666-666666666603', 'HIGH_SCHOOL', 'Senior Secondary Certificate', 'Science', 'Kendriya Vidyalaya', 'CBSE Board', 2008, '95%', 'A+', false),

-- Sneha Reddy (CAND004)
('77777777-7777-7777-7777-777777777707', '66666666-6666-6666-6666-666666666604', 'BACHELOR', 'Bachelor of Technology', 'Computer Science and Engineering', 'IIIT Hyderabad', 'IIIT Hyderabad', 2016, '8.4 CGPA', 'First Class', true),

-- Vikram Joshi (CAND005)
('77777777-7777-7777-7777-777777777708', '66666666-6666-6666-6666-666666666605', 'BACHELOR', 'Bachelor of Computer Applications', 'Computer Science', 'University of Calcutta', 'University of Calcutta', 2017, '8.0 CGPA', 'First Class', true),

-- Anita Gupta (CAND006)
('77777777-7777-7777-7777-777777777709', '66666666-6666-6666-6666-666666666606', 'BACHELOR', 'Bachelor of Technology', 'Information Technology', 'Delhi Technological University', 'Delhi Technological University', 2018, '7.8 CGPA', 'First Class', true),

-- Suresh Nair (CAND007)
('77777777-7777-7777-7777-777777777710', '66666666-6666-6666-6666-666666666607', 'MASTER', 'Master of Technology', 'Software Engineering', 'Indian Institute of Science', 'IISc Bangalore', 2014, '8.7 CGPA', 'First Class with Distinction', true),
('77777777-7777-7777-7777-777777777711', '66666666-6666-6666-6666-666666666607', 'BACHELOR', 'Bachelor of Engineering', 'Computer Science', 'College of Engineering Trivandrum', 'University of Kerala', 2012, '8.3 CGPA', 'First Class', false),

-- Meera Shah (CAND008)
('77777777-7777-7777-7777-777777777712', '66666666-6666-6666-6666-666666666608', 'BACHELOR', 'Bachelor of Engineering', 'Computer Engineering', 'Institute of Technology, Nirma University', 'Nirma University', 2015, '8.5 CGPA', 'First Class', true),

-- Karthik Subramanian (CAND009)
('77777777-7777-7777-7777-777777777713', '66666666-6666-6666-6666-666666666609', 'BACHELOR', 'Bachelor of Engineering', 'Electronics and Communication', 'SSN College of Engineering', 'Anna University', 2014, '8.1 CGPA', 'First Class', true),

-- Deepak Agarwal (CAND010)
('77777777-7777-7777-7777-777777777714', '66666666-6666-6666-6666-666666666610', 'MASTER', 'Master of Technology', 'Computer Science', 'IIT Delhi', 'IIT Delhi', 2011, '8.8 CGPA', 'First Class with Distinction', true),
('77777777-7777-7777-7777-777777777715', '66666666-6666-6666-6666-666666666610', 'BACHELOR', 'Bachelor of Technology', 'Computer Science', 'MNNIT Allahabad', 'MNNIT Allahabad', 2009, '8.4 CGPA', 'First Class', false);

-- ======================================================================
-- 5. CANDIDATE EXPERIENCE DATA
-- ======================================================================

-- Insert Experience records for senior candidates
INSERT INTO candidate_experience (experience_id, candidate_id, company_name, designation, start_date, end_date, is_current, duration_months, job_description, key_achievements, technologies_used, salary_amount, reason_for_leaving) VALUES
-- Arjun Sharma (CAND001) - 6.5 years experience
('88888888-8888-8888-8888-888888888801', '66666666-6666-6666-6666-666666666601', 'TechCorp Solutions', 'Senior Software Engineer', '2020-03-01', NULL, true, 54, 'Leading full-stack development projects for enterprise clients. Mentoring junior developers and architecting scalable solutions.', 'Led migration of legacy system to microservices, Reduced deployment time by 60%, Mentored 5 junior developers', 'React.js, Spring Boot, PostgreSQL, Docker, Kubernetes, AWS', 1650000.00, NULL),
('88888888-8888-8888-8888-888888888802', '66666666-6666-6666-6666-666666666601', 'InnoSoft Technologies', 'Software Engineer', '2017-07-15', '2020-02-28', false, 32, 'Full-stack web development using modern technologies. Worked on e-commerce and CRM applications.', 'Developed 3 major client applications, Improved application performance by 40%, Received Best Employee award 2019', 'Angular, Node.js, MongoDB, Express.js, MySQL', 1200000.00, 'Career growth and better opportunities'),
('88888888-8888-8888-8888-888888888803', '66666666-6666-6666-6666-666666666601', 'StartupXYZ', 'Junior Developer', '2013-08-01', '2017-07-10', false, 47, 'Started career as junior developer working on web applications and learning modern development practices.', 'Completed 10+ projects successfully, Quick learner and adaptive to new technologies', 'PHP, JavaScript, jQuery, MySQL, HTML5, CSS3', 600000.00, 'Seeking full-stack development opportunities'),

-- Priya Patel (CAND002) - 5.2 years experience
('88888888-8888-8888-8888-888888888804', '66666666-6666-6666-6666-666666666602', 'InnovateTech Pvt Ltd', 'Full Stack Developer', '2019-02-01', NULL, true, 67, 'Developing and maintaining full-stack applications for fintech clients. Working with React and Spring microservices.', 'Built trading platform handling 10k+ transactions daily, Implemented real-time dashboard, Led frontend team of 3 developers', 'React.js, Redux, Spring Boot, PostgreSQL, Redis, Kafka', 1450000.00, NULL),
('88888888-8888-8888-8888-888888888805', '66666666-6666-6666-6666-666666666602', 'WebSolutions Inc', 'Frontend Developer', '2017-06-15', '2019-01-31', false, 19, 'Frontend development using React.js and Angular for various client projects in healthcare and education domains.', 'Delivered 5 major projects on time, Improved UI performance by 50%, Implemented responsive design standards', 'React.js, Angular, TypeScript, SASS, Bootstrap', 900000.00, 'Better growth opportunities and technology exposure'),

-- Rahul Chauhan (CAND003) - 7.1 years experience
('88888888-8888-8888-8888-888888888806', '66666666-6666-6666-6666-666666666603', 'DevWorld Technologies', 'Lead Developer', '2021-01-15', NULL, true, 44, 'Leading development team of 8 engineers. Architecting enterprise solutions and driving technical decisions.', 'Architected microservices platform, Reduced infrastructure cost by 30%, Led digital transformation project', 'Java, Spring Boot, React.js, PostgreSQL, Docker, Kubernetes, AWS', 1750000.00, NULL),
('88888888-8888-8888-8888-888888888807', '66666666-6666-6666-6666-666666666603', 'TechFlow Systems', 'Senior Software Engineer', '2018-03-01', '2021-01-10', false, 34, 'Senior developer responsible for backend services and API development. Worked on high-traffic e-commerce platforms.', 'Optimized API response time by 70%, Handled 1M+ daily API calls, Implemented caching strategies', 'Java, Spring Framework, MySQL, Redis, ElasticSearch', 1400000.00, 'Leadership opportunities and team management'),
('88888888-8888-8888-8888-888888888808', '66666666-6666-6666-6666-666666666603', 'CodeCraft Solutions', 'Software Engineer', '2014-07-01', '2018-02-28', false, 44, 'Full-stack development focusing on web applications for BFSI sector. Worked with diverse technology stack.', 'Developed banking application modules, Ensured 99.9% uptime, Completed security audit certification', 'Java, JSF, Oracle, Hibernate, JavaScript', 1000000.00, 'Technology upgrade and modern stack exposure'),
('88888888-8888-8888-8888-888888888809', '66666666-6666-6666-6666-666666666603', 'TechStart Solutions', 'Associate Software Engineer', '2012-08-15', '2014-06-30', false, 22, 'Entry-level position working on web development projects and learning enterprise development practices.', 'Completed training programs, Contributed to 3 major releases, Quick adaptation to team processes', 'Java, Struts, MySQL, JavaScript, HTML', 450000.00, 'Career advancement'),

-- Suresh Nair (CAND007) - 5.3 years experience
('88888888-8888-8888-8888-888888888810', '66666666-6666-6666-6666-666666666607', 'QualityFirst Technologies', 'Senior QA Engineer', '2020-01-01', NULL, true, 57, 'Leading QA automation initiatives and managing testing for enterprise applications. Setting up CI/CD testing pipelines.', 'Reduced testing cycle time by 60%, Achieved 90% automation coverage, Led QA team of 4 engineers', 'Selenium WebDriver, TestNG, Jenkins, Java, Python, REST Assured', 1180000.00, NULL),
('88888888-8888-8888-8888-888888888811', '66666666-6666-6666-6666-666666666607', 'TestPro Solutions', 'QA Automation Engineer', '2017-09-01', '2019-12-31', false, 28, 'Automation testing for web and mobile applications. Developed test frameworks and maintained test suites.', 'Built comprehensive test automation framework, Increased test coverage by 80%, Reduced manual testing effort by 70%', 'Selenium, Appium, Java, TestNG, Maven, Git', 950000.00, 'Senior role and team leadership opportunities'),
('88888888-8888-8888-8888-888888888812', '66666666-6666-6666-6666-666666666607', 'QA Excellence Corp', 'QA Engineer', '2015-01-15', '2017-08-31', false, 31, 'Manual and automation testing for various client projects. Learned test automation tools and methodologies.', 'Completed 100+ test cycles, Found and reported 500+ defects, Transitioned from manual to automation testing', 'Manual Testing, Selenium Basics, JIRA, Test Management Tools', 650000.00, 'Automation testing focus and skill development'),

-- Karthik Subramanian (CAND009) - 4.8 years experience
('88888888-8888-8888-8888-888888888813', '66666666-6666-6666-6666-666666666609', 'CloudOps Technologies', 'DevOps Engineer', '2020-05-01', NULL, true, 52, 'Managing cloud infrastructure on AWS and implementing DevOps practices. Setting up CI/CD pipelines and monitoring.', 'Reduced deployment time from 2 hours to 15 minutes, Achieved 99.9% uptime, Implemented infrastructure as code', 'AWS, Docker, Kubernetes, Jenkins, Terraform, Ansible, Python', 1320000.00, NULL),
('88888888-8888-8888-8888-888888888814', '66666666-6666-6666-6666-666666666609', 'InfraTech Solutions', 'System Administrator', '2017-06-01', '2020-04-30', false, 35, 'Linux system administration and infrastructure management. Learned DevOps practices and cloud technologies.', 'Managed 50+ servers, Implemented monitoring solutions, Migrated on-premise to cloud infrastructure', 'Linux, Shell Scripting, Nagios, Apache, MySQL, Basic AWS', 850000.00, 'DevOps career transition and cloud expertise'),
('88888888-8888-8888-8888-888888888815', '66666666-6666-6666-6666-666666666609', 'TechSupport Inc', 'Junior System Admin', '2014-08-15', '2017-05-31', false, 33, 'Entry-level system administration role. Managing servers and learning infrastructure technologies.', 'Maintained 20+ servers, Resolved 95% tickets within SLA, Learned system administration fundamentals', 'Linux, Windows Server, Basic Networking, Shell Scripting', 480000.00, 'Advanced infrastructure and cloud opportunities'),

-- Deepak Agarwal (CAND010) - 5.7 years experience
('88888888-8888-8888-8888-888888888816', '66666666-6666-6666-6666-666666666610', 'CloudEngineers Pvt Ltd', 'Senior DevOps Engineer', '2019-04-01', NULL, true, 65, 'Leading DevOps transformation initiatives. Architecting cloud-native solutions and implementing best practices.', 'Led cloud migration for 20+ applications, Reduced infrastructure cost by 40%, Implemented zero-downtime deployments', 'AWS, Azure, Kubernetes, Docker, Terraform, Jenkins, Python, Go', 1480000.00, NULL),
('88888888-8888-8888-8888-888888888817', '66666666-6666-6666-6666-666666666610', 'InfraCloud Systems', 'DevOps Engineer', '2016-02-15', '2019-03-31', false, 37, 'DevOps engineer working on containerization and cloud adoption. Implemented CI/CD pipelines and monitoring.', 'Containerized 30+ applications, Implemented monitoring for 100+ services, Achieved 50% faster deployments', 'Docker, Kubernetes, AWS, Jenkins, Ansible, Prometheus, Grafana', 1200000.00, 'Senior role and architectural responsibilities'),
('88888888-8888-8888-8888-888888888818', '66666666-6666-6666-6666-666666666610', 'SystemCorp Technologies', 'Build Engineer', '2013-07-01', '2016-02-10', false, 31, 'Build and deployment engineer responsible for release management and build automation.', 'Automated build processes, Reduced build time by 60%, Managed release cycles for 5+ products', 'Jenkins, Ant, Maven, SVN, Shell Scripting, Linux', 750000.00, 'DevOps transition and cloud technologies'),
('88888888-8888-8888-8888-888888888819', '66666666-6666-6666-6666-666666666610', 'TechStart Solutions', 'Software Engineer', '2011-08-15', '2013-06-30', false, 22, 'Software development role focusing on Java applications. First job after completing M.Tech degree.', 'Developed core application modules, Learned enterprise development practices, Contributed to major releases', 'Java, J2EE, Oracle, Hibernate, Spring Framework', 550000.00, 'Infrastructure and DevOps interest');

-- ======================================================================
-- 6. CANDIDATE SKILLS DATA
-- ======================================================================

-- Insert Skills for all candidates
INSERT INTO candidate_skill (skill_id, candidate_id, skill_name, skill_category, proficiency_level, years_of_experience, certification_name, certification_date) VALUES
-- Arjun Sharma (CAND001) - Full Stack Developer
('99999999-9999-9999-9999-999999999901', '66666666-6666-6666-6666-666666666601', 'React.js', 'TECHNICAL', 'ADVANCED', 4.5, NULL, NULL),
('99999999-9999-9999-9999-999999999902', '66666666-6666-6666-6666-666666666601', 'Spring Boot', 'TECHNICAL', 'ADVANCED', 5.0, NULL, NULL),
('99999999-9999-9999-9999-999999999903', '66666666-6666-6666-6666-666666666601', 'PostgreSQL', 'TECHNICAL', 'INTERMEDIATE', 3.5, NULL, NULL),
('99999999-9999-9999-9999-999999999904', '66666666-6666-6666-6666-666666666601', 'AWS', 'TECHNICAL', 'INTERMEDIATE', 2.0, 'AWS Solutions Architect Associate', '2022-06-15'),
('99999999-9999-9999-9999-999999999905', '66666666-6666-6666-6666-666666666601', 'Docker', 'TECHNICAL', 'INTERMEDIATE', 2.5, NULL, NULL),
('99999999-9999-9999-9999-999999999906', '66666666-6666-6666-6666-666666666601', 'Team Leadership', 'BEHAVIORAL', 'ADVANCED', 3.0, NULL, NULL),

-- Priya Patel (CAND002) - Full Stack Developer
('99999999-9999-9999-9999-999999999907', '66666666-6666-6666-6666-666666666602', 'React.js', 'TECHNICAL', 'ADVANCED', 3.5, NULL, NULL),
('99999999-9999-9999-9999-999999999908', '66666666-6666-6666-6666-666666666602', 'Redux', 'TECHNICAL', 'ADVANCED', 3.0, NULL, NULL),
('99999999-9999-9999-9999-999999999909', '66666666-6666-6666-6666-666666666602', 'Spring Boot', 'TECHNICAL', 'INTERMEDIATE', 2.5, NULL, NULL),
('99999999-9999-9999-9999-999999999910', '66666666-6666-6666-6666-666666666602', 'PostgreSQL', 'TECHNICAL', 'INTERMEDIATE', 2.0, NULL, NULL),
('99999999-9999-9999-9999-999999999911', '66666666-6666-6666-6666-666666666602', 'TypeScript', 'TECHNICAL', 'ADVANCED', 3.0, NULL, NULL),

-- Rahul Chauhan (CAND003) - Lead Developer
('99999999-9999-9999-9999-999999999912', '66666666-6666-6666-6666-666666666603', 'Java', 'TECHNICAL', 'EXPERT', 7.0, 'Oracle Certified Professional Java SE 11', '2021-03-20'),
('99999999-9999-9999-9999-999999999913', '66666666-6666-6666-6666-666666666603', 'Spring Boot', 'TECHNICAL', 'EXPERT', 5.5, NULL, NULL),
('99999999-9999-9999-9999-999999999914', '66666666-6666-6666-6666-666666666603', 'Microservices', 'TECHNICAL', 'ADVANCED', 4.0, NULL, NULL),
('99999999-9999-9999-9999-999999999915', '66666666-6666-6666-6666-666666666603', 'Kubernetes', 'TECHNICAL', 'INTERMEDIATE', 2.5, 'Certified Kubernetes Administrator', '2022-01-10'),
('99999999-9999-9999-9999-999999999916', '66666666-6666-6666-6666-666666666603', 'Technical Architecture', 'FUNCTIONAL', 'ADVANCED', 3.0, NULL, NULL),
('99999999-9999-9999-9999-999999999917', '66666666-6666-6666-6666-666666666603', 'Team Management', 'BEHAVIORAL', 'ADVANCED', 3.5, NULL, NULL),

-- Sneha Reddy (CAND004) - React Developer
('99999999-9999-9999-9999-999999999918', '66666666-6666-6666-6666-666666666604', 'React.js', 'TECHNICAL', 'ADVANCED', 3.2, NULL, NULL),
('99999999-9999-9999-9999-999999999919', '66666666-6666-6666-6666-666666666604', 'JavaScript', 'TECHNICAL', 'ADVANCED', 3.5, NULL, NULL),
('99999999-9999-9999-9999-999999999920', '66666666-6666-6666-6666-666666666604', 'Material UI', 'TECHNICAL', 'ADVANCED', 2.8, NULL, NULL),
('99999999-9999-9999-9999-999999999921', '66666666-6666-6666-6666-666666666604', 'GraphQL', 'TECHNICAL', 'INTERMEDIATE', 1.5, NULL, NULL),
('99999999-9999-9999-9999-999999999922', '66666666-6666-6666-6666-666666666604', 'CSS3', 'TECHNICAL', 'ADVANCED', 3.0, NULL, NULL),

-- Vikram Joshi (CAND005) - Frontend Developer
('99999999-9999-9999-9999-999999999923', '66666666-6666-6666-6666-666666666605', 'React.js', 'TECHNICAL', 'INTERMEDIATE', 2.5, NULL, NULL),
('99999999-9999-9999-9999-999999999924', '66666666-6666-6666-6666-666666666605', 'JavaScript', 'TECHNICAL', 'ADVANCED', 2.8, NULL, NULL),
('99999999-9999-9999-9999-999999999925', '66666666-6666-6666-6666-666666666605', 'HTML5', 'TECHNICAL', 'ADVANCED', 2.8, NULL, NULL),
('99999999-9999-9999-9999-999999999926', '66666666-6666-6666-6666-666666666605', 'Bootstrap', 'TECHNICAL', 'INTERMEDIATE', 2.0, NULL, NULL),

-- Suresh Nair (CAND007) - QA Automation Engineer
('99999999-9999-9999-9999-999999999927', '66666666-6666-6666-6666-666666666607', 'Selenium WebDriver', 'TECHNICAL', 'EXPERT', 5.0, 'Selenium WebDriver Certification', '2020-05-15'),
('99999999-9999-9999-9999-999999999928', '66666666-6666-6666-6666-666666666607', 'TestNG', 'TECHNICAL', 'ADVANCED', 4.5, NULL, NULL),
('99999999-9999-9999-9999-999999999929', '66666666-6666-6666-6666-666666666607', 'Java', 'TECHNICAL', 'ADVANCED', 5.0, NULL, NULL),
('99999999-9999-9999-9999-999999999930', '66666666-6666-6666-6666-666666666607', 'REST API Testing', 'TECHNICAL', 'ADVANCED', 3.5, NULL, NULL),
('99999999-9999-9999-9999-999999999931', '66666666-6666-6666-6666-666666666607', 'Jenkins', 'TECHNICAL', 'INTERMEDIATE', 2.5, NULL, NULL),

-- Karthik Subramanian (CAND009) - DevOps Engineer
('99999999-9999-9999-9999-999999999932', '66666666-6666-6666-6666-666666666609', 'AWS', 'TECHNICAL', 'ADVANCED', 4.0, 'AWS Solutions Architect Professional', '2023-02-20'),
('99999999-9999-9999-9999-999999999933', '66666666-6666-6666-6666-666666666609', 'Docker', 'TECHNICAL', 'ADVANCED', 3.5, NULL, NULL),
('99999999-9999-9999-9999-999999999934', '66666666-6666-6666-6666-666666666609', 'Kubernetes', 'TECHNICAL', 'INTERMEDIATE', 2.5, 'Certified Kubernetes Administrator', '2022-11-10'),
('99999999-9999-9999-9999-999999999935', '66666666-6666-6666-6666-666666666609', 'Terraform', 'TECHNICAL', 'INTERMEDIATE', 2.0, NULL, NULL),
('99999999-9999-9999-9999-999999999936', '66666666-6666-6666-6666-666666666609', 'Python', 'TECHNICAL', 'INTERMEDIATE', 3.0, NULL, NULL),

-- Deepak Agarwal (CAND010) - Senior DevOps Engineer
('99999999-9999-9999-9999-999999999937', '66666666-6666-6666-6666-666666666610', 'AWS', 'TECHNICAL', 'EXPERT', 5.5, 'AWS Solutions Architect Professional', '2021-08-15'),
('99999999-9999-9999-9999-999999999938', '66666666-6666-6666-6666-666666666610', 'Azure', 'TECHNICAL', 'ADVANCED', 3.0, 'Microsoft Azure Solutions Architect', '2022-04-20'),
('99999999-9999-9999-9999-999999999939', '66666666-6666-6666-6666-666666666610', 'Kubernetes', 'TECHNICAL', 'EXPERT', 4.5, 'Certified Kubernetes Administrator', '2020-09-25'),
('99999999-9999-9999-9999-999999999940', '66666666-6666-6666-6666-666666666610', 'Terraform', 'TECHNICAL', 'ADVANCED', 4.0, 'HashiCorp Certified Terraform Associate', '2021-12-10'),
('99999999-9999-9999-9999-999999999941', '66666666-6666-6666-6666-666666666610', 'Jenkins', 'TECHNICAL', 'EXPERT', 5.0, NULL, NULL),
('99999999-9999-9999-9999-999999999942', '66666666-6666-6666-6666-666666666610', 'Solution Architecture', 'FUNCTIONAL', 'ADVANCED', 4.0, NULL, NULL);

-- ======================================================================
-- 7. JOB APPLICATIONS DATA
-- ======================================================================

-- Insert Job Applications
INSERT INTO job_application (
    application_id, requisition_id, candidate_id, posting_id, application_date,
    cover_letter, expected_salary, notice_period_days, available_from_date,
    current_stage, overall_status, overall_rating, technical_rating,
    communication_rating, cultural_fit_rating, company_id, created_by
) VALUES
-- Applications for Senior Full Stack Developer (REQ001)
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666601', '44444444-4444-4444-4444-444444444401', '2024-09-13',
 'I am excited to apply for the Senior Full Stack Developer position. With 6.5 years of experience in full-stack development and proven leadership skills, I believe I can contribute significantly to your HRMS platform development.', 1800000.00, 60, '2024-11-15',
 'INTERVIEW_L2', 'IN_PROGRESS', 8.5, 9.0, 8.0, 8.5, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab', '22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666602', '44444444-4444-4444-4444-444444444402', '2024-09-14',
 'I am interested in the Senior Full Stack Developer role. My experience with React and Spring Boot, combined with my passion for creating user-friendly applications, makes me a strong candidate for this position.', 1700000.00, 45, '2024-11-01',
 'INTERVIEW_L1', 'IN_PROGRESS', 7.8, 8.2, 7.5, 7.8, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac', '22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666603', '44444444-4444-4444-4444-444444444403', '2024-09-11',
 'As a Lead Developer with 7+ years of experience, I am excited about the opportunity to join your team and contribute to building next-generation HRMS solutions using modern technologies.', 1900000.00, 90, '2024-12-10',
 'OFFER_EXTENDED', 'IN_PROGRESS', 9.2, 9.5, 9.0, 9.0, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Applications for React.js Developer (REQ002)
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad', '22222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666604', '44444444-4444-4444-4444-444444444404', '2024-09-15',
 'I am passionate about frontend development and excited to work on the NEXUS HRMS platform. My experience with React.js and Material UI aligns perfectly with your requirements.', 1100000.00, 30, '2024-10-20',
 'TECHNICAL_TEST', 'IN_PROGRESS', 7.5, 8.0, 7.2, 7.8, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaae', '22222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666605', '44444444-4444-4444-4444-444444444405', '2024-09-16',
 'Looking forward to contributing to your React.js development team. I have strong experience in building responsive UIs and working with modern frontend technologies.', 950000.00, 30, '2024-10-25',
 'PHONE_INTERVIEW', 'IN_PROGRESS', 7.0, 7.5, 6.8, 7.2, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaf', '22222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666606', '44444444-4444-4444-4444-444444444406', '2024-09-17',
 'I am excited about the React.js Developer position. My recent experience in building modern web applications and passion for creating excellent user experiences make me a great fit.', 900000.00, 15, '2024-10-15',
 'SCREENING', 'IN_PROGRESS', NULL, NULL, NULL, NULL, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaag', '22222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666611', '44444444-4444-4444-4444-444444444404', '2024-09-16',
 'I would like to apply for the React.js Developer position. I have good experience with React and am eager to work on enterprise HRMS solutions.', 1200000.00, 30, '2024-10-30',
 'REJECTED', 'REJECTED', 5.5, 6.0, 5.2, 5.8, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaah', '22222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666612', '44444444-4444-4444-4444-444444444405', '2024-09-18',
 'Applying for the React.js Developer role. I am passionate about frontend development and have experience building user-friendly interfaces.', 1000000.00, 30, '2024-10-25',
 'INTERVIEW_L1', 'IN_PROGRESS', 7.2, 7.8, 6.9, 7.0, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Applications for QA Automation Engineer (REQ003)
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaai', '22222222-2222-2222-2222-222222222203', '66666666-6666-6666-6666-666666666607', '44444444-4444-4444-4444-444444444407', '2024-09-14',
 'I am very interested in the QA Automation Engineer position. With 5+ years of automation experience and expertise in Selenium, I can help ensure the quality of your HRMS platform.', 1350000.00, 45, '2024-11-01',
 'FINAL_INTERVIEW', 'IN_PROGRESS', 8.8, 9.2, 8.5, 8.8, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaj', '22222222-2222-2222-2222-222222222203', '66666666-6666-6666-6666-666666666608', '44444444-4444-4444-4444-444444444408', '2024-09-15',
 'Excited to apply for the QA Automation Engineer role. My experience in test automation and framework development aligns well with your requirements for ensuring platform quality.', 1250000.00, 60, '2024-11-15',
 'INTERVIEW_L1', 'IN_PROGRESS', 7.8, 8.0, 7.6, 7.9, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Applications for DevOps Engineer (REQ004)
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaak', '22222222-2222-2222-2222-222222222204', '66666666-6666-6666-6666-666666666609', '44444444-4444-4444-4444-444444444409', '2024-09-10',
 'I am very interested in the DevOps Engineer position. My experience with AWS, Docker, and Kubernetes, combined with my passion for automation, makes me an ideal candidate for this role.', 1550000.00, 45, '2024-10-30',
 'REFERENCE_CHECK', 'IN_PROGRESS', 8.5, 8.8, 8.2, 8.6, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaal', '22222222-2222-2222-2222-222222222204', '66666666-6666-6666-6666-666666666610', '44444444-4444-4444-4444-444444444410', '2024-09-11',
 'Applying for the DevOps Engineer position. With my extensive experience in cloud infrastructure and automation, I can help optimize your deployment processes and infrastructure management.', 1650000.00, 60, '2024-11-15',
 'OFFER_PENDING', 'IN_PROGRESS', 9.0, 9.3, 8.8, 9.1, (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 8. INTERVIEW TYPE AND SCHEDULE DATA
-- ======================================================================

-- Insert Interview Types
INSERT INTO interview_type_master (interview_type_id, type_name, type_description, typical_duration_minutes, evaluation_criteria, company_id) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 'Phone Screening', 'Initial phone interview to assess basic qualifications and interest', 30, 'Communication skills, Basic technical knowledge, Interest in role', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', 'Technical Test', 'Online coding/technical assessment', 90, 'Technical skills, Problem-solving ability, Code quality', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 'Technical Interview L1', 'First technical interview with team lead', 60, 'Technical expertise, System design, Problem-solving approach', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb04', 'Technical Interview L2', 'Advanced technical interview with senior team members', 75, 'Advanced technical concepts, Architecture knowledge, Leadership potential', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb05', 'Final Interview', 'Final interview with department head/manager', 45, 'Cultural fit, Leadership qualities, Long-term vision', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH')),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb06', 'HR Round', 'HR interview for policy discussion and offer negotiation', 30, 'Company policies, Salary expectations, Background verification', (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'));

-- Insert Interview Schedules
INSERT INTO interview_schedule (
    interview_id, application_id, interview_type_id, interview_round,
    scheduled_date, scheduled_start_time, scheduled_end_time,
    actual_start_time, actual_end_time, interview_mode,
    meeting_location, meeting_link, status, interview_result,
    overall_score, interviewer_feedback, candidate_feedback,
    company_id, created_by
) VALUES
-- Arjun Sharma interviews (CAND001) - Senior Full Stack Developer
('cccccccc-cccc-cccc-cccc-cccccccccc01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 1,
 '2024-09-14', '10:00:00', '10:30:00', '2024-09-14 10:02:00', '2024-09-14 10:28:00', 'PHONE_CALL',
 NULL, NULL, 'COMPLETED', 'PASS', 8.5,
 'Strong communication skills and good technical background. Recommended for next round.', 'Pleasant conversation, team seems knowledgeable.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', 2,
 '2024-09-16', '14:00:00', '15:30:00', '2024-09-16 14:05:00', '2024-09-16 15:25:00', 'ONLINE_TEST',
 NULL, 'https://codingtest.systech.com/test/12345', 'COMPLETED', 'PASS', 9.0,
 'Excellent coding skills, clean code, good problem-solving approach.', 'Challenging but fair technical assessment.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 3,
 '2024-09-18', '11:00:00', '12:00:00', '2024-09-18 11:00:00', '2024-09-18 12:10:00', 'VIDEO_CALL',
 NULL, 'https://meet.google.com/abc-defg-hij', 'COMPLETED', 'PASS', 8.8,
 'Strong technical knowledge, good system design thinking, shows leadership potential.', 'Good technical discussion, interviewer was very knowledgeable.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc04', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb04', 4,
 '2024-09-20', '15:30:00', '16:45:00', NULL, NULL, 'VIDEO_CALL',
 NULL, 'https://meet.google.com/xyz-uvw-rst', 'SCHEDULED', NULL, NULL,
 NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Rahul Chauhan interviews (CAND003) - Senior Full Stack Developer (Employee Referral)
('cccccccc-cccc-cccc-cccc-cccccccccc05', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 1,
 '2024-09-12', '09:00:00', '09:30:00', '2024-09-12 09:00:00', '2024-09-12 09:25:00', 'PHONE_CALL',
 NULL, NULL, 'COMPLETED', 'PASS', 9.0,
 'Excellent candidate, strong background, highly recommended by referring employee.', 'Great initial conversation, excited about the opportunity.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc06', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 2,
 '2024-09-13', '10:30:00', '11:30:00', '2024-09-13 10:30:00', '2024-09-13 11:45:00', 'IN_PERSON',
 'Conference Room A, 3rd Floor', NULL, 'COMPLETED', 'PASS', 9.5,
 'Outstanding technical skills, excellent leadership experience, perfect fit for senior role.', 'Very impressed with the team and technology stack.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc07', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb05', 3,
 '2024-09-14', '16:00:00', '16:45:00', '2024-09-14 16:00:00', '2024-09-14 16:40:00', 'IN_PERSON',
 'Conference Room B, 3rd Floor', NULL, 'COMPLETED', 'PASS', 9.2,
 'Excellent cultural fit, strong leadership qualities, recommended for offer.', 'Great company culture and vision, very interested in joining.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Sneha Reddy interviews (CAND004) - React.js Developer
('cccccccc-cccc-cccc-cccc-cccccccccc08', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 1,
 '2024-09-16', '14:00:00', '14:30:00', '2024-09-16 14:05:00', '2024-09-16 14:32:00', 'PHONE_CALL',
 NULL, NULL, 'COMPLETED', 'PASS', 8.0,
 'Good communication, solid React experience, enthusiastic about frontend development.', 'Nice conversation, team seems supportive.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc09', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', 2,
 '2024-09-18', '10:00:00', '11:30:00', NULL, NULL, 'ONLINE_TEST',
 NULL, 'https://codingtest.systech.com/test/23456', 'SCHEDULED', NULL, NULL,
 NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Suresh Nair interviews (CAND007) - QA Automation Engineer
('cccccccc-cccc-cccc-cccc-cccccccccc10', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaai', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 1,
 '2024-09-15', '11:00:00', '11:30:00', '2024-09-15 11:00:00', '2024-09-15 11:28:00', 'PHONE_CALL',
 NULL, NULL, 'COMPLETED', 'PASS', 8.8,
 'Excellent QA background, strong automation experience, great communication skills.', 'Very positive conversation, excited about the QA role.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc11', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaai', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 2,
 '2024-09-17', '15:00:00', '16:00:00', '2024-09-17 15:00:00', '2024-09-17 16:05:00', 'VIDEO_CALL',
 NULL, 'https://meet.google.com/qwe-rty-uio', 'COMPLETED', 'PASS', 9.0,
 'Outstanding automation expertise, excellent framework design skills, highly recommended.', 'Great technical discussion, impressed with the QA processes.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaai', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb05', 3,
 '2024-09-19', '10:30:00', '11:15:00', NULL, NULL, 'IN_PERSON',
 'Conference Room C, 2nd Floor', NULL, 'SCHEDULED', NULL, NULL,
 NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Karthik Subramanian interviews (CAND009) - DevOps Engineer
('cccccccc-cccc-cccc-cccc-cccccccccc13', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaak', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 1,
 '2024-09-11', '09:30:00', '10:00:00', '2024-09-11 09:30:00', '2024-09-11 09:55:00', 'PHONE_CALL',
 NULL, NULL, 'COMPLETED', 'PASS', 8.5,
 'Good DevOps background, strong AWS knowledge, shows passion for automation.', 'Good initial screening, interested in the infrastructure challenges.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc14', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaak', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 2,
 '2024-09-12', '14:30:00', '15:30:00', '2024-09-12 14:30:00', '2024-09-12 15:35:00', 'VIDEO_CALL',
 NULL, 'https://meet.google.com/def-ghi-jkl', 'COMPLETED', 'PASS', 8.8,
 'Strong technical skills, good understanding of cloud infrastructure and containerization.', 'Great technical interview, learned a lot about their infrastructure.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

('cccccccc-cccc-cccc-cccc-cccccccccc15', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaak', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb05', 3,
 '2024-09-13', '11:00:00', '11:45:00', '2024-09-13 11:00:00', '2024-09-13 11:42:00', 'IN_PERSON',
 'Conference Room A, 3rd Floor', NULL, 'COMPLETED', 'PASS', 8.6,
 'Good cultural fit, shows growth potential, recommended for offer with competitive package.', 'Impressed with company culture and growth opportunities.',
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- 9. OFFER LETTER DATA
-- ======================================================================

-- Insert Offer Letters
INSERT INTO offer_letter (
    offer_id, offer_number, application_id, job_title, department_id, designation_id,
    location_id, reporting_to_employee_id, annual_salary, monthly_salary,
    basic_salary, hra_amount, other_allowances, variable_pay_percentage,
    employment_type, probation_period_months, notice_period_days,
    offer_date, offer_expiry_date, expected_joining_date,
    offer_status, candidate_response, response_date,
    company_id, created_by
) VALUES
-- Offer for Rahul Chauhan (CAND003) - Senior Full Stack Developer
('dddddddd-dddd-dddd-dddd-dddddddddd01', 'SYSTECH-OFFER-2024-000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac',
 'Senior Full Stack Developer',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'Senior Software Engineer'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 1850000.00, 154166.67, 74000.00, 29600.00, 30566.67, 15.00,
 'PERMANENT', 6, 90,
 '2024-09-15', '2024-09-29', '2024-12-10',
 'SENT', NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager')),

-- Offer for Deepak Agarwal (CAND010) - DevOps Engineer
('dddddddd-dddd-dddd-dddd-dddddddddd02', 'SYSTECH-OFFER-2024-000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaal',
 'DevOps Engineer',
 (SELECT department_id FROM department_master WHERE department_name = 'Information Technology'),
 (SELECT designation_id FROM designation_master WHERE designation_name = 'DevOps Engineer'),
 (SELECT location_id FROM location_master WHERE location_name = 'Chennai Head Office'),
 (SELECT employee_id FROM employee_master WHERE employee_code = 'EMP001'),
 1600000.00, 133333.33, 64000.00, 25600.00, 26333.33, 10.00,
 'PERMANENT', 3, 60,
 '2024-09-14', '2024-09-28', '2024-11-15',
 'GENERATED', NULL, NULL,
 (SELECT company_id FROM company_master WHERE short_name = 'SYSTECH'), (SELECT user_id FROM user_master WHERE user_name = 'hr_manager'));

-- ======================================================================
-- RECRUITMENT SAMPLE DATA COMPLETED SUCCESSFULLY
-- ======================================================================

-- Verification Queries (Commented out for production use)
/*
-- Summary of recruitment data created:
SELECT 'Job Categories' as entity, COUNT(*) as count FROM job_category_master
UNION ALL
SELECT 'Job Requisitions', COUNT(*) FROM job_requisition
UNION ALL
SELECT 'Job Posting Channels', COUNT(*) FROM job_posting_channel
UNION ALL
SELECT 'Job Postings', COUNT(*) FROM job_posting
UNION ALL
SELECT 'Candidate Sources', COUNT(*) FROM candidate_source
UNION ALL
SELECT 'Candidates', COUNT(*) FROM candidate_master
UNION ALL
SELECT 'Education Records', COUNT(*) FROM candidate_education
UNION ALL
SELECT 'Experience Records', COUNT(*) FROM candidate_experience
UNION ALL
SELECT 'Skill Records', COUNT(*) FROM candidate_skill
UNION ALL
SELECT 'Job Applications', COUNT(*) FROM job_application
UNION ALL
SELECT 'Interview Types', COUNT(*) FROM interview_type_master
UNION ALL
SELECT 'Interview Schedules', COUNT(*) FROM interview_schedule
UNION ALL
SELECT 'Offer Letters', COUNT(*) FROM offer_letter;

-- Application pipeline summary:
SELECT
    jr.job_title,
    COUNT(ja.application_id) as total_applications,
    COUNT(CASE WHEN ja.current_stage = 'APPLIED' THEN 1 END) as applied,
    COUNT(CASE WHEN ja.current_stage LIKE '%INTERVIEW%' THEN 1 END) as interviews,
    COUNT(CASE WHEN ja.current_stage LIKE '%OFFER%' THEN 1 END) as offers,
    COUNT(CASE WHEN ja.overall_status = 'SELECTED' THEN 1 END) as selected,
    COUNT(CASE WHEN ja.overall_status = 'REJECTED' THEN 1 END) as rejected
FROM job_requisition jr
LEFT JOIN job_application ja ON jr.requisition_id = ja.requisition_id
GROUP BY jr.job_title, jr.requisition_id
ORDER BY total_applications DESC;
*/