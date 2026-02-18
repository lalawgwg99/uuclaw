"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ClawRouter = void 0;
const openai_1 = __importDefault(require("openai"));
const prompts_1 = require("./prompts");
// Model Definitions (4-model combo + REASON_STRICT override)
const MODELS = {
    MAIN_BRAIN: "minimax/minimax-m2.5",
    LOGIC_UNIT: "stepfun/step-3.5-flash:free",
    REASON_STRICT: "deepseek/deepseek-v3.2",
    TOOL_WORKER: "arcee-ai/trinity-large-preview:free"
};
// Env: OPENCLAW_REASON_STRICT_DEEPSEEK=1 → use DeepSeek V3.2 for reason_strict; else Step Flash
function useDeepSeekForReasonStrict() {
    const v = process.env.OPENCLAW_REASON_STRICT_DEEPSEEK || process.env.REASON_STRICT_DEEPSEEK;
    return v === "1" || v === "true" || v === "yes";
}
class ClawRouter {
    constructor(apiKey) {
        if (!apiKey)
            throw new Error("FATAL: OpenRouter API Key is missing.");
        // Initialize OpenAI client pointing to OpenRouter
        this.client = new openai_1.default({
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: apiKey,
            defaultHeaders: {
                "HTTP-Referer": "https://openclaw.ai", // Required by OpenRouter
                "X-Title": "OpenClaw"
            }
        });
    }
    inferTaskType(prompt) {
        const text = (prompt || "");
        const lower = text.toLowerCase();
        const length = text.length;
        if (length < 40)
            return "chat";
        if (length > 80 && /[{}\[\]]/.test(text) && lower.includes("json"))
            return "tool";
        if (length > 80 && (lower.includes("schema:") || lower.includes("schema requirement")))
            return "tool";
        // Hard override: strict reasoning keywords → reason_strict (Step or DeepSeek by env)
        const strictKeywords = ["證明", "反證", "最小化", "最佳化", "複雜度", "嚴格", "formal"];
        if (strictKeywords.some((k) => text.includes(k) || lower.includes(k)))
            return "reason_strict";
        const zhReason = ["為什麼", "推理", "分析", "步驟", "一步一步", "深入思考", "架構設計", "優缺點", "取捨"];
        if (length > 80 && zhReason.some((k) => text.includes(k)))
            return "reason";
        const enReason = ["reason step by step", "step by step", "analyze", "analysis", "design an architecture", "architecture design", "trade-offs", "pros and cons"];
        if (length > 80 && enReason.some((k) => lower.includes(k)))
            return "reason";
        return "chat";
    }
    async autoRoute(prompt, systemContext) {
        const inferred = this.inferTaskType(prompt);
        console.error("\x1b[35m[ROUTER] Auto-selected task type: " + inferred + "\x1b[0m");
        return this.route(inferred, prompt, systemContext);
    }
    /**
     * Core routing function: Selects model and system prompt based on task type.
     */
    async route(taskType, prompt, systemContext) {
        let modelId = MODELS.MAIN_BRAIN;
        let temperature = 0.7;
        let systemPrompt = prompts_1.PROMPT_MAIN;
        // Switch model configuration based on task type
        switch (taskType) {
            case 'reason_strict':
                modelId = useDeepSeekForReasonStrict() ? MODELS.REASON_STRICT : MODELS.LOGIC_UNIT;
                temperature = 0.5;
                systemPrompt = prompts_1.PROMPT_LOGIC;
                console.error("\x1b[33m[ROUTER] REASON_STRICT → " + modelId + " (env OPENCLAW_REASON_STRICT_DEEPSEEK=" + (useDeepSeekForReasonStrict() ? "1" : "0") + ")\x1b[0m");
                break;
            case 'reason':
                modelId = MODELS.LOGIC_UNIT;
                temperature = 0.6;
                systemPrompt = prompts_1.PROMPT_LOGIC;
                console.error("\x1b[33m[ROUTER] Logic Unit (" + modelId + ") for deep thinking...\x1b[0m");
                break;
            case 'tool':
                modelId = MODELS.TOOL_WORKER;
                temperature = 0.1; // Tool execution requires precision
                systemPrompt = prompts_1.PROMPT_TOOL;
                console.error(`\x1b[36m[ROUTER] Switching to Tool Worker (${modelId}) for execution...\x1b[0m`);
                break;
            default:
                console.error(`\x1b[32m[ROUTER] Using Main Brain (${modelId})...\x1b[0m`);
                // Use user provided system context if available, otherwise default main prompt
                if (systemContext)
                    systemPrompt = systemContext;
                break;
        }
        const messages = [
            { role: "system", content: systemPrompt },
            { role: "user", content: prompt }
        ];
        try {
            const stream = await this.client.chat.completions.create({
                model: modelId,
                messages: messages,
                temperature: temperature,
                stream: true
            });
            return stream;
        }
        catch (error) {
            console.error("\x1b[31m[ERROR] " + modelId + " failed:\x1b[0m", error);
            if (modelId === MODELS.REASON_STRICT) {
                console.error("\x1b[31m[FALLBACK] REASON_STRICT failed → trying Logic Unit (Step)...\x1b[0m");
                return this.route("reason", prompt, systemContext);
            }
            if (modelId !== MODELS.MAIN_BRAIN) {
                console.error("\x1b[31m[FALLBACK] Attempting fallback to Main Brain...\x1b[0m");
                return this.route("chat", prompt, systemContext);
            }
            throw error;
        }
    }
}
exports.ClawRouter = ClawRouter;
