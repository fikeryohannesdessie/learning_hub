const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const { DatabaseSync } = require("node:sqlite");

const app = express();
const PORT = process.env.PORT || 3000;

// #region debug-point C:server-file-response
function reportDebug(hypothesisId, msg, data = {}) {
  fetch("http://127.0.0.1:7777/event", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      sessionId: "web-pdf-blank",
      runId: "pre-fix",
      hypothesisId,
      location: "server.js",
      msg: `[DEBUG] ${msg}`,
      data,
      ts: Date.now(),
    }),
  }).catch(() => {});
}
// #endregion

app.use(cors());
app.use(express.json({ limit: "100mb" }));

// Ensure upload directory exists
const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

function detectMimeType(buffer) {
  if (!buffer || buffer.length === 0) {
    return "application/octet-stream";
  }

  if (
    buffer.length >= 5 &&
    buffer.subarray(0, 5).toString("utf8") === "%PDF-"
  ) {
    return "application/pdf";
  }

  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return "image/png";
  }

  if (
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
    return "image/jpeg";
  }

  if (
    buffer.length >= 12 &&
    buffer.subarray(0, 4).toString("utf8") === "RIFF" &&
    buffer.subarray(8, 12).toString("utf8") === "WAVE"
  ) {
    return "audio/wav";
  }

  if (
    buffer.length >= 8 &&
    buffer.subarray(4, 8).toString("utf8") === "ftyp"
  ) {
    return "video/mp4";
  }

  if (
    buffer.length >= 3 &&
    buffer.subarray(0, 3).toString("utf8") === "ID3"
  ) {
    return "audio/mpeg";
  }

  return "application/octet-stream";
}

function mimeTypeToExtension(mimeType) {
  switch (mimeType) {
    case "application/pdf":
      return "pdf";
    case "image/png":
      return "png";
    case "image/jpeg":
      return "jpg";
    case "audio/wav":
      return "wav";
    case "audio/mpeg":
      return "mp3";
    case "video/mp4":
      return "mp4";
    default:
      return "bin";
  }
}

