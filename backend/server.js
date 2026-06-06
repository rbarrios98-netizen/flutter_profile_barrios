const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const { Sequelize, DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');

require('dotenv').config();
const app = express();
app.use(cors());
app.use(bodyParser.json());

const SECRET = process.env.JWT_SECRET || 'dev_secret_key';
const DB_HOST = process.env.DB_HOST || '127.0.0.1';
const DB_PORT = process.env.DB_PORT || '3306';
const DB_NAME = process.env.DB_NAME || 'capstone';
const DB_USER = process.env.DB_USER || 'root';
const DB_PASS = process.env.DB_PASS || '';

const sequelize = new Sequelize(DB_NAME, DB_USER, DB_PASS, {
  host: DB_HOST,
  port: DB_PORT,
  dialect: 'mysql',
  logging: false,
});

async function testDb() {
  try {
    await sequelize.authenticate();
    console.log('Connected to MySQL');
  } catch (err) {
    console.error('MySQL connection error', err);
  }
}

const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  username: { type: DataTypes.STRING, unique: true, allowNull: false },
  password: { type: DataTypes.STRING, allowNull: false },
  role: { type: DataTypes.ENUM('admin','adviser','student'), allowNull: false },
});

const Project = sequelize.define('Project', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  title: { type: DataTypes.STRING },
  description: { type: DataTypes.TEXT },
  domain: { type: DataTypes.STRING },
  status: { type: DataTypes.STRING },
  student: { type: DataTypes.STRING },
  adviser: { type: DataTypes.STRING },
});

const Schedule = sequelize.define('Schedule', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  projectId: { type: DataTypes.INTEGER, allowNull: false },
  scheduledAt: { type: DataTypes.DATE, allowNull: false },
  location: { type: DataTypes.STRING },
  notes: { type: DataTypes.TEXT },
  createdBy: { type: DataTypes.STRING },
});

Project.hasMany(Schedule, { foreignKey: 'projectId' });
Schedule.belongsTo(Project, { foreignKey: 'projectId' });

async function seedDefaults() {
  try {
    const ucount = await User.count();
    if (ucount === 0) {
      await User.bulkCreate([
        { username: 'admin', password: bcrypt.hashSync('admin123', 10), role: 'admin' },
        { username: 'adviser', password: bcrypt.hashSync('adviser123', 10), role: 'adviser' },
        { username: 'student', password: bcrypt.hashSync('student123', 10), role: 'student' },
      ]);
      console.log('Seeded default users');
    }
    const pcount = await Project.count();
    if (pcount === 0) {
      await Project.create({ title: 'Smart Campus App', description: 'Mobile app for campus services', domain: 'Web & Mobile Development', status: 'Ongoing', student: 'Alice', adviser: 'Dr. Reyes' });
      await Project.create({ title: 'Face Recognition Attendance', description: 'Computer vision attendance system', domain: 'AI / Machine Learning', status: 'Proposed', student: 'Bob', adviser: 'Dr. Santos' });
      console.log('Seeded default projects');
    }
  } catch (err) {
    console.error('Seed error', err);
  }
}

async function initDb() {
  await testDb();
  await sequelize.sync();
  await seedDefaults();
}

initDb();

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'] || '';
  const token = authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const payload = jwt.verify(token, SECRET);
    req.user = payload;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid token' });
  }
}

function authorizeRoles(roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}

app.post('/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body || {};
    const user = await User.findOne({ where: { username } });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ username: user.username, role: user.role }, SECRET, { expiresIn: '8h' });
    res.json({ token, role: user.role, username: user.username });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/auth/signup', async (req, res) => {
  try {
    const { username, password, role } = req.body || {};
    if (!username || !password || !role) return res.status(400).json({ error: 'username, password and role required' });
    const allowed = ['admin','adviser','student'];
    if (!allowed.includes(role)) return res.status(400).json({ error: 'Invalid role' });
    const exists = await User.findOne({ where: { username } });
    if (exists) return res.status(409).json({ error: 'User already exists' });
    const hashed = bcrypt.hashSync(password, 10);
    const user = await User.create({ username, password: hashed, role });
    const token = jwt.sign({ username: user.username, role: user.role }, SECRET, { expiresIn: '8h' });
    res.status(201).json({ token, role: user.role, username: user.username });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/me', authenticateToken, (req, res) => {
  res.json({ username: req.user.username, role: req.user.role });
});

