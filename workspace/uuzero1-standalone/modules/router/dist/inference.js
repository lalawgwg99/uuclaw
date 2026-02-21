"use strict";

class Inference {
  constructor(config) {
    this.config = config;
  }

  inferTaskType(prompt) {
    const txt = prompt.toLowerCase();
    let score = { chat: 0, reason: 0, tool: 0 };

    // Keywords
    const strictKeywords = this.config.inference?.strictKeywords || [];
    const reasonKeywords = this.config.inference?.reasonKeywords || [];

    for (const kw of strictKeywords) {
      if (txt.includes(kw.toLowerCase())) {
        score.reason += 2;
      }
    }
    for (const kw of reasonKeywords) {
      if (txt.includes(kw.toLowerCase())) {
        score.reason += 1;
      }
    }

    // Length
    const len = prompt.length;
    const longReasonBoost = this.config.inference?.lengthThresholds?.longReasonBoost || 500;
    if (len > longReasonBoost) {
      score.reason += 1.5;
    }

    // Code detection
    if (this.config.inference?.codeDetection) {
      if (/```|function|class |def |import |require\(/.test(prompt)) {
        score.tool += 2;
      }
    }

    // Choose max
    const maxType = Object.keys(score).reduce((a, b) => score[a] > score[b] ? a : b, 'chat');
    return maxType;
  }
}

module.exports = { Inference };
