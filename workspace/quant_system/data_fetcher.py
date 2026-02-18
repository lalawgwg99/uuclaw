"""
數據獲取模組
支持：Yahoo Finance, Alpha Vantage, Reuters, Crypto APIs
"""

import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
from typing import Optional, List, Dict
import requests
import logging

logger = logging.getLogger(__name__)


class DataFetcher:
    """統一的數據獲取接口"""
    
    def __init__(self, data_source: str = "yahoo"):
        self.data_source = data_source
        self.cache = {}
    
    def get_price_data(
        self, 
        symbols: List[str], 
        start_date: str, 
        end_date: Optional[str] = None,
        interval: str = "1d"
    ) -> Dict[str, pd.DataFrame]:
        """
        獲取價格數據
        
        Args:
            symbols: 股票代碼列表
            start_date: 開始日期 (YYYY-MM-DD)
            end_date: 結束日期 (預設現在)
            interval: 數據頻率 (1d, 1h, 5m, etc.)
        
        Returns:
            Dict[symbol, DataFrame]
        """
        if end_date is None:
            end_date = datetime.now().strftime("%Y-%m-%d")
        
        result = {}
        for symbol in symbols:
            try:
                data = yf.download(symbol, start=start_date, end=end_date, interval=interval)
                if len(data) > 0:
                    result[symbol] = data
                    logger.info(f"Fetched {len(data)} records for {symbol}")
                else:
                    logger.warning(f"No data for {symbol}")
            except Exception as e:
                logger.error(f"Error fetching {symbol}: {e}")
        
        return result
    
    def get_fundamental_data(self, symbol: str) -> Dict:
        """
        獲取基本面數據
        PE ratio, Book Value, Dividends, etc.
        """
        try:
            ticker = yf.Ticker(symbol)
            info = ticker.info
            return {
                "pe_ratio": info.get("peRatio"),
                "pb_ratio": info.get("priceToBook"),
                "dividend_yield": info.get("dividendYield"),
                "beta": info.get("beta"),
                "market_cap": info.get("marketCap"),
                "eps": info.get("earningsPerShare"),
                "revenue": info.get("totalRevenue"),
                "profit_margin": info.get("profitMargins"),
                "debt_to_equity": info.get("debtToEquity"),
            }
        except Exception as e:
            logger.error(f"Error fetching fundamental for {symbol}: {e}")
            return {}
    
    def get_news_sentiment(self, symbols: List[str], days: int = 7) -> Dict[str, List[Dict]]:
        """
        獲取新聞數據（用於情緒分析）
        """
        news_data = {}
        for symbol in symbols:
            try:
                ticker = yf.Ticker(symbol)
                news = ticker.news
                news_data[symbol] = news[:10] if news else []
            except Exception as e:
                logger.error(f"Error fetching news for {symbol}: {e}")
                news_data[symbol] = []
        return news_data
    
    def get_options_chain(self, symbol: str) -> Dict:
        """
        獲取期權鏈數據
        """
        try:
            ticker = yf.Ticker(symbol)
            return {
                "calls": ticker.calls if hasattr(ticker, 'calls') else None,
                "puts": ticker.puts if hasattr(ticker, 'puts') else None,
            }
        except Exception as e:
            logger.error(f"Error fetching options for {symbol}: {e}")
            return {}
    
    def get_market_indices(self) -> pd.DataFrame:
        """獲取市場指數"""
        indices = ["^GSPC", "^IXIC", "^DJI", "^VIX"]
        return self.get_price_data(indices, 
                                  (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d"))
    
    def calculate_returns(self, price_data: pd.DataFrame) -> pd.DataFrame:
        """計算收益率"""
        if "Adj Close" in price_data.columns:
            return price_data["Adj Close"].pct_change().dropna()
        elif "Close" in price_data.columns:
            return price_data["Close"].pct_change().dropna()
        return pd.Series()


# 便捷函數
def fetch_stock_data(symbols: List[str], period: str = "1y") -> Dict[str, pd.DataFrame]:
    """快速獲取股票數據"""
    fetcher = DataFetcher()
    end_date = datetime.now().strftime("%Y-%m-%d")
    start_date = (datetime.now() - timedelta(days={
        "1mo": 30, "3mo": 90, "6mo": 180, "1y": 365, "2y": 730
    }.get(period, 365))).strftime("%Y-%m-%d")
    
    return fetcher.get_price_data(symbols, start_date, end_date)
