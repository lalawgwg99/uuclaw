"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CircuitBreaker = void 0;
class CircuitBreaker {
    constructor(config) {
        this.config = config;
        this.state = {
            failures: 0,
            lastFailureTime: null,
            state: 'CLOSED',
            halfOpenCalls: 0
        };
    }
    async execute(operation) {
        if (this.state.state === 'OPEN') {
            const now = Date.now();
            if (this.state.lastFailureTime && (now - this.state.lastFailureTime) > this.config.resetTimeoutMs) {
                this.state.state = 'HALF_OPEN';
                this.state.halfOpenCalls = 0;
            }
            else {
                throw new Error(`Circuit breaker OPEN for model. Retry after ${this.config.resetTimeoutMs}ms`);
            }
        }
        try {
            const result = await operation();
            this.onSuccess();
            return result;
        }
        catch (error) {
            this.onFailure();
            throw error;
        }
    }
    onSuccess() {
        this.state.failures = 0;
        this.state.state = 'CLOSED';
        this.state.halfOpenCalls = 0;
    }
    onFailure() {
        this.state.failures++;
        this.state.lastFailureTime = Date.now();
        if (this.state.failures >= this.config.failureThreshold) {
            this.state.state = 'OPEN';
        }
    }
    isClosed() {
        return this.state.state === 'CLOSED' || this.state.state === 'HALF_OPEN';
    }
    getState() {
        return { ...this.state };
    }
    reset() {
        this.state = {
            failures: 0,
            lastFailureTime: null,
            state: 'CLOSED',
            halfOpenCalls: 0
        };
    }
}
exports.CircuitBreaker = CircuitBreaker;
