"""
VaR 風險管理模組
支持：Historical VaR, Parametric VaR, Monte Carlo VaR, CVaR, Expected Shortfall
"""

import numpy as np
import pandas as pd
from typing import Dict, Optional, Tuple
from scipy import stats
import logging

logger = logging.getLogger(__name__)


class VaRCalculator:
    """
    Value at Risk 計算器
    """
    
    def __init__(
        self,
        confidence_level: float = 0.95,
        time_horizon: int = 1
    ):
        """
        Args:
            confidence_level: 置信度 (0.95 = 95%)
            time_horizon: 時間範圍（天）
        """
        self.confidence_level = confidence_level
        self.time_horizon = time_horizon
    
    def historical_var(
        self,
        returns: pd.Series,
        portfolio_value: float = 1.0
    ) -> float:
        """
        歷史 VaR
        
        基於歷史收益率分佈
        """
        # 調整時間範圍
        if self.time_horizon > 1:
            returns = returns * np.sqrt(self.time_horizon)
        
        # 計算 VaR
        var = np.percentile(returns, (1 - self.confidence_level) * 100)
        
        return abs(var) * portfolio_value
    
    def parametric_var(
        self,
        returns: pd.Series,
        portfolio_value: float = 1.0,
        method: str = "normal"
    ) -> float:
        """
        參數 VaR
        
        Args:
            method: "normal", "t", "skew_normal"
        """
        mu = returns.mean()
        sigma = returns.std()
        
        if method == "normal":
            z = stats.norm.ppf(1 - self.confidence_level)
        elif method == "t":
            # t 分佈
            df, loc, scale = stats.t.fit(returns)
            z = stats.t.ppf(1 - self.confidence_level, df, loc, scale)
        else:
            z = stats.norm.ppf(1 - self.confidence_level)
        
        if self.time_horizon > 1:
            mu = mu * self.time_horizon
            sigma = sigma * np.sqrt(self.time_horizon)
        
        var = -(mu + z * sigma)
        
        return var * portfolio_value
    
    def monte_carlo_var(
        self,
        returns: pd.Series,
        portfolio_value: float = 1.0,
        n_simulations: int = 10000
    ) -> float:
        """
        Monte Carlo VaR
        """
        mu = returns.mean()
        sigma = returns.std()
        
        # 模擬
        if self.time_horizon > 1:
            mu = mu * self.time_horizon
            sigma = sigma * np.sqrt(self.time_horizon)
        
        simulated_returns = np.random.normal(mu, sigma, n_simulations)
        
        var = -np.percentile(simulated_returns, (1 - self.confidence_level) * 100)
        
        return var * portfolio_value
    
    def cvar(
        self,
        returns: pd.Series,
        portfolio_value: float = 1.0
    ) -> float:
        """
        CVaR (Expected Shortfall)
        
        超過 VaR 的平均損失
        """
        var_threshold = -self.historical_var(returns, 1.0)
        
        tail_losses = returns[returns <= var_threshold]
        
        if len(tail_losses) == 0:
            return var_threshold * portfolio_value
        
        cvar = -tail_losses.mean()
        
        if self.time_horizon > 1:
            cvar = cvar * np.sqrt(self.time_horizon)
        
        return cvar * portfolio_value
    
    def portfolio_var(
        self,
        returns: pd.DataFrame,
        weights: np.ndarray,
        portfolio_value: float = 1.0
    ) -> Dict:
        """
        投資組合 VaR
        
        考慮資產間的相關性
        """
        # 組合收益率
        portfolio_returns = (returns * weights).sum(axis=1)
        
        return {
            "historical_var": self.historical_var(portfolio_returns, portfolio_value),
            "parametric_var": self.parametric_var(portfolio_returns, portfolio_value),
            "monte_carlo_var": self.monte_carlo_var(portfolio_returns, portfolio_value),
            "cvar": self.cvar(portfolio_returns, portfolio_value)
        }
    
    def stress_test(
        self,
        returns: pd.Series,
        scenarios: Dict[str, float]
    ) -> pd.DataFrame:
        """
        壓力測試
        
        Args:
            scenarios: 情境字典 {"scenario_name": shock_percentage}
        
        Returns:
            壓力測試結果
        """
        results = []
        
        current_value = 1.0
        
        for name, shock in scenarios.items():
            stressed_return = returns.mean() + shock * returns.std()
            stressed_value = current_value * (1 + stressed_return)
            loss = current_value - stressed_value
            
            results.append({
                "scenario": name,
                "shock_std": shock,
                "stressed_return": stressed_return,
                "portfolio_value": stressed_value,
                "loss": loss,
                "loss_pct": loss / current_value
            })
        
        return pd.DataFrame(results)


