#!/usr/bin/env python3
"""
OpenRouter 免費模型分析器
每天自動檢查免費模型並通過 Telegram 發送分析報告
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

try:
    import requests
except ImportError:
    print("錯誤：缺少 requests 函式庫")
    print("請執行：pip3 install requests")
    sys.exit(1)


def fetch_free_models():
    """從 OpenRouter API 獲取免費模型列表（帶快取，節省 API 呼叫與 token）"""
    import time
    cache_path = Path.home() / ".openclaw" / "free-models-cache.json"
    cache_ttl_ms = 60 * 60 * 1000  # 1 小時

    # 嘗試讀取快取
    try:
        if cache_path.exists():
            with open(cache_path, 'r', encoding='utf-8') as f:
                cache = json.load(f)
            last_check_ts = datetime.fromisoformat(cache.get("last_check", "")).timestamp() * 1000
            if (time.time() * 1000 - last_check_ts) < cache_ttl_ms:
                models = cache.get("models", [])
                print(f"[cache] 使用免費模型快取（{len(models)} 個模型，TTL 剩餘 {int((cache_ttl_ms - (time.time()*1000 - last_check_ts))/60000)} 分）")
                return models
    except Exception as e:
        print(f"[cache] 讀取快取失敗：{e}，將重新取得")

    # 若無快取或快取過期，從 API 取得
    print("[cache] 快取未命中，正在從 OpenRouter 獲取最新模型列表...")
    url = "https://openrouter.ai/api/v1/models"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        models = data.get("data", [])
        
        # 篩選免費模型
        free_models = []
        for model in models:
            pricing = model.get("pricing", {})
            prompt_price = float(pricing.get("prompt", "0"))
            completion_price = float(pricing.get("completion", "0"))
            
            if prompt_price == 0 and completion_price == 0:
                free_models.append({
                    "id": model.get("id"),
                    "name": model.get("name", model.get("id")),
                    "contextWindow": model.get("context_length", 128000)
                })
        
        print(f"[cache] 取得 {len(free_models)} 個免費模型，寫入快取")
        # 保存快取
        try:
            cache_data = {
                "last_check": datetime.now().isoformat(),
                "models": free_models
            }
            with open(cache_path, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"[cache] 寫入快取失敗：{e}")
        
        return free_models
    
    except requests.RequestException as e:
        print(f"API 請求失敗：{e}")
        return None


def get_current_model():
    """獲取當前使用的模型"""
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    
    try:
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            current = config.get("agents", {}).get("defaults", {}).get("model", {}).get("primary", "未設置")
            return current
    except Exception as e:
        return f"讀取失敗: {e}"
    
    return "未找到配置"


def analyze_models(free_models):
    """分析免費模型並生成建議"""
    if not free_models:
        return "未找到免費模型"
    
    # 按上下文長度排序
    sorted_by_context = sorted(free_models, key=lambda x: x['contextWindow'], reverse=True)
    
    # 分類模型
    large_context = [m for m in free_models if m['contextWindow'] >= 128000]
    vision_models = [m for m in free_models if 'vl' in m['id'].lower() or 'vision' in m['id'].lower()]
    thinking_models = [m for m in free_models if 'thinking' in m['id'].lower() or 'r1' in m['id'].lower()]
    coder_models = [m for m in free_models if 'coder' in m['id'].lower() or 'code' in m['name'].lower()]
    
    current_model = get_current_model()
    
    # 生成報告
    report = f"""📊 OpenRouter 免費模型分析報告
🕐 檢查時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

📌 當前使用模型:
{current_model}

📈 統計資訊:
• 總共找到 {len(free_models)} 個免費模型
• 大上下文模型 (≥128K): {len(large_context)} 個
• 視覺模型: {len(vision_models)} 個
• 思考模型: {len(thinking_models)} 個
• 編程模型: {len(coder_models)} 個

🏆 推薦模型:

1️⃣ 最大上下文 (適合長文檔):
   {sorted_by_context[0]['name']}
   ID: {sorted_by_context[0]['id']}
   上下文: {sorted_by_context[0]['contextWindow']:,} tokens

2️⃣ 編程任務推薦:
"""
    
    if coder_models:
        best_coder = max(coder_models, key=lambda x: x['contextWindow'])
        report += f"""   {best_coder['name']}
   ID: {best_coder['id']}
   上下文: {best_coder['contextWindow']:,} tokens
