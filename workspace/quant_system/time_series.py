"""
時序預測模組
支持：LSTM, GRU, Transformer, ARIMA, Prophet
"""

import numpy as np
import pandas as pd
from typing import Tuple, Optional, Dict
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

# 嘗試導入深度學習庫
try:
    import torch
    import torch.nn as nn
    from torch.utils.data import DataLoader, TensorDataset
    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False
    logger.warning("PyTorch not available, will use statistical models only")

try:
    from sklearn.preprocessing import MinMaxScaler, StandardScaler
    from sklearn.metrics import mean_squared_error, mean_absolute_error
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False


class LSTMModel(nn.Module if HAS_TORCH else object):
    """LSTM 預測模型"""
    
    def __init__(self, input_size: int, hidden_size: int = 64, num_layers: int = 2):
        if not HAS_TORCH:
            raise ImportError("PyTorch required for LSTM")
        
        super().__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        
        self.lstm = nn.LSTM(
            input_size, 
            hidden_size, 
            num_layers, 
            batch_first=True,
            dropout=0.2
        )
        self.fc = nn.Linear(hidden_size, 1)
    
    def forward(self, x):
        # x shape: (batch, seq_len, input_size)
        lstm_out, _ = self.lstm(x)
        out = self.fc(lstm_out[:, -1, :])
        return out


class TimeSeriesPredictor:
    """
    時序預測引擎
    支持多種模型的切換
    """
    
    def __init__(
        self, 
        model_type: str = "lstm",
        sequence_length: int = 60,
        prediction_horizon: int = 1
    ):
        """
        Args:
            model_type: "lstm", "gru", "arima", "prophet"
            sequence_length: 輸入序列長度
            prediction_horizon: 預測未來多少步
        """
        self.model_type = model_type.lower()
        self.sequence_length = sequence_length
        self.prediction_horizon = prediction_horizon
        self.model = None
        self.scaler = MinMaxScaler() if HAS_SKLEARN else None
        self.is_fitted = False
        
        self._init_model()
    
    def _init_model(self):
        """根據模型類型初始化模型"""
        if self.model_type == "lstm" and HAS_TORCH:
            self.model = LSTMModel(input_size=1, hidden_size=64, num_layers=2)
        elif self.model_type == "arima":
            self.model = ARIMAModel()
        elif self.model_type == "prophet":
            self.model = ProphetModel()
        else:
            # 默認使用簡單的移動平均
            self.model = MovingAverageModel()
    
    def prepare_data(self, data: pd.Series) -> Tuple[np.ndarray, np.ndarray]:
        """準備訓練數據"""
        if self.scaler is not None:
            scaled_data = self.scaler.fit_transform(data.values.reshape(-1, 1))
        else:
            scaled_data = data.values
        
        X, y = [], []
        for i in range(len(scaled_data) - self.sequence_length - self.prediction_horizon + 1):
            X.append(scaled_data[i:i + self.sequence_length])
            y.append(scaled_data[i + self.sequence_length:i + self.sequence_length + self.prediction_horizon])
        
        return np.array(X), np.array(y)
    
    def fit(self, data: pd.Series, epochs: int = 50, verbose: bool = True):
        """
        訓練模型
        
        Args:
            data: 價格數據序列
            epochs: 訓練輪數
        """
        logger.info(f"Training {self.model_type} model on {len(data)} data points")
        
        if self.model_type in ["lstm", "gru"] and HAS_TORCH:
            self._fit_deep_learning(data, epochs, verbose)
        elif self.model_type == "arima":
            self.model.fit(data)
        elif self.model_type == "prophet":
            self.model.fit(data)
        else:
            self.model.fit(data)
        
        self.is_fitted = True
        logger.info("Model training completed")
    
    def _fit_deep_learning(self, data: pd.Series, epochs: int, verbose: bool):
        """訓練深度學習模型"""
        X, y = self.prepare_data(data)
        
        # 轉換為 PyTorch 張量
        X_tensor = torch.FloatTensor(X)
        y_tensor = torch.FloatTensor(y).view(-1, self.prediction_horizon)
        
        dataset = TensorDataset(X_tensor, y_tensor)
        dataloader = DataLoader(dataset, batch_size=32, shuffle=True)
        
        criterion = nn.MSELoss()
        optimizer = torch.optim.Adam(self.model.parameters(), lr=0.001)
        
        self.model.train()
        for epoch in range(epochs):
            total_loss = 0
            for batch_X, batch_y in dataloader:
                optimizer.zero_grad()
                outputs = self.model(batch_X)
                loss = criterion(outputs, batch_y)
                loss.backward()
                optimizer.step()
                total_loss += loss.item()
            
            if verbose and (epoch + 1) % 10 == 0:
                logger.info(f"Epoch {epoch+1}/{epochs}, Loss: {total_loss/len(dataloader):.6f}")
    
    def predict(self, data: pd.Series, steps: Optional[int] = None) -> np.ndarray:
        """
        預測未來價格
        
        Returns:
            預測的價格數組
        """
        if not self.is_fitted:
            raise ValueError("Model must be fitted before prediction")
        
        steps = steps or self.prediction_horizon
        
        if self.model_type in ["lstm", "gru"] and HAS_TORCH:
            return self._predict_deep_learning(data, steps)
        else:
            return self.model.predict(data, steps)
    
    def _predict_deep_learning(self, data: pd.Series, steps: int) -> np.ndarray:
        """深度學習預測"""
        self.model.eval()
        
        # 使用最後 sequence_length 個點作為輸入
        if self.scaler is not None:
            scaled_data = self.scaler.transform(data.values.reshape(-1, 1))
        else:
            scaled_data = data.values
        
        predictions = []
        current_sequence = scaled_data[-self.sequence_length:].copy()
        
        with torch.no_grad():
            for _ in range(steps):
                X = torch.FloatTensor(current_sequence.reshape(1, -1, 1))
                pred = self.model(X).item()
                predictions.append(pred)
                current_sequence = np.append(current_sequence[1:], pred)
        
        # 反標準化
        if self.scaler is not None:
            predictions = self.scaler.inverse_transform(np.array(predictions).reshape(-1, 1)).flatten()
        
        return np.array(predictions)
    
    def evaluate(self, test_data: pd.Series) -> Dict[str, float]:
        """評估模型性能"""
        predictions = self.predict(test_data)
        actual = test_data.values[-len(predictions):]
        
        return {
            "mse": mean_squared_error(actual, predictions) if HAS_SKLEARN else 0,
            "mae": mean_absolute_error(actual, predictions) if HAS_SKLEARN else 0,
            "rmse": np.sqrt(mean_squared_error(actual, predictions)) if HAS_SKLEARN else 0,
            "mape": np.mean(np.abs((actual - predictions) / actual)) * 100 if HAS_SKLEARN else 0
        }


