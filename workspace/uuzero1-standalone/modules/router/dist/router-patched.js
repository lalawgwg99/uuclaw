    getCandidatesForTask(taskType) {
        switch (taskType) {
            case 'reason_strict':
                return [this.config.models['deepseek/deepseek-v3.2']?.id || 'deepseek/deepseek-v3.2',
                        this.config.models['stepfun/step-3.5-flash:free']?.id || 'stepfun/step-3.5-flash:free'];
            case 'reason':
                // Use deepseek-r1 for reasoning (free)
                return [this.config.models['deepseek/deepseek-r1-0528:free']?.id || 'deepseek/deepseek-r1-0528:free'];
            case 'tool':
                // Use trinity for tool execution (free)
                return [this.config.models['arcee-ai/trinity-large-preview:free']?.id || 'arcee-ai/trinity-large-preview:free'];
            case 'chat':
                // Use stepfun for chat by default
                return [this.config.models['stepfun/step-3.5-flash:free']?.id || 'stepfun/step-3.5-flash:free'];
            case 'auto':
            default:
                // Auto picks stepfun (default), fallbacks will handle if unhealthy
                return [this.config.defaultModel || 'stepfun/step-3.5-flash:free'];
        }
    }