"""
情緒分析交易模組
支持：新聞情緒、社交媒體情緒、 分析師建議
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional
from collections import Counter
import logging
import re

logger = logging.getLogger(__name__)

# 嘗試導入 NLP 庫
try:
    from textblob import TextBlob
    HAS_TEXTBLOB = True
except ImportError:
    HAS_TEXTBLOB = False

try:
    from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
    import torch
    HAS_TRANSFORMERS = True
except ImportError:
    HAS_TRANSFORMERS = False


class SentimentAnalyzer:
    """
    情緒分析引擎
    """
    
    def __init__(
        self,
        model_name: str = "finbert",
        use_pretrained: bool = True
    ):
        """
        Args:
            model_name: 情感分析模型 (finbert, distilbert, etc.)
            use_pretrained: 是否使用預訓練模型
        """
        self.model_name = model_name
        self.model = None
        self.tokenizer = None
        
        if use_pretrained:
            self._load_model()
    
    def _load_model(self):
        """加載預訓練模型"""
        if HAS_TRANSFORMERS:
            try:
                if "finbert" in self.model_name:
                    self.model = AutoModelForSequenceClassification.from_pretrained(
                        "ProsusAI/finbert"
                    )
                    self.tokenizer = AutoTokenizer.from_pretrained(
                        "ProsusAI/finbert"
                    )
                else:
                    # 使用默認情感分析模型
                    self.analyzer = pipeline("sentiment-analysis")
                logger.info(f"Loaded model: {self.model_name}")
            except Exception as e:
                logger.warning(f"Failed to load {self.model_name}: {e}")
                self.model = None
    
    def analyze_text(self, text: str) -> Dict:
        """
        分析單個文本的情緒
        
        Returns:
            {"sentiment": "positive/negative/neutral", "score": float}
        """
        if self.model is not None and HAS_TRANSFORMERS:
            return self._analyze_finbert(text)
        elif HAS_TEXTBLOB:
            return self._analyze_textblob(text)
        else:
            return self._analyze_keyword(text)
    
    def _analyze_finbert(self, text: str) -> Dict:
        """使用 FinBERT 分析"""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
        
        with torch.no_grad():
            outputs = self.model(**inputs)
            probs = torch.softmax(outputs.logits, dim=1)
        
        labels = ["negative", "neutral", "positive"]
        pred = torch.argmax(probs, dim=1).item()
        
        return {
            "sentiment": labels[pred],
            "confidence": probs[0][pred].item(),
            "scores": {
                "positive": probs[0][2].item(),
                "neutral": probs[0][1].item(),
                "negative": probs[0][0].item()
            }
        }
    
    def _analyze_textblob(self, text: str) -> Dict:
        """使用 TextBlob 分析"""
        blob = TextBlob(text)
        polarity = blob.sentiment.polarity  # -1 to 1
        subjectivity = blob.sentiment.subjectivity  # 0 to 1
        
        if polarity > 0.1:
            sentiment = "positive"
        elif polarity < -0.1:
            sentiment = "negative"
        else:
            sentiment = "neutral"
        
        return {
            "sentiment": sentiment,
            "score": polarity,
            "subjectivity": subjectivity
        }
    
    def _analyze_keyword(self, text: str) -> Dict:
        """基於關鍵詞的簡單分析"""
        text_lower = text.lower()
        
        positive_words = [
            "bullish", "upgrade", "buy", "outperform", "beat", "surge", 
            "gain", "profit", "growth", "success", "strong", "upgrade"
        ]
        negative_words = [
            "bearish", "downgrade", "sell", "underperform", "miss", 
            "drop", "loss", "decline", "weak", "warning", "risk"
        ]
        
        pos_count = sum(1 for w in positive_words if w in text_lower)
        neg_count = sum(1 for w in negative_words if w in text_lower)
        
        if pos_count > neg_count:
            sentiment = "positive"
            score = min(pos_count / (pos_count + neg_count + 1), 1)
        elif neg_count > pos_count:
            sentiment = "negative"
            score = -min(neg_count / (pos_count + neg_count + 1), 1)
        else:
            sentiment = "neutral"
            score = 0
        
        return {"sentiment": sentiment, "score": score}
    
    def analyze_news(
        self, 
        news_items: List[Dict],
        aggregate: bool = True
    ) -> Dict:
        """
        分析新聞列表
        
        Args:
            news_items: [{"title": str, "description": str}, ...]
        
        Returns:
            匯總情緒分數
        """
        results = []
        
        for item in news_items:
            text = f"{item.get('title', '')} {item.get('description', '')}"
            result = self.analyze_text(text)
            results.append(result)
        
        if not results:
            return {"sentiment": "neutral", "score": 0}
        
        if aggregate:
            # 匯總
            sentiments = [r["sentiment"] for r in results]
            scores = [r.get("score", 0) for r in results]
            
            most_common = Counter(sentiments).most_common(1)[0][0]
            avg_score = np.mean(scores)
            
            return {
                "sentiment": most_common,
                "score": avg_score,
                "positive_count": sentiments.count("positive"),
                "negative_count": sentiments.count("negative"),
                "neutral_count": sentiments.count("neutral"),
                "total_news": len(results)
            }
        
        return {"individual": results}


class AnalystRecommendations:
    """
    分析師建議聚合
    """
    
    # 分析師評級映射
    RATING_MAP = {
        "strong buy": 5, "buy": 4, "outperform": 4,
        "hold": 3, "neutral": 3,
        "underperform": 2, "sell": 1, "strong sell": 0
    }
    
    def __init__(self):
        self.ratings = []
    
    def add_rating(
        self, 
        firm: str, 
        rating: str, 
        target_price: Optional[float] = None,
        current_price: Optional[float] = None
    ):
        """添加分析師評級"""
        normalized_rating = rating.lower().strip()
        score = self.RATING_MAP.get(normalized_rating, 3)
        
        upside = None
        if target_price and current_price:
            upside = (target_price - current_price) / current_price
        
        self.ratings.append({
            "firm": firm,
            "rating": rating,
            "score": score,
            "target_price": target_price,
            "upside": upside
        })
    
    def get_consensus(self) -> Dict:
        """計算共識評級"""
        if not self.ratings:
            return {"consensus": "neutral", "score": 3, "count": 0}
        
        avg_score = np.mean([r["score"] for r in self.ratings])
        upsi_des = [r["upside"] for r in self.ratings if r["upside"] is not None]
        avg_upside = np.mean(upsi_des) if upsi_des else None
        
        if avg_score >= 4:
            consensus = "bullish"
        elif avg_score <= 2:
            consensus = "bearish"
        else:
            consensus = "neutral"
        
        return {
            "consensus": consensus,
            "score": avg_score,
            "count": len(self.ratings),
            "buy_count": sum(1 for r in self.ratings if r["score"] >= 4),
            "sell_count": sum(1 for r in self.ratings if r["score"] <= 2),
            "average_upside": avg_upside,
            "ratings": self.ratings
        }


class SentimentStrategy:
    """
    基於情緒的交易策略
    """
    
    def __init__(
        self,
        sentiment_threshold: float = 0.3,
        confirm_days: int = 1
    ):
        self.sentiment_threshold = sentiment_threshold
        self.confirm_days = confirm_days
        self.analyzer = SentimentAnalyzer()
    
    def generate_signals(
        self,
        prices: pd.Series,
        news_data: List[Dict]
    ) -> pd.DataFrame:
        """生成交易信號"""
        # 分析情緒
        sentiment_result = self.analyzer.analyze_news(news_data)
        
        signals = pd.DataFrame(index=prices.index)
        signals["price"] = prices
        signals["sentiment"] = sentiment_result.get("score", 0)
        signals["sentiment_label"] = sentiment_result.get("sentiment", "neutral")
        
        # 生成信號
        signals["signal"] = 0
        
        # 強正面情緒 + 價格上漲 -> 買入
        signals.loc[
            (signals["sentiment"] > self.sentiment_threshold) & 
            (prices.pct_change() > 0),
            "signal"
        ] = 1
        
        # 強負面情緒 + 價格下跌 -> 賣出
        signals.loc[
            (signals["sentiment"] < -self.sentiment_threshold) & 
            (prices.pct_change() < 0),
            "signal"
        ] = -1
        
        return signals
    
    def backtest(
        self,
        prices: pd.Series,
        news_data: List[Dict],
        initial_capital: float = 100000
    ) -> Dict:
        """回測"""
        signals = self.generate_signals(prices, news_data)
        
        signals["returns"] = prices.pct_change()
        signals["strategy_returns"] = signals["signal"].shift(1) * signals["returns"]
        signals["cumulative"] = (1 + signals["strategy_returns"]).cumprod()
        
        total_return = signals["cumulative"].iloc[-1] - 1
        
        return {
            "total_return": total_return,
            "sentiment": signals["sentiment"].iloc[-1],
            "signals": signals
        }


# 便捷函數
def analyze_market_sentiment(symbols: List[str]) -> Dict:
    """
    便捷函數：分析市場情緒
    
    Example:
        >>> sentiment = analyze_market_sentiment(["AAPL", "TSLA"])
    """
    from .data_fetcher import DataFetcher
    
    fetcher = DataFetcher()
    analyzer = SentimentAnalyzer()
    
    results = {}
    for symbol in symbols:
        news = fetcher.get_news_sentiment([symbol], days=7)
        
        if symbol in news and news[symbol]:
            result = analyzer.analyze_news(news[symbol])
            results[symbol] = result
        else:
            results[symbol] = {"sentiment": "neutral", "score": 0}
    
    # 總體市場情緒
    all_scores = [r.get("score", 0) for r in results.values()]
    market_sentiment = np.mean(all_scores) if all_scores else 0
    
    return {
        "market_sentiment": market_sentiment,
        "symbols": results
    }
