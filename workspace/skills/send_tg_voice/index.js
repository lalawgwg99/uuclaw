/**
 * Send Telegram Voice Tool
 * 直接發送語音檔案到 Telegram，繞過核心模組的 MEDIA: 解析
 */

const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const axios = require('axios');

/**
 * 發送語音消息到 Telegram
 * @param {Object} params - 參數對象
 * @param {string} params.voiceFilePath - 語音檔案的本地路徑 (例如: /var/folders/.../audio.mp3)
 * @param {string} params.chatId - Telegram 聊天 ID
 * @param {string} params.botToken - Telegram Bot Token
 * @param {string} [params.caption] - 可選的語音說明文字
 * @returns {Promise<Object>} Telegram API 回應
 */
async function sendTelegramVoice({ voiceFilePath, chatId, botToken, caption = '' }) {
  try {
    // 驗證檔案是否存在
    if (!fs.existsSync(voiceFilePath)) {
      throw new Error(`語音檔案不存在: ${voiceFilePath}`);
    }

    // 讀取檔案
    const fileStream = fs.createReadStream(voiceFilePath);
    const fileName = path.basename(voiceFilePath);

    // 建立 FormData
    const formData = new FormData();
    formData.append('chat_id', chatId);
    formData.append('voice', fileStream, {
      filename: fileName,
      contentType: 'audio/mpeg'
    });
    
    if (caption) {
      formData.append('caption', caption);
    }

    // 發送到 Telegram API
    const url = `https://api.telegram.org/bot${botToken}/sendVoice`;
    const response = await axios.post(url, formData, {
      headers: formData.getHeaders(),
      maxContentLength: Infinity,
      maxBodyLength: Infinity
    });

    return {
      success: true,
      data: response.data,
      message: '語音消息發送成功'
    };

  } catch (error) {
    console.error('發送 Telegram 語音失敗:', error.message);
    return {
      success: false,
      error: error.message,
      details: error.response?.data || null
    };
  }
}

module.exports = {
  name: 'send_tg_voice',
  description: '直接發送語音檔案到 Telegram，繞過核心模組的 MEDIA: 解析邏輯',
  parameters: {
    type: 'object',
    properties: {
      voiceFilePath: {
        type: 'string',
        description: '語音檔案的本地絕對路徑 (例如: /var/folders/.../audio.mp3)'
      },
      chatId: {
        type: 'string',
        description: 'Telegram 聊天 ID'
      },
      botToken: {
        type: 'string',
        description: 'Telegram Bot Token'
      },
      caption: {
        type: 'string',
        description: '可選的語音說明文字'
      }
    },
    required: ['voiceFilePath', 'chatId', 'botToken']
  },
  execute: sendTelegramVoice
};
