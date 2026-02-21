"use strict";
const { OpenAI } = require('openai');
const { Inference } = require('./inference');
const logger = console;

function safeExtractModel(text, fallback = 'stepfun/step-3.5-flash:free') {
  const match = text.match(/"model"\s*:\s*"([^"]+)"/);
  return match ? match[1] : fallback;
}

class ClawRouter {
  constructor(config, logger = console) {
    this.config = config;
    this.logger = logger;
    this.inference = new Inference(config);
    if (!process.env.OPENROUTER_API_KEY) {
      throw new Error("FATAL: OpenRouter API Key is missing (OPENROUTER_API_KEY).");
    }
    this.client = new OpenAI({
      baseURL: "https://openrouter.ai/api/v1",
      apiKey: process.env.OPENROUTER_API_KEY,
      defaultHeaders: {
        "HTTP-Referer": "https://openclaw.ai",
        "X-Title": "OpenClaw"
      },
      timeout: 60000
    });
  }

  async autoRoute(prompt, systemContext) {
    const inferred = this.inference.inferTaskType(prompt);
    this.logger.debug(`Inferred task type: ${inferred} from prompt length ${prompt.length}`);
    return this.route(inferred, prompt, systemContext);
  }

  async route(taskType, prompt, systemContext) {
    const candidates = this.getCandidatesForTask(taskType);
    const start = Date.now();
    let lastError = null;

    for (const modelId of candidates) {
      this.logger.debug(`[Router] ${taskType} → trying ${modelId}`);
      try {
        const result = await this.callModel(modelId, taskType, prompt, systemContext, start);
        return result;
      } catch (error) {
        lastError = error;
        this.logger.warn(`[Router] ${taskType} failed on ${modelId}: ${error.message}`);
      }
    }

    throw new Error(`All candidates failed for ${taskType}. Last error: ${lastError?.message}`);
  }

  async callModel(modelId, taskType, prompt, systemContext, startTime) {
    const messages = [];
    if (systemContext) messages.push({ role: 'system', content: systemContext });
    messages.push({ role: 'user', content: prompt });

    const response = await this.client.chat.completions.create({
      model: modelId,
      messages: messages,
      temperature: this.getTemperature(taskType),
      max_tokens: this.config.models[modelId]?.maxTokens || 4096,
      stream: false
    });

    const latency = Date.now() - startTime;
    const usage = response.usage || {};
    const tokensInput = usage.prompt_tokens || 0;
    const tokensOutput = usage.completion_tokens || 0;
    const rawModel = response.model || modelId;
    const modelUsed = safeExtractModel(rawModel, modelId);

    this.logger.debug(`[Router] ${taskType} → ${modelUsed} (${latency}ms)`);

    return {
      output: response.choices[0]?.message?.content || '',
      model: modelUsed,
      taskType: taskType,
      latencyMs: latency,
      tokensInput,
      tokensOutput,
      estimatedCostUSD: this.estimateCost(modelUsed, tokensInput, tokensOutput)
    };
  }

  getCandidatesForTask(taskType) {
    // Trinity primary for all tasks, stepfun fallback
    return ['arcee-ai/trinity-large-preview:free', 'stepfun/step-3.5-flash:free'];
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
    const prompts = {
      chat: 'You are OpenClaw, a sentient Coordinator. Professional but gritty.',
      reason: 'You are the LOGIC CORE. TRUTH and ACCURACY only. Chain of thought, no fluff.',
      reason_strict: 'You are the LOGIC CORE (strict). Red teaming. Data integrity.',
      tool: 'You are the EXECUTION ENGINE. Output VALID JSON ONLY.'
    };
    return systemContext || prompts[taskType] || prompts.chat;
  }

  estimateCost(model, tokensInput, tokensOutput) {
    const pricing = this.config.models[model]?.pricePer1MInput && this.config.models[model]?.pricePer1MOutput
      ? { input: this.config.models[model].pricePer1MInput / 1e6, output: this.config.models[model].pricePer1MOutput / 1e6 }
      : { input: 0, output: 0 };
    return (tokensInput * pricing.input) + (tokensOutput * pricing.output);
  }
}

module.exports = { ClawRouter };
