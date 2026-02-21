const { execSync } = require('child_process');

const tests = [
  { type: 'auto', prompt: 'Hello' },
  { type: 'chat', prompt: 'Hi' },
  { type: 'reason', prompt: 'Explain quantum physics' },
  { type: 'tool', prompt: 'Generate JSON: {name: "test"}' }
];

tests.forEach(t => {
  try {
    const result = execSync(`node index.js api --prompt "${t.prompt}" --type ${t.type}`, { encoding: 'utf8' });
    const parsed = JSON.parse(result);
    const model = parsed.model || (parsed.raw && parsed.raw.match(/\[(.*?)\]/)?.[1]) || 'unknown';
    console.log(`${t.type.padEnd(10)} -> ${model} (${parsed.latencyMs}ms)`);
  } catch (e) {
    console.log(`${t.type.padEnd(10)} -> ERROR: ${e.message}`);
  }
});
