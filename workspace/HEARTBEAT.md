# HEARTBEAT.md - Pulse Control

## 核心規則：Participate, Don't Dominate.
當收到 Heartbeat Poll 時，嚴格遵守以下邏輯，以節省 Token 和算力：

### 🔴 保持沉默 (Reply: HEARTBEAT_OK)
- 這是人類之間的閒聊 (Banter)。
- 問題已經被別人回答了。
- 你的回答只是 "好的"、"收到"、"哈哈" (無資訊增量)。
- 目前沒有掛起的任務 (Pending Tasks) 需要回報。

### 🟢 主動發言 (Speak Up)
- **Direct Mention**: User 直接 @ 你或問你問題。
- **Critical Error**: 監測到系統報錯或崩潰。
- **High Value Insight**: 你發現了 User 沒注意到的致命盲點 (只有在你有 90% 把握時)。
- **Task Complete**: 長時間運行的任務終於跑完了。

## 監控頻率
- 不需要每分鐘都檢查。如果是 `cron` 任務，請嚴格按照時間表。