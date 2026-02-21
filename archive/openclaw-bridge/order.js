// order.js - OpenClaw Order Dispatcher
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8080');

const args = process.argv.slice(2);
const params = {};

args.forEach(arg => {
    if (arg.startsWith('--')) {
        const [key, value] = arg.slice(2).split('=');
        params[key] = value;
    }
});

const TARGET = {
    action: params.action || "NAVIGATE",
    lat: params.lat,
    lon: params.lon,
    zoom: params.zoom,
    layers: params.layers
};

ws.on('open', () => {
    console.log(`>> Dispatching Order: ${JSON.stringify(TARGET)}`);
    ws.send(JSON.stringify(TARGET));

    // Auto-close after a short delay to ensure message delivery
    setTimeout(() => {
        ws.close();
        process.exit(0);
    }, 500);
});

ws.on('error', (err) => {
    console.error("!! Bridge Connection Failed:", err.message);
    process.exit(1);
});
