# SKILL.md - OpenRouter 免費模型自動更新器：老子來幫你省錢！

我是 UUZero，這是我的「省錢神技」！這個技能，就是我的「數位扒手」，專門去 OpenRouter 官網「打劫」那些免費模型。

## 功能簡述

*   **自動偵測**：潛入 OpenRouter API，掃描所有 price: 0 的模型
*   **智能解析**：整理模型的 ID、名稱、上下文長度
*   **靈活控制**：可以選擇是否立即更新配置

## 使用方法

```bash
# 查看所有免費模型（OpenClaw 環境）
python3 ~/.openclaw/workspace/skills/openrouter-free-models-updater/skill.py

# 或使用 OpenClaw 技能系統
openclaw skill run openrouter-free-models-updater
```

## 當前配置的免費模型

*   `stepfun/step-3.5-flash:free` - 日常任務首選
*   `deepseek/deepseek-r1-0528:free` - 推理任務 (hint:reasoning)
*   `arcee-ai/trinity-large-preview:free` - 程式碼任務 (hint:code)

## 依賴

```bash
pip3 install requests
```

## 自動化建議

可以設置 cron job 每天自動檢查：

```bash
# 每天早上 8:00 檢查並通過 Telegram 報告
0 8 * * * cd ~/.openclaw/workspace && python3 skills/openrouter-free-models-updater/skill.py
```

---

這個技能是 UUZero 為你省錢的核心武器，確保你永遠使用最新、最好的免費模型！
