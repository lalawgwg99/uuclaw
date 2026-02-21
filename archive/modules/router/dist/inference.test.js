"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const inference_1 = require("../src/inference");
describe('TaskInference', () => {
    const config = {
        strictKeywords: ['證明', '反證', '最小化', '最佳化', '複雜度', '嚴格', 'formal'],
        reasonKeywords: ['為什麼', '推理', '分析', '步驟', '一步一步', '深入思考', '架構設計', '優缺點', '取捨',
            'reason step by step', 'step by step', 'analyze', 'analysis', 'design an architecture', 'architecture design', 'trade-offs', 'pros and cons'],
        lengthThresholds: {
            shortChat: 40,
            mediumChat: 80,
            longReasonBoost: 500,
            codeReasonBoostLength: 500
        },
        weights: { chat: 1, reason: 1, reason_strict: 1, tool: 1 },
        codeDetection: true
    };
    const inference = new inference_1.TaskInference(config);
    test('short prompt returns chat', () => {
        expect(inference.inferTaskType('Hi there')).toBe('chat');
    });
    test('strict reasoning keyword triggers reason_strict', () => {
        expect(inference.inferTaskType('證明這個定理')).toBe('reason_strict');
    });
    test('reason keyword with length returns reason', () => {
        const longPrompt = '為什麼會這樣？\n'.repeat(10);
        expect(inference.inferTaskType(longPrompt)).toBe('reason');
    });
    test('JSON / schema triggers tool', () => {
        const prompt = 'Convert this to JSON: { "name": "test" }';
        expect(inference.inferTaskType(prompt)).toBe('tool');
    });
    test('code detection prefers chat for short code, reason for long code', () => {
        const shortCode = 'function add(a, b) { return a + b; }';
        expect(inference.inferTaskType(shortCode)).toBe('chat');
        const longCode = 'function complex() {\n' + '  // many lines\n'.repeat(30) + '}';
        expect(inference.inferTaskType(longCode)).toBe('reason');
    });
});
