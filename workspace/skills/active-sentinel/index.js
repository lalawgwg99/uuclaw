#!/usr/bin/env node

/**
 * Active Sentinel - 24/7 監控特勤隊
 * Command: active-sentinel <command> [options]
 */

import fs from 'fs';
import path from 'path';
import https from 'https';
import http from 'http';
import { execSync } from 'child_process';

const CONFIG_DIR = path.join(process.env.HOME, '.config', 'active-sentinel');
const TASKS_FILE = path.join(CONFIG_DIR, 'tasks.json');
const ALERT_LOG = path.join(CONFIG_DIR, 'alerts.log');
const STATE_FILE = path.join(CONFIG_DIR, 'state.json');

// 確保配置目錄存在
if (!fs.existsSync(CONFIG_DIR)) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
}

// 工具函數
function loadTasks() {
  if (!fs.existsSync(TASKS_FILE)) return [];
  return JSON.parse(fs.readFileSync(TASKS_FILE, 'utf8'));
}

function saveTasks(tasks) {
  fs.writeFileSync(TASKS_FILE, JSON.stringify(tasks, null, 2));
}

function logAlert(msg) {
  const time = new Date().toISOString();
  const line = `[${time}] ${msg}\n`;
  fs.appendFileSync(ALERT_LOG, line);
  console.error(line.trim());
}

function sendAlert(task, reason, details = '') {
  logAlert(`🚨 [${task.name}] ${reason} - ${details}`);
  const alertFile = path.join(CONFIG_DIR, 'pending-alerts', `${Date.now()}-${task.name}.txt`);
  fs.mkdirSync(path.dirname(alertFile), { recursive: true });
  fs.writeFileSync(alertFile, JSON.stringify({
    task: task.name,
    reason,
    details,
    timestamp: new Date().toISOString()
  }));
}

function httpCheck(task) {
  return new Promise((resolve) => {
    const lib = task.url.startsWith('https') ? https : http;
    const start = Date.now();
    const req = lib.get(task.url, { timeout: task.timeout || 10000 }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        resolve({
          status: res.statusCode,
          duration,
          body: data,
          ok: true
        });
      });
    });
    req.on('error', (err) => resolve({ ok: false, error: err.message }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ ok: false, error: 'timeout' });
    });
  });
}

function runTask(task) {
  return httpCheck(task).then(result => {
    if (!result.ok) {
      return { status: 'fail', error: result.error };
    }
    if (task.expect && result.status !== task.expect) {
      return { status: 'fail', error: `status ${result.status} != ${task.expect}` };
    }
    if (task.contains && !result.body.includes(task.contains)) {
      return { status: 'fail', error: `body missing "${task.contains}"` };
    }
    if (task.maxDuration && result.duration > task.maxDuration) {
      return { status: 'fail', error: `slow response ${result.duration}ms` };
    }
    return { status: 'ok', duration: result.duration };
  });
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) return {};
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function cooldownElapsed(task, state) {
  const lastAlert = state[`alert:${task.name}`];
  const now = Date.now();
  const cooldown = task.cooldown || 10 * 60 * 1000;
  if (!lastAlert) return true;
  return now - lastAlert > cooldown;
}

function markAlerted(task, state) {
  state[`alert:${task.name}`] = Date.now();
  saveState(state);
}

async function runAll() {
  const tasks = loadTasks();
  const state = loadState();
  let changed = false;
  for (const task of tasks) {
    if (!task.enabled) continue;
    try {
      const result = await runTask(task);
      if (result.status !== 'ok') {
        console.log(`❌ ${task.name}: ${result.error}`);
        if (cooldownElapsed(task, state)) {
          sendAlert(task, '檢查失敗', result.error);
          markAlerted(task, state);
          changed = true;
        }
      } else {
        console.log(`✅ ${task.name}: ${result.duration}ms`);
        if (state[`alert:${task.name}`]) {
          delete state[`alert:${task.name}`];
          changed = true;
        }
      }
    } catch (e) {
      console.error(`💥 ${task.name}: ${e.message}`);
    }
  }
  if (changed) saveState(state);
}

// CLI
const command = process.argv[2];

switch (command) {
  case 'add':
    {
      const name = process.argv[3];
      const args = process.argv.slice(4);
      const task = { name, enabled: true };
      for (let i = 0; i < args.length; i++) {
        if (args[i] === '--url') task.url = args[++i];
        else if (args[i] === '--interval') task.interval = parseInt(args[++i]);
        else if (args[i] === '--expect') task.expect = parseInt(args[++i]);
        else if (args[i] === '--contains') task.contains = args[++i];
        else if (args[i] === '--cooldown') task.cooldown = parseInt(args[++i]) * 60 * 1000;
        else if (args[i] === '--max-duration') task.maxDuration = parseInt(args[++i]);
      }
      const tasks = loadTasks();
      tasks.push(task);
      saveTasks(tasks);
      console.log(`✅ 已新增監控：${name}`);
    }
    break;

  case 'list':
    const tasks = loadTasks();
    console.log('監控任務清單：');
    tasks.forEach(t => {
      console.log(`  ${t.enabled ? '🟢' : '🔴'} ${t.name} → ${t.url} (interval=${t.interval}s)`);
    });
    break;

  case 'remove':
    const nameToRemove = process.argv[3];
    let tasks2 = loadTasks().filter(t => t.name !== nameToRemove);
    saveTasks(tasks2);
    console.log(`✅ 已移除：${nameToRemove}`);
    break;

  case 'test':
    const testName = process.argv[3];
    const t = loadTasks().find(x => x.name === testName);
    if (!t) {
      console.error('找不到任務');
      process.exit(1);
    }
    runTask(t).then(r => {
      if (r.status === 'ok') {
        console.log(`✅ 檢查成功，耗時 ${r.duration}ms`);
      } else {
        console.log(`❌ 檢查失敗：${r.error}`);
      }
    });
    break;

  case 'run':
    runAll().then(() => console.log('🏁 檢查完成'));
    break;

  default:
    console.log(`
Active Sentinel - 24/7 監控特勤隊

用法：
  active-sentinel add <name> --url <url> [--interval <sec>] [--expect <status>] [--contains <text>]
  active-sentinel list
  active-sentinel remove <name>
  active-sentinel test <name>
  active-sentinel run   # 執行所有檢查

示例：
  active-sentinel add mysite --url https://example.com --interval 30 --expect 200
  active-sentinel add api --url https://api.example.com/health --contains '"ok":true'
`);
    process.exit(1);
}