/**
 * Telegram Voice Sender Skill
 * 讓 Agent 可以直接發送語音到 Telegram
 */

const { execSync } = require('child_process');
const path = require('path');

const SCRIPT_PATH = path.join(__dirname, '../send_tg_voice.sh');

async function sendVoiceToTelegram({ voiceFilePath, caption = '' }) {
  try {
    // 驗證檔案路徑
    if (!voiceFilePath) {
      throw new Error('必須提供語音檔案路徑');
    }

    console.log(`[Telegram Voice] 正在發送語音: ${voiceFilePath}`);

    // 執行發送腳本
    const result = execSync(`"${SCRIPT_PATH}" "${voiceFilePath}"`, {
      encoding: 'utf8',
      timeout: 30000
    });

    console.log(`[Telegram Voice] 發送結果: ${result}`);

    return {
      success: true,
      message: '語音已成功發送到 Telegram',
      output: result
    };

  } catch (error) {
    console.error('[Telegram Voice] 發送失敗:', error.message);
    return {
      success: false,
      error: error.message,
      stderr: error.stderr?.toString() || ''
    };
  }
}

module.exports = {
  name: 'send_telegram_voice',
  description: '發送語音檔案到 Telegram（繞過核心模組的 MEDIA: 解析）',
  parameters: {
    type: 'object',
    properties: {
      voiceFilePath: {
        type: 'string',
        description: '語音檔案的本地絕對路徑（例如: /var/folders/.../audio.mp3）'
      },
      caption: {
        type: 'string',
        description: '可選的語音說明文字（目前未使用）'
      }
    },
    required: ['voiceFilePath']
  },
  execute: sendVoiceToTelegram
};
