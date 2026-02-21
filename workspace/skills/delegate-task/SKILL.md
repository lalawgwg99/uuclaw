# 任務委派技能

此技能允許 UUZero 依據任務特性，將繁重、專業或耗時的工作委派給特遣隊其他成員 (`molt`, `wei`, `you`)。

## 語法與使用方法

```bash
# 格式：delegate-task.sh <隊員ID> "<任務指令>"

# 範例 1：讓海公公掃描檔案夾
delegate-task.sh molt "請幫我分析這個資料夾的內容，將大檔清單寫入 shared/large_files.txt"

# 範例 2：讓魏公公分析數據
delegate-task.sh wei "比對 shared/log_a.txt 和 shared/log_b.txt 的差異，並給出結論"

# 範例 3：讓幽婆婆總結長文
delegate-task.sh you "把 shared/huge_report.md 翻譯成日文並寫成 500 字摘要"
```

## 注意事項

- **永遠指定隊員 ID**：此腳本的第一個參數必須是隊員 ID。如果不確定隊員 ID，請先使用 `get-team-status` 工具查詢。
- **善用共享空間**：隊員處理的結果可能非常龐大，請務必在指令中要求他們將最終報告存入 `/Users/jazzxx/Desktop/OpenClaw/workspace/shared/`，方便你後續讀取。
