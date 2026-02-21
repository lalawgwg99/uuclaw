#!/usr/bin/env node
/**
 * UUZero Standalone Runner
 * 獨立運行版本 - 不依賴 OpenClaw 框架
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROUTER_DIR = path.join(__dirname, 'modules', 'router');

// 檢查環境變數
function checkEnv() {
  const required = ['OPENROUTER_API_KEY'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    console.error('❌ 缺少必需的環境變數:');
    missing.forEach(k => console.error(`   - ${k}`));
    console.error('\n請設定環境變數後重試。');
    process.exit(1);
  }
}

// 運行 sanity check
function runSanityCheck() {
  console.log('🔍 執行 Sanity Check...\n');
  
  const checks = [
    { name: 'Router 目錄', test: () => fs.existsSync(ROUTER_DIR) },
    { name: 'Router CLI', test: () => fs.existsSync(path.join(ROUTER_DIR, 'dist', 'cli.js')) },
    { name: 'Dependencies', test: () => fs.existsSync(path.join(ROUTER_DIR, 'node_modules')) },
    { name: 'Config', test: () => fs.existsSync(path.join(ROUTER_DIR, 'dist', 'config.js')) }
  ];
  
  let passed = 0;
  checks.forEach(({ name, test }) => {
    try {
      if (test()) {
        console.log(`   ✅ ${name}`);
        passed++;
      } else {
        console.log(`   ❌ ${name} - 缺失`);
      }
    } catch (e) {
      console.log(`   ❌ ${name} - 錯誤: ${e.message}`);
    }
  });
  
  console.log(`\n📊 Sanity Check: ${passed}/${checks.length} 通過\n`);
  return passed === checks.length;
}

// 安裝依賴（如果需要）
function ensureDependencies() {
  const nodeModules = path.join(ROUTER_DIR, 'node_modules');
  if (!fs.existsSync(nodeModules)) {
    console.log('📦 安裝依賴中...');
    const result = spawn('npm', ['install'], { 
      cwd: ROUTER_DIR, 
      stdio: 'inherit',
      shell: true 
    });
    result.on('close', code => {
      if (code !== 0) {
        console.error('❌ 依賴安裝失敗');
        process.exit(code);
      }
      console.log('✅ 依賴就緒\n');
      startRouter();
    });
    return false;
  }
  return true;
}

// 啟動路由器
function startRouter() {
  console.log('🚀 啟動 UUZero Standalone Router...\n');
  console.log('使用方法: node standalone.js [--type <type>] --prompt "<你的任務>"');
  console.log('  或: echo "<任務>" | node standalone.js\n');
  
  // 如果沒有參數，進入交互模式
  if (process.argv.length <= 2) {
    console.log('🤖 交互模式已啟用 (輸入 "exit" 退出)\n');
    const rl = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    rl.on('line', async (line) => {
      if (line.trim() === 'exit' || line.trim() === 'quit') {
        rl.close();
        process.exit(0);
        return;
      }
      
      if (line.trim()) {
        await runTask('auto', line);
      }
      rl.prompt();
    });
    
    rl.setPrompt('UUZero> ');
    rl.prompt();
  } else {
    // 命令行參數模式
    const args = process.argv.slice(2);
    let taskType = 'auto';
    let prompt = '';
    
    for (let i = 0; i < args.length; i++) {
      if (args[i] === '--type' && args[i+1]) {
        taskType = args[++i];
      } else if (args[i] === '--prompt' && args[i+1]) {
        prompt = args[++i];
      } else if (!prompt && !args[i].startsWith('--')) {
        prompt = args[i];
      }
    }
    
    if (!prompt) {
      console.error('❌ 請提供 --prompt 參數或直接輸入任務文本');
      console.error('用法: node standalone.js [--type auto] --prompt "你的任務"');
      process.exit(1);
    }
    
    runTask(taskType, prompt).then(() => process.exit(0));
  }
}

async function runTask(taskType, prompt) {
  const cliPath = path.join(ROUTER_DIR, 'dist', 'cli.js');
  const args = ['--type', taskType, '--prompt', prompt, '--json'];
  
  try {
    const child = spawn('node', [cliPath, ...args], {
      cwd: ROUTER_DIR,
      env: { ...process.env },
      stdio: 'pipe'
    });
    
    let output = '';
    child.stdout.on('data', data => {
      process.stdout.write(data);
      output += data.toString();
    });
    
    child.stderr.on('data', data => {
      process.stderr.write(data);
    });
    
    await new Promise((resolve, reject) => {
      child.on('close', code => {
        if (code === 0) resolve();
        else reject(new Error(`Process exited with code ${code}`));
      });
      child.on('error', reject);
    });
    
    return output;
  } catch (e) {
    console.error(`\n❌ 執行失敗: ${e.message}`);
  }
}

// 主流程
async function main() {
  console.log('🦞 UUZero Standalone Build - 獨立全自動落地\n');
  console.log('❌ 外部協議依賴已排除');
  console.log('✅ 原生環境可跑 (僅需 Node.js + OpenRouter API Key)\n');
  
  checkEnv();
  
  if (!runSanityCheck()) {
    console.log('🔧 正在修復缺失組件...');
    if (!ensureDependencies()) return;
  }
  
  if (ensureDependencies()) {
    startRouter();
  }
}

main().catch(e => {
  console.error('💥 Fatal error:', e);
  process.exit(1);
});