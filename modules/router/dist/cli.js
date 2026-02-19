#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const router_1 = require("./router");
const config_1 = require("./config");
async function main() {
    const config = (0, config_1.loadConfig)();
    const router = new router_1.ClawRouter(config);
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
        const stream = taskType === 'auto'
            ? await router.autoRoute(finalPrompt)
            : await router.route(taskType, finalPrompt);
        let fullOutput = "";
        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content;
            if (content) {
                process.stdout.write(content);
                fullOutput += content;
            }
        }
        const latency = Date.now() - start;
        const tokensInput = Math.ceil(finalPrompt.length / 4);
        const tokensOutput = Math.ceil(fullOutput.length / 4);
        router.recordCost(taskType === 'auto' ? config.defaultModel : taskType === 'reason' ? 'stepfun/step-3.5-flash:free'
            : taskType === 'tool' ? 'arcee-ai/trinity-large-preview:free'
                : 'minimax/minimax-m2.5', tokensInput, tokensOutput);
        if (outputJson) {
            const report = {
                taskType,
                latencyMs: latency,
                tokensInput,
                tokensOutput,
                estimatedCostUSD: router.getSessionCost(),
                model: config.defaultModel
            };
            console.error("\n--- METRICS ---");
            console.error(JSON.stringify(report, null, 2));
        }
        else {
            console.error(`\n[metrics] latency=${latency}ms tokens=${tokensInput}+${tokensOutput} cost=$${router.getSessionCost().toFixed(6)}`);
        }
    }
    catch (error) {
        console.error("Execution failed:", error.message);
        process.exit(1);
    }
    finally {
        router.close();
    }
}
main();
