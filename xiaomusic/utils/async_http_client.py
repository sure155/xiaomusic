#!/usr/bin/env python3
"""
优化后的异步 HTTP 客户端
替换同步的 requests 库
"""

import asyncio
import logging
from typing import Optional, Dict, List, Any

import aiohttp


class AsyncHttpClient:
    """异步 HTTP 客户端封装"""

    def __init__(self, timeout: int = 30):
        self.timeout = aiohttp.ClientTimeout(total=timeout)
        self.log = logging.getLogger(__name__)

    async def get(
        self, url: str, headers: Optional[Dict[str, str]] = None, json_data: bool = False
    ) -> Optional[Dict[str, Any]]:
        """异步 GET 请求

        Args:
            url: 请求 URL
            headers: 请求头
            json_data: 是否返回 JSON 格式

        Returns:
            响应数据或 None
        """
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                async with session.get(url, headers=headers) as resp:
                    if resp.status == 200:
                        if json_data:
                            return await resp.json()
                        return await resp.text()
                    self.log.warning(f"GET {url} 失败: HTTP {resp.status}")
                    return None
        except asyncio.TimeoutError:
            self.log.error(f"GET {url} 超时")
            return None
        except Exception as e:
            self.log.error(f"GET {url} 异常: {e}")
            return None

    async def post(
        self, url: str, data: Optional[Dict[str, Any]] = None, json: bool = True
    ) -> Optional[Dict[str, Any]]:
        """异步 POST 请求

        Args:
            url: 请求 URL
            data: 请求数据
            json: 是否使用 JSON 格式

        Returns:
            响应数据或 None
        """
        try:
            async with aiohttp.ClientSession(timeout=self.timeout) as session:
                if json:
                    async with session.post(url, json=data) as resp:
                        if resp.status == 200:
                            return await resp.json()
                        self.log.warning(f"POST {url} 失败: HTTP {resp.status}")
                        return None
                else:
                    async with session.post(url, data=data) as resp:
                        if resp.status == 200:
                            return await resp.text()
                        self.log.warning(f"POST {url} 失败: HTTP {resp.status}")
                        return None
        except asyncio.TimeoutError:
            self.log.error(f"POST {url} 超时")
            return None
        except Exception as e:
            self.log.error(f"POST {url} 异常: {e}")
            return None

    async def batch_get(
        self, urls: List[str], headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Optional[Any]]:
        """批量 GET 请求（并发）

        Args:
            urls: URL 列表
            headers: 请求头

        Returns:
            URL 到响应数据的映射
        """
        tasks = [self.get(url, headers) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        return dict(zip(urls, results))


# 全局单例
_http_client: Optional[AsyncHttpClient] = None


def get_http_client() -> AsyncHttpClient:
    """获取全局 HTTP 客户端单例"""
    global _http_client
    if _http_client is None:
        _http_client = AsyncHttpClient()
    return _http_client
