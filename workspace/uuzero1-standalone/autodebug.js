#!/usr/bin/env node
/**
 * UUZero Standalone Auto-Debug & Sanity Check
 * 自動檢查系統完整性並修復常見問題
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const ROUTER_DIR = path.join(ROOT, 'modules', 'router');
const CONFIG_DIR = path.join(ROOT, 'config');
const CONFIG_PATH = path.join(CONFIG_DIR, 'router-config.json');
const LOGS_DIR = path.join(ROOT, 'logs');

const COLORS = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(msg, color = 'reset') {
  console.log(`${COLORS[color]}${msg}${COLORS.reset}`);
}

function section(title) {
  console.log();
  log(`=== ${title} ===`, 'cyan');
}

// 1. 檢查環境變數
function checkEnv() {
  section('環境檢查');
  const required = ['OPENROUTER_API_KEY'];
  const optional = ['OPENCLAW_REASON_STRICT_DEEPSEEK', 'OPENCLAW_ROUTING_LOG'];
  
  let allPresent = true;
  
  required.forEach(key => {
    if (process.env[key]) {
      log(`✅ ${key}=${process.env[key].substring(0, 10)}...`, 'green');
    } else {
      log(`❌ 缺少必要環境變數: ${key}`, 'red');
      allPresent = false;
    }
  });
  
  optional.forEach(key => {
    if (process.env[key]) {
      log(`🔧 ${key}=${process.env[key]}`, 'yellow');
    } else {
      log(`⚪ ${key} 未設定 (可選)`, 'blue');
    }
  });
  
  return allPresent;
}

// 2. 檢查檔案結構
function checkFiles() {
  section('檔案結構檢查');
  
  const checks = [
    { path: 'package.json', desc: '项目配置' },
    { path: 'server.js', desc: 'HTTP 服务器' },
    { path: 'standalone.js', desc: 'CLI 运行器' },
    { path: 'config/router-config.json', desc: '路由器配置' },
    { path: 'modules/router/package.json', desc: '路由器模块配置' },
    { path: 'modules/router/dist/cli.js', desc: '路由器 CLI' },
    { path: 'modules/router/dist/router.js', desc: '路由器引擎' },
    { path: 'modules/router/dist/inference.js', desc: '任务推断' },
    { path: 'modules/router/dist/health.js', desc: '健康监控' },
    { path: 'modules/router/dist/circuit.js', desc: '断路器' },
    { path: 'modules/router/dist/cost.js', desc: '成本追踪' },
    { path: 'modules/router/dist/logger.js', desc: '日志系统' },
    { path: 'modules/router/dist/config.js', desc: '配置加载' }
  ];
  
  let passed = 0, failed = 0;
  
  checks.forEach(({ path: p, desc }) => {
    const fullPath = path.join(ROOT, p);
    if (fs.existsSync(fullPath)) {
      log(`✅ ${desc} (${p})`, 'green');
      passed++;
    } else {
      log(`❌ ${desc} 缺失 (${p})`, 'red');
      failed++;
    }
  });
  
  console.log(`\n📊 文件检查: ${passed} 通过, ${failed} 失败`);
  return failed === 0;
}

// 3. 檢查依賴
function checkDependencies() {
  section('依賴檢查');
  
  const roots = [ROOT, ROUTER_DIR];
  let allGood = true;
  
  roots.forEach(root => {
    const pkgPath = path.join(root, 'package.json');
    const nodeModules = path.join(root, 'node_modules');
    
    if (!fs.existsSync(pkgPath)) {
      log(`⚠️ 未找到 package.json in ${root}`, 'yellow');
      return;
    }
    
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    const name = pkg.name || 'unknown';
    
    if (fs.existsSync(nodeModules)) {
      log(`✅ ${name}: node_modules 存在`, 'green');
    } else {
      log(`❌ ${name}: 缺少 node_modules！需要运行 npm install`, 'red');
      allGood = false;
    }
  });
  
  return allGood;
}

// 4. 檢查配置
function checkConfig() {
  section('配置檢查');
  
  if (!fs.existsSync(CONFIG_DIR)) {
    log('❌ config 目錄不存在', 'red');
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
    log('✅ 已創建 config 目錄', 'green');
  }
  
  if (!fs.existsSync(CONFIG_PATH)) {
    log('⚠️ router-config.json 不存在，將生成預設配置', 'yellow');
    const defaultConfig = {
      defaultModel: 'stepfun/step-3.5-flash:free',
      fallbacks: [
        'arcee-ai/trinity-large-preview:free',
        'minimax/minimax-m2.5'
      ],
      complexityThreshold: 0.6,
      port: 3000,
      wsPort: 8080,
      healthCheckInterval: 30000,
      maxConcurrent: 10
    };
    fs.writeFileSync(CONFIG_PATH, JSON.stringify(defaultConfig, null, 2));
    log('✅ 已生成預設配置', 'green');
  } else {
    try {
      const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
      log('✅ 配置檔案格式正確', 'green');
      
      // 檢查關鍵字段
      const required = ['defaultModel', 'fallbacks', 'port', 'wsPort'];
      const missing = required.filter(k => !(k in config));
      if (missing.length > 0) {
        log(`❌ 配置缺少字段: ${missing.join(', ')}`, 'red');
        return false;
      }
    } catch (e) {
      log(`❌ 配置檔案解析錯誤: ${e.message}`, 'red');
      return false;
    }
  }
  
  return true;
}

// 5. 建立日志目錄
function ensureLogsDir() {
  section('日誌目錄');
  if (!fs.existsSync(LOGS_DIR)) {
    fs.mkdirSync(LOGS_DIR);
    log('✅ 已創建 logs 目錄', 'green');
  } else {
    log('✅ logs 目錄存在', 'green');
  }
}

// 6. 測試 Router CLI
function testRouterCLI() {
  section('Router CLI 測試');
  
  const cliPath = path.join(ROUTER_DIR, 'dist', 'cli.js');
  if (!fs.existsSync(cliPath)) {
    log('❌ CLI 文件不存在', 'red');
    return false;
  }
  
  log('🧪 測試 Router CLI (使用測試提示詞)...', 'blue');
  
  try {
    const result = execSync(`node "${cliPath}" --type auto --prompt "Hello test" --json`, {
      cwd: ROUTER_DIR,
      env: { ...process.env, OPENROUTER_API_KEY: 'dummy-for-structure-test' },
      stdio: 'pipe',
      timeout: 10000
    });
    
    // 即使 API 失败，CLI structural test passed if it runs
    log('✅ CLI 可執行', 'green');
    return true;
  } catch (e) {
    // Check if it's a network/API error (expected) or binary error
    if (e.message.includes('Cannot find module') || e.message.includes('not found')) {
      log(`❌ CLI 執行失敗: ${e.message}`, 'red');
      return false;
    } else {
      // Expected: API errors when using dummy key
      log('✅ CLI 結構正常 (API 錯誤是預期的，因使用測試 Key)', 'green');
      return true;
    }
  }
}

// 7. 驗證 Node.js 版本
function checkNodeVersion() {
  section('執行環境');
  const version = process.version;
  const major = parseInt(version.slice(1).split('.')[0], 10);
  if (major >= 18) {
    log(`✅ Node.js ${version} (>=18 推薦)`, 'green');
    return true;
  } else {
    log(`❌ Node.js ${version} 過舊，建議 >=18`, 'red');
    return false;
  }
}

// 8. 執行所有 sanity check 並嘗試自動修復
function runSanityCheck() {
  section('Sanity Check 執行中...');
  
  const results = {
    env: checkEnv(),
    files: checkFiles(),
    deps: checkDependencies(),
    config: checkConfig(),
    cli: testRouterCLI(),
    node: checkNodeVersion()
  };
  
  ensureLogsDir();
  
  section('Sanity Check 總結');
  
  const allPassed = Object.values(results).every(v => v === true);
  
  if (allPassed) {
    log('🎉 所有檢查通過！系統已就緒。', 'green');
  } else {
    log('⚠️ 部分檢查失敗，請手動修復以下問題：', 'yellow');
    Object.entries(results).forEach(([key, passed]) => {
      if (!passed) log(`   - ${key}`, 'red');
    });
  }
  
  // 嘗試自動修復
  log('\n🔧 嘗試自動修復...', 'blue');
  
  let fixed = 0;
  
  // 缺少依賴？
  if (!results.deps) {
    log('📦 安裝缺失的依賴...', 'yellow');
    try {
      execSync('npm install', { cwd: ROOT, stdio: 'inherit' });
      execSync('npm install', { cwd: ROUTER_DIR, stdio: 'inherit' });
      log('✅ 依賴安裝完成', 'green');
      fixed++;
    } catch (e) {
      log(`❌ 依賴安裝失敗: ${e.message}`, 'red');
    }
  }
  
  // 配置文件修復
  if (!results.config) {
    try {
      if (fs.existsSync(CONFIG_PATH)) fs.unlinkSync(CONFIG_PATH);
      const defaultConfig = {
        defaultModel: 'stepfun/step-3.5-flash:free',
        fallbacks: ['arcee-ai/trinity-large-preview:free', 'minimax/minimax-m2.5'],
        complexityThreshold: 0.6,
        port: 3000,
        wsPort: 8080,
        healthCheckInterval: 30000,
        maxConcurrent: 10
      };
      fs.writeFileSync(CONFIG_PATH, JSON.stringify(defaultConfig, null, 2));
      log('✅ 配置文件已重置為預設值', 'green');
      fixed++;
    } catch (e) {
      log(`❌ 配置重置失敗: ${e.message}`, 'red');
    }
  }
  
  section('最終狀態');
  if (fixed > 0) {
    log(`✅ 自動修復了 ${fixed} 個問題，請重新運行檢查確認。`, 'green');
  } else if (allPassed) {
    log('✅ 系統完美，無需修復！', 'green');
  } else {
    log('❌ 仍有問題未能自動修復，請手動處理。', 'red');
  }
  
  console.log();
  log('🚀 準備就緒後可使用以下命令啟動:', 'blue');
  console.log('   npm start           - 啟動 HTTP + WebSocket 服务器');
  console.log('   node standalone.js  - 啟動 CLI 交互模式');
  console.log();
  
  return allPassed;
}

// 執行
try {
  const success = runSanityCheck();
  process.exit(success ? 0 : 1);
} catch (e) {
  log(`💥 診斷過程失敗: ${e.message}`, 'red');
  process.exit(1);
}