"""
    else:
        report += "   無專門的編程模型\n"
    
    report += "\n3️⃣ 思考推理任務:\n"
    if thinking_models:
        best_thinking = max(thinking_models, key=lambda x: x['contextWindow'])
        report += f"""   {best_thinking['name']}
   ID: {best_thinking['id']}
   上下文: {best_thinking['contextWindow']:,} tokens
"""
    else:
        report += "   無思考模型\n"
    
    report += "\n4️⃣ 視覺任務:\n"
    if vision_models:
        best_vision = max(vision_models, key=lambda x: x['contextWindow'])
        report += f"""   {best_vision['name']}
   ID: {best_vision['id']}
   上下文: {best_vision['contextWindow']:,} tokens
"""
    else:
        report += "   無視覺模型\n"
    
    report += f"""
📋 完整模型列表 (前 10 名):
"""
    
    for i, model in enumerate(sorted_by_context[:10], 1):
        report += f"{i}. {model['name']}\n"
        report += f"   ID: {model['id']}\n"
        report += f"   上下文: {model['contextWindow']:,}\n\n"
    
    report += f"""
💡 建議:
• 如果需要處理長文檔，建議使用 {sorted_by_context[0]['name']}
• 如果主要做編程任務，建議使用 {coder_models[0]['name'] if coder_models else '通用模型'}
• 所有模型都是免費的，可以隨時切換測試

🔄 如需更換模型，請回覆模型 ID
"""
    
    return report


def send_telegram_message(message):
    """發送 Telegram 訊息"""
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        bot_token = config.get("channels", {}).get("telegram", {}).get("botToken")
        allow_from = config.get("channels", {}).get("telegram", {}).get("allowFrom", [])
        
        if not bot_token:
            print("錯誤：未找到 Telegram bot token")
            return False
        
        if not allow_from or allow_from == ["*"]:
            print("錯誤：未設置允許的用戶 ID")
            return False
        
        # 發送給所有允許的用戶
        success_count = 0
        for chat_id in allow_from:
            if chat_id == "*":
                continue
            
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            data = {
                "chat_id": chat_id,
                "text": message,
                "parse_mode": "HTML"
            }
            
            response = requests.post(url, json=data, timeout=10)
            if response.status_code == 200:
                success_count += 1
                print(f"✓ 已發送訊息到 {chat_id}")
            else:
                print(f"✗ 發送到 {chat_id} 失敗: {response.text}")
        
        return success_count > 0
    
    except Exception as e:
        print(f"發送 Telegram 訊息失敗：{e}")
        return False


def save_models_cache(free_models):
    """保存模型列表到緩存"""
    cache_path = Path.home() / ".openclaw" / "free-models-cache.json"
    
    try:
        cache_data = {
            "last_check": datetime.now().isoformat(),
            "models": free_models
        }
        
        with open(cache_path, 'w', encoding='utf-8') as f:
            json.dump(cache_data, f, indent=2, ensure_ascii=False)
        
        print(f"✓ 已保存模型緩存到：{cache_path}")
        return True
    except Exception as e:
        print(f"保存緩存失敗：{e}")
        return False


def main():
    """主函數"""
    # 檢查是否為靜默模式（不發送 Telegram）
    silent_mode = len(sys.argv) > 1 and sys.argv[1] == '--silent'
    
    print("=" * 60)
    print("OpenRouter 免費模型分析器")
    print("=" * 60)
    
    # 獲取免費模型
    free_models = fetch_free_models()
    
    if free_models is None:
        error_msg = "❌ 無法獲取 OpenRouter 模型列表\n請檢查網路連線"
        print(f"\n{error_msg}")
        if not silent_mode:
            send_telegram_message(error_msg)
        sys.exit(1)
    
    if not free_models:
        error_msg = "❌ 未找到免費模型"
        print(f"\n{error_msg}")
        if not silent_mode:
            send_telegram_message(error_msg)
        sys.exit(1)
    
    # 保存緩存
    save_models_cache(free_models)
    
    # 生成分析報告
    report = analyze_models(free_models)
    print("\n" + report)
    
    # 發送到 Telegram
    if not silent_mode:
        print("\n" + "=" * 60)
        print("正在發送報告到 Telegram...")
        if send_telegram_message(report):
            print("✓ 報告已成功發送到 Telegram")
        else:
            print("✗ 發送 Telegram 訊息失敗")
            print("請檢查 ~/.openclaw/openclaw.json 中的 Telegram 配置")
    else:
        print("\n" + "=" * 60)
        print("靜默模式：未發送 Telegram 訊息")
    
    print("=" * 60)


if __name__ == "__main__":
    main()