# 簡化模型（當深度學習不可用時）
class MovingAverageModel:
    """移動平均預測模型"""
    
    def __init__(self, window: int = 20):
        self.window = window
        self.ma = None
    
    def fit(self, data: pd.Series):
        self.ma = data.rolling(window=self.window).mean().iloc[-1]
    
    def predict(self, data: pd.Series, steps: int) -> np.ndarray:
        return np.full(steps, self.ma)


class ARIMAModel:
    """ARIMA 統計模型"""
    
    def __init__(self, order: tuple = (5, 1, 0)):
        self.order = order
        self.model = None
        self.result = None
    
    def fit(self, data: pd.Series):
        try:
            from statsmodels.tsa.arima.model import ARIMA
            self.model = ARIMA(data, order=self.order)
            self.result = self.model.fit()
        except Exception as e:
            logger.warning(f"ARIMA fitting failed: {e}, using simple mean")
            self.result = None
    
    def predict(self, data: pd.Series, steps: int) -> np.ndarray:
        if self.result is not None:
            forecast = self.result.forecast(steps=steps)
            return forecast.values
        return np.full(steps, data.mean())


class ProphetModel:
    """Facebook Prophet 模型"""
    
    def __init__(self):
        self.model = None
    
    def fit(self, data: pd.Series):
        try:
            from prophet import Prophet
            df = pd.DataFrame({
                "ds": data.index,
                "y": data.values
            })
            self.model = Prophet()
            self.model.fit(df)
        except ImportError:
            logger.warning("Prophet not installed")
        except Exception as e:
            logger.warning(f"Prophet fitting failed: {e}")
    
    def predict(self, data: pd.Series, steps: int) -> np.ndarray:
        if self.model is not None:
            future = self.model.make_future_dataframe(periods=steps)
            forecast = self.model.predict(future)
            return forecast["yhat"].values[-steps:]
        return np.full(steps, data.mean())


def predict_price(
    symbol: str, 
    model_type: str = "lstm",
    prediction_days: int = 5
) -> Dict:
    """
    便捷函數：預測股票價格
    
    Example:
        >>> prediction = predict_price("AAPL", "lstm", prediction_days=5)
        >>> print(prediction)
    """
    from .data_fetcher import DataFetcher
    
    # 獲取數據
    fetcher = DataFetcher()
    data = fetcher.get_price_data(
        [symbol], 
        start_date=(datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")
    )
    
    if symbol not in data or len(data[symbol]) == 0:
        return {"error": f"No data for {symbol}"}
    
    prices = data[symbol]["Close"].dropna()
    
    # 訓練模型
    predictor = TimeSeriesPredictor(model_type=model_type)
    predictor.fit(prices)
    
    # 預測
    predictions = predictor.predict(prices, steps=prediction_days)
    
    # 評估（用最後30天數據）
    test_data = prices[-30:]
    metrics = predictor.evaluate(test_data)
    
    return {
        "symbol": symbol,
        "model": model_type,
        "predictions": predictions.tolist(),
        "current_price": float(prices.iloc[-1]),
        "metrics": metrics,
        "next_day_prediction": float(predictions[0]),
        "confidence": "high" if metrics.get("mape", 100) < 5 else "medium" if metrics.get("mape", 100) < 15 else "low"
    }
