/**
 * LRU + TTL Cache for OpenClaw skills
 * 節省重複計算與 API 呼叫，降低 token 消耗
 */
interface CacheEntry<T> {
  value: T;
  expiresAt: number; // ms since epoch
}

export class TimedLRUCache<K, V> {
  private cache: Map<K, CacheEntry<V>>;
  private maxSize: number;
  private defaultTtlMs: number;

  constructor(maxSize: number = 1000, defaultTtlMs: number = 10 * 60 * 1000) {
    this.cache = new Map();
    this.maxSize = maxSize;
    this.defaultTtlMs = defaultTtlMs;
  }

  set(key: K, value: V, ttlMs?: number): void {
    const expiresAt = Date.now() + (ttlMs ?? this.defaultTtlMs);
    // LRU：如果超過大小，移除最舊的
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey !== undefined) this.cache.delete(firstKey);
    }
    this.cache.set(key, { value, expiresAt });
  }

  get(key: K): V | undefined {
    const entry = this.cache.get(key);
    if (!entry) return undefined;
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return undefined;
    }
    // 更新 LRU 順序
    this.cache.delete(key);
    this.cache.set(key, entry);
    return entry.value;
  }

  has(key: K): boolean {
    return this.get(key) !== undefined;
  }

  delete(key: K): boolean {
    return this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size;
  }

  keys(): IterableIterator<K> {
    return this.cache.keys();
  }
}

// 裝飾器：用於技能方法
export function cached<K extends string, T extends (...args: any[]) => any>(ttlMs?: number) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    const cache = new TimedLRUCache<K, any>(200, ttlMs ?? 10 * 60 * 1000);

    descriptor.value = async function (this: any, ...args: any[]): Promise<ReturnType<T>> {
      const key: K = JSON.stringify(args) as K;
      const cachedResult = cache.get(key);
      if (cachedResult !== undefined) {
        return cachedResult;
      }
      const result = await originalMethod.apply(this, args);
      cache.set(key, result, ttlMs);
      return result;
    };
    return descriptor;
  };
}
