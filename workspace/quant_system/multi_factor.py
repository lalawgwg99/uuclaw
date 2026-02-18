"""
多因子模型模組
支持：Fama-French 三因子、五因子、動量因子、價值因子
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
from sklearn.linear_model import LinearRegression, Ridge
import logging

logger = logging.getLogger(__name__)


class MultiFactorModel:
    """
    多因子定價模型
    """
    
    def __init__(
        self,
        factors: List[str] = None,
        use_fama_french: bool = True
    ):
        """
        Args:
            factors: 因子列表
            use_fama_french: 是否使用 FF 因子
        """
        self.factors = factors or ["mkt", "smb", "hml", "mom"]
        self.use_fama_french = use_fama_french
        self.model = None
        self.factor_returns = None
        self.factor_betas = None
    
    def fit(
        self,
        returns: pd.DataFrame,
        factor_data: Optional[pd.DataFrame] = None
    ) -> Dict:
        """
        擬合因子模型
        
        Args:
            returns: 資產收益率 DataFrame
            factor_data: 因子收益率 DataFrame
        
        Returns:
            回歸結果
        """
        # 如果沒有提供因子數據，生成模擬因子
        if factor_data is None:
            factor_data = self._generate_factors(returns)
        
        self.factor_returns = factor_data
        
        results = {}
        
        for asset in returns.columns:
            # 去除 NaN
            valid_idx = returns[asset].notna() & factor_data.notna().all(axis=1)
            
            y = returns.loc[valid_idx, asset]
            X = factor_data.loc[valid_idx]
            
            # OLS 回歸
            self.model = LinearRegression()
            self.model.fit(X, y)
            
            # 計算 alpha 和 betas
            results[asset] = {
                "alpha": self.model.intercept_,
                "betas": dict(zip(X.columns, self.model.coef_)),
                "r_squared": self.model.score(X, y)
            }
        
        self.factor_betas = results
        return results
    
    def _generate_fins_factors(self, prices: pd.DataFrame) -> pd.DataFrame:
        """生成基本面因子"""
        factors = pd.DataFrame(index=prices.index)
        
        # 市場因子 (Market)
        if len(prices.columns) > 1:
            equal_weight = prices.mean(axis=1)
            factors["mkt"] = equal_weight.pct_change()
        else:
            factors["mkt"] = prices.iloc[:, 0].pct_change()
        
        # 規模因子 (Size) - 小減大
        if len(prices.columns) >= 2:
            small = prices.iloc[:, :len(prices.columns)//2].mean(axis=1)
            large = prices.iloc[:, len(prices.columns)//2:].mean(axis=1)
            factors["smb"] = (small.pct_change() - large.pct_change())
        
        # 價值因子 (Value) - 高book減低book（模擬）
        # 這裡用價格動能作為代理
        factors["hml"] = prices.pct_change(30) - prices.pct_change()
        
        # 動量因子 (Momentum)
        factors["mom"] = prices.pct_change(90)
        
        return factors.fillna(0)
    
    def predict_returns(
        self,
        factor_betas: Dict,
        factor_returns: pd.DataFrame
    ) -> pd.Series:
        """
        根據因子預測收益
        """
        predictions = {}
        
        for asset, betas in factor_betas.items():
            pred = betas["alpha"]
            
            for factor, beta in betas.get("betas", {}).items():
                if factor in factor_returns.columns:
                    pred += beta * factor_returns[factor].iloc[-1]
            
            predictions[asset] = pred
        
        return pd.Series(predictions)
    
    def factor_exposure(
        self,
        returns: pd.DataFrame,
        factor_data: Optional[pd.DataFrame] = None
    ) -> pd.DataFrame:
        """
        計算因子暴露
        """
        results = self.fit(returns, factor_data)
        
        # 轉換為 DataFrame
        betas_df = pd.DataFrame({
            asset: data.get("betas", {})
            for asset, data in results.items()
        }).T
        
        return betas_df
    
    def performance_attribution(
        self,
        actual_returns: pd.Series,
        factor_returns: pd.DataFrame,
        betas: Dict
    ) -> Dict:
        """
        業績歸因
        
        分解收益來源
        """
        total_return = actual_returns.mean() * 252
        
        # 因子貢獻
        factor_contrib = {}
        for factor, beta in betas.get("betas", {}).items():
            if factor in factor_returns.columns:
                factor_contrib[factor] = beta * factor_returns[factor].mean() * 252
        
        # Alpha 貢獻
        alpha_contrib = betas.get("alpha", 0) * 252
        
        # 殘差
        residual = total_return - alpha_contrib - sum(factor_contrib.values())
        
        return {
            "total_return": total_return,
            "alpha": alpha_contrib,
            "factor_contributions": factor_contrib,
            "residual": residual
        }


class FamaFrench3Factor:
    """Fama-French 三因子模型"""
    
    def __init__(self):
        self.factors = ["mkt", "smb", "hml"]
    
    def get_factors(self, start_date: str, end_date: str) -> pd.DataFrame:
        """
        獲取 FF 因子數據
        
        這裡返回模擬數據，實際應從 Kenneth French 数据库獲取
        """
        # 模擬因子
        dates = pd.date_range(start_date, end_date, freq="D")
        
        np.random.seed(42)
        
        factors = pd.DataFrame({
            "mkt": np.random.normal(0.0005, 0.01, len(dates)),
            "smb": np.random.normal(0.0002, 0.005, len(dates)),
            "hml": np.random.normal(0.0001, 0.005, len(dates))
        }, index=dates)
        
        return factors


class Carhart4Factor:
    """Carhart 四因子模型（加動量）"""
    
    def __init__(self):
        self.factors = ["mkt", "smb", "hml", "mom"]
    
    def get_factors(self, start_date: str, end_date: str) -> pd.DataFrame:
        """獲取因子數據"""
        dates = pd.date_range(start_date, end_date, freq="D")
        
        np.random.seed(42)
        
        factors = pd.DataFrame({
            "mkt": np.random.normal(0.0005, 0.01, len(dates)),
            "smb": np.random.normal(0.0002, 0.005, len(dates)),
            "hml": np.random.normal(0.0001, 0.005, len(dates)),
            "mom": np.random.normal(0.0003, 0.008, len(dates))
        }, index=dates)
        
        return factors


class FactorInvesting:
    """
    因子投資策略
    """
    
    def __init__(self):
        self.scores = {}
    
    def calculate_factor_scores(
        self,
        prices: pd.DataFrame,
        fundamentals: pd.DataFrame
    ) -> pd.DataFrame:
        """
        計算因子分數
        """
        scores = pd.DataFrame(index=prices.columns)
        
        # 動量分數
        scores["momentum"] = prices.pct_change(90)
        
        # 價值分數（如果提供基本面數據）
        if "pe_ratio" in fundamentals.columns:
            scores["value"] = 1 / fundamentals["pe_ratio"]
        
        # 規模分數
        if "market_cap" in fundamentals.columns:
            scores["size"] = fundamentals["market_cap"]
        
        # 質量分數
        if "profit_margin" in fundamentals.columns:
            scores["quality"] = fundamentals["profit_margin"]
        
        # 波動率分數
        scores["volatility"] = prices.pct_change().std()
        
        return scores
    
    def rank_assets(
        self,
        scores: pd.DataFrame,
        factor_weights: Optional[Dict] = None
    ) -> pd.Series:
        """
        根據因子分數排名資產
        """
        factor_weights = factor_weights or {
            "value": 0.3,
            "momentum": 0.3,
            "quality": 0.2,
            "size": 0.1,
            "volatility": 0.1
        }
        
        # 標準化
        normalized = (scores - scores.mean()) / scores.std()
        
        # 加權
        combined = pd.Series(0.0, index=scores.index)
        
        for factor, weight in factor_weights.items():
            if factor in normalized.columns:
                combined += normalized[factor] * weight
        
        return combined.sort_values(ascending=False)
    
    def select_top_n(
        self,
        scores: pd.DataFrame,
        n: int = 10,
        factor_weights: Optional[Dict] = None
    ) -> List[str]:
        """
        選擇 top N 資產
        """
        rankings = self.rank_assets(scores, factor_weights)
        return rankings.head(n).index.tolist()


# 便捷函數
def run_factor_analysis(
    returns: pd.DataFrame,
    factors: Optional[pd.DataFrame] = None
) -> Dict:
    """
    便捷函數：因子分析
    
    Example:
        >>> results = run_factor_analysis(asset_returns)
    """
    model = MultiFactorModel()
    results = model.fit(returns, factors)
    
    # 轉換為可讀格式
    summary = {}
    for asset, data in results.items():
        summary[asset] = {
            "alpha": f"{data['alpha']*252:.2%}",
            "r_squared": f"{data['r_squared']:.2%}",
            "market_beta": data.get("betas", {}).get("mkt", 0)
        }
    
    return {
        "results": results,
        "summary": summary
    }
