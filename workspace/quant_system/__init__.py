"""
UUZero Quant System - 完整量化交易系統
整合 8 大模組：時序預測、均值回歸、情緒分析、組合格化、VaR風控、期權定價、多因子模型、RL交易代理

Author: UUZero
Framework: MiniMax M2.5 + DeepSeek R1
"""

from .data_fetcher import DataFetcher
from .time_series import TimeSeriesPredictor
from .mean_reversion import MeanReversionStrategy
from .sentiment import SentimentAnalyzer
from .portfolio import PortfolioOptimizer
from .var_model import VaRCalculator
from .options import OptionsPricer
from .multi_factor import MultiFactorModel
from .rl_agent import RLTradingAgent
from .risk_manager import RiskManager
from .signal_aggregator import SignalAggregator

__version__ = "1.0.0"
__all__ = [
    "DataFetcher",
    "TimeSeriesPredictor", 
    "MeanReversionStrategy",
    "SentimentAnalyzer",
    "PortfolioOptimizer",
    "VaRCalculator",
    "OptionsPricer",
    "MultiFactorModel",
    "RLTradingAgent",
    "RiskManager",
    "SignalAggregator"
]
