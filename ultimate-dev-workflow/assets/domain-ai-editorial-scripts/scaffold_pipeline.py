#!/usr/bin/env python3
"""Scaffold a runnable AI web-novel pipeline project skeleton.

Generates the Phase-1 structure of a novel-pipeline-style project:
packaging, env template, central config, SQLite data layer, unified LLM
client (with mock), smoke tests, and placeholder directories.

Usage:
    python scaffold_pipeline.py --path /path/to/new-project [--name novel_pipeline]

The generated project is self-contained and `python run_tests.py` passes
without any external service.
"""

import argparse
import os
import shutil
import sys
from pathlib import Path


PYPROJECT = """\
[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[project]
name = "{name}"
version = "0.1.0"
description = "AI web-novel auto-generation and publishing pipeline"
requires-python = ">=3.9"
dependencies = []

[tool.setuptools.packages.find]
include = ["{pkg}*"]
"""

ENV_EXAMPLE = """\
# LLM
LLM_API_KEY=
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL_PLANNING=
LLM_MODEL_WRITING=
LLM_MODEL_EDITING=
LLM_MODEL_REVIEWING=
LLM_MODEL_MEMORY=
DEEPSEEK_API_KEY=

# Platform login state (Cookie + CSRF, refresh periodically)
PLATFORM_COOKIE=
PLATFORM_CSRF_TOKEN=
PLATFORM_BOOK_ID=
PLATFORM_VOLUME_ID=

# Budget and cost rates (CNY per 1k tokens)
MONTHLY_BUDGET=100
COST_PRO_PER_1K=0.01
COST_FLASH_PER_1K=0.002

# Runtime environment for orchestrator executeCommand nodes
PYTHON_EXE=C:/path/to/python.exe
PIPELINE_ROOT=C:/path/to/project
NODES_EXCLUDE=[]
"""

GITIGNORE = """\
*.db
*.db-shm
*.db-wal
*.log
.env
.venv/
__pycache__/
*.pyc
*.egg-info/
n8n_tmp/
exports/
backups/
"""

README = """\
# {title}

AI web-novel auto-generation and publishing pipeline.

## Layout

- `{pkg}/` - Python library (config / db / llm_client)
- `tools/` - pipeline scripts (called by the orchestrator)
- `prompts/agents/` - persona files (frontmatter: model/temperature/max_tokens)
- `prompts/knowledge/` - knowledge packages (frontmatter: agents/type/keywords)
- `n8n/` - workflow JSON sources
- `docs/planning/` - decisions and platform rules
- `tests/` - unittest suite (isolated, no real DB / webhooks)

## Quick start

```bash
cp .env.example ~/.n8n/.env   # fill keys
python run_tests.py           # smoke tests must pass
```
"""

PKG_INIT = '"""AI web-novel pipeline package."""\n'

CONFIG_PY = '''\
"""Central configuration: paths, env loading, and pipeline constants."""

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

AGENTS_DIR = ROOT / "prompts" / "agents"
KNOWLEDGE_DIR = ROOT / "prompts" / "knowledge"
TOOLS_DIR = ROOT / "tools"
N8N_DIR = ROOT / "n8n"
TMP_DIR = ROOT / "n8n_tmp"
DB_PATH = ROOT / "demo.db"
ENV_FILE = Path.home() / ".n8n" / ".env"


def load_env():
    """Process env wins; ~/.n8n/.env fills missing keys only."""
    env = dict(os.environ)
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                env.setdefault(k.strip(), v.strip())
    return env


def env_value(key, default=""):
    return load_env().get(key, default)
'''

