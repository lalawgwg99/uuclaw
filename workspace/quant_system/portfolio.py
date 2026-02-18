"""
投資組合格化模組
支持：現代投資組合理論 (MPT)、Black-Litterman、風險平價
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
from scipy.optimize import minimize
import logging

logger = logging.getLogger(__name__)

try:
    from sklearn.covariance import LedoitWolf
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False


class PortfolioOptimizer:
    """
    投資組合優化器
    """
    
    def __init__(
        self,
        risk_free_rate: float = 0.02,
        optimization_method: str = "max_sharpe"
    ):
        """
        Args:
            risk_free_rate: 無風險利率
            optimization_method: "max_sharpe", "min_volatility", "max_return", "risk_parity"
        """
        self.risk_free_rate = risk_free_rate
        self.optimization_method = optimization_method
        self.weights = None
        self.returns = None
        self.covariance = None
    
    def fit(
        self,
        returns: pd.DataFrame,
        constraints: Optional[Dict] = None
    ) -> np.ndarray:
        """
        擬合最優權重
        
        Args:
            returns: 資產收益率 DataFrame
        
        Returns:
            最優權重數組
        """
        self.returns = returns
        n_assets = len(returns.columns)
        
        # 估計協方差矩陣
        self.covariance = returns.cov()
        
        # 初始化權重
        init_weights = np.array([1.0 / n_assets] * n_assets)
        
        # 約束條件
        constraints = constraints or {}
        bounds = tuple(
            (constraints.get("min_weight", 0), constraints.get("max_weight", 1))
            for _ in range(n_assets)
        )
        
        if constraints.get("long_only", True):
            bounds = tuple((0, 1) for _ in range(n_assets))
        
        # 優化目標
        if self.optimization_method == "max_sharpe":
            objective = self._sharpe_ratio
        elif self.optimization_method == "min_volatility":
            objective = self._portfolio_volatility
        elif self.optimization_method == "max_return":
            objective = lambda w: -self._portfolio_return(w)
        elif self.optimization_method == "risk_parity":
            objective = self._risk_parity_objective
        else:
            objective = self._sharpe_ratio
        
        # 優化
        result = minimize(
            objective,
            init_weights,
            method="SLSQP",
            bounds=bounds,
            constraints={"type": "eq", "fun": lambda w: np.sum(w) - 1}
        )
        
        self.weights = result.x
        return self.weights
    
    def _portfolio_return(self, weights: np.ndarray) -> float:
        """計算組合預期收益"""
        return np.dot(weights, self.returns.mean() * 252)
    
    def _portfolio_volatility(self, weights: np.ndarray) -> float:
        """計算組合波動率"""
        return np.sqrt(
            np.dot(weights, np.dot(self.covariance * 252, weights))
        )
    
    def _sharpe_ratio(self, weights: np.ndarray) -> float:
        """夏普比率（負值，用於最小化）"""
        p_return = self._portfolio_return(weights)
        p_vol = self._portfolio_volatility(weights)
        
        if p_vol == 0:
            return 0
        
        sharpe = (p_return - self.risk_free_rate) / p_vol
        return -sharpe  # 最小化負值 = 最大化夏普
    
    def _risk_parity_objective(self, weights: np.ndarray) -> float:
        """風險平價目標"""
        port_vol = self._portfolio_volatility(weights)
        marginal_contrib = np.dot(self.covariance * 252, weights)
        risk_contrib = weights * marginal_contrib / port_vol
        
        target_risk = port_vol / len(weights)
        
        return np.sum((risk_contrib - target_risk) ** 2)
    
    def get_portfolio_metrics(self) -> Dict:
        """計算組合指標"""
        if self.weights is None:
            raise ValueError("Must fit model first")
        
        ret = self._portfolio_return(self.weights)
        vol = self._portfolio_volatility(self.weights)
        sharpe = (ret - self.risk_free_rate) / vol if vol > 0 else 0
        
        return {
            "expected_return": ret,
            "volatility": vol,
            "sharpe_ratio": sharpe,
            "weights": dict(zip(self.returns.columns, self.weights))
        }
    
    def efficient_frontier(
        self,
        n_points: int = 50
    ) -> Tuple[np.ndarray, np.ndarray]:
        """計算有效前沿"""
        returns_range = np.linspace(
            self.returns.mean().min() * 252,
            self.returns.mean().max() * 252,
            n_points
        )
        
        frontier_vols = []
        frontier_rets = []
        
        for target_ret in returns_range:
            result = minimize(
                self._portfolio_volatility,
                np.ones(len(self.returns.columns)) / len(self.returns.columns),
                method="SLSQP",
                bounds=tuple((0, 1) for _ in self.returns.columns),
                constraints=[
                    {"type": "eq", "fun": lambda w: np.sum(w) - 1},
                    {"type": "eq", "fun": lambda w: self._portfolio_return(w) - target_ret}
                ]
            )
            
            if result.success:
                frontier_vols.append(result.fun)
                frontier_rets.append(target_ret)
        
        return np.array(frontier_vols), np.array(frontier_rets)


class BlackLitterman:
    """
    Black-Litterman 模型
    結合市場均衡收益與投資者觀點
    """
    
    def __init__(
        self,
        market_caps: np.ndarray,
        risk_aversion: float = 2.5
    ):
        """
        Args:
            market_caps: 市值數組
            risk_aversion: 風險厭惡系數
        """
        self.market_caps = market_caps
        self.risk_aversion = risk_aversion
        self.weights = None
    
    def calculate_implied_returns(
        self,
        covariance: np.ndarray
    ) -> np.ndarray:
        """
        計算隱含市場收益率
        
        Args:
            covariance: 協方差矩陣
        
        Returns:
            隱含收益率
        """
        # 市場權重（市值加權）
        self.weights = self.market_caps / self.market_caps.sum()
        
        # Black-Litterman 公式
        implied_returns = self.risk_aversion * np.dot(covariance, self.weights)
        
        return implied_returns
    
    def blend_with_views(
        self,
        implied_returns: np.ndarray,
        views: np.ndarray,
        view_confidences: np.ndarray,
        covariance: np.ndarray,
        tau: float = 0.05
    ) -> np.ndarray:
        """
        混合觀點與市場均衡
        
        Args:
            implied_returns: 隱含收益率
            views: 投資者觀點收益率
            view_confidences: 觀點置信度 (0-1)
            tau: 不確定性參數
        
        Returns:
            調整後的收益率
        """
        n = len(implied_returns)
        
        # 觀點矩陣
        P = np.eye(n)
        
        # 觀點方差
        Omega = np.diag(tau * np.diag(np.dot(np.dot(P, covariance), P.T)))
        
        # 混合
        mkt_prior = implied_returns
        posterior = np.linalg.solve(
            np.linalg.inv(tau * covariance) + np.dot(P.T, np.linalg.inv(Omega), P),
            np.dot(np.linalg.inv(tau * covariance), mkt_prior) + 
            np.dot(P.T, np.linalg.inv(Omega), views)
        )
        
        return posterior


class RiskParity:
    """風險平價策略"""
    
    def __init__(self):
        self.weights = None
    
    def fit(self, returns: pd.DataFrame) -> np.ndarray:
        """擬合風險平價權重"""
        cov = returns.cov() * 252
        
        def risk_parity_objective(w, cov):
            vol = np.sqrt(np.dot(w, np.dot(cov, w)))
            risk_contrib = w * np.dot(cov, w) / vol
            target = vol / len(w)
            return np.sum((risk_contrib - target) ** 2)
        
        n = len(returns.columns)
        init = np.ones(n) / n
        
        result = minimize(
            risk_parity_objective,
            init,
            args=(cov,),
            method="SLSQP",
            bounds=tuple((0, 1) for _ in range(n)),
            constraints={"type": "eq", "fun": lambda w: np.sum(w) - 1}
        )
        
 = result.x
        self.weights        return self.weights


class MeanVarianceCVaR:
    """均值-CVaR 優化"""
    
    def __init__(self, cvar_alpha: float = 0.95):
        """
        Args:
            cvar_alpha: 置信水平
        """
        self.cvar_alpha = cvar_alpha
        self.weights = None
    
    def _cvar(self, weights: np.ndarray, returns: np.ndarray) -> float:
        """計算 CVaR"""
        port_returns = returns @ weights
        var_threshold = np.percentile(port_returns, (1 - self.cvar_alpha) * 100)
        cvar = -np.mean(port_returns[port_returns <= var_threshold])
        return cvar
    
    def fit(
        self,
        returns: pd.DataFrame,
        target_return: Optional[float] = None
    ) -> np.ndarray:
        """擬合"""
        n = len(returns.columns)
        ret_array = returns.values
        
        init = np.ones(n) / n
        
        constraints = [{"type": "eq", "fun": lambda w: np.sum(w) - 1}]
        
        if target_return is not None:
            constraints.append({
                "type": "eq",
                "fun": lambda w: returns.mean() @ w - target_return
            })
        
        result = minimize(
            lambda w: self._cvar(w, ret_array),
            init,
            method="SLSQP",
            bounds=tuple((0, 1) for _ in range(n)),
            constraints=constraints
        )
        
        self.weights = result.x
        return self.weights


# 便捷函數
def optimize_portfolio(
    prices: pd.DataFrame,
    method: str = "max_sharpe"
) -> Dict:
    """
    便捷函數：優化投資組合
    
    Example:
        >>> result = optimize_portfolio(price_data, "max_sharpe")
    """
    # 計算收益率
    returns = prices.pct_change().dropna()
    
    # 優化
    optimizer = PortfolioOptimizer(optimization_method=method)
    weights = optimizer.fit(returns)
    
    metrics = optimizer.get_portfolio_metrics()
    
    return metrics
