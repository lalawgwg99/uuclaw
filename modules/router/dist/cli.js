"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const router_1 = require("./router");
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const apiKey = process.env.OPENROUTER_API_KEY;
if (!apiKey) {
    console.error("Error: OPENROUTER_API_KEY is not set.");
    process.exit(1);
}
const router = new router_1.ClawRouter(apiKey);
async function main() {
    const args = process.argv.slice(2);
    let taskType = 'auto';
    let prompt = "";
    let context = "";
    let schema = "";
    // One-click: reason_strict → DeepSeek V3.2 for this run
    if (args.includes("--reason-strict-deepseek")) {
        process.env.OPENCLAW_REASON_STRICT_DEEPSEEK = "1";
    }
    // Simple flag parser; tools will call this with explicit flags
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '--type') {
            const type = args[++i];
            if (type === 'chat' || type === 'reason' || type === 'tool' || type === 'auto')
                taskType = type;
        }
        else if (arg === '--prompt') {
            prompt = args[++i] || "";
        }
        else if (arg === '--context') {
            context = args[++i] || "";
        }
        else if (arg === '--schema') {
            schema = args[++i] || "";
        }
    }
    if (!prompt) {
        console.error("Usage: node cli.js --type <type> --prompt <prompt> [--context <ctx>] [--schema <sch>]");
        process.exit(1); // Fail gracefully but exit 1 to indicate error
    }
    // Combine inputs based on logic requested by user ("Hub-and-Spoke" Skill logic)
    // The Skill definition passes structured params; here we merge them into the prompt for the Router.
    let finalPrompt = prompt;
    if (taskType === 'reason' && context) {
        finalPrompt = `Context Summary:\n${context}\n\nTask:\n${prompt}`;
    }
    else if (taskType === 'tool' && schema) {
        finalPrompt = `Schema Requirement:\n${schema}\n\nInput Data:\n${prompt}`;
    }
    try {
        const stream = taskType === 'auto'
            ? await router.autoRoute(finalPrompt)
            : await router.route(taskType, finalPrompt);
        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content;
            if (content) {
                process.stdout.write(content);
            }
        }
        process.stdout.write("\n");
    }
    catch (error) {
        console.error("Execution failed:", error);
        process.exit(1);
    }
}
main();
