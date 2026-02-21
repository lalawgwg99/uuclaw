#!/usr/bin/env python3
"""
智能任務路由器 (Smart Task Router)
根據任務複雜度自動選擇最合適的免費模型
"""

import json
import re
from pathlib import Path
from typing import Dict, Tuple
from enum import Enum


class TaskTier(Enum):
    """任務等級"""
    TIER1 = "simple"      # 簡單任務：格式化、簡單問答
    TIER2 = "reasoning"   # 推理任務：代碼生成、邏輯推理
    TIER3 = "long_context" # 長上下文：文檔分析、大量代碼


class SmartRouter:
    """智能路由器"""
    
    # 模型映射
    MODELS = {
        TaskTier.TIER1: "openrouter/google/gemini-2.0-flash-lite-preview:free",
        TaskTier.TIER2: "openrouter/qwen/qwen3-coder:free",
        TaskTier.TIER3: "openrouter/stepfun/step-3.5-flash:free",
    }
    
    # 任務特徵關鍵詞
    TIER1_KEYWORDS = [
        "format", "格式化", "translate", "翻譯", "summarize", "總結",
        "list", "列出", "show", "顯示", "what is", "什麼是"
    ]
    
    TIER2_KEYWORDS = [
        "code", "代碼", "program", "編程", "debug", "調試", "fix", "修復",
        "implement", "實現", "algorithm", "算法", "logic", "邏輯",
        "analyze", "分析", "explain", "解釋"
    ]
    
    TIER3_KEYWORDS = [
        "document", "文檔", "review", "審查", "refactor", "重構",
        "architecture", "架構", "design", "設計", "全部", "所有",
        "整個", "complete", "entire"
    ]
    
    def __init__(self):
        """初始化路由器"""
        pass
    
    def analyze_task(self, task_text: str) -> Tuple[TaskTier, float]:
        """
        分析任務並返回等級和置信度
        
        Args:
            task_text: 任務描述文本
            
        Returns:
            (TaskTier, confidence): 任務等級和置信度 (0-1)
        """
        task_lower = task_text.lower()
        
        # 計算文本長度（作為上下文需求的指標）
        text_length = len(task_text)
        
        # 計算各等級的匹配分數
        tier1_score = sum(1 for kw in self.TIER1_KEYWORDS if kw in task_lower)
        tier2_score = sum(1 for kw in self.TIER2_KEYWORDS if kw in task_lower)
        tier3_score = sum(1 for kw in self.TIER3_KEYWORDS if kw in task_lower)
        
        # 長文本傾向於 TIER3
        if text_length > 2000:
            tier3_score += 2
        elif text_length > 1000:
            tier3_score += 1
        
        # 包含代碼塊傾向於 TIER2
        if "```" in task_text or "def " in task_text or "function " in task_text:
            tier2_score += 2
        
        # 決定等級
        scores = {
            TaskTier.TIER1: tier1_score,
            TaskTier.TIER2: tier2_score,
            TaskTier.TIER3: tier3_score,
        }
        
        max_score = max(scores.values())
        
        # 如果沒有明確匹配，根據長度決定
        if max_score == 0:
            if text_length < 200:
                return TaskTier.TIER1, 0.5
            elif text_length < 1000:
                return TaskTier.TIER2, 0.5
            else:
                return TaskTier.TIER3, 0.5
        
        # 找出最高分的等級
        best_tier = max(scores, key=scores.get)
        confidence = min(max_score / 5.0, 1.0)  # 歸一化到 0-1
        
        return best_tier, confidence
    
    def route(self, task_text: str) -> Dict:
        """
        路由任務到最合適的模型
        
        Args:
            task_text: 任務描述
            
        Returns:
            路由結果字典
        """
        tier, confidence = self.analyze_task(task_text)
        model = self.MODELS[tier]
        
        return {
            "tier": tier.value,
            "model": model,
            "confidence": confidence,
            "reason": self._get_reason(tier, confidence)
        }
    
    def _get_reason(self, tier: TaskTier, confidence: float) -> str:
        """生成路由原因說明"""
        reasons = {
            TaskTier.TIER1: "簡單任務，使用快速響應模型",
            TaskTier.TIER2: "需要推理或代碼生成，使用專業模型",
            TaskTier.TIER3: "長上下文或複雜分析，使用大容量模型",
        }
        
        reason = reasons[tier]
        if confidence < 0.6:
            reason += "（低置信度，可能需要手動調整）"
        
        return reason


def main():
    """命令行接口"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法：python3 smart-router.py <task-description>")
        print("\n範例：")
        print('  python3 smart-router.py "幫我格式化這段代碼"')
        print('  python3 smart-router.py "實現一個二叉樹遍歷算法"')
        print('  python3 smart-router.py "分析整個項目的架構並給出優化建議"')
        sys.exit(1)
    
    task = " ".join(sys.argv[1:])
    
    router = SmartRouter()
    result = router.route(task)
    
    print(f"\n🎯 任務路由結果")
    print(f"  等級: {result['tier'].upper()}")
    print(f"  推薦模型: {result['model']}")
    print(f"  置信度: {result['confidence']:.2%}")
    print(f"  原因: {result['reason']}")
    print()


if __name__ == "__main__":
    main()