class RiskManager:
    """
    風險管理器
    整合所有風險指標
    """
    
    def __init__(
        self,
        var_confidence: float = 0.95,
        max_var_pct: float = 0.05,
        max_position_pct: float = 0.2
    ):
        """
        Args:
            var_confidence: VaR 置信度
            max_var_pct: 最大 VaR 百分比
            max_position_pct: 單一資產最大權重
        """
        self.var_calculator = VaRCalculator(confidence_level=var_confidence)
        self.max_var_pct = max_var_pct
        self.max_position_pct = max_position_pct
    
    def calculate_risk_metrics(
        self,
        returns: pd.Series,
        portfolio_value: float = 1.0
    ) -> Dict:
        """計算完整風險指標"""
        
        var_95 = self.var_calculator.historical_var(returns, portfolio_value)
        var_99 = self.var_calculator.parametric_var(returns, portfolio_value)
        cvar = self.var_calculator.cvar(returns, portfolio_value)
        
        # 其他風險指標
        max_drawdown = self._max_drawdown(returns)
        volatility = returns.std() * np.sqrt(252)
        
        return {
            "var_95": var_95,
            "var_95_pct": var_95 / portfolio_value,
            "var_99": var_99,
            "cvar": cvar,
            "volatility_annual": volatility,
            "max_drawdown": max_drawdown,
            "risk_level": self._assess_risk_level(var_95 / portfolio_value)
        }
    
    def check_position_limits(
        self,
        weights: np.ndarray
    ) -> Dict:
        """檢查倉位限制"""
        violations = []
        
        for i, w in enumerate(weights):
            if w > self.max_position_pct:
                violations.append(f"Asset {i}: {w:.2%} > {self.max_position_pct:.2%}")
        
        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "max_weight": weights.max(),
            "min_weight": weights.min()
        }
    
    def _max_drawdown(self, returns: pd.Series) -> float:
        """計算最大回撤"""
        cumulative = (1 + returns).cumprod()
        rolling_max = cumulative.cummax()
        drawdown = (cumulative - rolling_max) / rolling_max
        return drawdown.min()
    
    def _assess_risk_level(self, var_pct: float) -> str:
        """評估風險等級"""
        if var_pct < 0.02:
            return "low"
        elif var_pct < 0.05:
            return "medium"
        elif var_pct < 0.10:
            return "high"
        else:
            return "extreme"
    
    def generate_risk_report(
        self,
        returns: pd.DataFrame,
        weights: Optional[np.ndarray] = None,
        portfolio_value: float = 1000000
    ) -> Dict:
        """生成完整風險報告"""
        
        if weights is not None:
            # 投資組合風險
            portfolio_returns = (returns * weights).sum(axis=1)
            risk_metrics = self.calculate_risk_metrics(portfolio_returns, portfolio_value)
            position_check = self.check_position_limits(weights)
        else:
            # 單一資產風險
            risk_metrics = {}
            position_check = {"valid": True}
            
            for col in returns.columns:
                r = returns[col]
                risk_metrics[col] = self.calculate_risk_metrics(r, 1.0)
        
        return {
            "risk_metrics": risk_metrics,
            "position_limits": position_check,
            "recommendations": self._generate_recommendations(risk_metrics, position_check)
        }
    
    def _generate_recommendations(
        self,
        risk_metrics: Dict,
        position_check: Dict
    ) -> List[str]:
        """生成風險建議"""
        recommendations = []
        
        if risk_metrics.get("var_95_pct", 0) > self.max_var_pct:
            recommendations.append(
                f"VaR ({risk_metrics['var_95_pct']:.2%}) 超過閾值 ({self.max_var_pct:.2%})，建議降低風險"
            )
        
        if not position_check["valid"]:
            recommendations.append(
                f"倉位超限: {', '.join(position_check['violations'])}"
            )
        
        if risk_metrics.get("risk_level") == "high":
            recommendations.append("風險等級高，考慮減倉或對沖")
        
        return recommendations


# 便捷函數
def calculate_var(
    returns: pd.Series,
    method: str = "historical",
    confidence: float = 0.95
) -> float:
    """
    便捷函數：計算 VaR
    
    Example:
        >>> var = calculate_var(returns, "historical", 0.95)
    """
    calculator = VaRCalculator(confidence_level=confidence)
    
    if method == "historical":
        return calculator.historical_var(returns)
    elif method == "parametric":
        return calculator.parametric_var(returns)
    elif method == "monte_carlo":
        return calculator.monte_carlo_var(returns)
    elif method == "cvar":
        return calculator.cvar(returns)
    else:
        return calculator.historical_var(returns)
