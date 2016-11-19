CREATE TABLE posts(
  id INTEGER NOT NULL PRIMARY KEY,
  title TEXT,
  slug TEXT,
  body TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