DB_PY = '''\
"""SQLite data layer with migrations."""

import sqlite3
from pathlib import Path

from __PKG__ import config


SCHEMA = """
CREATE TABLE IF NOT EXISTS novels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    genre TEXT NOT NULL,
    premise TEXT NOT NULL,
    status TEXT DEFAULT 'planning',
    book_id TEXT DEFAULT '',
    volume_id TEXT DEFAULT '',
    tags TEXT DEFAULT '[]',
    abstract TEXT DEFAULT '',
    protagonists TEXT DEFAULT '[]',
    outline TEXT DEFAULT '{}',
    volume_goal TEXT DEFAULT '',
    updated_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS chapters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL REFERENCES novels(id),
    volume_id INTEGER REFERENCES volumes(id),
    seq INTEGER NOT NULL,
    outline TEXT NOT NULL,
    status TEXT DEFAULT 'draft',
    words INTEGER DEFAULT 0,
    score REAL DEFAULT 0,
    published_at TEXT,
    title TEXT DEFAULT '',
    fanqie_item_id TEXT DEFAULT '',
    UNIQUE(novel_id, seq)
);
CREATE TABLE IF NOT EXISTS volumes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL REFERENCES novels(id),
    name TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS chapter_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_id INTEGER NOT NULL REFERENCES chapters(id),
    content TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS chapter_summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_id INTEGER NOT NULL REFERENCES chapters(id),
    summary TEXT DEFAULT '',
    character_updates TEXT DEFAULT '{}',
    plot_events TEXT DEFAULT '[]',
    next_hook TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS characters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL REFERENCES novels(id),
    name TEXT NOT NULL,
    role TEXT DEFAULT '',
    traits TEXT DEFAULT '',
    goals TEXT DEFAULT '',
    state TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS character_evolution (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL,
    chapter_id INTEGER,
    name TEXT NOT NULL,
    snapshot TEXT DEFAULT '{}',
    change_log TEXT DEFAULT '',
    arc TEXT DEFAULT '',
    created_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS world_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL,
    chapter_id INTEGER,
    event_type TEXT DEFAULT '',
    content TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS plot_threads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL REFERENCES novels(id),
    planted_chapter INTEGER NOT NULL,
    expected_recover_chapter INTEGER,
    status TEXT DEFAULT 'open',
    description TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS quality_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_id INTEGER NOT NULL REFERENCES chapters(id),
    scores TEXT NOT NULL,
    passed INTEGER NOT NULL,
    revision_count INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS publish_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_id INTEGER NOT NULL REFERENCES chapters(id),
    platform TEXT NOT NULL,
    action TEXT NOT NULL,
    result TEXT NOT NULL,
    error TEXT,
    ai_declared INTEGER DEFAULT 1,
    created_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS cost_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER DEFAULT 0,
    node_name TEXT DEFAULT '',
    model TEXT DEFAULT '',
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    cost REAL DEFAULT 0,
    run_id TEXT DEFAULT '',
    created_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS agent_diaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent TEXT NOT NULL,
    novel_id INTEGER DEFAULT 0,
    diary_type TEXT DEFAULT 'daily',
    content TEXT DEFAULT '{}',
    created_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS agent_states (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent TEXT NOT NULL,
    novel_id INTEGER DEFAULT 0,
    mood TEXT DEFAULT '{}',
    updated_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS agent_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER DEFAULT 0,
    meeting_id INTEGER DEFAULT 0,
    agent TEXT NOT NULL,
    novel_id INTEGER,
    task TEXT NOT NULL,
    detail TEXT DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT DEFAULT '',
    completed_at TEXT DEFAULT '',
    result TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS agent_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent TEXT NOT NULL,
    novel_id INTEGER,
    activity_type TEXT NOT NULL,
    title TEXT NOT NULL,
    detail TEXT DEFAULT '{}',
    created_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS novel_knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER NOT NULL,
    category TEXT NOT NULL,
    entity TEXT NOT NULL,
    content TEXT NOT NULL,
    source_chapter INTEGER,
    version INTEGER NOT NULL DEFAULT 1,
    updated_at TEXT DEFAULT '',
    UNIQUE(novel_id, category, entity)
);
CREATE TABLE IF NOT EXISTS weekly_meetings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    novel_id INTEGER DEFAULT 0,
    held_at TEXT DEFAULT '',
    status TEXT DEFAULT 'completed',
    summary TEXT DEFAULT '',
    report TEXT DEFAULT '{}'
);
CREATE TABLE IF NOT EXISTS meeting_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    kind TEXT DEFAULT 'topic',
    topic TEXT DEFAULT '',
    status TEXT DEFAULT 'running',
    novel_id INTEGER DEFAULT 0,
    db_path TEXT DEFAULT '',
    attendees TEXT DEFAULT '[]',
    transcript TEXT DEFAULT '[]',
    report TEXT DEFAULT '',
    current_round INTEGER DEFAULT 0,
    instruction TEXT DEFAULT '',
    heartbeat_at TEXT DEFAULT '',
    created_at TEXT DEFAULT '',
    updated_at TEXT DEFAULT ''
);
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT DEFAULT '',
    category TEXT NOT NULL,
    action TEXT NOT NULL,
    target_type TEXT DEFAULT '',
    target_id TEXT DEFAULT '',
    detail TEXT DEFAULT '{}',
    source TEXT DEFAULT 'web'
);
"""


def connect(db_path=None):
    p = Path(db_path or config.DB_PATH)
    if not p.is_absolute():
        p = config.ROOT / p
    p.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(p))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA journal_mode=WAL")
    conn.executescript(SCHEMA)
    conn.commit()
    return conn
'''

