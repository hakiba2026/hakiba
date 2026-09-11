-- حقيبة الأستاذ — المخطط الأولي لقاعدة بيانات D1 (SQLite)
-- ملاحظة: هذا اسكيلتون بداية، يُستكمل تدريجيًا حسب كل module (كل module يضيف جداوله الخاصة ببادئة plg_<module>_ في schema.sql الخاص به).

-- ============ المستخدمون والأدوار ============
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  locale TEXT NOT NULL DEFAULT 'ar', -- 'ar' | 'fr'
  is_active INTEGER NOT NULL DEFAULT 1,
  is_identity_verified INTEGER NOT NULL DEFAULT 0,
  two_factor_enabled INTEGER NOT NULL DEFAULT 0,
  two_factor_secret TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS roles (
  id TEXT PRIMARY KEY,
  key TEXT UNIQUE NOT NULL -- 'super_admin' | 'content_admin' | 'support' | 'billing'
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL REFERENCES users(id),
  role_id TEXT NOT NULL REFERENCES roles(id),
  PRIMARY KEY (user_id, role_id)
);

-- ============ الباقات والاشتراكات ============
CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  price_dzd INTEGER NOT NULL,
  duration_days INTEGER NOT NULL, -- 30 | 180 | 365
  monthly_lesson_quota INTEGER NOT NULL,
  monthly_exercise_quota INTEGER NOT NULL,
  monthly_exam_quota INTEGER NOT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  plan_id TEXT NOT NULL REFERENCES plans(id),
  status TEXT NOT NULL DEFAULT 'active', -- 'active' | 'frozen' | 'cancelled' | 'expired'
  starts_at TEXT NOT NULL,
  ends_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS activation_codes (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL, -- HQB-XXXX-XXXX-XXXX + checksum
  plan_id TEXT NOT NULL REFERENCES plans(id),
  duration_days INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'unused', -- 'unused' | 'used' | 'expired'
  linked_email TEXT,
  used_by_user_id TEXT REFERENCES users(id),
  used_at TEXT,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============ الصلاحيات / Plugins ============
CREATE TABLE IF NOT EXISTS plugins (
  id TEXT PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  name_ar TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  icon TEXT,
  category TEXT
);

CREATE TABLE IF NOT EXISTS plan_plugins (
  plan_id TEXT NOT NULL REFERENCES plans(id),
  plugin_id TEXT NOT NULL REFERENCES plugins(id),
  PRIMARY KEY (plan_id, plugin_id)
);

CREATE TABLE IF NOT EXISTS user_plugin_overrides (
  user_id TEXT NOT NULL REFERENCES users(id),
  plugin_id TEXT NOT NULL REFERENCES plugins(id),
  enabled INTEGER NOT NULL, -- 1 = منح استثنائي, 0 = سحب استثنائي
  PRIMARY KEY (user_id, plugin_id)
);

-- ============ التصنيف الأكاديمي ============
CREATE TABLE IF NOT EXISTS stages (
  id TEXT PRIMARY KEY, name_ar TEXT NOT NULL, name_fr TEXT NOT NULL, sort_order INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS branches (
  id TEXT PRIMARY KEY, stage_id TEXT NOT NULL REFERENCES stages(id), name_ar TEXT NOT NULL, name_fr TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS levels (
  id TEXT PRIMARY KEY, branch_id TEXT REFERENCES branches(id), stage_id TEXT NOT NULL REFERENCES stages(id), name_ar TEXT NOT NULL, name_fr TEXT NOT NULL, sort_order INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS subjects (
  id TEXT PRIMARY KEY, level_id TEXT NOT NULL REFERENCES levels(id), name_ar TEXT NOT NULL, name_fr TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS units (
  id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES subjects(id), name_ar TEXT NOT NULL, name_fr TEXT NOT NULL, sort_order INTEGER DEFAULT 0
);

-- ============ الطابور ============
CREATE TABLE IF NOT EXISTS jobs (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL, -- 'lesson' | 'exercise' | 'exam'
  user_id TEXT NOT NULL REFERENCES users(id),
  payload_json TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'processing' | 'done' | 'failed'
  retry_count INTEGER NOT NULL DEFAULT 0,
  result_url TEXT,
  error_message TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============ التدقيق ============
CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
