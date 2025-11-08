-- Cohera CRM - Multi-Tenant SQL Schema
-- Database: MySQL

-- This schema is designed for a multi-tenant architecture.
-- Unlike the PostgreSQL version, MySQL does not have built-in Row-Level Security (RLS)
-- in the same way. Multi-tenancy MUST be enforced at the application level.
--
-- APPLICATION REQUIREMENT:
-- Every database query (SELECT, INSERT, UPDATE, DELETE) on a tenant-scoped table
-- (e.g., users, clients, issues) MUST include a 'WHERE org_id = ?' clause,
-- where '?' is the organization ID of the authenticated user.
-- This prevents data leaks between tenants.

-- ----------------------------
-- 1. Organizations (Tenants)
-- ----------------------------
-- Stores the information for each tenant company.
CREATE TABLE organizations (
    org_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE organizations COMMENT = 'Stores each root tenant/company that subscribes to Cohera.';

-- ----------------------------
-- 2. Users
-- ----------------------------
-- Stores user accounts. Each user belongs to one organization.
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255),
    -- 'admin' (Company Administrator) or 'user' (Sales & Support Team)
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    INDEX idx_users_org_id (org_id),
    INDEX idx_users_email (email),
    CONSTRAINT chk_user_role CHECK (role IN ('admin', 'user'))
);

ALTER TABLE users COMMENT = 'User accounts, scoped to a single organization (tenant).';

-- ----------------------------
-- 3. Clients
-- ----------------------------
-- Stores client/customer information, scoped to an organization.
CREATE TABLE clients (
    client_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    assigned_to_user_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_clients_org_id (org_id),
    INDEX idx_clients_assigned_to (assigned_to_user_id)
);

ALTER TABLE clients COMMENT = 'Client records for each organization. Central data point.';

-- ----------------------------
-- 4. Issues
-- ----------------------------
-- Tracks support tickets and issues, linked to organizations and clients.
CREATE TABLE issues (
    issue_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    client_id BIGINT,
    title TEXT NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'Open',
    priority VARCHAR(50) DEFAULT 'Medium',
    created_by_user_id BIGINT,
    assigned_to_user_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- For PRD requirement 5.3: Third-Party Issue Tracking Integration
    external_issue_id VARCHAR(255), -- Stores ID from Jira, Redmine, etc.
    
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    
    INDEX idx_issues_org_id (org_id),
    INDEX idx_issues_client_id (client_id),
    INDEX idx_issues_assigned_to (assigned_to_user_id),
    INDEX idx_issues_status (status),
    
    CONSTRAINT chk_issue_status CHECK (status IN ('Open', 'In Progress', 'Closed')),
    CONSTRAINT chk_issue_priority CHECK (priority IN ('Low', 'Medium', 'High'))
);

ALTER TABLE issues COMMENT = 'Issue tracking system. Scoped to org and linked to clients/users.';

-- ----------------------------
-- 5. Meetings
-- ----------------------------
-- Stores information about meetings, linked to Google Calendar/Meet.
CREATE TABLE meetings (
    meeting_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    created_by_user_id BIGINT,
    client_id BIGINT,
    title VARCHAR(255) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    -- For PRD requirement 5.2: Google Workspace Integration
    google_calendar_event_id VARCHAR(255),
    google_meet_link TEXT,
    notes TEXT,
    -- For PRD requirement 5.4: AI Meeting Note Taker
    transcription_id VARCHAR(255), -- ID from transcription service
    ai_summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE SET NULL,

    INDEX idx_meetings_org_id (org_id),
    INDEX idx_meetings_client_id (client_id),
    INDEX idx_meetings_start_time (start_time)
);

ALTER TABLE meetings COMMENT = 'Meeting records, integrated with Google Workspace and AI note-takers.';

-- ----------------------------
-- 6. Activities
-- ----------------------------
-- Central chronological log for all interactions (PRD 5.7).
CREATE TABLE activities (
    activity_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    user_id BIGINT, -- User who performed action
    client_id BIGINT, -- Client related to action
    -- Associate activity with a specific item (e.g., issue_id, meeting_id)
    related_item_id BIGINT,
    activity_type ENUM(
        'email_sent',
        'email_received',
        'call_logged',
        'meeting_scheduled',
        'meeting_held',
        'issue_created',
        'issue_status_changed',
        'note_added'
    ) NOT NULL,
    details JSON, -- Store email subject, call notes, issue title, etc.
    activity_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE SET NULL,
    
    INDEX idx_activities_org_id (org_id),
    INDEX idx_activities_client_id (client_id),
    INDEX idx_activities_user_id (user_id),
    INDEX idx_activities_timestamp (activity_timestamp DESC)
);

ALTER TABLE activities COMMENT = 'Consolidated activity summary feed for all interactions.';

-- ----------------------------
-- 7. VoIP Calls
-- ----------------------------
-- Stores logs and recordings from VoIP integration (PRD 5.5).
CREATE TABLE voip_calls (
    call_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id BIGINT NOT NULL,
    user_id BIGINT, -- Cohera user
    client_id BIGINT,
    phone_number VARCHAR(50) NOT NULL,
    direction VARCHAR(10),
    start_time DATETIME NOT NULL,
    duration_seconds INT,
    -- For PRD requirement 5.5: VoIP Integration (e.g., Twilio)
    external_call_sid VARCHAR(255) UNIQUE, -- e.g., Twilio Call SID
    recording_url TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE SET NULL,
    
    INDEX idx_voip_calls_org_id (org_id),
    INDEX idx_voip_calls_user_id (user_id),
    INDEX idx_voip_calls_client_id (client_id),
    
    CONSTRAINT chk_call_direction CHECK (direction IN ('inbound', 'outbound'))
);

ALTER TABLE voip_calls COMMENT = 'Log of VoIP calls and links to recordings.';

-- End of Schema --