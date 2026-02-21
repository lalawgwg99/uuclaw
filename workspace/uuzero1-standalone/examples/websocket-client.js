// WebSocket Client Example
// 使用方法: node examples/websocket-client.js

const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
  console.log('✅ Connected to UUZero Standalone');
  
  // 發送測試任務
  const task = {
    type: 'auto',
    prompt: 'Explain quantum entanglement in simple terms',
    context: ''
  };
  
  ws.send(JSON.stringify(task));
  console.log('📤 Sent task:', task.prompt);
});

ws.on('message', (data) => {
  try {
    const msg = JSON.parse(data);
    if (msg.type === 'system') {
      console.log('📢', msg.message);
    } else if (msg.success) {
      console.log('\n🤖 Response:', msg.output);
      console.log(`   Model: ${msg.model}, Latency: ${msg.latencyMs}ms`);
    } else {
      console.error('❌ Error:', msg.error);
    }
  } catch (e) {
    console.log('📨 Raw:', data.toString());
  }
});

ws.on('close', () => {
  console.log('\n🔌 Disconnected');
});

ws.on('error', (err) => {
  console.error('💥 WebSocket error:', err.message);
});