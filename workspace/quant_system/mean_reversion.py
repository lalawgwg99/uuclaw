"""
均值回歸策略模組
支持：Z-Score 策略、配對交易、Bollinger Bands
"""

import numpy as np
import pandas as pd
from typing import Tuple, Dict, List, Optional
from scipy import stats
import logging

logger = logging.getLogger(__name__)

try:
    from sklearn.linear_model import LinearRegression, Ridge
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False


class MeanReversionStrategy:
    """
    均值回歸交易策略
    
    核心思想：價格偏離均值後會回歸
    """
    
    def __init__(
        self,
        lookback_period: int = 60,
        entry_threshold: float = 2.0,
        exit_threshold: float = 0.5,
        holding_period: int = 20
    ):
        """
        Args:
            lookback_period: 計算均值的回顧期
            entry_threshold: 進場閾值（標準差倍數）
            exit_threshold: 出場閾值
            holding_period: 最大持倉天數
        """
        self.lookback_period = lookback_period
        self.entry_threshold = entry_threshold
        self.exit_threshold = exit_threshold
        self.holding_period = holding_period
        
        self.mean = None
        self.std = None
        self.signals = None
    
    def fit(self, prices: pd.Series):
        """根據歷史數據擬合模型參數"""
        self.mean = prices.rolling(window=self.lookback_period).mean()
        self.std = prices.rolling(window=self.lookback_period).std()
        logger.info(f"Fitted Mean Reversion model: lookback={self.lookback_period}")
    
    def calculate_z_score(self, prices: pd.Series) -> pd.Series:
        """計算 Z-Score"""
        if self.mean is None:
            self.fit(prices)
        
        z_score = (prices - self.mean) / self.std
        return z_score
    
    def generate_signals(self, prices: pd.Series) -> pd.DataFrame:
        """
        生成交易信號
        
        Returns:
            DataFrame with columns: signal, z_score, position
            signal: 1 (long), -1 (short), 0 (neutral)
        """
        z_scores = self.calculate_z_score(prices)
        
        signals = pd.DataFrame(index=prices.index)
        signals["price"] = prices
        signals["z_score"] = z_scores
        signals["mean"] = self.mean
        signals["upper_band"] = self.mean + self.entry_threshold * self.std
        signals["lower_band"] = self.mean - self.entry_threshold * self.std
        
        # 初始信號
        signals["signal"] = 0
        
        # 進場邏輯
        signals.loc[z_scores < -self.entry_threshold, "signal"] = 1   # 價格太低，做多
        signals.loc[z_scores > self.entry_threshold, "signal"] = -1  # 價格太高，做空
        
        # 出場邏輯
        signals.loc[abs(z_scores) < self.exit_threshold, "signal"] = 0
        
        self.signals = signals
        return signals
    
    def backtest(
        self, 
        prices: pd.Series, 
        initial_capital: float = 100000
    ) -> Dict:
        """
        回測策略
        
        Returns:
            回測結果字典
        """
        signals = self.generate_signals(prices)
        signals["returns"] = prices.pct_change()
        signals["strategy_returns"] = signals["signal"].shift(1) * signals["returns"]
        
        # 計算累積收益
        signals["cumulative_returns"] = (1 + signals["returns"]).cumprod()
        signals["strategy_cumulative"] = (1 + signals["strategy_returns"]).cumprod()
        
        # 計算持倉
        signals["position"] = signals["signal"].shift(1).fillna(0)
        
        # 績效指標
        total_return = signals["strategy_cumulative"].iloc[-1] - 1
        annual_return = (1 + total_return) ** (252 / len(prices)) - 1
        volatility = signals["strategy_returns"].std() * np.sqrt(252)
        sharpe = annual_return / volatility if volatility > 0 else 0
        
        # 最大回撤
        rolling_max = signals["strategy_cumulative"].cummax()
        drawdown = (signals["strategy_cumulative"] - rolling_max) / rolling_max
        max_drawdown = drawdown.min()
        
        # 交易次數
        trades = (signals["signal"].diff() != 0).sum()
        
        return {
            "total_return": total_return,
            "annual_return": annual_return,
            "volatility": volatility,
            "sharpe_ratio": sharpe,
            "max_drawdown": max_drawdown,
            "total_trades": trades,
            "win_rate": (signals["strategy_returns"] > 0).mean(),
            "signals": signals
        }


