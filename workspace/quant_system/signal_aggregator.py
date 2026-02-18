"""
信號聚合模組 - 整合 8 大量化模組
這是 UUZero 量化系統的核心
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class SignalAggregator:
    """
    信號聚合器
    
    整合所有 8 個模組的信號：
    1. 時序預測 (TimeSeries)
    2. 均值回歸 (MeanReversion)
    3. 情緒分析 (Sentiment)
    4. 組合格化 (Portfolio)
    5. VaR 風控 (Risk)
    6. 期權定價 (Options)
    7. 多因子模型 (MultiFactor)
    8. RL 交易代理 (RLAgent)
    """
    
    def __init__(
        self,
        symbols: List[str],
        weights: Optional[Dict[str, float]] = None
    ):
        """
        Args:
            symbols: 股票代碼列表
            weights: 各模組權重
        """
        self.symbols = symbols
        
        # 默認權重
        self.weights = weights or {
            "time_series": 0.15,
            "mean_reversion": 0.10,
            "sentiment": 0.10,
            "portfolio": 0.15,
            "multi_factor": 0.15,
            "rl_agent": 0.15,
            "options": 0.10,
            "var": 0.10  # 風控，不直接產生信號
        }
        
        # 存儲各模組結果
        self.signals = {}
        self.risk_metrics = {}
        
        # 初始化子模組
        self._init_modules()
    
    def _init_modules(self):
        """初始化子模組"""
        # 延遲導入，避免循環依賴
        from .data_fetcher import DataFetcher
        from .time_series import TimeSeriesPredictor
        from .mean_reversion import MeanReversionStrategy
        from .sentiment import SentimentAnalyzer
        from .portfolio import PortfolioOptimizer
        from .var_model import RiskManager
        from .multi_factor import MultiFactorModel
        from .rl_agent import RLTradingAgent, TradingEnvironment
        
        self.data_fetcher = DataFetcher()
        self.time_series = TimeSeriesPredictor()
        self.mean_reversion = MeanReversionStrategy()
        self.sentiment = SentimentAnalyzer()
        self.portfolio = PortfolioOptimizer()
        self.risk_manager = RiskManager()
        self.multi_factor = MultiFactorModel()
        self.rl_agent = None  # 稍後訓練
    
    def fetch_data(self, period: str = "1y") -> Dict:
        """獲取市場數據"""
        logger.info(f"Fetching data for {self.symbols}")
        
        self.price_data = self.data_fetcher.get_price_data(
            self.symbols,
            start_date=(datetime.now() - pd.Timedelta(days={
                "1mo": 30, "3mo": 90, "6mo": 180, "1y": 365, "2y": 730
            }.get(period, 365))).strftime("%Y-%m-%d")
        )
        
        # 合併為單一 DataFrame
        self.returns = pd.DataFrame({
            symbol: data["Close"].pct_change().dropna()
            for symbol, data in self.price_data.items()
            if len(data) > 0
        })
        
        return self.price_data
    
    def run_time_series(self) -> Dict:
        """運行時序預測"""
        logger.info("Running Time Series Analysis")
        
        signals = {}
        
        for symbol in self.symbols:
            if symbol in self.price_data and len(self.price_data[symbol]) > 0:
                prices = self.price_data[symbol]["Close"].dropna()
                
                # 訓練預測模型
                predictor = TimeSeriesPredictor(model_type="arima")
                predictor.fit(prices)
                
                # 預測未來
                predictions = predictor.predict(prices, steps=5)
                
                # 信號：根據預測方向
                if predictions[-1] > prices.iloc[-1]:
                    signal = 1  # 上漲
                elif predictions[-1] < prices.iloc[-1]:
                    signal = -1  # 下跌
                else:
                    signal = 0
                
                signals[symbol] = {
                    "signal": signal,
                    "prediction": predictions[-1],
                    "current_price": prices.iloc[-1],
                    "confidence": "medium"
                }
        
        self.signals["time_series"] = signals
        return signals
    
    def run_mean_reversion(self) -> Dict:
        """運行均值回歸"""
        logger.info("Running Mean Reversion")
        
        signals = {}
        
        for symbol in self.symbols:
            if symbol in self.returns.columns:
                returns = self.returns[symbol].dropna()
                
                strategy = MeanReversionStrategy()
                result = strategy.backtest(returns)
                
                # 最後一個信號
                last_signal = result["signals"]["signal"].iloc[-1]
                
                signals[symbol] = {
                    "signal": int(last_signal),
                    "z_score": result["signals"]["z_score"].iloc[-1]
                }
        
        self.signals["mean_reversion"] = signals
        return signals
    
    def run_sentiment(self) -> Dict:
        """運行情緒分析"""
        logger.info("Running Sentiment Analysis")
        
        signals = {}
        
        for symbol in self.symbols:
            news = self.data_fetcher.get_news_sentiment([symbol], days=7)
            
            if symbol in news and news[symbol]:
                result = self.sentiment.analyze_news(news[symbol])
                
                # 轉換為交易信號
                score = result.get("score", 0)
                
                if score > 0.3:
                    signal = 1
                elif score < -0.3:
                    signal = -1
                else:
                    signal = 0
                
                signals[symbol] = {
                    "signal": signal,
                    "sentiment_score": score,
                    "sentiment": result.get("sentiment", "neutral")
                }
            else:
                signals[symbol] = {"signal": 0, "sentiment": "neutral"}
        
        self.signals["sentiment"] = signals
        return signals
    
    def run_portfolio_optimization(self) -> Dict:
        """運行組合格化"""
        logger.info("Running Portfolio Optimization")
        
        if len(self.returns.columns) < 2:
            return {"weights": {symbol: 1/len(self.symbols) for symbol in self.symbols}}
        
        # 優化
        self.portfolio.fit(self.returns)
        metrics = self.portfolio.get_portfolio_metrics()
        
        weights = metrics.get("weights", {})
        
        # 轉換為信號（權重 > 平均權重則買入）
        avg_weight = 1 / len(self.symbols)
        
        signals = {}
        for symbol, weight in weights.items():
            if weight > avg_weight * 1.5:
                signal = 1
            elif weight < avg_weight * 0.5:
                signal = -1
            else:
                signal = 0
            
            signals[symbol] = {
                "signal": signal,
                "weight": weight
            }
        
        self.signals["portfolio"] = signals
        return signals
    
    def run_multi_factor(self) -> Dict:
        """運行多因子模型"""
        logger.info("Running Multi-Factor Model")
        
        results = self.multi_factor.fit(self.returns)
        
        signals = {}
        
        for symbol, data in results.items():
            # Alpha 為正則買入
            alpha = data.get("alpha", 0)
            mkt_beta = data.get("betas", {}).get("mkt", 1)
            
            if alpha > 0 and mkt_beta > 0:
                signal = 1
            elif alpha < 0 and mkt_beta < 0:
                signal = -1
            else:
                signal = 0
            
            signals[symbol] = {
                "signal": signal,
                "alpha": alpha,
                "r_squared": data.get("r_squared", 0)
            }
        
        self.signals["multi_factor"] = signals
        return signals
    
    def run_rl_agent(self) -> Dict:
        """運行 RL 代理"""
        logger.info("Running RL Trading Agent")
        
        signals = {}
        
        for symbol in self.symbols:
            if symbol in self.price_data and len(self.price_data[symbol]) > 30:
                prices = self.price_data[symbol]
                
                # 創建環境
                env = TradingEnvironment(prices, initial_balance=100000)
                
                # 訓練代理（快速版本）
                agent = RLTradingAgent(state_size=5, action_size=3)
                agent.train(env, episodes=10)
                
                # 獲取當前動作
                state = env.reset()
                action = agent.act(state, training=False)
                
                # 轉換為信號
                signal_map = {0: 0, 1: 1, 2: -1}  # Hold, Buy, Sell
                
                signals[symbol] = {
                    "signal": signal_map.get(action, 0),
                    "action": action
                }
        
        self.signals["rl_agent"] = signals
        return signals
    
    def calculate_risk(self) -> Dict:
        """計算風險指標"""
        logger.info("Calculating Risk Metrics")
        
        if len(self.returns.columns) == 0:
            return {}
        
        # 使用最优权重
        if "portfolio" in self.signals:
            weights_dict = self.signals["portfolio"]
            weights = np.array([
                weights_dict.get(s, {}).get("weight", 1/len(self.symbols))
                for s in self.symbols
            ])
            weights = weights / weights.sum()  # 标准化
        else:
            weights = np.ones(len(self.symbols)) / len(self.symbols)
        
        risk_report = self.risk_manager.generate_risk_report(
            self.returns,
            weights,
            portfolio_value=1000000
        )
        
        self.risk_metrics = risk_report
        return risk_report
    
    def aggregate_signals(self) -> Dict[str, int]:
        """
        聚合所有信號
        
        Returns:
            最終交易信號 {symbol: signal}
        """
        logger.info("Aggregating all signals")
        
        final_signals = {}
        
        for symbol in self.symbols:
            weighted_sum = 0
            total_weight = 0
            
            for module_name, weight in self.weights.items():
                if module_name == "var":
                    continue  # 風控不產生信號
                
                if module_name in self.signals:
                    module_signals = self.signals[module_name]
                    
                    if symbol in module_signals:
                        signal = module_signals[symbol].get("signal", 0)
                        weighted_sum += signal * weight
                        total_weight += weight
            
            # 歸一化
            if total_weight > 0:
                normalized = weighted_sum / total_weight
            else:
                normalized = 0
            
            # 轉換為最終信號
            if normalized > 0.2:
                final_signals[symbol] = 1  # 買入
            elif normalized < -0.2:
                final_signals[symbol] = -1  # 賣出
            else:
                final_signals[symbol] = 0  # 持有
        
        self.final_signals = final_signals
        return final_signals
    
    def run_all(self) -> Dict:
        """運行所有模組並聚合"""
        # 1. 獲取數據
        self.fetch_data()
        
        # 2. 運行各模組
        self.run_time_series()
        self.run_mean_reversion()
        self.run_sentiment()
        self.run_portfolio_optimization()
        self.run_multi_factor()
        self.run_rl_agent()
        
        # 3. 計算風險
        self.calculate_risk()
        
        # 4. 聚合信號
        final_signals = self.aggregate_signals()
        
        return {
            "signals": final_signals,
            "module_signals": self.signals,
            "risk_metrics": self.risk_metrics,
            "timestamp": datetime.now().isoformat()
        }
    
    def get_recommendation(self) -> Dict:
        """獲取交易建議"""
        if not hasattr(self, "final_signals"):
            self.run_all()
        
        recommendations = []
        
        for symbol, signal in self.final_signals.items():
            if signal == 1:
                action = "BUY"
            elif signal == -1:
                action = "SELL"
            else:
                action = "HOLD"
            
            # 收集依據
            reasons = []
            
            for module, module_signals in self.signals.items():
                if symbol in module_signals:
                    s = module_signals[symbol].get("signal", 0)
                    if s == signal or (s != 0 and signal != 0):
                        reasons.append(module)
            
            recommendations.append({
                "symbol": symbol,
                "action": action,
                "confidence": len(reasons) / len(self.weights),
                "reasons": reasons
            })
        
        return {
            "recommendations": recommendations,
            "risk_metrics": self.risk_metrics,
            "timestamp": datetime.now().isoformat()
        }


# 便捷函數
def run_quant_system(symbols: List[str]) -> Dict:
    """
    便捷函數：運行完整量化系統
    
    Example:
        >>> result = run_quant_system(["AAPL", "MSFT", "GOOGL"])
    """
    aggregator = SignalAggregator(symbols)
    result = aggregator.get_recommendation()
    return result
