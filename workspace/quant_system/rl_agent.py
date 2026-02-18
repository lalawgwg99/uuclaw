"""
強化學習交易代理模組
支持：Deep Q-Learning, Policy Gradient, Actor-Critic
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
import logging
from collections import deque
import random

logger = logging.getLogger(__name__)

# 嘗試導入深度學習
try:
    import torch
    import torch.nn as nn
    import torch.optim as optim
    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False
    logger.warning("PyTorch not available, RL capabilities limited")


class TradingEnvironment:
    """
    交易環境
    OpenAI Gym 風格的環境
    """
    
    def __init__(
        self,
        prices: pd.DataFrame,
        initial_balance: float = 100000,
        transaction_cost: float = 0.001,
        max_position: float = 1.0
    ):
        """
        Args:
            prices: 價格數據
            initial_balance: 初始資金
            transaction_cost: 交易成本
            max_position: 最大倉位比例
        """
        self.prices = prices
        self.initial_balance = initial_balance
        self.transaction_cost = transaction_cost
        self.max_position = max_position
        
        self.reset()
    
    def reset(self) -> np.ndarray:
        """重置環境"""
        self.current_step = 0
        self.balance = self.initial_balance
        self.position = 0
        self.total_profit = 0
        self.trade_history = []
        
        return self._get_state()
    
    def _get_state(self) -> np.ndarray:
        """獲取當前狀態"""
        # 價格歷史（最近20天）
        lookback = 20
        start_idx = max(0, self.current_step - lookback)
        price_history = self.prices.iloc[start_idx:self.current_step + 1]
        
        if len(price_history) < lookback + 1:
            # 填充
            padding = lookback + 1 - len(price_history)
            price_history = pd.concat([
                pd.DataFrame([price_history.iloc[0]] * padding),
                price_history
            ])
        
        # 標準化價格
        normalized_prices = price_history["Close"].values / price_history["Close"].iloc[0]
        
        # 額外特徵
        returns = price_history["Close"].pct_change().fillna(0).values
        volatility = np.std(returns) if len(returns) > 1 else 0
        
        state = np.array([
            self.balance / self.initial_balance,
            self.position,
            normalized_prices[-1],
            returns[-1] if len(returns) > 0 else 0,
            volatility
        ])
        
        return state
    
    def step(self, action: int) -> Tuple[np.ndarray, float, bool]:
        """
        執行動作
        
        Actions:
            0: Hold
            1: Buy
            2: Sell
        
        Returns:
            (next_state, reward, done)
        """
        current_price = self.prices.iloc[self.current_step]["Close"]
        
        # 執行動作
        if action == 1:  # Buy
            if self.balance > 0:
                buy_amount = min(self.balance * 0.1, self.balance)  # 買10%
                shares = buy_amount / current_price * (1 - self.transaction_cost)
                self.position += shares
                self.balance -= buy_amount
                self.trade_history.append(("BUY", current_price, shares))
        
        elif action == 2:  # Sell
            if self.position > 0:
                sell_amount = self.position * 0.1  # 賣10%
                proceeds = sell_amount * current_price * (1 - self.transaction_cost)
                self.position -= sell_amount
                self.balance += proceeds
                self.trade_history.append(("SELL", current_price, sell_amount))
        
        # 前進一步
        self.current_step += 1
        done = self.current_step >= len(self.prices) - 1
        
        # 計算獎勵
        portfolio_value = self.balance + self.position * current_price
        reward = (portfolio_value - self.initial_balance) / self.initial_balance
        
        next_state = self._get_state() if not done else None
        
        return next_state, reward, done
    
    def render(self):
        """渲染環境（打印狀態）"""
        current_price = self.prices.iloc[self.current_step]["Close"]
        portfolio_value = self.balance + self.position * current_price
        
        print(f"Step: {self.current_step}, Price: {current_price:.2f}, "
              f"Position: {self.position:.2f}, Balance: {self.balance:.2f}, "
              f"Portfolio: {portfolio_value:.2f}")


class DQNetwork(nn.Module if HAS_TORCH else object):
    """Deep Q-Network"""
    
    def __init__(self, state_size: int, action_size: int, hidden_size: int = 64):
        if not HAS_TORCH:
            raise ImportError("PyTorch required")
        
        super().__init__()
        
        self.fc1 = nn.Linear(state_size, hidden_size)
        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.fc3 = nn.Linear(hidden_size, action_size)
        
        self.optimizer = optim.Adam(self.parameters(), lr=0.001)
        self.loss_fn = nn.MSELoss()
    
    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return self.fc3(x)
    
    def train_step(
        self,
        states: torch.Tensor,
        actions: torch.Tensor,
        rewards: torch.Tensor,
        next_states: torch.Tensor,
        dones: torch.Tensor,
        gamma: float = 0.99
    ):
        """訓練一步"""
        # 當前 Q 值
        current_q = self.forward(states).gather(1, actions.unsqueeze(1))
        
        # 目標 Q 值
        with torch.no_grad():
            next_q = self.forward(next_states).max(1)[0]
            target_q = rewards + gamma * next_q * (1 - dones)
        
        # 損失
        loss = self.loss_fn(current_q.squeeze(), target_q)
        
        # 更新
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()
        
        return loss.item()


class RLTradingAgent:
    """
    強化學習交易代理
    """
    
    def __init__(
        self,
        state_size: int,
        action_size: int = 3,  # Hold, Buy, Sell
        memory_size: int = 10000,
        batch_size: int = 32,
        gamma: float = 0.99,
        epsilon: float = 1.0,
        epsilon_decay: float = 0.995,
        epsilon_min: float = 0.01
    ):
        """
        Args:
            state_size: 狀態空間大小
            action_size: 動作空間大小
            memory_size: 經驗回放記憶大小
            batch_size: 批次大小
            gamma: 折扣因子
            epsilon: 探索率
        """
        self.state_size = state_size
        self.action_size = action_size
        self.gamma = gamma
        self.epsilon = epsilon
        self.epsilon_decay = epsilon_decay
        self.epsilon_min = epsilon_min
        self.batch_size = batch_size
        
        # 經驗回放
        self.memory = deque(maxlen=memory_size)
        
        # Q 網絡
        if HAS_TORCH:
            self.q_network = DQNetwork(state_size, action_size)
            self.target_network = DQNetwork(state_size, action_size)
            self.update_target_network()
    
    def update_target_network(self):
        """更新目標網絡"""
        if HAS_TORCH:
            self.target_network.load_state_dict(self.q_network.state_dict())
    
    def remember(
        self,
        state: np.ndarray,
        action: int,
        reward: float,
        next_state: np.ndarray,
        done: bool
    ):
        """存儲經驗"""
        self.memory.append((state, action, reward, next_state, done))
    
    def act(self, state: np.ndarray, training: bool = True) -> int:
        """
        選擇動作
        
        epsilon-greedy 策略
        """
        if not HAS_TORCH:
            # 隨機動作
            return random.randint(0, self.action_size - 1)
        
        if training and random.random() < self.epsilon:
            return random.randint(0, self.action_size - 1)
        
        state_tensor = torch.FloatTensor(state).unsqueeze(0)
        
        with torch.no_grad():
            q_values = self.q_network(state_tensor)
        
        return q_values.argmax().item()
    
    def replay(self):
        """經驗回放訓練"""
        if not HAS_TORCH or len(self.memory) < self.batch_size:
            return 0
        
        batch = random.sample(self.memory, self.batch_size)
        
        states = torch.FloatTensor(np.array([e[0] for e in batch]))
        actions = torch.LongTensor([e[1] for e in batch])
        rewards = torch.FloatTensor([e[2] for e in batch])
        next_states = torch.FloatTensor(np.array([e[3] for e in batch]))
        dones = torch.FloatTensor([e[4] for e in batch])
        
        loss = self.q_network.train_step(
            states, actions, rewards, next_states, dones, self.gamma
        )
        
        # 衰減 epsilon
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
        
        return loss
    
    def train(
        self,
        env: TradingEnvironment,
        episodes: int = 100,
        update_freq: int = 10
    ) -> Dict:
        """
        訓練代理
        
        Returns:
            訓練歷史
        """
        history = {
            "episodes": [],
            "rewards": [],
            "profits": []
        }
        
        for episode in range(episodes):
            state = env.reset()
            total_reward = 0
            done = False
            
            while not done:
                action = self.act(state)
                next_state, reward, done = env.step(action)
                
                self.remember(state, action, reward, next_state, done)
                
                # 訓練
                loss = self.replay()
                
                state = next_state
                total_reward += reward
            
            # 定期更新目標網絡
            if episode % update_freq == 0:
                self.update_target_network()
            
            history["episodes"].append(episode)
            history["rewards"].append(total_reward)
            
            portfolio_value = env.balance + env.position * env.prices.iloc[env.current_step]["Close"]
            profit = (portfolio_value - env.initial_balance) / env.initial_balance
            history["profits"].append(profit)
            
            if (episode + 1) % 10 == 0:
                logger.info(f"Episode {episode+1}/{episodes}, "
                          f"Profit: {profit:.2%}, Epsilon: {self.epsilon:.3f}")
        
        return history
    
    def evaluate(
        self,
        env: TradingEnvironment,
        episodes: int = 10
    ) -> Dict:
        """評估代理"""
        profits = []
        
        for _ in range(episodes):
            state = env.reset()
            done = False
            
            while not done:
                action = self.act(state, training=False)
                next_state, _, done = env.step(action)
                state = next_state
            
            current_price = env.prices.iloc[env.current_step]["Close"]
            portfolio_value = env.balance + env.position * current_price
            profit = (portfolio_value - env.initial_balance) / env.initial_balance
            profits.append(profit)
        
        return {
            "mean_profit": np.mean(profits),
            "std_profit": np.std(profits),
            "max_profit": np.max(profits),
            "min_profit": np.min(profits)
        }


class PolicyGradientAgent:
    """
    Policy Gradient 代理
    """
    
    def __init__(
        self,
        state_size: int,
        action_size: int = 3,
        learning_rate: float = 0.001
    ):
        self.state_size = state_size
        self.action_size = action_size
        
        if HAS_TORCH:
            self.policy_network = nn.Sequential(
                nn.Linear(state_size, 64),
                nn.ReLU(),
                nn.Linear(64, 64),
                nn.ReLU(),
                nn.Linear(64, action_size),
                nn.Softmax(dim=-1)
            )
            self.optimizer = optim.Adam(self.policy_network.parameters(), lr=learning_rate)
    
    def get_action(self, state: np.ndarray) -> int:
        """選擇動作"""
        if not HAS_TORCH:
            return random.randint(0, self.action_size - 1)
        
        state_tensor = torch.FloatTensor(state).unsqueeze(0)
        
        with torch.no_grad():
            probs = self.policy_network(state_tensor)
        
        action = torch.multinomial(probs, 1).item()
        return action
    
    def update(self, states, actions, rewards):
        """更新策略"""
        if not HAS_TORCH:
            return
        
        # 計算回報
        returns = []
        G = 0
        for r in reversed(rewards):
            G = r + 0.99 * G
            returns.insert(0, G)
        
        returns = torch.FloatTensor(returns)
        
        # 標準化
        returns = (returns - returns.mean()) / (returns.std() + 1e-9)
        
        # 計算損失
        states = torch.FloatTensor(np.array(states))
        actions = torch.LongTensor(actions)
        
        probs = self.policy_network(states)
        log_probs = torch.log(probs.gather(1, actions.unsqueeze(1)) + 1e-8)
        
        loss = -(log_probs.squeeze() * returns).mean()
        
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()


# 便捷函數
def train_rl_trader(
    prices: pd.DataFrame,
    initial_capital: float = 100000,
    episodes: int = 100
) -> Dict:
    """
    便捷函數：訓練 RL 交易員
    
    Example:
        >>> result = train_rl_trader(price_data, episodes=100)
    """
    # 創建環境
    env = TradingEnvironment(prices, initial_capital)
    
    # 創建代理
    agent = RLTradingAgent(state_size=5, action_size=3)
    
    # 訓練
    history = agent.train(env, episodes=episodes)
    
    # 評估
    eval_result = agent.evaluate(env)
    
    return {
        "training_history": history,
        "evaluation": eval_result
    }
