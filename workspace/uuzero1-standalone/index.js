/**
 * UUZero Skill - OpenClaw Integration
 * 提供與 OpenClaw 的橋接，執行時會啟動獨立伺服器並呼叫 API
 */

const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const fs = require('fs');

const ROOT = __dirname;
const SERVER_JS = path.join(ROOT, 'server.js');
const CONFIG_PATH = path.join(ROOT, 'config', 'router-config.json');
const PID_FILE = path.join(ROOT, 'server.pid');

function loadConfig() {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
    }
  } catch (e) {
    console.warn('⚠️ Config load error:', e.message);
  }
  return { port: 3000 };
}

async function isServerRunning(port) {
  return new Promise(resolve => {
    const req = http.request({
      hostname: 'localhost',
      port: port,
      path: '/health',
      timeout: 2000
    }, res => {
      resolve(true);
    });
    req.on('error', () => resolve(false));
    req.end();
  });
}

function getServerPID() {
  try {
    if (fs.existsSync(PID_FILE)) {
      const pid = parseInt(fs.readFileSync(PID_FILE, 'utf8'), 10);
      return isNaN(pid) ? null : pid;
    }
  } catch (e) {}
  return null;
}

async function ensureServerRunning() {
  const config = loadConfig();
  const running = await isServerRunning(config.port);
  
  if (running) {
    return true;
  }
  
  // 啟動伺服器
  console.log('[UUZero] Starting server...');
  
  // 檢查是否有舊的 PID
  const oldPid = getServerPID();
  if (oldPid) {
    try {
      process.kill(oldPid, 'SIGTERM');
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (e) {}
  }
  
  const child = spawn('node', [SERVER_JS], {
    cwd: ROOT,
    detached: true,
    stdio: 'ignore',
    env: { ...process.env }
  });
  
  fs.writeFileSync(PID_FILE, child.pid.toString());
  
  // 等待啟動（缩短到 2 秒）
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  const nowRunning = await isServerRunning(config.port);
  if (nowRunning) {
    console.log('[UUZero] Server ready (PID:', child.pid + ')');
    return true;
  } else {
    console.error('[UUZero] Server start failed');
    // 清理 PID
    try { fs.unlinkSync(PID_FILE); } catch(e) {}
    return false;
  }
}

async function callRouter(params) {
  const config = loadConfig();
  
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(params);
    const req = http.request({
      hostname: 'localhost',
      port: config.port,
      path: '/generate',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve(json);
        } catch (e) {
          reject(e);
        }
      });
    });
    
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function stopServer() {
  const pid = getServerPID();
  if (pid) {
    try {
      process.kill(pid, 'SIGTERM');
      console.log('[UUZero] Server stopped (PID:', pid + ')');
      fs.unlinkSync(PID_FILE);
    } catch (e) {
      console.error('[UUZero] Failed to stop server:', e.message);
    }
  } else {
    console.log('[UUZero] No server running (no PID file)');
  }
}

async function getStatus() {
  const config = loadConfig();
  const running = await isServerRunning(config.port);
  
  const status = {
    server: running ? 'running' : 'stopped',
    port: config.port,
    wsPort: config.wsPort,
    pid: getServerPID()
  };
  
  if (running) {
    try {
      const res = await new Promise((resolve, reject) => {
        const req = http.request({
          hostname: 'localhost',
          port: config.port,
          path: '/health',
          method: 'GET',
          timeout: 2000
        }, res => resolve(res));
        req.on('error', reject);
        req.end();
      });
      
      let body = '';
      res.on('data', chunk => body += chunk);
      await new Promise(resolve => res.on('end', resolve));
      const data = JSON.parse(body);
      status.health = data;
    } catch (e) {
      status.health = 'unavailable';
    }
  }
  
  return status;
}

// OpenClaw Skill Interface
module.exports = {
  name: 'uuzero',
  description: 'UUZero Standalone Sovereign Agent - 独立AI代理，支持多模型路由',
  parameters: {
    type: 'object',
    properties: {
      prompt: {
        type: 'string',
        description: '要執行的任務文本'
      },
      type: {
        type: 'string',
        enum: ['auto', 'chat', 'reason', 'tool'],
        description: '任務類型 (auto=自動推斷)',
        default: 'auto'
      },
      context: {
        type: 'string',
        description: '可選的上下文內容'
      }
    },
    required: ['prompt']
  },
  
  // 執行單次任務（主要功能）
  execute: async function(params) {
    try {
      // 確保伺服器啟動
      const ready = await ensureServerRunning();
      if (!ready) {
        return {
          success: false,
          error: 'Failed to start uuzero server',
          output: null
        };
      }
      
      // 呼叫 API
      const result = await callRouter({
        prompt: params.prompt,
        type: params.type || 'auto',
        context: params.context || ''
      });
      
      return {
        success: true,
        output: result.raw || result.output || result,
        model: result.model,
        latencyMs: result.latencyMs,
        taskType: result.taskType
      };
      
    } catch (error) {
      return {
        success: false,
        error: error.message,
        output: null
      };
    }
  },
  
  // 輔助指令
  commands: {
    start: async function() {
      const ready = await ensureServerRunning();
      return {
        success: ready,
        message: ready ? 'UUZero server started' : 'Failed to start server'
      };
    },
    
    stop: async function() {
      stopServer();
      return { success: true, message: 'UUZero server stopped' };
    },
    
    status: async function() {
      const status = await getStatus();
      return { success: true, status };
    }
  }
};

// CLI entry point when run directly
if (require.main === module) {
  const [, , command, ...args] = process.argv;
  
  async function main() {
    try {
      switch (command) {
        case 'start':
          const startRes = await module.exports.commands.start();
          console.log(JSON.stringify(startRes, null, 2));
          break;
          
        case 'stop':
          const stopRes = await module.exports.commands.stop();
          console.log(JSON.stringify(stopRes, null, 2));
          break;
          
        case 'status':
          const statusRes = await module.exports.commands.status();
          console.log(JSON.stringify(statusRes, null, 2));
          break;
          
        case 'run':
          const prompt = args.join(' ');
          if (!prompt) {
            console.error('Usage: node index.js run "your task"');
            process.exit(1);
          }
          const execRes = await module.exports.execute({ prompt });
          console.log(JSON.stringify(execRes, null, 2));
          break;
          
        case 'api':
          // Parse args: --prompt "..." [--type auto] [--context "..."]
          const params = { type: 'auto' };
          for (let i = 0; i < args.length; i++) {
            if (args[i] === '--prompt' && args[i+1]) params.prompt = args[++i];
            if (args[i] === '--type' && args[i+1]) params.type = args[++i];
            if (args[i] === '--context' && args[i+1]) params.context = args[++i];
          }
          if (!params.prompt) {
            console.error('Usage: node index.js api --prompt "task" [--type auto] [--context "..."]');
            process.exit(1);
          }
          const apiRes = await module.exports.execute(params);
          console.log(JSON.stringify(apiRes, null, 2));
          break;
          
        default:
          console.log(`
🦞 UUZero Skill - Command Line Interface

Usage: node index.js <command> [args]

Commands:
  start              啟動伺服器
  stop               停止伺服器
  status             檢查狀態
  run "task"         執行單次任務
  api --prompt "..." [--type auto] [--context "..."]  直接呼叫 API

Examples:
  node index.js start
  node index.js run "寫一首關於編程的詩"
  node index.js status
          `);
      }
    } catch (e) {
      console.error('💥 Error:', e.message);
      process.exit(1);
    }
  }
  
  main();
}