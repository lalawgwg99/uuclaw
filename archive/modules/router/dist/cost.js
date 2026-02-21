"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CostTracker = void 0;
class CostTracker {
    constructor(models) {
        this.modelPricing = models;
        this.sessionAccumulated = new Map();
        this.grandTotal = 0;
    }
    estimateCost(modelId, tokensInput, tokensOutput) {
        const pricing = this.modelPricing[modelId];
        if (!pricing)
            return 0;
        const inputCost = (tokensInput / 1000000) * pricing.pricePer1MInput;
        const outputCost = (tokensOutput / 1000000) * pricing.pricePer1MOutput;
        return inputCost + outputCost;
    }
    record(modelId, tokensInput, tokensOutput) {
        const cost = this.estimateCost(modelId, tokensInput, tokensOutput);
        const prev = this.sessionAccumulated.get(modelId) || 0;
        this.sessionAccumulated.set(modelId, prev + cost);
        this.grandTotal += cost;
    }
    getSessionCost() {
        let total = 0;
        for (const v of this.sessionAccumulated.values()) {
            total += v;
        }
        return total;
    }
    getModelBreakdown() {
        return new Map(this.sessionAccumulated);
    }
    resetSession() {
        this.sessionAccumulated.clear();
    }
    getGrandTotal() {
        return this.grandTotal;
    }
}
exports.CostTracker = CostTracker;
