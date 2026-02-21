// auto-rotate.js - Run with: node auto-rotate.js
const WebSocket = require('ws');

const LOCATIONS = [
    // 1. 北美 - 矽谷核心 (NVIDIA/RunPod)
    {
        name: "Silicon Valley (NVIDIA HQ)",
        lat: "37.3541",
        lon: "-121.9552",
        zoom: "8.5",
        layers: "tech,finance"
    },
    // 2. 北美 - 鳳凰城 (Azure AI Supercomputer)
    {
        name: "Phoenix (Microsoft Azure)",
        lat: "33.4484",
        lon: "-112.0740",
        zoom: "9.0",
        layers: "tech,datacenter"
    },
    // 3. 亞洲 - 東京 (SoftBank/NVIDIA)
    {
        name: "Tokyo (SoftBank H100 Cluster)",
        lat: "35.6762",
        lon: "139.6503",
        zoom: "10.0",
        layers: "tech,ais"
    },
    // 4. 亞洲 - 新加坡 (APAC Hub)
    {
        name: "Singapore (Data Center Hub)",
        lat: "1.3521",
        lon: "103.8198",
        zoom: "11.0",
        layers: "tech,shipping"
    },
    // 5. 歐洲 - 法蘭克福 (Google Cloud/Interconnection)
    {
        name: "Frankfurt (DE-CIX Node)",
        lat: "50.1109",
        lon: "8.6821",
        zoom: "10.5",
        layers: "tech,finance"
    }
];

function startLoop() {
    const ws = new WebSocket('ws://localhost:8080');
    let currentIndex = 0;

    ws.on('open', () => {
        console.log(">> Connected to Neural Bridge. Starting Global AI Patrol...");

        const rotate = () => {
            const target = LOCATIONS[currentIndex];
            console.log(`>> 🔄 TARGET ACQUIRED: ${target.name}`);

            const command = {
                action: "NAVIGATE",
                ...target
            };

            ws.send(JSON.stringify(command));

            currentIndex = (currentIndex + 1) % LOCATIONS.length;
        };

        // Execute immediately
        rotate();

        // Then rotate every 30 seconds
        setInterval(rotate, 30000);
    });

    ws.on('error', (err) => {
        console.error("!! Connection Error. Is the bridge running?", err.message);
        process.exit(1);
    });
}

startLoop();
