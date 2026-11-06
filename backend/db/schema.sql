/*
  Schema for local SQLite (SQLCipher) and remote PostgreSQL.
  It includes:
   - users (with pending_sync flag for offline sign‑up)
   - quizzes (is_online flag distinguishes online vs offline created quizzes)
   - questions
   - sessions (answers by participants)
   - answers
*/

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  created_at TEXT NOT NULL,
  pending_sync INTEGER NOT NULL DEFAULT 0   -- 1 = created offline, not yet synced
);

CREATE TABLE IF NOT EXISTS quizzes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  creator_id INTEGER NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  secret_code TEXT NOT NULL,
  is_online INTEGER NOT NULL DEFAULT 1,   -- 1 = online (server), 0 = offline (local only)
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quiz_id INTEGER NOT NULL REFERENCES quizzes(id),
  question_text TEXT NOT NULL,
  answer TEXT NOT NULL,
  position INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quiz_id INTEGER NOT NULL REFERENCES quizzes(id),
  participant_id INTEGER NOT NULL REFERENCES users(id),
  started_at TEXT NOT NULL,
  completed_at TEXT,
  secret_code_used TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL REFERENCES sessions(id),
  question_id INTEGER NOT NULL REFERENCES questions(id),
  given_answer TEXT,
  is_correct INTEGER,
  answered_at TEXT
);

-- Indexes for quick look‑ups
CREATE INDEX IF NOT EXISTS idx_quizzes_code ON quizzes(secret_code);
CREATE INDEX IF NOT EXISTS idx_sessions_quiz_user ON sessions(quiz_id, participant_id);
