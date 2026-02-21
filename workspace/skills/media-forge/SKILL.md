# Media Forge Skill

Media Forge 是 UUZero 的多媒體生成工廠，能快速將文字、數據轉換為圖片、GIF、音频、簡單影片片段，用於 Telegram 傳播或內容創作。

## 核心功能

- **Text-to-Image**：利用 `seedance-screenwriter` 生成 video storyboard → 調用 runway/pika/其他 API 生成 image
- **Text-to-Speech**：使用本地或雲端 TTS（`openai-whisper` 反向、`tts` CLI）
- **Spectrogram 生成**：音樂/音频可視化（`songsee`）
- **Text-to-GIF**：將連續 frames 組合成動圖
- **Video Clip 剪輯**：從 RTSP/影片中截取片段（`camsnap`, `video-frames`）
- **Batch Processing**：批量生成，統一格式輸出

## 使用方法

```bash
# 生成圖片
media-forge image "一只貓在飛" --output cat_flying.png --model runway

# 生成語音
media-forge tts "Hello world" --output hello.mp3 --lang en

# 生成频谱圖
media-forge spectrogram audio.mp3 --output spec.png

# 生成 GIF（多張圖片）
media-forge gif frame-*.png --output animation.gif --delay 100

# 從影片剪輯
media-forge clip input.mp4 --start 00:00:05 --duration 10 --output clip.mp4
```

## 依賴

- `seedance-screenwriter`（storyboard 生成）
- `songsee`（spectrogram）
- `camsnap`, `video-frames`（影片處理）
- `tts`（文字轉語音）
- `canvas`（圖像合成）

## 與 OpenClaw 整合

Media Forge 主要作為 **creative agent** 的工具集，當用戶要求「generate image/audio/video」時，由 `CodeMonkey` 或 `SmoothTalker` 調用對應子命令。

同時支援 background generation：

```bash
# 將大量文本批量轉語音
media-forge tts-batch texts.txt --output-dir ./audio

# 自動生成每日圖卡（quote + bg）
media-forge card "今日金句" --bg gradient --output daily_card.png
```

## 輸出格式

- 圖片：PNG（預設）、JPEG、WebP
- 音頻：MP3、WAV、OGG
- 影片：MP4（H.264）、WebM、GIF
- 所有Intermediate files 存 `~/.cache/media-forge`

## 配置

環境變數：
- `MEDIA_FORGE_OUTPUT_DIR`：輸出目錄（預設 `~/Pictures/MediaForge`）
- `RUNWAY_API_KEY` / `PIKA_API_KEY`：第三方生成服務 key
- `OPENAI_API_KEY`：用於 DALL·E（備用）

## License

MIT