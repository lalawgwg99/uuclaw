"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
const fs_1 = __importDefault(require("fs"));
class Logger {
    constructor(config) {
        this.config = config;
    }
    debug(message) {
        if (this.config.logging.debugRoute) {
            console.error(`\x1b[90m[DEBUG]\x1b[0m ${message}`);
        }
    }
    route(modelId, taskType, reason) {
        console.error(`\x1b[36m[ROUTER]\x1b[0m ${modelId} → ${taskType} (${reason})`);
    }
    fallback(from, to) {
        console.error(`\x1b[33m[FALLBACK]\x1b[0m ${from} → ${to}`);
    }
    error(modelId, error) {
        console.error(`\x1b[31m[ERROR]\x1b[0m ${modelId}: ${error.message}`);
    }
    logRouting(entry) {
        if (this.config.logging.routingLog && this.config.logging.routingLogPath) {
            try {
                fs_1.default.appendFileSync(this.config.logging.routingLogPath, JSON.stringify(entry) + '\n');
            }
            catch (e) {
                console.error('Failed to write routing log:', e);
            }
        }
        if (this.config.logging.debugRoute) {
            console.error(`[LOG] ${JSON.stringify(entry, null, 2)}`);
        }
    }
    close() {
        // nothing to close
    }
}
exports.Logger = Logger;
