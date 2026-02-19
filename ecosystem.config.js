module.exports = {
  apps: [
    {
      name: 'openclaw',
      script: '/opt/homebrew/lib/node_modules/openclaw/openclaw.mjs',
      args: 'gateway --force',
      cwd: '/Users/jazzxx/Desktop/OpenClaw',
      env: {
        OPENCLAW_HOME: '/Users/jazzxx/Desktop/OpenClaw',
        OPENCLAW_CONFIG_PATH: '/Users/jazzxx/Desktop/OpenClaw/openclaw.json',
        NODE_ENV: 'production'
      },
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: '/tmp/openclaw-error.log',
      out_file: '/tmp/openclaw-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