class PairsTradingStrategy:
    """
    配對交易策略
    找到兩個高度相關的資產，做多被低估的，做空被高估的
    """
    
    def __init__(
        self,
        hedge_ratio_lookback: int = 60,
        entry_threshold: float = 2.0,
        exit_threshold: float = 0.0
    ):
        self.hedge_ratio_lookback = hedge_ratio_lookback
        self.entry_threshold = entry_threshold
        self.exit_threshold = exit_threshold
        self.hedge_ratio = None
        
    def find_cointegration(
        self, 
        price1: pd.Series, 
        price2: pd.Series
    ) -> Dict:
        """
        協整檢驗
        
        Returns:
            cointegration stats
        """
        from statsmodels.tsa.stattools import coint
        
        score, pvalue, _ = coint(price1, price2)
        
        return {
            "cointegration_score": score,
            "p_value": pvalue,
            "is_cointegrated": pvalue < 0.05
        }
    
    def calculate_hedge_ratio(
        self, 
        price1: pd.Series, 
        price2: pd.Series
    ) -> pd.Series:
        """計算對沖比率（滾動）"""
        if not HAS_SKLEARN:
            # 簡單比率
            return price1 / price2
        
        # 使用線性回歸
        hedge_ratios = pd.Series(index=price1.index)
        
        for i in range(self.hedge_ratio_lookback, len(price1)):
            y = price1.iloc[i-self.hedge_ratio_lookback:i]
            x = price2.iloc[i-self.hedge_ratio_lookback:i]
            
            model = Ridge(alpha=1.0)
            model.fit(x.values.reshape(-1, 1), y.values)
            hedge_ratios.iloc[i] = model.coef_[0]
        
        return hedge_ratios.fillna(method="bfill")
    
    def generate_signals(
        self, 
        price1: pd.Series, 
        price2: pd.Series
    ) -> pd.DataFrame:
        """生成配對交易信號"""
        # 計算對沖比率
        self.hedge_ratio = self.calculate_hedge_ratio(price1, price2)
        
        # 計算價差（Spread）
        spread = price1 - self.hedge_ratio * price2
        
        # Z-Score
        spread_mean = spread.rolling(window=self.hedge_ratio_lookback).mean()
        spread_std = spread.rolling(window=self.hedge_ratio_lookback).std()
        z_score = (spread - spread_mean) / spread_std
        
        signals = pd.DataFrame(index=price1.index)
        signals["price1"] = price1
        signals["price2"] = price2
        signals["spread"] = spread
        signals["z_score"] = z_score
        
        # 進場信號
        signals["signal"] = 0
        signals.loc[z_score > self.entry_threshold, "signal"] = -1  # 價差太高，做空
        signals.loc[z_score < -self.entry_threshold, "signal"] = 1   # 價差太低，做多
        
        # 出場
        signals.loc[abs(z_score) < self.exit_threshold, "signal"] = 0
        
        return signals
    
    def backtest(
        self,
        price1: pd.Series,
        price2: pd.Series,
        initial_capital: float = 100000
    ) -> Dict:
        """配對交易回測"""
        signals = self.generate_signals(price1, price2)
        
        # 計算收益
        ret1 = price1.pct_change()
        ret2 = price2.pct_change()
        
        # 組合收益（考慮對沖）
        position = signals["signal"].shift(1).fillna(0)
        hedge = self.hedge_ratio.shift(1).fillna(1)
        
        # 資產1 收益 + 資產2 對沖收益
        strategy_returns = position * ret1 - position * hedge * ret2
        
        signals["strategy_returns"] = strategy_returns
        signals["cumulative"] = (1 + strategy_returns).cumprod()
        
        total_return = signals["cumulative"].iloc[-1] - 1
        
        return {
            "total_return": total_return,
            "cointegration": self.find_cointegration(price1, price2),
            "signals": signals
        }


class BollingerBandsStrategy:
    """布林帶策略"""
    
    def __init__(
        self,
        window: int = 20,
        num_std: float = 2.0
    ):
        self.window = window
        self.num_std = num_std
    
    def generate_signals(self, prices: pd.Series) -> pd.DataFrame:
        """生成信號"""
        ma = prices.rolling(window=self.window).mean()
        std = prices.rolling(window=self.window).std()
        
        upper = ma + self.num_std * std
        lower = ma - self.num_std * std
        
        signals = pd.DataFrame(index=prices.index)
        signals["price"] = prices
        signals["ma"] = ma
        signals["upper"] = upper
        signals["lower"] = lower
        
        # 信號
        signals["signal"] = 0
        signals.loc[prices < lower, "signal"] = 1   # 超賣，做多
        signals.loc[prices > upper, "signal"] = -1  # 超買，做空
        signals.loc[(prices > ma) & (signals["signal"].shift(1) == 1), "signal"] = 0  # 回到均線，平倉
        
        return signals


# 便捷函數
def run_mean_reversion(
    symbol: str,
    strategy: str = "zscore",
    **kwargs
) -> Dict:
    """
    運行均值回歸策略
    
    Example:
        >>> result = run_mean_reversion("AAPL", strategy="zscore")
    """
    from .data_fetcher import DataFetcher
    from datetime import timedelta
    
    fetcher = DataFetcher()
    data = fetcher.get_price_data(
        [symbol],
        start_date=(pd.Timestamp.now() - timedelta(days=365)).strftime("%Y-%m-%d")
    )
    
    if symbol not in data:
        return {"error": f"No data for {symbol}"}
    
    prices = data[symbol]["Close"].dropna()
    
    if strategy == "zscore":
        model = MeanReversionStrategy(**kwargs)
    elif strategy == "bollinger":
        model = BollingerBandsStrategy(**kwargs)
    else:
        model = MeanReversionStrategy(**kwargs)
    
    result = model.backtest(prices)
    
    return {
        "symbol": symbol,
        "strategy": strategy,
        "total_return": result["total_return"],
        "sharpe_ratio": result["sharpe_ratio"],
        "max_drawdown": result["max_drawdown"],
        "total_trades": result["total_trades"]
    }
