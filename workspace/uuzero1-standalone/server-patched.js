/**
 * Parse METRICS JSON from stderr (defensive)
 */
function parseMetrics(stderr) {
  const match = stderr.match(/--- METRICS ---\s*(\{.*\})/s);
  if (match) {
    try {
      return JSON.parse(match[1]);
    } catch (e) {
      return null;
    }
  }
  return null;
}

/**
 * Execute router task and return clean result
 */
function runRouterTask(type, prompt, context = '', schema = '') {
  return new Promise((resolve, reject) => {
    const cliPath = path.join(ROUTER_DIR, 'dist', 'cli.js');
    const args = ['--type', type, '--prompt', prompt, '--json'];
    if (context) args.push('--context', context);
    if (schema) args.push('--schema', schema);

    const child = spawn('node', [cliPath, ...args], {
      cwd: ROUTER_DIR,
      env: { ...process.env },
      stdio: ['ignore', 'pipe', 'pipe']
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
