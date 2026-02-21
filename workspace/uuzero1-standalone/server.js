#!/usr/bin/env node
/**
 * UUZero Standalone Server - Clean response format version
 */

const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const WebSocket = require('ws');
const http = require('http');

const ROUTER_DIR = path.join(__dirname, 'modules', 'router');
const CONFIG_PATH = path.join(__dirname, 'config', 'router-config.json');

function loadConfig() {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
    }
  } catch (e) {
    console.warn('⚠️ Config load error:', e.message);
  }
  return {
    defaultModel: 'stepfun/step-3.5-flash:free',
    fallbacks: ['arcee-ai/trinity-large-preview:free', 'deepseek/deepseek-r1-0528:free'],
    port: 3000,
    wsPort: 8080
  };
}

const config = loadConfig();

const healthState = { routerReady: false, lastCheck: Date.now(), errorCount: 0 };
function updateHealth(ready = true) {
  healthState.routerReady = ready;
  healthState.lastCheck = Date.now();
  if (ready) healthState.errorCount = 0;
  else healthState.errorCount++;
}

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ name: 'UUZero Standalone', version: '1.0.0', status: healthState.routerReady ? 'healthy' : 'degraded', uptime: process.uptime() });
});

app.get('/health', (req, res) => {
  const healthy = healthState.routerReady && healthState.errorCount < 5;
  res.status(healthy ? 200 : 503).json({ status: healthy ? 'healthy' : 'unhealthy', uptime: process.uptime(), routerReady: healthState.routerReady, errorCount: healthState.errorCount });
});

app.get('/metrics', (req, res) => {
  res.setHeader('Content-Type', 'text/plain');
  res.send(`uuzero_uptime_seconds ${process.uptime()}\nuuzero_errors_total ${healthState.errorCount}\nuuzero_router_ready ${healthState.routerReady ? 1 : 0}\n`);
});

app.post('/route', async (req, res) => {
  const { prompt, type = 'auto', context = '', schema = '' } = req.body;
  if (!prompt) return res.status(400).json({ error: 'Missing prompt' });
  const start = Date.now();
  try {
    const result = await runRouterTask(type, prompt, context, schema);
    res.json({ success: true, latencyMs: Date.now() - start, ...result });
  } catch (e) {
    updateHealth(false);
    res.status(500).json({ success: false, error: e.message, latencyMs: Date.now() - start });
  }
});

app.post('/generate', async (req, res) => {
  const { prompt } = req.body;
  if (!prompt) return res.status(400).json({ error: 'Missing prompt' });
  try {
    const start = Date.now();
    const result = await runRouterTask('chat', prompt);
    res.json({ success: true, latencyMs: Date.now() - start, output: result.output || '', model: result.model });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

function startWebSocketServer(server) {
  const wss = new WebSocket.Server({ server });
  wss.on('connection', ws => {
    console.log('>> WebSocket Connected');
    ws.on('message', async msg => {
      try {
        const { type = 'auto', prompt, context = '', schema = '' } = JSON.parse(msg);
        if (!prompt) return ws.send(JSON.stringify({ error: 'Missing prompt' }));
        const result = await runRouterTask(type, prompt, context, schema);
        ws.send(JSON.stringify({ success: true, ...result }));
      } catch (e) {
        ws.send(JSON.stringify({ success: false, error: e.message }));
      }
    });
    ws.send(JSON.stringify({ type: 'system', message: 'Connected to UUZero Standalone' }));
  });
  console.log(`⚡ WebSocket on port ${config.wsPort}`);
  return wss;
}

/**
 * Parse METRICS JSON from stderr (defensive)
 */
function parseMetrics(stderr) {
  const match = stderr.match(/--- METRICS ---\s*(\{.*\})/s);
  if (match) {
    try { return JSON.parse(match[1]); } catch (e) { return null; }
  }
  return null;
}

/**
 * Execute router task and return clean result
 */

function parseMetrics(stderr) {
  const match = stderr.match(/--- METRICS ---\s*(\{.*\})/s);
  if (match) {
    try { return JSON.parse(match[1]); } catch (e) { return null; }
  }
  return null;
}

function runRouterTask(type, prompt, context = '', schema = '') {
  return new Promise((resolve, reject) => {
    const cliPath = path.join(ROUTER_DIR, 'dist', 'cli.js');
    const args = ['--type', type, '--prompt', prompt, '--json'];
    if (context) args.push('--context', context);
    if (schema) args.push('--schema', schema);

    const child = spawn('node', [cliPath, ...args], {
      cwd: ROUTER_DIR,
      env: { ...process.env },
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 180000, // 180s for DeepSeek
      killSignal: 'SIGTERM'
    });

    let stdout = '', stderr = '';
    child.stdout.on('data', d => stdout += d.toString());
    child.stderr.on('data', d => stderr += d.toString());

    child.on('close', code => {
      if (code !== 0) return reject(new Error(`Router exit ${code}\n${stderr}`));

      try {
        const metrics = parseMetrics(stderr);
        resolve({
          success: true,
          output: stdout.trim(),
          taskType: metrics?.taskType || type,
          model: metrics?.model,
          latencyMs: metrics?.latencyMs,
          tokensInput: metrics?.tokensInput,
          tokensOutput: metrics?.tokensOutput,
          estimatedCostUSD: metrics?.estimatedCostUSD,
          logs: stderr.trim()
        });
      } catch (e) {
        resolve({
          success: true,
          output: stdout.trim(),
          taskType: type,
          logs: stderr.trim(),
          parseError: e.message
        });
      }
    });

    child.on('error', reject);
  });
}



function startHealthLoop() {
  setInterval(() => {
    runRouterTask('auto', 'health ping')
      .then(() => updateHealth(true))
      .catch(() => updateHealth(false));
  }, 30000);
}

async function main() {
  console.log('🦞 UUZero Standalone Server');
  console.log('✅ 檢查環境...');

  if (!process.env.OPENROUTER_API_KEY) {
    console.error('❌ 缺少 OPENROUTER_API_KEY');
    process.exit(1);
  }

  if (!fs.existsSync(path.join(ROUTER_DIR, 'dist', 'cli.js'))) {
    console.error('❌ Router CLI 不存在');
    process.exit(1);
  }

  fs.mkdirSync(path.join(__dirname, 'config'), { recursive: true });
  if (!fs.existsSync(CONFIG_PATH)) {
    fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
  }

  console.log('✅ 預熱 Router (async)...');
  runRouterTask('auto', 'ping')
    .then(() => { console.log('   Router ready'); updateHealth(true); })
    .catch(e => console.warn('   Router preheat failed (will retry on first use):', e.message));

  const server = http.createServer(app);
  server.listen(config.port, () => {
    console.log(`🚀 HTTP server listening on :${config.port}`);
    console.log(`   GET /health, GET /metrics, POST /route, POST /generate`);
  });

  startWebSocketServer(server);
  startHealthLoop();

  process.on('SIGTERM', () => server.close(() => process.exit(0)));
  process.on('SIGINT', () => server.close(() => process.exit(0)));

  console.log('✅ Server running\n');
}

main();
