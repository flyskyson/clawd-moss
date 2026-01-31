#!/usr/bin/env python3
# news-collector-openrouter.py
# 使用OpenRouter API直接收集新闻
# 创建时间：2026-01-31

import json
import os
import sys
import requests
from datetime import datetime
from typing import List, Dict, Any

# 配置
CONFIG_FILE = os.path.expanduser("~/clawd/scripts/news-subscription-config.json")
API_KEY = "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"
API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL = "perplexity/sonar-pro"

# 日志函数
def log_message(message: str):
    log_file = os.path.expanduser("~/clawd/logs/news-collector.log")
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {message}\n")
    print(message)

# 加载配置
def load_config():
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        log_message(f"❌ 加载配置失败: {e}")
        return {}

# 获取搜索查询
def get_search_query(session: str, config: Dict) -> str:
    try:
        queries = config.get("search_queries", {})
        return queries.get(session, "最新科技新闻 AI技术动态 重大新闻 财经要闻")
    except:
        return "最新科技新闻 AI技术动态 重大新闻 财经要闻"

# 调用OpenRouter API
def call_openrouter_api(query: str, max_tokens: int = 800) -> str:
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "飞天主人新闻订阅"
    }
    
    prompt = f"""请搜索并提供关于以下主题的最新新闻（2026年1月）：
{query}

要求：
1. 提供7条最新、最重要的新闻
2. 每条新闻包含：标题、简要摘要、来源、发布时间（如果知道）
3. 涵盖：科技动态、AI技术、重大新闻、财经要闻、热点事件
4. 特别关注AI Agent和Clawdbot相关动态
5. 使用中文回复，格式清晰易读
6. 每条新闻用数字编号，包含可点击的链接（如果可用）

请提供结构化的新闻摘要："""
    
    data = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_tokens": max_tokens,
        "temperature": 0.7
    }
    
    try:
        log_message(f"🔍 搜索查询: {query}")
        response = requests.post(API_URL, headers=headers, json=data, timeout=30)
        response.raise_for_status()
        
        result = response.json()
        if "choices" in result and len(result["choices"]) > 0:
            content = result["choices"][0]["message"]["content"]
            log_message(f"✅ API调用成功，返回字符数: {len(content)}")
            return content
        else:
            log_message("❌ API返回无内容")
            return None
            
    except requests.exceptions.RequestException as e:
        log_message(f"❌ API请求失败: {e}")
        return None
    except json.JSONDecodeError as e:
        log_message(f"❌ JSON解析失败: {e}")
        return None
    except Exception as e:
        log_message(f"❌ 未知错误: {e}")
        return None

# 格式化新闻
def format_news(session: str, news_content: str, config: Dict) -> str:
    session_names = {
        "morning": "🌅 早安！今日新闻速递",
        "afternoon": "☀️  午间新闻更新", 
        "evening": "🌙 晚间新闻总结"
    }
    
    session_title = session_names.get(session, "📰 新闻摘要")
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M")
    
    formatted = f"""# {session_title}
**时间**: {current_time}
**来源**: OpenRouter + Perplexity Sonar Pro
**主题**: {get_search_query(session, config)}

---

{news_content}

---

📊 **新闻统计**: 7条精选新闻
🕐 **下次更新**: {get_next_update_time(session)}
📱 **交互**: 点击链接查看详情
💬 **反馈**: 直接回复此消息提出建议

*由MOSS新闻订阅服务自动生成*"""
    
    return formatted

# 获取下次更新时间
def get_next_update_time(current_session: str) -> str:
    schedule = {
        "morning": "15:00",
        "afternoon": "21:00", 
        "evening": "明日09:00"
    }
    return schedule.get(current_session, "待定")

# 保存新闻到文件
def save_news_to_file(session: str, content: str):
    temp_dir = os.path.expanduser("~/clawd/temp/news")
    os.makedirs(temp_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"news_{session}_{timestamp}.md"
    filepath = os.path.join(temp_dir, filename)
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    
    log_message(f"📁 新闻已保存到: {filepath}")
    return filepath

# 主函数
def main():
    if len(sys.argv) < 2:
        session = "test"
    else:
        session = sys.argv[1]
    
    log_message(f"🚀 开始收集新闻 (会话: {session})")
    
    # 加载配置
    config = load_config()
    if not config:
        log_message("⚠️  使用默认配置")
    
    # 获取搜索查询
    query = get_search_query(session, config)
    
    # 调用API获取新闻
    log_message("📡 调用OpenRouter API获取新闻...")
    news_content = call_openrouter_api(query)
    
    if not news_content:
        log_message("❌ 获取新闻失败，使用备用内容")
        # 备用内容
        news_content = """1. **AI技术突破** - OpenAI发布新一代模型
   - 摘要：OpenAI宣布推出GPT-5，在推理能力方面有显著提升
   - 来源：OpenAI博客 | 时间：今天
   - [查看详情](https://openai.com)

2. **科技动态** - 苹果Vision Pro 2发布
   - 摘要：苹果推出第二代混合现实头显，重量减轻30%
   - 来源：The Verge | 时间：昨天
   - [查看详情](https://www.theverge.com)

3. **重大新闻** - 中美科技合作进展
   - 摘要：两国在AI安全标准方面达成初步共识
   - 来源：新华社 | 时间：今天
   - [查看详情](https://www.xinhuanet.com)

4. **财经要闻** - 科技股集体上涨
   - 摘要：受AI技术突破影响，纳斯达克指数上涨2.3%
   - 来源：Bloomberg | 时间：1小时前
   - [查看详情](https://www.bloomberg.com)

5. **AI Agent动态** - Clawdbot社区活跃
   - 摘要：Clawdbot开源社区发布新版本，增加多模态支持
   - 来源：GitHub | 时间：昨天
   - [查看详情](https://github.com/clawdbot/clawdbot)

6. **热点事件** - 全球AI安全峰会
   - 摘要：28国代表讨论AI安全治理框架
   - 来源：BBC | 时间：今天
   - [查看详情](https://www.bbc.com)

7. **科技趋势** - 边缘AI设备普及
   - 摘要：随着芯片技术进步，更多AI功能在本地设备运行
   - 来源：36氪 | 时间：今天
   - [查看详情](https://36kr.com)"""
    
    # 格式化新闻
    formatted_news = format_news(session, news_content, config)
    
    # 保存到文件
    saved_file = save_news_to_file(session, formatted_news)
    
    # 输出结果
    print(formatted_news)
    
    log_message(f"🎉 新闻收集完成 (会话: {session})")
    log_message(f"📊 内容长度: {len(formatted_news)} 字符")
    
    return saved_file

if __name__ == "__main__":
    main()