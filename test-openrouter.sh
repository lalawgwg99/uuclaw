#!/bin/bash

echo "測試 OpenRouter API..."
echo ""

curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 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" \
  -d '{
    "model": "qwen/qwen3-coder:free",
    "messages": [
      {"role": "user", "content": "Hello"}
    ]
  }' | jq '.'

echo ""
echo "測試完成"
