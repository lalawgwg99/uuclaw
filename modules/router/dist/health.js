"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HealthMonitor = void 0;
class HealthMonitor {
    constructor(config) {
        this.config = config;
        this.metrics = {
            recentSuccesses: [],
            recentLatencies: [],
            lastUpdated: Date.now()
        };
    }
    recordSuccess(latencyMs) {
        this.pushMetric(1, latencyMs);
    }
    recordFailure(latencyMs) {
        this.pushMetric(0, latencyMs);
    }
    pushMetric(success, latencyMs) {
        this.metrics.recentSuccesses.push(success);
        this.metrics.recentLatencies.push(latencyMs);
        if (this.metrics.recentSuccesses.length > this.config.windowSize) {
            this.metrics.recentSuccesses.shift();
            this.metrics.recentLatencies.shift();
        }
        this.metrics.lastUpdated = Date.now();
    }
    getSuccessRate() {
        if (this.metrics.recentSuccesses.length === 0)
            return 1.0;
        const sum = this.metrics.recentSuccesses.reduce((a, b) => a + b, 0);
        return sum / this.metrics.recentSuccesses.length;
    }
    getAvgLatency() {
        if (this.metrics.recentLatencies.length === 0)
            return 0;
        const sum = this.metrics.recentLatencies.reduce((a, b) => a + b, 0);
        return sum / this.metrics.recentLatencies.length;
    }
    isHealthy() {
        if (!this.config.dynamicWeighting)
            return true;
        const successRate = this.getSuccessRate();
        const avgLatency = this.getAvgLatency();
        return successRate >= this.config.successRateThreshold && avgLatency <= this.config.latencyThresholdMs;
    }
    getWeightPenalty() {
        if (!this.config.dynamicWeighting)
            return 1.0;
        const successRate = this.getSuccessRate();
        const avgLatency = this.getAvgLatency();
        let penalty = 1.0;
        if (successRate < this.config.successRateThreshold) {
            penalty *= 0.5;
        }
        if (avgLatency > this.config.latencyThresholdMs) {
            penalty *= 0.8;
        }
        return penalty;
    }
    getMetrics() {
        return { ...this.metrics };
    }
}
exports.HealthMonitor = HealthMonitor;