LLM_CLIENT_PY = '''\
"""Unified LLM client: OpenAI-compatible chat with retries and cost estimate."""

import json
import time
import urllib.error
import urllib.request

from __PKG__ import config


def estimate_cost(model, usage, env=None):
    env = env if env is not None else config.load_env()
    is_flash = "flash" in str(model or "")
    try:
        rate = float(env.get("COST_FLASH_PER_1K") or 0.002) if is_flash else float(
            env.get("COST_PRO_PER_1K") or 0.01
        )
    except (TypeError, ValueError):
        rate = 0.002 if is_flash else 0.01
    pt = int(usage.get("prompt_tokens") or 0)
    ct = int(usage.get("completion_tokens") or 0)
    return round((pt + ct) / 1000.0 * rate, 6)


class LLMError(RuntimeError):
    pass


def chat_deepseek(model, system, user, temperature=0.5, max_tokens=1600,
                  messages=None, tools=None, json_mode=None):
    """Direct chat call. Returns {text, usage, model, tool_calls}.

    Empty content raises LLMError instead of silently succeeding. Retries
    429/5xx up to 3 attempts. Never forces tool_choice (thinking models
    reject it); callers implement their own tool loop when needed.
    """
    env = config.load_env()
    api_key = env.get("DEEPSEEK_API_KEY") or env.get("LLM_API_KEY")
    base_url = (env.get("LLM_BASE_URL") or "https://api.deepseek.com").rstrip("/")
    if not api_key:
        raise LLMError("DEEPSEEK_API_KEY / LLM_API_KEY not configured")
    msgs = messages or [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]
    payload = dict(
        model=model,
        messages=msgs,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    if tools:
        payload["tools"] = tools
    if json_mode:
        payload["response_format"] = dict(type="json_object")
    url = base_url + "/chat/completions"
    data = json.dumps(payload).encode("utf-8")
    last_err = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                url,
                data=data,
                method="POST",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": "Bearer " + api_key,
                },
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                body = json.loads(resp.read().decode("utf-8"))
            msg = body["choices"][0]["message"]
            text = msg.get("content") or ""
            usage = body.get("usage") or {}
            if not text.strip() and not msg.get("tool_calls"):
                raise LLMError("empty content from model")
            return {
                "text": text,
                "usage": usage,
                "model": model,
                "tool_calls": msg.get("tool_calls") or [],
            }
        except urllib.error.HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504):
                raise LLMError(f"LLM rejected: HTTP {exc.code}") from exc
            last_err = exc
        except (urllib.error.URLError, KeyError, ValueError) as exc:
            last_err = exc
        time.sleep(1.0 * (attempt + 1))
    raise LLMError(f"LLM call failed: {last_err}")


class MockLLMClient:
    """Deterministic client for tests and demos."""

    def __init__(self, responses=None):
        self.responses = dict(responses or {})
        self.calls = []

    def chat(self, system, user, tier="writing", temperature=0.8, max_tokens=2000):
        self.calls.append({"tier": tier, "system": system, "user": user})
        resp = self.responses.get(tier)
        if callable(resp):
            return resp(tier, system, user)
        return resp if resp is not None else f"[mock:{tier}]"
'''

