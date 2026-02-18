"""
期權定價模組
支持：Black-Scholes, Binomial, Greeks 計算
"""

import numpy as np
import pandas as pd
from typing import Dict, Optional, Tuple
from scipy.stats import norm
import logging

logger = logging.getLogger(__name__)


class OptionsPricer:
    """
    期權定價引擎
    """
    
    def __init__(self):
        pass
    
    def black_scholes(
        self,
        S: float,      # 現貨價格
        K: float,      # 執行價格
        T: float,      # 到期時間（年）
        r: float,      # 無風險利率
        sigma: float,  # 波動率
        option_type: str = "call"
    ) -> Dict:
        """
        Black-Scholes 期權定價
        
        Args:
            S: 標的資產現價
            K: 執行價格
            T: 到期時間（年）
            r: 無風險利率
            sigma: 波動率
            option_type: "call" 或 "put"
        
        Returns:
            期權價格和 Greeks
        """
        # 計算 d1 和 d2
        d1 = (np.log(S / K) + (r + 0.5 * sigma ** 2) * T) / (sigma * np.sqrt(T))
        d2 = d1 - sigma * np.sqrt(T)
        
        if option_type.lower() == "call":
            # Call 期權
            price = S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2)
            delta = norm.cdf(d1)
            rho = K * T * np.exp(-r * T) * norm.cdf(d2)
        else:
            # Put 期權
            price = K * np.exp(-r * T) * norm.cdf(-d2) - S * norm.cdf(-d1)
            delta = norm.cdf(d1) - 1
            rho = -K * T * np.exp(-r * T) * norm.cdf(-d2)
        
        # Greeks
        gamma = norm.pdf(d1) / (S * sigma * np.sqrt(T))
        vega = S * norm.pdf(d1) * np.sqrt(T)
        theta = (-S * norm.pdf(d1) * sigma / (2 * np.sqrt(T)) 
                 - r * K * np.exp(-r * T) * norm.cdf(d2 if option_type == "call" else -d2))
        
        return {
            "price": price,
            "delta": delta,
            "gamma": gamma,
            "vega": vega,
            "theta": theta,
            "rho": rho,
            "d1": d1,
            "d2": d2
        }
    
    def binomial(
        self,
        S: float,
        K: float,
        T: float,
        r: float,
        sigma: float,
        n_steps: int = 100,
        option_type: str = "call",
        american: bool = False
    ) -> float:
        """
        二叉樹期權定價
        
        Args:
            n_steps: 樹的節點數
            american: 是否為美式期權
        """
        dt = T / n_steps
        u = np.exp(sigma * np.sqrt(dt))
        d = 1 / u
        p = (np.exp(r * dt) - d) / (u - d)
        
        # 初始化節點價格
        prices = np.array([S * (u ** (n_steps - i)) * (d ** i) 
                          for i in range(n_steps + 1)])
        
        # 初始化期權價值
        if option_type.lower() == "call":
            option_values = np.maximum(prices - K, 0)
        else:
            option_values = np.maximum(K - prices, 0)
        
        # 向後遞推
        for j in range(n_steps - 1, -1, -1):
            for i in range(j + 1):
                # 期望值
                expected = p * option_values[i] + (1 - p) * option_values[i + 1]
                option_values[i] = np.exp(-r * dt) * expected
                
                # 美式期權提前執行
                if american:
                    if option_type.lower() == "call":
                        exercise = max(prices[i] - K, 0)
                    else:
                        exercise = max(K - prices[i], 0)
                    option_values[i] = max(option_values[i], exercise)
        
        return option_values[0]
    
    def implied_volatility(
        self,
        market_price: float,
        S: float,
        K: float,
        T: float,
        r: float,
        option_type: str = "call",
        initial_guess: float = 0.3
    ) -> float:
        """
        計算隱含波動率
        
        使用牛頓法
        """
        from scipy.optimize import newton
        
        def objective(sigma):
            bs = self.black_scholes(S, K, T, r, sigma, option_type)
            return bs["price"] - market_price
        
        try:
            iv = newton(objective, initial_guess)
            return iv
        except:
            return initial_guess
    
    def greeks(
        self,
        S: float,
        K: float,
        T: float,
        r: float,
        sigma: float,
        option_type: str = "call"
    ) -> Dict:
        """計算所有 Greeks"""
        return self.black_scholes(S, K, T, r, sigma, option_type)


