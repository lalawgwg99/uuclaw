#!/usr/bin/env python3
"""
Telegram 模型控制技能
允許通過 Telegram 命令查看和切換模型
"""

import json
import sys
from pathlib import Path

# 添加父目錄到路徑以導入 model-manager
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent / "lib"))

try:
    from model_manager import ModelManager
except ImportError:
    print("錯誤：無法導入 model_manager")
    print("請確保 lib/model-manager.py 存在")
    sys.exit(1)


def handle_list_models(manager: ModelManager) -> str:
    """處理列出模型命令"""
    models = manager.list_models()
    
    if not models:
        return "❌ 未找到任何模型"
    
    # 按提供者分組
    by_provider = {}
    for model in models:
        provider = model.get("_provider", "unknown")
        if provider not in by_provider:
            by_provider[provider] = []
        by_provider[provider].append(model)
    
    response = f"📋 可用模型列表（共 {len(models)} 個）\n\n"
    
    for provider, prov_models in by_provider.items():
        response += f"🔹 {provider} ({len(prov_models)} 個模型)\n"
        for model in prov_models[:5]:  # 每個提供者最多顯示 5 個
            response += f"  • {model.get('name', 'Unknown')}\n"
            response += f"    ID: {model.get('id')}\n"
            response += f"    上下文: {model.get('contextWindow', 0):,}\n"
        
        if len(prov_models) > 5:
            response += f"  ... 還有 {len(prov_models) - 5} 個模型\n"
        response += "\n"
    
    response += "💡 使用 /switch <model-id> 切換模型"
    return response


def handle_current_model(manager: ModelManager) -> str:
    """處理查看當前模型命令"""
    current = manager.get_current_model()
    
    # 嘗試獲取模型詳情
    all_models = manager.list_models()
    model_info = None
    
    for model in all_models:
        if model.get("id") in current or current.endswith(model.get("id", "")):
            model_info = model
            break
    
    response = "📌 當前模型\n\n"
    response += f"ID: {current}\n"
    
    if model_info:
        response += f"名稱: {model_info.get('name', 'Unknown')}\n"
        response += f"提供者: {model_info.get('_provider', 'unknown')}\n"
        response += f"上下文: {model_info.get('contextWindow', 0):,} tokens\n"
    
    return response


def handle_switch_model(manager: ModelManager, model_id: str) -> str:
    """處理切換模型命令"""
    try:
        # 檢查模型是否存在
        all_models = manager.list_models()
        model_exists = False
        model_info = None
        
        for model in all_models:
            if model.get("id") == model_id or model_id in model.get("id", ""):
                model_exists = True
                model_info = model
                break
        
        if not model_exists:
            return f"❌ 模型不存在：{model_id}\n\n使用 /models 查看可用模型"
        
        # 切換模型
        full_model_id = model_info.get("id")
        provider = model_info.get("_provider", "")
        
        # 構建完整的模型 ID（包含提供者前綴）
        if provider and not full_model_id.startswith(provider):
            full_model_id = f"{provider}/{full_model_id}"
        
        manager.set_current_model(full_model_id)
        
        response = "✅ 模型已切換\n\n"
        response += f"新模型: {model_info.get('name', 'Unknown')}\n"
        response += f"ID: {full_model_id}\n"
        response += f"上下文: {model_info.get('contextWindow', 0):,} tokens\n\n"
        response += "⚠️ 請重啟 OpenClaw 以使更改生效"
        
        return response
    
    except Exception as e:
        return f"❌ 切換失敗：{e}"


def handle_free_models(manager: ModelManager) -> str:
    """處理查看免費模型命令"""
    # 查找 openrouter-free 提供者的模型
    models = manager.list_models("openrouter-free")
    
    if not models:
        return "❌ 未找到免費模型\n\n請先運行免費模型更新器"
    
    # 按上下文長度排序
    models.sort(key=lambda x: x.get("contextWindow", 0), reverse=True)
    
    response = f"🆓 OpenRouter 免費模型（共 {len(models)} 個）\n\n"
    response += "🏆 推薦模型：\n\n"
    
    # 找出編程模型
    coder_models = [m for m in models if 'coder' in m.get('id', '').lower()]
    if coder_models:
        m = coder_models[0]
        response += f"👨‍💻 編程：{m.get('name')}\n"
        response += f"   /switch {m.get('id')}\n\n"
    
    # 找出思考模型
    thinking_models = [m for m in models if 'thinking' in m.get('id', '').lower() or 'r1' in m.get('id', '').lower()]
    if thinking_models:
        m = thinking_models[0]
        response += f"🧠 思考：{m.get('name')}\n"
        response += f"   /switch {m.get('id')}\n\n"
    
    # 最大上下文
    if models:
        m = models[0]
        response += f"📄 大上下文：{m.get('name')}\n"
        response += f"   {m.get('contextWindow', 0):,} tokens\n"
        response += f"   /switch {m.get('id')}\n\n"
    
    response += f"使用 /models 查看完整列表"
    
    return response


def main():
    """主函數"""
    if len(sys.argv) < 2:
        print("用法：python3 skill.py <command> [args]")
        print("命令：")
        print("  models - 列出所有模型")
        print("  current - 顯示當前模型")
        print("  switch <model-id> - 切換模型")
        print("  free - 顯示免費模型")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        manager = ModelManager()
        
        if command == "models":
            print(handle_list_models(manager))
        
        elif command == "current":
            print(handle_current_model(manager))
        
        elif command == "switch":
            if len(sys.argv) < 3:
                print("❌ 請提供模型 ID")
                sys.exit(1)
            model_id = sys.argv[2]
            print(handle_switch_model(manager, model_id))
        
        elif command == "free":
            print(handle_free_models(manager))
        
        else:
            print(f"❌ 未知命令：{command}")
            sys.exit(1)
    
    except Exception as e:
        print(f"❌ 錯誤：{e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
