# 使用 curl 測試 UUZero Standalone API

# 1. 健康檢查
curl http://localhost:3000/health

# 2. 快速生成 (chat 類型)
curl -X POST http://localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Hello! Who are you?"}'

# 3. 智能路由 (auto 類型)
curl -X POST http://localhost:3000/route \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Analyze the structural advantage of using a decentralized identity protocol for AI agents.",
    "type": "auto"
  }'

# 4. 批次處理
curl -X POST http://localhost:3000/batch \
  -H "Content-Type: application/json" \
  -d '{
    "prompts": [
      "Write a haiku about coding.",
      "Explain recursion in 10 words.",
      "What is 2+2?"
    ],
    "type": "auto"
  }'

# 5. Metrics
curl http://localhost:3000/metrics

# 6. 帶上下文
curl -X POST http://localhost:3000/route \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Based on the context, what is the main point?",
    "context": "The Sovereign Agent Protocol defines the core protocols for building autonomous AI agents. It includes Identity Governance, Cognitive Routing, and Capital Amplifier.",
    "type": "reason"
  }'