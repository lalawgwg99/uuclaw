#!/usr/bin/env python3
"""
OpenClaw 集中式模型管理工具
提供統一的模型添加、更新、刪除和查詢功能
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime


class ModelManager:
    """OpenClaw 模型管理器"""
    
    def __init__(self, config_path: Optional[str] = None):
        """初始化模型管理器"""
        self.config_path = self._find_config(config_path)
        self.config = self._load_config()
    
    def _find_config(self, config_path: Optional[str]) -> Path:
        """查找配置文件"""
        if config_path:
            path = Path(config_path)
            if path.exists():
                return path
        
        # 嘗試常見位置
        locations = [
            Path.cwd() / "openclaw.json",
            Path.home() / ".openclaw" / "openclaw.json",
        ]
        
        for loc in locations:
            if loc.exists():
                return loc
        
        raise FileNotFoundError(
            "找不到 openclaw.json 配置文件。\n"
            "請確保文件存在於以下位置之一：\n"
            "  - 當前目錄\n"
            "  - ~/.openclaw/openclaw.json\n"
            "或使用 --config 參數指定路徑"
        )
    
    def _load_config(self) -> Dict:
        """載入配置文件"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            raise ValueError(f"配置文件不是有效的 JSON：{e}")
    
    def _save_config(self, backup: bool = True):
        """保存配置文件"""
        if backup:
            self._backup_config()
        
        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
    
    def _backup_config(self):
        """備份配置文件"""
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_path = self.config_path.with_suffix(f'.json.backup-{timestamp}')
        
        with open(self.config_path, 'r') as src:
            with open(backup_path, 'w') as dst:
                dst.write(src.read())
        
        print(f"✓ 已備份配置到：{backup_path}")
        
        # 清理舊備份（保留最近 5 個）
        backup_pattern = f"{self.config_path.stem}.backup-*"
        backups = sorted(
            self.config_path.parent.glob(backup_pattern),
            key=lambda p: p.stat().st_mtime,
            reverse=True
        )
        
        for old_backup in backups[5:]:
            old_backup.unlink()
    
    def add_model(self, provider: str, model_id: str, model_name: str, 
                  context_window: int = 128000, **kwargs) -> bool:
        """添加模型到指定提供者"""
        # 確保結構存在
        if "models" not in self.config:
            self.config["models"] = {}
        if "providers" not in self.config["models"]:
            self.config["models"]["providers"] = {}
        if provider not in self.config["models"]["providers"]:
            self.config["models"]["providers"][provider] = {
                "models": []
            }
        
        provider_config = self.config["models"]["providers"][provider]
        
        # 檢查模型是否已存在
        existing_models = provider_config.get("models", [])
        for existing in existing_models:
            if existing.get("id") == model_id:
                print(f"⚠️  模型已存在：{model_id}")
                return False
        
        # 添加新模型
        new_model = {
            "id": model_id,
            "name": model_name,
            "contextWindow": context_window,
            **kwargs
        }
        
        if "models" not in provider_config:
            provider_config["models"] = []
        
        provider_config["models"].append(new_model)
        self._save_config()
        
        print(f"✓ 已添加模型：{model_name} ({model_id})")
        return True
    
    def remove_model(self, provider: str, model_id: str) -> bool:
        """從指定提供者移除模型"""
        try:
            provider_config = self.config["models"]["providers"][provider]
            models = provider_config.get("models", [])
            
            original_count = len(models)
            provider_config["models"] = [
                m for m in models if m.get("id") != model_id
            ]
            
            if len(provider_config["models"]) < original_count:
                self._save_config()
                print(f"✓ 已移除模型：{model_id}")
                return True
            else:
                print(f"⚠️  未找到模型：{model_id}")
                return False
        except KeyError:
            print(f"❌ 提供者不存在：{provider}")
            return False
    
    def list_models(self, provider: Optional[str] = None) -> List[Dict]:
        """列出模型"""
        try:
            providers = self.config["models"]["providers"]
            
            if provider:
                if provider not in providers:
                    print(f"❌ 提供者不存在：{provider}")
                    return []
                return providers[provider].get("models", [])
            else:
                # 列出所有提供者的模型
                all_models = []
                for prov_name, prov_config in providers.items():
                    models = prov_config.get("models", [])
                    for model in models:
                        model["_provider"] = prov_name
                        all_models.append(model)
                return all_models
        except KeyError:
            return []
    
    def get_current_model(self) -> str:
        """獲取當前使用的模型"""
        try:
            return self.config["agents"]["defaults"]["model"]["primary"]
        except KeyError:
            return "未設置"
    
    def set_current_model(self, model_id: str) -> bool:
        """設置當前使用的模型"""
        # 確保結構存在
        if "agents" not in self.config:
            self.config["agents"] = {}
        if "defaults" not in self.config["agents"]:
            self.config["agents"]["defaults"] = {}
        if "model" not in self.config["agents"]["defaults"]:
            self.config["agents"]["defaults"]["model"] = {}
        
        old_model = self.get_current_model()
        self.config["agents"]["defaults"]["model"]["primary"] = model_id
        self._save_config()
        
        print(f"✓ 模型已切換")
        print(f"  舊模型：{old_model}")
        print(f"  新模型：{model_id}")
        return True


def main():
    """命令行接口"""
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenClaw 模型管理工具")
    parser.add_argument("--config", help="配置文件路徑")
    
    subparsers = parser.add_subparsers(dest="command", help="命令")
    
    # add 命令
    add_parser = subparsers.add_parser("add", help="添加模型")
    add_parser.add_argument("provider", help="提供者名稱")
    add_parser.add_argument("model_id", help="模型 ID")
    add_parser.add_argument("model_name", help="模型名稱")
    add_parser.add_argument("--context", type=int, default=128000, help="上下文窗口大小")
    
    # remove 命令
    remove_parser = subparsers.add_parser("remove", help="移除模型")
    remove_parser.add_argument("provider", help="提供者名稱")
    remove_parser.add_argument("model_id", help="模型 ID")
    
    # list 命令
    list_parser = subparsers.add_parser("list", help="列出模型")
    list_parser.add_argument("--provider", help="指定提供者")
    
    # current 命令
    subparsers.add_parser("current", help="顯示當前模型")
    
    # switch 命令
    switch_parser = subparsers.add_parser("switch", help="切換模型")
    switch_parser.add_argument("model_id", help="模型 ID")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    try:
        manager = ModelManager(args.config)
        
        if args.command == "add":
            manager.add_model(
                args.provider,
                args.model_id,
                args.model_name,
                args.context
            )
        
        elif args.command == "remove":
            manager.remove_model(args.provider, args.model_id)
        
        elif args.command == "list":
            models = manager.list_models(args.provider)
            if models:
                print(f"\n找到 {len(models)} 個模型：\n")
                for i, model in enumerate(models, 1):
                    provider = model.get("_provider", "unknown")
                    print(f"{i}. {model.get('name', 'Unknown')}")
                    print(f"   ID: {model.get('id')}")
                    print(f"   提供者: {provider}")
                    print(f"   上下文: {model.get('contextWindow', 0):,} tokens")
                    print()
            else:
                print("未找到模型")
        
        elif args.command == "current":
            current = manager.get_current_model()
            print(f"當前模型：{current}")
        
        elif args.command == "switch":
            manager.set_current_model(args.model_id)
    
    except Exception as e:
        print(f"❌ 錯誤：{e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
