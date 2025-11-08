-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. User Management
CREATE TABLE Users (
    id UUID PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Onboarding & Assessments
CREATE TABLE Assessments (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    assessment_type TEXT NOT NULL, -- e.g., 'PHQ-8'
    score INTEGER NOT NULL,
    answers JSONB, -- To store the full list of answers
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Metrics & Analytics
CREATE TABLE DailyMetrics (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    steps FLOAT,
    active_energy FLOAT,
    heart_rate FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE TypingMetrics (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    words_per_minute FLOAT,
    total_edit_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE MotionMetrics (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    avg_acceleration_x FLOAT,
    avg_acceleration_y FLOAT,
    avg_acceleration_z FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Journaling
CREATE TABLE JournalEntries (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    title TEXT,
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE AIChatMessages (
    id SERIAL PRIMARY KEY,
    entry_id INTEGER REFERENCES JournalEntries(id) ON DELETE CASCADE,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    sender TEXT NOT NULL, -- 'user' or 'ai'
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Community
CREATE TABLE CommunityPosts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    title TEXT,
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE PostLikes (
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES CommunityPosts(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, post_id)
);

-- 6. Wellness Tasks
CREATE TABLE WellnessTasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT
);

CREATE TABLE UserTasks (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES Users(id) ON DELETE CASCADE,
    task_id INTEGER REFERENCES WellnessTasks(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Support Resources
CREATE TABLE SupportResources (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    url TEXT,
    resource_type TEXT -- e.g., 'article', 'video', 'hotline'
);
