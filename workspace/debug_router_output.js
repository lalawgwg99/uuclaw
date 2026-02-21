const { spawn } = require('child_process');
const path = require('path');

const ROUTER_DIR = path.join(__dirname, 'uuzero1-standalone', 'modules', 'router');
const cliPath = path.join(ROUTER_DIR, 'dist', 'cli.js');

const child = spawn('node', [cliPath, '--type', 'chat', '--prompt', 'test', '--json'], {
  cwd: ROUTER_DIR,
  env: { ...process.env },
  stdio: 'pipe'
});

let stdout = '', stderr = '';
child.stdout.on('data', d => stdout += d.toString());
child.stderr.on('data', d => stderr += d.toString());

child.on('close', code => {
  console.log('Exit code:', code);
  console.log('STDERR:', stderr.slice(0, 200));
  console.log('STDOUT sample (tail 500 chars):');
  console.log(stdout.slice(-500));
  
  const tail = stdout.slice(-2000);
  const start = tail.indexOf('{');
  const end = tail.lastIndexOf('}') + 1;
  console.log('\nIndices:', { start, end, tailLength: tail.length });
  
  if (start !== -1 && end > start) {
    try {
      const jsonStr = tail.slice(start, end);
      const json = JSON.parse(jsonStr);
      console.log('\nParsed JSON model:', json.model);
    } catch (e) {
      console.error('\nJSON parse error:', e.message);
      console.log('JSON string sample:', jsonStr.slice(0, 300));
    }
  } else {
    console.log('\nNo JSON object found in tail');
  }
});

child.on('error', e => console.error('Spawn error:', e));

setTimeout(() => {
  if (!child.exitCode) {
    console.log('\nTimeout, killing...');
    process.kill(-child.pid);
  }
}, 15000);