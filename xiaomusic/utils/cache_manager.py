#!/usr/bin/env python3
"""
优化后的缓存管理器
为音乐列表、时长信息等添加缓存，提升性能
"""

import asyncio
import json
import os
import pickle
import time
import hashlib
from pathlib import Path
from typing import Any, Optional
from datetime import datetime
import logging


class CacheManager:
    """通用缓存管理器 - 支持内存和文件双重缓存"""

    def __init__(self, cache_dir: str = "/tmp/xiaomusic_cache", default_ttl: int = 3600):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.default_ttl = default_ttl
        self.memory_cache: Dict[str, Dict[str, Any]] = {}
        self.log = logging.getLogger(__name__)

    def _get_cache_key(self, key: str) -> str:
        """生成缓存键的哈希"""
        return hashlib.md5(key.encode()).hexdigest()

    def _get_cache_path(self, key: str) -> Path:
        """获取缓存文件路径"""
        cache_key = self._get_cache_key(key)
        return self.cache_dir / f"{cache_key}.cache"

    async def get(self, key: str, ttl: Optional[int] = None) -> Optional[Any]:
        """获取缓存

        Args:
            key: 缓存键
            ttl: 缓存有效期（秒），默认使用 default_ttl

        Returns:
            缓存数据或 None
        """
        ttl = ttl or self.default_ttl
        current_time = time.time()

        # 先检查内存缓存
        if key in self.memory_cache:
            cache_data = self.memory_cache[key]
            if current_time - cache_data["time"] < cache_data["ttl"]:
                self.log.debug(f"命中内存缓存: {key}")
                return cache_data["data"]
            del self.memory_cache[key]

        # 检查文件缓存
        cache_path = self._get_cache_path(key)
        if cache_path.exists():
            try:
                with open(cache_path, "rb") as f:
                    cache_data = pickle.load(f)

                if current_time - cache_data["time"] < ttl:
                    # 同时更新内存缓存
                    self.memory_cache[key] = cache_data
                    self.log.debug(f"命中文件缓存: {key}")
                    return cache_data["data"]
                else:
                    # 缓存过期
                    cache_path.unlink()
                    self.log.debug(f"缓存过期已删除: {key}")
            except Exception as e:
                self.log.warning(f"读取缓存失败 {key}: {e}")

        return None

    async def set(
        self, key: str, data: Any, ttl: Optional[int] = None
    ) -> None:
        """设置缓存

        Args:
            key: 缓存键
            data: 缓存数据
            ttl: 缓存有效期（秒），默认使用 default_ttl
        """
        ttl = ttl or self.default_ttl
        cache_data = {
            "data": data,
            "time": time.time(),
            "ttl": ttl,
        }

        # 保存到内存
        self.memory_cache[key] = cache_data

        # 保存到文件
        cache_path = self._get_cache_path(key)
        try:
            with open(cache_path, "wb") as f:
                pickle.dump(cache_data, f)
            self.log.debug(f"已缓存: {key}")
        except Exception as e:
            self.log.warning(f"保存缓存失败 {key}: {e}")

    async def clear(self, key: Optional[str] = None) -> None:
        """清除缓存

        Args:
            key: 指定键，None 表示清除所有
        """
        if key:
            # 清除指定键
            if key in self.memory_cache:
                del self.memory_cache[key]
            cache_path = self._get_cache_path(key)
            if cache_path.exists():
                cache_path.unlink()
            self.log.info(f"已清除缓存: {key}")
        else:
            # 清除所有缓存
            self.memory_cache.clear()
            for cache_file in self.cache_dir.glob("*.cache"):
                try:
                    cache_file.unlink()
                except Exception as e:
                    self.log.warning(f"删除缓存文件失败: {e}")
            self.log.info("已清除所有缓存")

    def cleanup(self) -> None:
        """清理过期缓存（同步方法，适合在后台任务中调用）"""
        current_time = time.time()
        cleaned = 0

        for cache_file in self.cache_dir.glob("*.cache"):
            try:
                with open(cache_file, "rb") as f:
                    cache_data = pickle.load(f)

                if current_time - cache_data["time"] > cache_data["ttl"]:
                    cache_file.unlink()
                    cleaned += 1
            except Exception:
                # 损坏的缓存文件也删除
                try:
                    cache_file.unlink()
                    cleaned += 1
                except Exception:
                    pass

        if cleaned > 0:
            self.log.info(f"清理了 {cleaned} 个过期缓存")


class MusicListCache:
    """音乐列表专用缓存"""

    # 音乐列表缓存 2 小时
    MUSIC_LIST_TTL = 7200

    # 歌曲时时长缓存 1 天
    DURATION_TTL = 86400

    def __init__(self, cache_manager: CacheManager):
        self.cache = cache_manager
        self.log = logging.getLogger(__name__)

    async def get_all_music(self, force_refresh: bool = False) -> Optional[list]:
        """获取全部音乐列表

        Args:
            force_refresh: 是否强制刷新

        Returns:
            音乐列表或 None
        """
        if force_refresh:
            await self.cache.clear("all_music_list")
            self.log.info("强制刷新音乐列表缓存")
        return await self.cache.get("all_music_list", ttl=self.MUSIC_LIST_TTL)

    async def set_all_music(self, music_list: list) -> None:
        """设置全部音乐列表

        Args:
            music_list: 音乐列表
        """
        await self.cache.set("all_music_list", music_list, ttl=self.MUSIC_LIST_TTL)
        self.log.info(f"已缓存音乐列表: {len(music_list)} 首歌曲")

    async def get_duration(self, filename: str) -> Optional[float]:
        """获取歌曲时长

        Args:
            filename: 文件名

        Returns:
            时长（秒）或 None
        """
        return await self.cache.get(f"duration:{filename}", ttl=self.DURATION_TTL)

    async def set_duration(self, filename: str, duration: float) -> None:
        """设置歌曲时长

        Args:
            filename: 文件名
            duration: 时长（秒）
        """
        await self.cache.set(
            f"duration:{filename}", duration, ttl=self.DURATION_TTL
        )
        self.log.debug(f"已缓存时长: {filename} = {duration}s")

    async def get_duration_batch(self, filenames: list) -> dict:
        """批量获取歌曲时长

        Args:
            filenames: 文件名列表

        Returns:
            文件名到时长的映射
        """
        result = {}
        uncached = []

        # 先从缓存获取
        for filename in filenames:
            duration = await self.get_duration(filename)
            if duration is not None:
                result[filename] = duration
            else:
                uncached.append(filename)

        result["uncached"] = uncached
        return result


# 全局单例
_cache_manager: Optional[CacheManager] = None
_music_list_cache: Optional[MusicListCache] = None


def get_cache_manager(config_path: str = "/tmp/xiaomusic_cache") -> CacheManager:
    """获取全局缓存管理器单例"""
    global _cache_manager
    if _cache_manager is None:
        _cache_manager = CacheManager(cache_dir=config_path)
    return _cache_manager


def get_music_list_cache() -> MusicListCache:
    """获取全局音乐列表缓存单例"""
    global _music_list_cache
    if _music_list_cache is None:
        _music_list_cache = MusicListCache(get_cache_manager())
    return _music_list_cache
