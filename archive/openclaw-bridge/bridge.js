// bridge.js - Run with: node bridge.js
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

console.log('⚡ OpenClaw Bridge Active on :8080');

wss.on('connection', (ws) => {
    console.log('>> Node Connected');

    ws.on('message', (message) => {
        // Broadcast received command to all connected clients (Frontend)
        const command = message.toString();
        console.log(`Command Broadcast: ${command}`);

        wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(command);
            }
        });
    });
});
