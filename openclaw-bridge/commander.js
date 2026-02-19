// commander.js - 戰術指揮官 V2
// 用法: 
// node commander.js ai   (顯示算力中心)
// node commander.js tw   (顯示台海熱點)
// node commander.js uk   (顯示烏克蘭前線)

const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8080');

// 取得命令行參數 (e.g., 'ai', 'tw')
const targetKey = process.argv[2] || 'tw';

// 戰術座標庫 (Tactical Database)
const TARGETS = {
    // --- 🔥 衝突與地緣 (Hotspots) ---

    // 1. 台灣 (台海): 灰區威脅、晶片核心
    'tw': {
        action: "NAVIGATE",
        lat: "23.5", lon: "119.5", zoom: "7.0",
        layers: "military,conflicts,ais",
        desc: ">> [地緣] 台海中線：共軍機艦活動與 ADIZ 侵擾監控"
    },
    // 2. 緬甸 (內戰): 政府軍襲擊 BNRA 營地 (比孟加拉更具破壞性)
    'mm': {
        action: "NAVIGATE",
        lat: "21.91", lon: "95.95", zoom: "6.5",
        layers: "conflicts,fires", // 開啟火災圖層監測戰火
        desc: ">> [衝突] 緬甸內戰：BNRA 營地襲擊與傷亡監測"
    },
    // 3. 孟加拉 (政局): 新總理上任
    'bd': {
        action: "NAVIGATE",
        lat: "23.68", lon: "90.35", zoom: "7.0",
        layers: "protests,economic",
        desc: ">> [政局] 孟加拉：政權更迭後的社會穩定度"
    },

    // --- 💰 金融與政策 (Finance & Policy) ---

    // 4. 華盛頓特區 (政策): 最高法院關稅裁決 (影響全球市場的源頭)
    'dc': {
        action: "NAVIGATE",
        lat: "38.90", lon: "-77.03", zoom: "10.0",
        layers: "economic,labels",
        desc: ">> [政策] 美國 DC：2/20 最高法院關稅裁決 (市場波動源)"
    },
    // 5. 紐約 (加密貨幣/ETF): Bitcoin ETF 流出監控
    'nyc': {
        action: "NAVIGATE",
        lat: "40.71", lon: "-74.00", zoom: "11.0",
        layers: "economic,grid",
        desc: ">> [金融] 華爾街：BTC ETF $3.8B 資金流出警示"
    },
    // 6. 瑞士 (避險): 黃金 $4938 歷史高點
    'ch': {
        action: "NAVIGATE",
        lat: "46.8", lon: "8.2", zoom: "7.0",
        layers: "resources,economic",
        desc: ">> [避險] 瑞士金庫：全球資金避險流向 (Gold / Privacy)"
    },

    // --- 🖥️ 科技與供應鏈 (Tech) ---

    // 7. 矽谷/舊金山 (AI 需求): 導致 PS6 延期的元兇 (AI 搶算力)
    'sf': {
        action: "NAVIGATE",
        lat: "37.40", lon: "-122.05", zoom: "9.0",
        layers: "technology,data_centers",
        desc: ">> [科技] 矽谷：AI 算力壟斷與硬體資源擠壓"
    }
};

const command = TARGETS[targetKey];

if (!command) {
    console.error(`❌ 未知指令: ${targetKey}`);
    console.error(`可用指令: node commander.js [ai | tw | uk]`);
    process.exit(1);
}

ws.on('open', () => {
    console.log(`\n🚀 正在發送戰術指令...`);
    console.log(command.desc);
    console.log(`座標: ${command.lat}, ${command.lon} | 圖層: ${command.layers}`);

    ws.send(JSON.stringify(command));

    // 發送後稍微延遲關閉，確保傳輸完成
    setTimeout(() => {
        console.log("✅ 指令已執行");
        ws.close();
    }, 500);
});

ws.on('error', (err) => {
    console.error("❌ 連線失敗: 你的 Neural Bridge (bridge.js) 有開嗎？");
    console.error("錯誤詳情:", err.message);
});
