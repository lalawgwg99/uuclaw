#!/usr/bin/env python3
"""
UUZero 量化系統 - 主程序

使用方法:
    python main.py [symbols...]

示例:
    python main.py AAPL MSFT GOOGL
    python main.py BTC-USD ETH-USD
"""

import sys
import json
from quant_system import run_quant_system, SignalAggregator


def main():
    # 默認股票
    default_symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]
    
    # 獲取命令行參數
    if len(sys.argv) > 1:
        symbols = sys.argv[1:]
    else:
        symbols = default_symbols
    
    print("=" * 60)
    print("UUZero 量化交易系統")
    print("=" * 60)
    print(f"分析標的: {', '.join(symbols)}")
    print("-" * 60)
    
    # 運行系統
    try:
        result = run_quant_system(symbols)
        
        # 打印結果
        print("\n📊 交易建議:")
        print("-" * 40)
        
        for rec in result["recommendations"]:
            emoji = "🟢" if rec["action"] == "BUY" else "🔴" if rec["action"] == "SELL" else "⚪"
            print(f"{emoji} {rec['symbol']}: {rec['action']} (信心度: {rec['confidence']:.0%})")
            if rec["reasons"]:
                print(f"   依據: {', '.join(rec['reasons'])}")
        
        # 風險報告
        print("\n⚠️ 風險指標:")
        print("-" * 40)
        
        risk = result.get("risk_metrics", {})
        if "var_95_pct" in risk:
            print(f"VaR (95%): {risk.get('var_95_pct', 0):.2%}")
        
        if risk.get("recommendations"):
            print("建議:")
            for rec in risk["recommendations"]:
                print(f"  • {rec}")
        
        print("\n" + "=" * 60)
        print(f"生成時間: {result['timestamp']}")
        
    except Exception as e:
        print(f"❌ 錯誤: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