// Initialize SQLite database
const db = new DatabaseSync(path.join(__dirname, "database.db"));

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    uid TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    role TEXT NOT NULL DEFAULT 'viewer',
    is_verified INTEGER NOT NULL DEFAULT 0,
    verification_submitted INTEGER NOT NULL DEFAULT 0,
    institution TEXT,
    id_number TEXT,
    credential_file_id TEXT,
    is_rejected INTEGER NOT NULL DEFAULT 0,
    verification_comment TEXT,
    bio TEXT,
    security_answers TEXT,
    created_at TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS user_passwords (
    email TEXT PRIMARY KEY,
    password TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS content (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    url TEXT,
    grade_level TEXT,
    subject TEXT,
    description TEXT,
    extra_data TEXT,
    rejection_reason TEXT,
    uploaded_at TEXT NOT NULL,
    approved_at TEXT
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS artifacts (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    sections_json TEXT NOT NULL,
    viewer_ids_json TEXT NOT NULL DEFAULT '[]',
    rejection_reason TEXT,
    thumbnail_url TEXT,
    is_sequential INTEGER NOT NULL DEFAULT 1,
    classification TEXT NOT NULL DEFAULT 'tangible',
    detailed_description TEXT,
    heritage_significance_json TEXT,
    created_at TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS bookmarks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    extra_data TEXT NOT NULL DEFAULT '{}',
    bookmarked_at TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS analysis_results (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    artifact_id TEXT NOT NULL,
    section_id TEXT NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    completed_at TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS user_progress (
    user_id TEXT NOT NULL,
    artifact_id TEXT NOT NULL,
    completed_content_ids TEXT NOT NULL DEFAULT '[]',
    analysis_scores TEXT NOT NULL DEFAULT '{}',
    last_accessed_item_id TEXT,
    last_accessed_at TEXT NOT NULL,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, artifact_id)
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS translations (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS storage_entries (
    box_name TEXT NOT NULL,
    entry_key TEXT NOT NULL,
    value_type TEXT NOT NULL,
    text_value TEXT,
    blob_value BLOB,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (box_name, entry_key)
  )
`);

// Seed Admin User
const checkAdmin = db
  .prepare("SELECT * FROM users WHERE email = ?")
  .get("admin@chpa.org");
if (!checkAdmin) {
  db.prepare(
    `
    INSERT INTO users (uid, email, display_name, role, is_verified, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `,
  ).run(
    "hardcoded_admin_01",
    "admin@chpa.org",
    "Heritage Admin",
    "admin",
    1,
    "2024-01-01T00:00:00.000Z",
  );

  db.prepare(
    `
    INSERT INTO user_passwords (email, password)
    VALUES (?, ?)
  `,
  ).run("admin@chpa.org", "admin123");
  console.log("Admin seeded successfully.");
}

// ------------------------------------------------------------- USERS API
app.post("/api/users", (req, res) => {
  const user = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO users (
        uid, email, display_name, role, is_verified, verification_submitted,
        institution, id_number, credential_file_id, is_rejected,
        verification_comment, bio, security_answers, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    ).run(
      user.uid,
      user.email,
      user.display_name ?? null,
      user.role ?? "viewer",
      user.is_verified ?? 0,
      user.verification_submitted ?? 0,
      user.institution ?? null,
      user.id_number ?? null,
      user.credential_file_id ?? null,
      user.is_rejected ?? 0,
      user.verification_comment ?? null,
      user.bio ?? null,
      user.security_answers ?? null,
      user.created_at,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/users/by-email/:email", (req, res) => {
  try {
    const row = db
      .prepare("SELECT * FROM users WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))")
      .get(req.params.email);
    res.json(row || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/users/by-uid/:uid", (req, res) => {
  try {
    const row = db
      .prepare("SELECT * FROM users WHERE uid = ?")
      .get(req.params.uid);
    res.json(row || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/users", (req, res) => {
  try {
    const rows = db
      .prepare("SELECT * FROM users ORDER BY created_at ASC")
      .all();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/users/:uid", (req, res) => {
  const fields = req.body;
  try {
    const keys = Object.keys(fields);
    if (keys.length === 0) return res.json({ success: true });

    const setClause = keys.map((k) => `${k} = ?`).join(", ");
    const values = keys.map((k) => fields[k]);
    values.push(req.params.uid);

    db.prepare(`UPDATE users SET ${setClause} WHERE uid = ?`).run(...values);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/users/:email", (req, res) => {
  try {
    const email = req.params.email.trim().toLowerCase();
    db.prepare("DELETE FROM users WHERE LOWER(TRIM(email)) = ?").run(email);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- PASSWORDS API
app.post("/api/passwords", (req, res) => {
  const { email, password } = req.body;
  try {
    db.prepare(
      "INSERT OR REPLACE INTO user_passwords (email, password) VALUES (?, ?)",
    ).run(email.trim().toLowerCase(), password);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/passwords/:email", (req, res) => {
  try {
    const row = db
      .prepare(
        "SELECT password FROM user_passwords WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))",
      )
      .get(req.params.email);
    res.json(row ? row.password : null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/passwords/:email", (req, res) => {
  try {
    db.prepare(
      "DELETE FROM user_passwords WHERE LOWER(TRIM(email)) = LOWER(TRIM(?))",
    ).run(req.params.email);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- CONTENT API
app.post("/api/content", (req, res) => {
  const item = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO content (
        id, title, type, author_id, author_name, status, url, grade_level,
        subject, description, extra_data, rejection_reason, uploaded_at, approved_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    ).run(
      item.id,
      item.title,
      item.type,
      item.author_id,
      item.author_name,
      item.status,
      item.url,
      item.grade_level,
      item.subject,
      item.description,
      item.extra_data,
      item.rejection_reason,
      item.uploaded_at,
      item.approved_at,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/content/:id", (req, res) => {
  try {
    const row = db
      .prepare("SELECT * FROM content WHERE id = ?")
      .get(req.params.id);
    res.json(row || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/content", (req, res) => {
  const { status, author_id } = req.query;
  try {
    let rows;
    if (status) {
      rows = db
        .prepare(
          "SELECT * FROM content WHERE status = ? ORDER BY uploaded_at DESC",
        )
        .all(status);
    } else if (author_id) {
      rows = db
        .prepare(
          "SELECT * FROM content WHERE author_id = ? ORDER BY uploaded_at DESC",
        )
        .all(author_id);
    } else {
      rows = db
        .prepare("SELECT * FROM content ORDER BY uploaded_at DESC")
        .all();
    }
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/content/:id/status", (req, res) => {
  const { status, rejection_reason, approved_at } = req.body;
  try {
    db.prepare(
      "UPDATE content SET status = ?, rejection_reason = ?, approved_at = ? WHERE id = ?",
    ).run(status, rejection_reason || null, approved_at || null, req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/content/by-author/:authorId", (req, res) => {
  try {
    const authorId = req.params.authorId;
    const contentItems = db
      .prepare("SELECT id FROM content WHERE author_id = ?")
      .all(authorId);

    // Delete files too
    contentItems.forEach((item) => {
      const filePath = path.join(uploadDir, `content_${item.id}.bin`);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    });

    db.prepare("DELETE FROM content WHERE author_id = ?").run(authorId);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/content/:id", (req, res) => {
  try {
    db.prepare("DELETE FROM content WHERE id = ?").run(req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- ARTIFACTS API
app.post("/api/artifacts", (req, res) => {
  const item = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO artifacts (
        id, title, description, author_id, author_name, status, sections_json,
        viewer_ids_json, rejection_reason, thumbnail_url, is_sequential,
        classification, detailed_description, heritage_significance_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    ).run(
      item.id,
      item.title,
      item.description,
      item.author_id,
      item.author_name,
      item.status,
      item.sections_json,
      item.viewer_ids_json || "[]",
      item.rejection_reason,
      item.thumbnail_url,
      item.is_sequential !== undefined ? item.is_sequential : 1,
      item.classification || "tangible",
      item.detailed_description,
      item.heritage_significance_json,
      item.created_at,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/artifacts/:id", (req, res) => {
  try {
    const row = db
      .prepare("SELECT * FROM artifacts WHERE id = ?")
      .get(req.params.id);
    res.json(row || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/artifacts", (req, res) => {
  const { status, author_id, classification } = req.query;
  try {
    let rows;
    if (status && classification) {
      rows = db
        .prepare(
          "SELECT * FROM artifacts WHERE status = ? AND classification = ? ORDER BY created_at DESC",
        )
        .all(status, classification);
    } else if (status) {
      rows = db
        .prepare(
          "SELECT * FROM artifacts WHERE status = ? ORDER BY created_at DESC",
        )
        .all(status);
    } else if (author_id) {
      rows = db
        .prepare(
          "SELECT * FROM artifacts WHERE author_id = ? ORDER BY created_at DESC",
        )
        .all(author_id);
    } else {
      rows = db
        .prepare("SELECT * FROM artifacts ORDER BY created_at DESC")
        .all();
    }
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/artifacts/:id/status", (req, res) => {
  const { status, rejection_reason } = req.body;
  try {
    db.prepare(
      "UPDATE artifacts SET status = ?, rejection_reason = ? WHERE id = ?",
    ).run(status, rejection_reason || null, req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/artifacts/:id/viewer-ids", (req, res) => {
  const { viewer_ids_json } = req.body;
  try {
    db.prepare("UPDATE artifacts SET viewer_ids_json = ? WHERE id = ?").run(
      viewer_ids_json,
      req.params.id,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- BOOKMARKS API
app.post("/api/bookmarks", (req, res) => {
  const item = req.body;
  try {
    db.prepare(
      "INSERT OR REPLACE INTO bookmarks (id, title, type, extra_data, bookmarked_at) VALUES (?, ?, ?, ?, ?)",
    ).run(
      item.id,
      item.title,
      item.type,
      item.extra_data || "{}",
      item.bookmarked_at,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/bookmarks", (req, res) => {
  try {
    const rows = db
      .prepare("SELECT * FROM bookmarks ORDER BY bookmarked_at DESC")
      .all();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/bookmarks/:id/exists", (req, res) => {
  try {
    const row = db
      .prepare("SELECT id FROM bookmarks WHERE id = ?")
      .get(req.params.id);
    res.json(!!row);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/bookmarks/:id", (req, res) => {
  try {
    db.prepare("DELETE FROM bookmarks WHERE id = ?").run(req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- ANALYSIS RESULTS API
app.post("/api/analysis-results", (req, res) => {
  const row = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO analysis_results (
        id, user_id, user_name, artifact_id, section_id, score, total_questions, completed_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    ).run(
      row.id,
      row.user_id,
      row.user_name,
      row.artifact_id,
      row.section_id,
      row.score,
      row.total_questions,
      row.completed_at,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/analysis-results/by-artifact/:artifactId", (req, res) => {
  try {
    const rows = db
      .prepare(
        "SELECT * FROM analysis_results WHERE artifact_id = ? ORDER BY completed_at DESC",
      )
      .all(req.params.artifactId);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/analysis-results/by-user/:userId", (req, res) => {
  try {
    const rows = db
      .prepare(
        "SELECT * FROM analysis_results WHERE user_id = ? ORDER BY completed_at DESC",
      )
      .all(req.params.userId);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- USER PROGRESS API
app.post("/api/user-progress", (req, res) => {
  const row = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO user_progress (
        user_id, artifact_id, completed_content_ids, analysis_scores, last_accessed_item_id, last_accessed_at, time_spent_seconds
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `,
    ).run(
      row.user_id,
      row.artifact_id,
      row.completed_content_ids,
      row.analysis_scores,
      row.last_accessed_item_id,
      row.last_accessed_at,
      row.time_spent_seconds || 0,
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/user-progress/:userId/:artifactId", (req, res) => {
  try {
    const row = db
      .prepare(
        "SELECT * FROM user_progress WHERE user_id = ? AND artifact_id = ?",
      )
      .get(req.params.userId, req.params.artifactId);
    res.json(row || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- TRANSLATIONS API
app.post("/api/translations", (req, res) => {
  const { key, value } = req.body;
  try {
    db.prepare(
      "INSERT OR REPLACE INTO translations (key, value) VALUES (?, ?)",
    ).run(key, value);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/translations/:key", (req, res) => {
  try {
    const row = db
      .prepare("SELECT value FROM translations WHERE key = ?")
      .get(req.params.key);
    res.json(row ? row.value : null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- SQLITE STORAGE API
app.get("/api/storage/:boxName", (req, res) => {
  try {
    const rows = db
      .prepare(
        `
      SELECT box_name, entry_key, value_type, text_value, blob_value, updated_at
      FROM storage_entries
      WHERE box_name = ?
      ORDER BY updated_at ASC
    `,
      )
      .all(req.params.boxName);

    res.json(
      rows.map((row) => ({
        ...row,
        blob_value: row.blob_value
          ? Buffer.from(row.blob_value).toString("base64")
          : null,
      })),
    );
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/storage/:boxName/:key", (req, res) => {
  const { value_type, text_value, blob_value, updated_at } = req.body;
  try {
    db.prepare(
      `
      INSERT OR REPLACE INTO storage_entries (
        box_name, entry_key, value_type, text_value, blob_value, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?)
    `,
    ).run(
      req.params.boxName,
      req.params.key,
      value_type,
      text_value ?? null,
      blob_value ? Buffer.from(blob_value, "base64") : null,
      updated_at || Date.now(),
    );

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/storage/:boxName/:key", (req, res) => {
  try {
    db.prepare(
      "DELETE FROM storage_entries WHERE box_name = ? AND entry_key = ?",
    ).run(req.params.boxName, req.params.key);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------------------------------------------- FILE UPLOADS/DOWNLOADS
app.post(
  "/api/files/:type/:id",
  express.raw({ type: "*/*", limit: "100mb" }),
  (req, res) => {
    const { type, id } = req.params;
    reportDebug("C", "Incoming file upload request", {
      type,
      id,
      contentType: req.headers["content-type"] || null,
      contentLength: req.headers["content-length"] || null,
      bodyType: Buffer.isBuffer(req.body) ? "buffer" : typeof req.body,
      bodyLength: Buffer.isBuffer(req.body) ? req.body.length : null,
    });
    if (type !== "content" && type !== "artifact") {
      reportDebug("C", "Rejected invalid upload type", { type, id });
      return res.status(400).json({ error: "Invalid type" });
    }

    if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
      reportDebug("C", "Rejected empty upload body", {
        type,
        id,
        bodyType: Buffer.isBuffer(req.body) ? "buffer" : typeof req.body,
      });
      return res.status(400).json({ error: "Empty file body" });
    }

    const filePath = path.join(uploadDir, `${type}_${id}.bin`);
    try {
      fs.writeFileSync(filePath, req.body);
      reportDebug("C", "Stored uploaded file", {
        type,
        id,
        filePath,
        bytesWritten: req.body.length,
      });
      res.json({ success: true });
    } catch (err) {
      reportDebug("C", "Failed to store uploaded file", {
        type,
        id,
        error: err.message,
      });
      res.status(500).json({ error: err.message });
    }
  },
);

app.get("/api/files/:type/:id", (req, res) => {
  const { type, id } = req.params;
  reportDebug("C", "Incoming file download request", { type, id });
  if (type !== "content" && type !== "artifact") {
    reportDebug("C", "Rejected invalid file type", { type, id });
    return res.status(400).json({ error: "Invalid type" });
  }

  const filePath = path.join(uploadDir, `${type}_${id}.bin`);
  if (!fs.existsSync(filePath)) {
    reportDebug("C", "Requested file missing", { type, id, filePath });
    return res.status(404).send("File not found");
  }

  try {
    const fileBuffer = fs.readFileSync(filePath);
    const mimeType = detectMimeType(fileBuffer);
    const extension = mimeTypeToExtension(mimeType);
    const disposition =
      mimeType === "application/pdf" ? "inline" : "attachment";
    reportDebug("C", "Serving file response", {
      type,
      id,
      mimeType,
      extension,
      disposition,
      length: fileBuffer.length,
    });

    res.setHeader("Content-Type", mimeType);
    res.setHeader(
      "Content-Disposition",
      `${disposition}; filename="${type}_${id}.${extension}"`,
    );
    res.setHeader("Content-Length", fileBuffer.length);
    res.send(fileBuffer);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.delete("/api/files/:type/:id", (req, res) => {
  const { type, id } = req.params;
  if (type !== "content" && type !== "artifact") {
    return res.status(400).json({ error: "Invalid type" });
  }

  const filePath = path.join(uploadDir, `${type}_${id}.bin`);
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`CHPA Backend Server listening on port ${PORT}`);
});
