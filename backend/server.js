const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ---- Config ----
const JWT_SECRET = process.env.JWT_SECRET || 'quiz_app_jwt_secret';
const PORT = process.env.PORT || 4000;

// PostgreSQL connection pool (adjust credentials as needed)
const pool = new Pool({
  user: process.env.PGUSER || 'postgres',
  host: process.env.PGHOST || 'localhost',
  database: process.env.PGDATABASE || 'quiz_app',
  password: process.env.PGPASS || 'password',
  port: process.env.PGPORT ? parseInt(process.env.PGPORT) : 5432,
});

// ---- Helper Middleware ----
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user; // { userId }
    next();
  });
}

// ---- Routes ----
// Sign‑up
app.post('/api/auth/signup', async (req, res) => {
  const { email, password, displayName } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Missing fields' });
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, display_name, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id`,
      [email, passwordHash, displayName]
    );
    const token = jwt.sign({ userId: result.rows[0].id }, JWT_SECRET);
    res.json({ token });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Could not create user' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const result = await pool.query('SELECT id, password_hash FROM users WHERE email = $1', [email]);
  if (result.rowCount === 0) return res.status(401).json({ error: 'Invalid credentials' });
  const user = result.rows[0];
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
  const token = jwt.sign({ userId: user.id }, JWT_SECRET);
  res.json({ token });
});

// Create a quiz (protected)
app.post('/api/quizzes', authenticateToken, async (req, res) => {
  const { title, description, secretCode, questions } = req.body; // questions: [{question_text, answer, position}]
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const quizRes = await client.query(
      `INSERT INTO quizzes (creator_id, title, description, secret_code, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id`,
      [req.user.userId, title, description, secretCode]
    );
    const quizId = quizRes.rows[0].id;
    const qInsert = `INSERT INTO questions (quiz_id, question_text, answer, position) VALUES ($1, $2, $3, $4)`;
    for (const q of questions) {
      await client.query(qInsert, [quizId, q.question_text, q.answer, q.position]);
    }
    await client.query('COMMIT');
    res.json({ quizId });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(e);
    res.status(500).json({ error: 'Failed to create quiz' });
  } finally {
    client.release();
  }
});

// Get quiz by secret code (public)
app.get('/api/quizzes', async (req, res) => {
  const { code } = req.query;
  if (!code) return res.status(400).json({ error: 'Missing code' });
  const quizRes = await pool.query('SELECT * FROM quizzes WHERE secret_code = $1', [code]);
  if (quizRes.rowCount === 0) return res.status(404).json({ error: 'Quiz not found' });
  const quiz = quizRes.rows[0];
  const qRes = await pool.query('SELECT * FROM questions WHERE quiz_id = $1 ORDER BY position', [quiz.id]);
  quiz.questions = qRes.rows;
  res.json(quiz);
});

// Sync endpoint – simplistic bulk upsert (placeholder)
app.post('/api/sync', authenticateToken, async (req, res) => {
  // In a real implementation you would process client changes, apply conflict resolution, and return server changes.
  res.json({ message: 'Sync not yet implemented' });
});

app.listen(PORT, () => console.log(`Quiz backend listening on port ${PORT}`));
