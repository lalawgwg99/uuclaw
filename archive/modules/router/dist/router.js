"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ClawRouter = void 0;
const openai_1 = __importDefault(require("openai"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const logger_1 = require("./logger");
const inference_1 = require("./inference");
const circuit_1 = require("./circuit");
const health_1 = require("./health");
const cost_1 = require("./cost");
class ClawRouter {
    constructor(config, apiKey) {
        this.config = config;
        this.logger = new logger_1.Logger(config);
        this.inference = new inference_1.TaskInference(config.inference);
        this.circuitBreakers = new Map();
        this.healthMonitors = new Map();
        this.costTracker = new cost_1.CostTracker(config.models);
        const key = apiKey || process.env.OPENROUTER_API_KEY;
        if (!key) {
            throw new Error("FATAL: OpenRouter API Key is missing (OPENROUTER_API_KEY).");
        }
        this.client = new openai_1.default({
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: key,
            defaultHeaders: {
                "HTTP-Referer": "https://openclaw.ai",
                "X-Title": "OpenClaw"
            }
        });
    }
    async autoRoute(prompt, systemContext) {
        const inferred = this.inference.inferTaskType(prompt);
        this.logger.debug(`Inferred task type: ${inferred} from prompt length ${prompt.length}`);
        return this.route(inferred, prompt, systemContext);
    }
    async route(taskType, prompt, systemContext) {
        const start = Date.now();
        let modelId = this.selectModel(taskType);
        let temperature = this.getTemperature(taskType);
        let systemPrompt = this.getSystemPrompt(taskType, systemContext);
        // Register circuit & health if first time
        if (!this.circuitBreakers.has(modelId)) {
            this.circuitBreakers.set(modelId, new circuit_1.CircuitBreaker(this.config.circuitBreaker));
        }
        if (!this.healthMonitors.has(modelId)) {
            this.healthMonitors.set(modelId, new health_1.HealthMonitor(this.config.healthCheck));
        }
        const breaker = this.circuitBreakers.get(modelId);
        const health = this.healthMonitors.get(modelId);
        // Dynamic weighting: if health is poor, penalize and potentially switch
        if (this.config.healthCheck.dynamicWeighting && !health.isHealthy()) {
            const penalty = health.getWeightPenalty();
            this.logger.debug(`Health penalty for ${modelId}: ${penalty.toFixed(2)} (successRate=${health.getSuccessRate().toFixed(2)})`);
            // If penalty is severe, consider fallback
            if (penalty < 0.5) {
                const fallback = this.selectFallback(modelId, taskType);
                if (fallback) {
                    this.logger.fallback(modelId, fallback);
                    modelId = fallback;
                    // Reset breaker/health for new model
                    if (!this.circuitBreakers.has(modelId)) {
                        this.circuitBreakers.set(modelId, new circuit_1.CircuitBreaker(this.config.circuitBreaker));
                    }
                    if (!this.healthMonitors.has(modelId)) {
                        this.healthMonitors.set(modelId, new health_1.HealthMonitor(this.config.healthCheck));
                    }
                }
            }
        }
        const messages = [
            { role: "system", content: systemPrompt },
            { role: "user", content: prompt }
        ];
        try {
            const stream = await breaker.execute(() => this.client.chat.completions.create({
                model: modelId,
                messages: messages, // type assertion for simplicity
                temperature: temperature,
                stream: true,
                max_tokens: 4096 // Fixed to safe default; override per-model from config if needed
            }));
            // Success: record health
            const latency = Date.now() - start;
            health.recordSuccess(latency);
            this.logger.route(modelId, taskType, 'routed');
            this.logger.logRouting({
                ts: new Date().toISOString(),
                taskType,
                inputLength: prompt.length,
                matchedKeywords: [],
                modelSelected: modelId,
                latencyMs: latency
            });
            return stream;
        }
        catch (error) {
            const latency = Date.now() - start;
            health.recordFailure(latency);
            // Classify error for smarter fallback
            const errorType = this.classifyError(error);
            this.logger.error(modelId, error);
            this.logger.logRouting({
                ts: new Date().toISOString(),
                taskType,
                inputLength: prompt.length,
                matchedKeywords: [],
                modelSelected: modelId,
                fallbackUsed: true,
                fallbackFrom: modelId,
                errorType,
                latencyMs: latency
            });
            // Circuit breaker will handle retry logic partially; we implement manual fallback chain
            if (taskType === 'reason_strict' || taskType === 'reason') {
                // For reason_strict: fallback to reason (Step if using DeepSeek, otherwise DeepSeek if using Step? Actually step config)
                const fallback = this.config.fallbacks[0] || 'stepfun/step-3.5-flash:free';
                this.logger.fallback(modelId, fallback);
                return this.route('reason', prompt, systemContext); // recursive fallback
            }
            else {
                // fallback to main brain (MiniMax) or chat
                const fallback = this.config.defaultModel;
                this.logger.fallback(modelId, fallback);
                return this.route('chat', prompt, systemContext);
            }
        }
    }
    selectModel(taskType) {
        // In a real system we could have separate model mapping per task type; for now use default
        // But we can also use dynamic weighting: choose best health among possible candidates
        const candidates = this.getCandidatesForTask(taskType);
        if (candidates.length === 0)
            return this.config.defaultModel;
        // Pick the first healthy candidate, else first
        for (const cid of candidates) {
            const health = this.healthMonitors.get(cid);
            if (!health || health.isHealthy()) {
                return cid;
            }
        }
        return candidates[0];
    }
    getCandidatesForTask(taskType) {
        switch (taskType) {
            case 'reason_strict':
                return [this.config.models['deepseek/deepseek-v3.2']?.id || 'deepseek/deepseek-v3.2',
                    this.config.models['stepfun/step-3.5-flash:free']?.id || 'stepfun/step-3.5-flash:free'];
            case 'reason':
                return [this.config.models['stepfun/step-3.5-flash:free']?.id || 'stepfun/step-3.5-flash:free'];
            case 'tool':
                return [this.config.models['arcee-ai/trinity-large-preview:free']?.id || 'arcee-ai/trinity-large-preview:free'];
            case 'chat':
            default:
                return [this.config.models['minimax/minimax-m2.5']?.id || 'minimax/minimax-m2.5'];
        }
    }
    selectFallback(currentModel, taskType) {
        // Simple round-robin or based on type; not used now
        const idx = this.config.fallbacks.findIndex(m => m === currentModel);
        if (idx >= 0 && idx + 1 < this.config.fallbacks.length) {
            return this.config.fallbacks[idx + 1];
        }
        return this.config.fallbacks[0] || null;
    }
    getTemperature(taskType) {
        switch (taskType) {
            case 'reason_strict':
            case 'reason':
                return 0.5;
            case 'tool':
                return 0.1;
            default:
                return 0.7;
        }
    }
    getSystemPrompt(taskType, systemContext) {
        // Placeholder: merge prompts based on type; currently from original prompts module
        const prompts = {
            chat: `You are OpenClaw, a sentient Coordinator. Professional but gritty.`,
            reason: `You are the LOGIC CORE. TRUTH and ACCURACY only. Chain of thought, no fluff.`,
            reason_strict: `You are the LOGIC CORE (strict). Red teaming. Data integrity.`,
            tool: `You are the EXECUTION ENGINE. Output VALID JSON ONLY.`
        };
        return systemContext || prompts[taskType] || prompts.chat;
    }
    classifyError(error) {
        if (error.response) {
            const status = error.response.status;
            if (status === 429)
                return 'rate_limit';
            if (status >= 500 && status < 600)
                return 'server_error';
            if (status === 401)
                return 'auth_error';
            if (status === 400)
                return 'bad_request';
        }
        if (error.code === 'ECONNABORTED')
            return 'timeout';
        return 'unknown';
    }
    // Expose for external token counting
    estimateCost(modelId, tokensInput, tokensOutput) {
        return this.costTracker.estimateCost(modelId, tokensInput, tokensOutput);
    }
    recordCost(modelId, tokensInput, tokensOutput) {
        this.costTracker.record(modelId, tokensInput, tokensOutput);
    }
    getSessionCost() {
        return this.costTracker.getSessionCost();
    }
    getModelCostBreakdown() {
        return this.costTracker.getModelBreakdown();
    }
    getGrandTotalCost() {
        return this.costTracker.getGrandTotal();
    }
    close() {
        this.logger.close();
    }
}
exports.ClawRouter = ClawRouter;
