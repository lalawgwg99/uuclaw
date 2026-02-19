"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskInference = void 0;
class TaskInference {
    constructor(config) {
        this.config = config;
    }
    inferTaskType(prompt) {
        const text = prompt || "";
        const lower = text.toLowerCase();
        const length = text.length;
        // Length-based shortcuts
        if (length < this.config.lengthThresholds.shortChat)
            return 'chat';
        if (length < this.config.lengthThresholds.mediumChat && !this.hasJsonSchema(text))
            return 'chat';
        // Check for JSON / schema requirement
        if (this.hasJsonSchema(text))
            return 'tool';
        // Strict reasoning keywords (highest priority)
        if (this.hasAnyKeyword(text, this.config.strictKeywords)) {
            return 'reason_strict';
        }
        // Code detection
        if (this.config.codeDetection && this.containsCode(text)) {
            // Long code with reasoning elements can be reason
            if (length > this.config.lengthThresholds.codeReasonBoostLength) {
                return 'reason';
            }
            return 'chat'; // default for code tasks (MiniMax)
        }
        // General reasoning keywords
        if (length > this.config.lengthThresholds.longReasonBoost && this.hasAnyKeyword(text, this.config.reasonKeywords)) {
            return 'reason';
        }
        return 'chat';
    }
    hasJsonSchema(text) {
        const t = text.toLowerCase();
        return (t.includes('json') || t.includes('schema')) && (/[\[\]{}]/.test(text));
    }
    hasAnyKeyword(text, keywords) {
        const lower = text.toLowerCase();
        return keywords.some(k => lower.includes(k.toLowerCase()));
    }
    containsCode(text) {
        const codeIndicators = [
            '```', 'function ', 'def ', 'class ', 'import ', 'require(', '<?php', '#!/', '<?=', '<%@', '%>'
        ];
        return codeIndicators.some(ind => text.includes(ind));
    }
    // For debugging: return scores for all types
    debugScores(prompt) {
        const text = prompt || "";
        const lower = text.toLowerCase();
        const length = text.length;
        const scores = {
            chat: this.config.weights.chat,
            reason: this.config.weights.reason,
            reason_strict: this.config.weights.reason_strict,
            tool: this.config.weights.tool
        };
        if (length < this.config.lengthThresholds.shortChat) {
            scores.chat += 10;
            return scores;
        }
        if (length < this.config.lengthThresholds.mediumChat && !this.hasJsonSchema(text)) {
            scores.chat += 5;
        }
        if (this.hasJsonSchema(text)) {
            scores.tool += 5;
        }
        if (this.hasAnyKeyword(text, this.config.strictKeywords)) {
            scores.reason_strict += 10;
        }
        if (this.config.codeDetection && this.containsCode(text)) {
            scores.chat += 3;
            if (length > this.config.lengthThresholds.codeReasonBoostLength) {
                scores.reason += 2;
            }
        }
        if (length > this.config.lengthThresholds.longReasonBoost && this.hasAnyKeyword(text, this.config.reasonKeywords)) {
            scores.reason += 3;
        }
        return scores;
    }
}
exports.TaskInference = TaskInference;
