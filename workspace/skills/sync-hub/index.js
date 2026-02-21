#!/usr/bin/env node

/**
 * Sync Hub - 跨平台數據同步中樞
 * Command: sync-hub <command> [options]
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const CONFIG_DIR = path.join(process.env.HOME, '.config', 'sync-hub');
const PIPES_FILE = path.join(CONFIG_DIR, 'pipes.json');
const HISTORY_FILE = path.join(CONFIG_DIR, 'history.jsonl');

if (!fs.existsSync(CONFIG_DIR)) fs.mkdirSync(CONFIG_DIR, { recursive: true });

function loadPipes() {
  if (!fs.existsSync(PIPES_FILE)) return [];
  return JSON.parse(fs.readFileSync(PIPES_FILE, 'utf8'));
}

function savePipes(pipes) {
  fs.writeFileSync(PIPES_FILE, JSON.stringify(pipes, null, 2));
}

function logHistory(entry) {
  const line = JSON.stringify({ ...entry, ts: new Date().toISOString() }) + '\n';
  fs.appendFileSync(HISTORY_FILE, line);
}

function usage() {
  console.log(`
Sync Hub - 跨平台數據同步

用法：
  sync-hub pipe add <name> --source <src> --target <tgt> [--direction <both|one-way>] [--map <mapping>]
  sync-hub list
  sync-hub run <name>
  sync-hub history [--last <n>]
  sync-hub remove <name>

來源/目標格式：
  telegram://<chat_id>
  things://<list>
  obsidian://<vault>/<folder>
  sheets://<spreadsheet_id>/<sheet_name>

示例：
  sync-hub pipe add tg2things --source telegram://12345 --target things://inbox --direction both
`);
  process.exit(1);
}

// 簡易單向同步實作（MVP）
async function runPipe(pipe) {
  console.log(`🔄 運行同步管道：${pipe.name}`);
  console.log(`   從 ${pipe.source} 同步到 ${pipe.target}`);

  // TODO: 根據 source/target type 調用對應 CLI
  // 目前僅 logging

  logHistory({
    pipe: pipe.name,
    status: 'success',
    items: 0
  });

  return { success: true };
}

const command = process.argv[2];
const args = process.argv.slice(3);

switch (command) {
  case 'pipe':
    if (args[0] === 'add') {
      const name = args[1];
      const pipe = { name };
      for (let i = 2; i < args.length; i++) {
        if (args[i] === '--source') pipe.source = args[++i];
        else if (args[i] === '--target') pipe.target = args[++i];
        else if (args[i] === '--direction') pipe.direction = args[++i];
        else if (args[i] === '--map') pipe.map = args[++i];
      }
      const pipes = loadPipes();
      pipes.push(pipe);
      savePipes(pipes);
      console.log(`✅ 管道已建立：${name}`);
    } else if (args[0] === 'list') {
      const pipes = loadPipes();
      console.log('同步管道清單：');
      pipes.forEach(p => {
        console.log(`  ${p.name}: ${p.source} → ${p.target} (${p.direction || 'one-way'})`);
      });
    } else if (args[0] === 'remove') {
      const name = args[1];
      let pipes = loadPipes().filter(p => p.name !== name);
      savePipes(pipes);
      console.log(`✅ 管道已刪除：${name}`);
    } else {
      usage();
    }
    break;

  case 'run':
    const pipeName = args[0];
    const pipes = loadPipes();
    const pipe = pipes.find(p => p.name === pipeName);
    if (!pipe) {
      console.error('找不到管道');
      process.exit(1);
    }
    await runPipe(pipe).then(r => {
      if (r.success) console.log(`✅ ${pipeName} 同步完成`);
      else console.log(`❌ ${pipeName} 同步失敗`);
    });
    break;

  case 'list':
    loadPipes().forEach(p => console.log(p.name));
    break;

  case 'history':
    const lastN = parseInt(args.find(a => a === '--last' ? args[args.indexOf('--last') + 1] : null)) || 10;
    if (!fs.existsSync(HISTORY_FILE)) {
      console.log('無歷史記錄');
      break;
    }
    const lines = fs.readFileSync(HISTORY_FILE, 'utf8').trim().split('\n').slice(-lastN);
    lines.forEach(l => {
      const rec = JSON.parse(l);
      console.log(`[${rec.ts}] ${rec.pipe}: ${rec.status} (${rec.items} items)`);
    });
    break;

  case 'remove':
    const nameToRemove = args[0];
    let pipes2 = loadPipes().filter(p => p.name !== nameToRemove);
    savePipes(pipes2);
    console.log(`✅ 管道已刪除：${nameToRemove}`);
    break;

  default:
    usage();
}