class OptionsStrategy:
    """
    期權策略
    """
    
    def __init__(self):
        self.pricer = OptionsPricer()
    
    def covered_call(
        self,
        stock_price: float,
        strike: float,
        T: float,
        r: float,
        sigma: float
    ) -> Dict:
        """
        備兌看漲期權
        持有股票 + 賣出 Call
        """
        # 股票收益
        stock_value = stock_price
        
        # 期權收益（賣出）
        call = self.pricer.black_scholes(stock_price, strike, T, r, sigma, "call")
        
        # 組合價值
        # 到期時收益
        def payoff(stock_at_expiry):
            stock_payoff = stock_at_expiry
            call_payoff = max(stock_at_expiry - strike, 0)
            return stock_payoff - call_payoff
        
        return {
            "strategy": "covered_call",
            "initial_credit": call["price"],
            "max_profit": stock_price - strike + call["price"] if stock_price > strike else stock_price + call["price"],
            "max_loss": call["price"],  # 股票跌到0
            "break_even": stock_price - call["price"],
            "call_greeks": call
        }
    
    def protective_put(
        self,
        stock_price: float,
        strike: float,
        T: float,
        r: float,
        sigma: float
    ) -> Dict:
        """
        保護性看跌期權
        持有股票 + 買入 Put
        """
        put = self.pricer.black_scholes(stock_price, strike, T, r, sigma, "put")
        
        return {
            "strategy": "protective_put",
            "initial_debit": put["price"],
            "max_loss": strike - put["price"],  # 股票跌到0
            "max_profit": float("inf"),
            "break_even": stock_price + put["price"],
            "put_greeks": put
        }
    
    def straddle(
        self,
        stock_price: float,
        strike: float,
        T: float,
        r: float,
        sigma: float,
        long: bool = True
    ) -> Dict:
        """
        跨式期權
        買入/賣出 相同執行價的 Call 和 Put
        """
        call = self.pricer.black_scholes(stock_price, strike, T, r, sigma, "call")
        put = self.pricer.black_scholes(stock_price, strike, T, r, sigma, "put")
        
        premium = call["price"] + put["price"]
        
        if long:
            return {
                "strategy": "long_straddle",
                "cost": premium,
                "max_loss": premium,
                "max_profit": float("inf"),
                "break_even": [strike - premium, strike + premium]
            }
        else:
            return {
                "strategy": "short_straddle",
                "credit": premium,
                "max_loss": float("inf"),
                "max_profit": premium,
                "break_even": [strike - premium, strike + premium]
            }
    
    def iron_condor(
        self,
        S: float,
        strikes: Tuple[float, float, float, float],
        T: float,
        r: float,
        sigma: float
    ) -> Dict:
        """
        鐵禿鷹價差
        
        strikes: (put_buy_strike, put_sell_strike, call_sell_strike, call_buy_strike)
        """
        put_buy = self.pricer.black_scholes(S, strikes[0], T, r, sigma, "put")
        put_sell = self.pricer.black_scholes(S, strikes[1], T, r, sigma, "put")
        call_sell = self.pricer.black_scholes(S, strikes[2], T, r, sigma, "call")
        call_buy = self.pricer.black_scholes(S, strikes[3], T, r, sigma, "call")
        
        net_credit = (put_sell["price"] + call_sell["price"] - 
                     put_buy["price"] - call_buy["price"])
        
        max_loss = (strikes[1] - strikes[0]) + (strikes[3] - strikes[2]) - net_credit
        
        return {
            "strategy": "iron_condor",
            "net_credit": net_credit,
            "max_profit": net_credit,
            "max_loss": max_loss,
            "break_even": [
                strikes[1] - net_credit,
                strikes[2] + net_credit
            ]
        }
    
    def volatility_smile(
        self,
        options_chain: pd.DataFrame,
        S: float,
        T: float,
        r: float
    ) -> pd.DataFrame:
        """
        計算波動率微笑
        
        Args:
            options_chain: 期權鏈數據，需包含 strike, price, type 列
        """
        results = []
        
        for _, row in options_chain.iterrows():
            iv = self.implied_volatility(
                row["price"], S, row["strike"], T, r, row["type"]
            )
            results.append({
                "strike": row["strike"],
                "type": row["type"],
                "iv": iv,
                "moneyness": row["strike"] / S
            })
        
        return pd.DataFrame(results)


# 便捷函數
def price_option(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: str = "call",
    method: str = "black_scholes"
) -> Dict:
    """
    便捷函數：期權定價
    
    Example:
        >>> result = price_option(100, 100, 1, 0.05, 0.2, "call")
    """
    pricer = OptionsPricer()
    
    if method == "black_scholes":
        return pricer.black_scholes(S, K, T, r, sigma, option_type)
    elif method == "binomial":
        price = pricer.binomial(S, K, T, r, sigma, 100, option_type)
        return {"price": price}
    else:
        return pricer.black_scholes(S, K, T, r, sigma, option_type)


def compute_greeks(
    S: float,
    K: float,
    T: float,
    r: float,
    sigma: float,
    option_type: str = "call"
) -> Dict:
    """計算 Greeks"""
    pricer = OptionsPricer()
    return pricer.greeks(S, K, T, r, sigma, option_type)
