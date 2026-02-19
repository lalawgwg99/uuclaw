// openclaw-brain.js
// Status: Production Ready
// Model: Auto-detect from openclaw.json (Currently: Minimax M2.5)

const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');
const OpenAI = require('openai'); // OpenRouter SDK

// --- 1. 自動載入 OpenClaw 核心配置 ---
function loadConfig() {
    // 嘗試在上一層目錄尋找 openclaw.json
    const configPath = path.join(__dirname, '../openclaw.json');

    if (!fs.existsSync(configPath)) {
        console.error("❌ 找不到 openclaw.json！請確認它在專案根目錄。");
        process.exit(1);
    }

    const rawData = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(rawData);
}

const config = loadConfig();
const LLM_CONFIG = config.llm || {};

console.log(`🔌 核心接入: ${LLM_CONFIG.provider || 'Custom'} / ${LLM_CONFIG.model}`);

// 初始化 AI 客戶端 (依照你的設定檔)
const openai = new OpenAI({
    baseURL: LLM_CONFIG.base_url || 'https://openrouter.ai/api/v1',
    apiKey: LLM_CONFIG.api_key,
    defaultHeaders: {
        "HTTP-Referer": "https://github.com/openclaw", // OpenRouter 要求
        "X-Title": "OpenClaw Coordinator"
    }
});

// --- 2. 每日情報輸入 (可替換為 fs.readFileSync 讀檔) ---
const DAILY_REPORT = `
【2026/02/18 重點報告】
1. 孟加拉：新總理上任，政局動盪，社會不穩。
2. 瑞士：黃金價格突破 $4938，避險資金大量湧入。
3. 台灣：新竹科學園區 AI 晶片產能吃緊，PS6 延期主因。
4. 緬甸：北部武裝衝突升級，波及稀土礦區。
5. 華盛頓：最高法院即將對關稅做出裁決，市場屏息。
`;

// --- 3. 戰術指令提示詞 (System Prompt) ---
const SYSTEM_PROMPT = `
你是一個戰情室指揮官。將輸入的新聞轉換為 WorldMonitor 的導航指令 JSON。
你的模型是 ${LLM_CONFIG.model}，請精準輸出。

可用圖層 (Layers):
- conflicts (衝突/戰爭)
- military (軍事/基地)
- economic (經濟/貿易)
- technology (科技/數據中心)
- resources (資源/黃金)
- protests (抗議/暴動)

[重要] 輸出格式必須是純 JSON Array，不要 Markdown，不要解釋。
範例:
[{"action":"NAVIGATE","lat":"23.5","lon":"121.0","zoom":"7.0","layers":"technology","desc":">> [科技] 台灣晶片產能壓力"}]
`;

async function main() {
    console.log("🧠 OpenClaw 正在分析每日報告...");

    try {
        // 呼叫 AI (Main Brain)
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: SYSTEM_PROMPT },
                { role: "user", content: DAILY_REPORT }
            ],
            model: LLM_CONFIG.model, // 動態使用 openclaw.json 裡的模型
            temperature: 0.1,
        });

        // 清洗數據 (移除 Markdown 標記)
        let rawContent = completion.choices[0].message.content;
        rawContent = rawContent.replace(/```json/g, '').replace(/```/g, '').trim();

        const commands = JSON.parse(rawContent);
        console.log(`✅ 戰術指令生成完畢: ${commands.length} 個目標`);

        // 連接 Neural Bridge
        const ws = new WebSocket('ws://localhost:8080');

        ws.on('open', async () => {
            console.log("⚡ Neural Link 連線成功");

            for (const cmd of commands) {
                console.log(`\n🚀 執行: ${cmd.desc}`);
                // 發送指令
                ws.send(JSON.stringify(cmd));
                // 每個點停留 12 秒
                await new Promise(r => setTimeout(r, 12000));
            }

            console.log("\n🏁 巡航結束。通訊切斷。");
            ws.close();
        });

        ws.on('error', (err) => {
            console.error("❌ Bridge 連線失敗！請先執行: node openclaw-bridge/bridge.js");
        });

    } catch (e) {
        console.error("❌ 執行錯誤:", e.message);
        if (e.response) console.error("API Error:", e.response.data);
    }
}

main();