app.get('/projects', authenticateToken, async (req, res) => {
  try {
    const projects = await Project.findAll({ order: [['createdAt','DESC']] });
    res.json(projects);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Admin: list users (without passwords)
app.get('/users', authenticateToken, authorizeRoles(['admin']), async (req, res) => {
  try {
    const users = await User.findAll({ attributes: ['id', 'username', 'role'], order: [['id','ASC']] });
    res.json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/projects/:id', authenticateToken, async (req, res) => {
  try {
    const id = req.params.id;
    const p = await Project.findByPk(id);
    if (!p) return res.status(404).json({ error: 'Not found' });
    res.json(p);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/projects', authenticateToken, authorizeRoles(['admin','student']), async (req, res) => {
  try {
    const body = req.body || {};
    const p = {
      title: body.title || 'Untitled',
      description: body.description || '',
      domain: body.domain || 'Unspecified',
      status: body.status || 'Proposed',
      student: body.student || '',
      adviser: body.adviser || '',
    };
    if (req.user && req.user.role === 'student' && !p.student) p.student = req.user.username;
    const created = await Project.create(p);
    res.status(201).json(created);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/classify', authenticateToken, (req, res) => {
  const text = (req.body && (req.body.title || req.body.description || '')).toLowerCase();
  let domain = 'Other';
  if (text.includes('mobile') || text.includes('web') || text.includes('flutter') || text.includes('react')) domain = 'Web & Mobile Development';
  else if (text.includes('machine') || text.includes('data') || text.includes('learning') || text.includes('vision') || text.includes('nlp')) domain = 'AI / Machine Learning';
  else if (text.includes('iot') || text.includes('sensor') || text.includes('arduino') || text.includes('raspberry')) domain = 'Embedded / IoT';
  else if (text.includes('security') || text.includes('network') || text.includes('encryption')) domain = 'Networking & Security';
  else if (text.includes('cloud') || text.includes('docker') || text.includes('ci/cd')) domain = 'Cloud & DevOps';
  res.json({ domain });
});

// Create a schedule (admin or adviser)
app.post('/schedules', authenticateToken, authorizeRoles(['admin','adviser']), async (req, res) => {
  try {
    const body = req.body || {};
    const projectId = body.projectId;
    const scheduledAt = body.scheduledAt;
    if (!projectId || !scheduledAt) return res.status(400).json({ error: 'projectId and scheduledAt required' });
    const payload = {
      projectId: projectId,
      scheduledAt: new Date(scheduledAt),
      location: body.location || '',
      notes: body.notes || '',
      createdBy: req.user ? req.user.username : null,
    };
    const created = await Schedule.create(payload);
    res.status(201).json(created);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get schedules for a project
app.get('/projects/:id/schedules', authenticateToken, async (req, res) => {
  try {
    const id = req.params.id;
    const schedules = await Schedule.findAll({ where: { projectId: id }, order: [['scheduledAt','ASC']] });
    res.json(schedules);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// List schedules, optionally filtered by student name (via project relation)
app.get('/schedules', authenticateToken, async (req, res) => {
  try {
    const student = req.query.student;
    const include = { model: Project };
    const findOptions = {
      include: [include],
      order: [['scheduledAt', 'ASC']],
    };
    if (student) {
      // filter by associated Project.student
      findOptions.include = [{ model: Project, where: { student: student } }];
    }
    const schedules = await Schedule.findAll(findOptions);
    res.json(schedules);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Capstone backend listening on ${port}`));