SMOKE_TEST = '''\
import os
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)

from __PKG__ import config, db  # noqa: E402
from __PKG__.llm_client import MockLLMClient, estimate_cost  # noqa: E402


class SmokeTests(unittest.TestCase):
    def test_config_loads_env(self):
        self.assertTrue(config.ROOT.exists())

    def test_db_creates_core_tables(self):
        tmp = tempfile.mkdtemp()
        conn = db.connect(os.path.join(tmp, "t.db"))
        try:
            names = {
                r["name"]
                for r in conn.execute(
                    "SELECT name FROM sqlite_master WHERE type='table'"
                ).fetchall()
            }
            for required in ("novels", "chapters", "publish_logs", "cost_logs",
                             "agent_diaries", "novel_knowledge", "audit_logs"):
                self.assertIn(required, names)
        finally:
            conn.close()

    def test_mock_llm_and_cost(self):
        client = MockLLMClient({"writing": "hello"})
        self.assertEqual(client.chat("s", "u", tier="writing"), "hello")
        self.assertEqual(estimate_cost("deepseek-v4-flash", {"prompt_tokens": 1000, "completion_tokens": 0}), 0.002)


if __name__ == "__main__":
    unittest.main()
'''

RUN_TESTS = '''\
"""Run the full test suite (standard library only)."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

suite = unittest.TestLoader().discover(str(ROOT / "tests"))
result = unittest.TextTestRunner(verbosity=2).run(suite)
sys.exit(0 if result.wasSuccessful() else 1)
'''


PLACEHOLDERS = [
    ("tools", ".gitkeep"),
    ("prompts/agents", ".gitkeep"),
    ("prompts/knowledge", ".gitkeep"),
    ("n8n", ".gitkeep"),
    ("docs/planning", ".gitkeep"),
    ("docs/reviews", ".gitkeep"),
]


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description="Scaffold a novel-pipeline project")
    ap.add_argument("--path", required=True, help="target project directory")
    ap.add_argument("--name", default="novel-pipeline", help="project name")
    ap.add_argument("--force", action="store_true", help="overwrite existing dir")
    args = ap.parse_args()

    target = Path(args.path).resolve()
    if target.exists() and any(target.iterdir()) and not args.force:
        print(f"[abort] {target} is not empty; use --force to overwrite")
        sys.exit(1)
    pkg = args.name.replace("-", "_").lower()
    title = args.name.replace("_", " ").title()

    write(target / "pyproject.toml", PYPROJECT.format(name=args.name, pkg=pkg))
    write(target / ".env.example", ENV_EXAMPLE)
    write(target / ".gitignore", GITIGNORE)
    write(target / "README.md", README.format(title=title, pkg=pkg))
    write(target / "run_tests.py", RUN_TESTS)
    write(target / pkg / "__init__.py", PKG_INIT)
    write(target / pkg / "config.py", CONFIG_PY)
    write(target / pkg / "db.py", DB_PY.replace("__PKG__", pkg))
    write(target / pkg / "llm_client.py", LLM_CLIENT_PY.replace("__PKG__", pkg))
    write(target / "tests" / "test_smoke.py", SMOKE_TEST.replace("__PKG__", pkg))
    for sub, fname in PLACEHOLDERS:
        write(target / sub / fname, "")

    print(f"[ok] scaffolded {target}")
    print(f"[next] cd {target} && python run_tests.py")


if __name__ == "__main__":
    main()
