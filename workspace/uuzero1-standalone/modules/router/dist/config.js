"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadConfig = loadConfig;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// Default model pricing (USD per 1M tokens) - sourced from_openrouter as of 2025
const DEFAULT_MODELS = {
    'stepfun/step-3.5-flash:free': {
        id: 'stepfun/step-3.5-flash:free',
        alias: 'step',
        pricePer1MInput: 0,
        pricePer1MOutput: 0,
        maxTokens: 4096,
        priority: 2
    },
    'arcee-ai/trinity-large-preview:free': {
        id: 'arcee-ai/trinity-large-preview:free',
        alias: 'trinity',
        pricePer1MInput: 0,
        pricePer1MOutput: 0,
        maxTokens: 4096,
        priority: 3
    }
};
function loadConfig() {
    // Allow overriding model IDs via env for flexibility
    const overrideModels = {
        mainBrain: process.env.OPENCLAW_MAIN_MODEL,
        logicUnit: process.env.OPENCLAW_LOGIC_MODEL,
        toolWorker: process.env.OPENCLAW_TOOL_MODEL,
        reasonStrict: process.env.OPENCLAW_REASON_STRICT_MODEL
    };
    const models = { ...DEFAULT_MODELS };
    // Apply overrides if provided
    if (overrideModels.mainBrain && models[overrideModels.mainBrain]) {
        models[overrideModels.mainBrain].priority = 1;
    }
    if (overrideModels.logicUnit && models[overrideModels.logicUnit]) {
        models[overrideModels.logicUnit].priority = 2;
    }
    if (overrideModels.toolWorker && models[overrideModels.toolWorker]) {
        models[overrideModels.toolWorker].priority = 3;
    }
    if (overrideModels.reasonStrict && models[overrideModels.reasonStrict]) {
        models[overrideModels.reasonStrict].priority = 4;
    }
    const baseConfig = {
        models,
        defaultModel: 'stepfun/step-3.5-flash:free',
        fallbacks: [
            'arcee-ai/trinity-large-preview:free'
        ],
        inference: {
            strictKeywords: ['證明', '反證', '最小化', '最佳化', '複雜度', '嚴格', 'formal'],
            reasonKeywords: ['為什麼', '推理', '分析', '步驟', '一步一步', '深入思考', '架構設計', '優缺點', '取捨',
                'reason step by step', 'step by step', 'analyze', 'analysis', 'design an architecture', 'architecture design', 'trade-offs', 'pros and cons'],
            lengthThresholds: {
                shortChat: 40,
                mediumChat: 80,
                longReasonBoost: 500,
                codeReasonBoostLength: 500
            },
            weights: {
                chat: 1.0,
                reason: 1.0,
                reason_strict: 1.0,
                tool: 1.0
            },
            codeDetection: true
        },
        circuitBreaker: {
            enabled: true,
            failureThreshold: 3,
            resetTimeoutMs: 5 * 60 * 1000, // 5 minutes
            halfOpenMaxCalls: 1
        },
        healthCheck: {
            enabled: true,
            successRateThreshold: 0.9,
            latencyThresholdMs: 5000,
            checkIntervalMs: 60000
        },
        logging: {
            debugRoute: false,
            routingLog: false,
            routingLogPath: './routing.log'
        }
    };
    return baseConfig;
}
