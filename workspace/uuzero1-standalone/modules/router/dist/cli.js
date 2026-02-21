#!/usr/bin/env node
"use strict";

// 徹底靜音 stdout：關閉所有第三方套件的 debug 輸出
process.env.DOTENV_CONFIG_DEBUG = 'false';
process.env.DEBUG = '';

Object.defineProperty(exports, "__esModule", { value: true });
const router_1 = require("./router");
const config_1 = require("./config");
async function main() {
    const config = (0, config_1.loadConfig)();

    // Stderr-only logger to keep stdout clean for model output
    const stderrLogger = {
      debug: (...args) => console.error('[DEBUG]', ...args),
      warn: (...args) => console.error('[WARN]', ...args),
      log: (...args) => console.error('[LOG]', ...args),
      error: console.error
    };
    const router = new router_1.ClawRouter(config, stderrLogger);

    const args = process.argv.slice(2);
    let taskType = 'auto';
    let prompt = "";
    let context = "";
    let schema = "";
    let outputJson = false;
    if (args.includes("--reason-strict-deepseek")) {
        process.env.OPENCLAW_REASON_STRICT_DEEPSEEK = "1";
    }
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        switch (arg) {
            case '--type':
                const type = args[++i];
                if (['chat', 'reason', 'tool', 'auto'].includes(type)) {
                    taskType = type;
                }
                break;
            case '--prompt':
                prompt = args[++i] || "";
                break;
            case '--context':
                context = args[++i] || "";
                break;
            case '--schema':
                schema = args[++i] || "";
                break;
            case '--debug-route':
                config.logging.debugRoute = true;
                break;
            case '--routing-log':
                const logPath = args[++i];
                config.logging.routingLog = true;
                config.logging.routingLogPath = logPath;
                break;
            case '--json':
                outputJson = true;
                break;
        }
    }
    if (!prompt) {
        console.error("Usage: open99-router --type <type> --prompt \"<prompt>\" [--context <ctx>] [--schema <sch>] [--debug-route] [--routing-log <path>] [--json]");
        process.exit(1);
    }
    let finalPrompt = prompt;
    if (taskType === 'reason' && context) {
        finalPrompt = `Context:\n${context}\n\nTask:\n${prompt}`;
    }
    else if (taskType === 'tool' && schema) {
        finalPrompt = `Schema:\n${schema}\n\nInput:\n${prompt}`;
    }
    try {
        const start = Date.now();
        const result = taskType === 'auto'
            ? await router.autoRoute(finalPrompt)
            : await router.route(taskType, finalPrompt);
        let fullOutput = "";
        if (result && typeof result === 'object' && result.output) {
            fullOutput = result.output;
            process.stdout.write(fullOutput);
        }
        const latency = Date.now() - start;
        const tokensInput = result.tokensInput || Math.ceil(finalPrompt.length / 4);
        const tokensOutput = result.tokensOutput || Math.ceil(fullOutput.length / 4);
        const estimatedCost = result.estimatedCostUSD || 0;
        const report = {
            taskType,
            latencyMs: latency,
            tokensInput,
            tokensOutput,
            estimatedCostUSD: estimatedCost,
            model: result.model
        };
        console.error("\n--- METRICS ---");
        console.error(JSON.stringify(report, null, 2));
    }
    catch (error) {
        console.error("Execution failed:", error.message);
        process.exit(1);
    }
}
main();
