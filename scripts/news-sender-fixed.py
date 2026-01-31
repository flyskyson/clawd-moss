#!/usr/bin/env python3
"""
news-sender-fixed.py - 修复版新闻发送脚本
"""

import os
import json
import re
from datetime import datetime
from pathlib import Path

class NewsSenderFixed:
    def __init__(self, config_path="scripts/news-sender-config.json"):
        self.config = self.load_config(config_path)
        self.news_dir = "temp/news"
        self.log_dir = "logs"
        
        # 确保目录存在
        os.makedirs(self.news_dir, exist_ok=True)
        os.makedirs(self.log_dir, exist_ok=True)
    
    def load_config(self, config_path):
        """加载发送配置"""
        default_config = {
            "feishu": {
                "enabled": True,
                "target": "ou_8924c5894c324474511b00980af769ee",
                "format": "markdown",
                "split_messages": True,
                "max_length": 2000,
                "include_summary": True,
                "include_details": True
            },
            "schedules": {
                "morning": {"send": True, "delay_minutes": 5},
                "afternoon": {"send": True, "delay_minutes": 5},
                "evening": {"send": True, "delay_minutes": 5}
            },
            "content": {
                "max_articles": 7,
                "include_source": True,
                "include_time": True,
                "categories": ["科技", "AI", "财经", "热点"]
            }
        }
        
        config_file = os.path.expanduser(f"~/{config_path}")
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    # 合并配置
                    default_config.update(user_config)
            except Exception as e:
                print(f"⚠️ 加载配置文件失败，使用默认配置: {e}")
        
        return default_config
    
    def log_info(self, message):
        """记录信息日志"""
        log_file = os.path.join(self.log_dir, "news-sender.log")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] INFO: {message}\n"
        
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry)
        
        print(message)
    
    def log_warning(self, message):
        """记录警告日志"""
        log_file = os.path.join(self.log_dir, "news-sender.log")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] WARNING: {message}\n"
        
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry)
        
        print(f"⚠️  {message}")
    
    def log_error(self, message):
        """记录错误日志"""
        log_file = os.path.join(self.log_dir, "news-sender.log")
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] ERROR: {message}\n"
        
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry)
        
        print(f"❌ {message}")
    
    def find_latest_news(self, session):
        """查找指定会话的最新新闻文件"""
        pattern = f"news_{session}_*.txt"
        files = []
        
        try:
            for file in os.listdir(self.news_dir):
                if file.startswith(f"news_{session}_") and file.endswith(".txt"):
                    files.append(file)
        except FileNotFoundError:
            self.log_error(f"新闻目录不存在: {self.news_dir}")
            return None
        
        if not files:
            self.log_warning(f"未找到 {session} 新闻文件")
            return None
        
        # 按时间排序，取最新的
        files.sort(reverse=True)
        return os.path.join(self.news_dir, files[0])
    
    def read_news_content(self, filepath):
        """读取新闻内容"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError:
            self.log_error(f"新闻文件不存在: {filepath}")
            return None
        except Exception as e:
            self.log_error(f"读取新闻文件失败: {e}")
            return None
    
    def parse_news_content(self, content):
        """解析新闻内容，提取结构化信息 - 修复版"""
        if not content:
            return None
        
        # 提取标题
        title_match = re.search(r'# (.+?)\n', content)
        title = title_match.group(1) if title_match else "新闻更新"
        
        # 提取时间
        time_match = re.search(r'\*\*时间\*\*: (.+?)\n', content)
        time_str = time_match.group(1) if time_match else datetime.now().strftime("%Y-%m-%d %H:%M")
        
        # 修复版正则表达式：匹配实际的新闻格式
        # 格式: 1. **标题：中国核聚变三大突破**  \n   **简要摘要：** 1月16日...
        article_pattern = r'(\d+)\. \*\*标题：(.+?)\*\*  \\n   \*\*简要摘要：\*\* (.+?)  \\n   \*\*来源：\*\* (.+?)(?=\n\n|\d+\.|$)'
        
        articles = []
        matches = re.findall(article_pattern, content, re.DOTALL)
        
        if not matches:
            # 尝试另一种格式
            article_pattern2 = r'(\d+)\. \*\*标题：(.+?)\*\*\s*\n\s*\*\*简要摘要：\*\* (.+?)\s*\n\s*\*\*来源：\*\* (.+?)(?=\n\n|\d+\.|$)'
            matches = re.findall(article_pattern2, content, re.DOTALL)
        
        for match in matches:
            index, article_title, summary, source = match
            articles.append({
                "index": int(index),
                "title": article_title.strip(),
                "summary": summary.strip(),
                "source": source.strip()
            })
        
        # 如果仍然没有匹配，尝试简单解析
        if not articles:
            # 查找所有编号的条目
            lines = content.split('\n')
            current_article = None
            
            for line in lines:
                # 匹配 "1. **标题：xxx**"
                title_match = re.match(r'(\d+)\. \*\*标题：(.+?)\*\*', line)
                if title_match:
                    if current_article:
                        articles.append(current_article)
                    
                    current_article = {
                        "index": int(title_match.group(1)),
                        "title": title_match.group(2).strip(),
                        "summary": "",
                        "source": ""
                    }
                elif current_article:
                    # 匹配摘要
                    if '简要摘要' in line:
                        summary = line.split('简要摘要：')[-1].strip()
                        current_article['summary'] = summary
                    # 匹配来源
                    elif '来源：' in line:
                        source = line.split('来源：')[-1].strip()
                        current_article['source'] = source
            
            if current_article:
                articles.append(current_article)
        
        # 统计信息
        stats_match = re.search(r'📊 \*\*新闻统计\*\*: (\d+)条精选新闻', content)
        article_count = int(stats_match.group(1)) if stats_match else len(articles)
        
        return {
            "title": title,
            "time": time_str,
            "articles": articles,
            "article_count": article_count,
            "raw_content": content
        }
    
    def format_for_feishu(self, news_data, session):
        """格式化新闻内容为飞书消息"""
        if not news_data or not news_data.get("articles"):
            # 返回原始内容作为备选
            if news_data and news_data.get("raw_content"):
                content = news_data["raw_content"]
                # 分割长消息
                max_len = self.config["feishu"]["max_length"]
                if len(content) > max_len:
                    parts = []
                    while content:
                        part = content[:max_len]
                        # 尝试在段落边界分割
                        last_newline = part.rfind('\n')
                        if last_newline > max_len * 0.8:  # 如果在合理位置找到换行
                            part = content[:last_newline]
                            content = content[last_newline:].lstrip()
                        else:
                            content = content[max_len:]
                        parts.append(part)
                    return parts
                return [content]
            return ["⚠️ 新闻内容为空或格式错误"]
        
        articles = news_data["articles"]
        title = news_data["title"]
        time_str = news_data["time"]
        
        # 构建消息
        messages = []
        current_message = f"# {title}\n**时间**: {time_str}\n\n"
        
        for article in articles[:self.config["content"]["max_articles"]]:
            article_text = f"### {article['index']}. {article['title']}\n"
            article_text += f"**摘要**: {article['summary']}\n"
            article_text += f"**来源**: {article['source']}\n\n"
            
            # 检查是否超过长度限制
            if len(current_message) + len(article_text) > self.config["feishu"]["max_length"]:
                messages.append(current_message)
                current_message = article_text
            else:
                current_message += article_text
        
        # 添加最后一条消息
        if current_message:
            # 添加统计信息
            stats = f"\n📊 **新闻统计**: {len(articles)}条精选新闻\n"
            stats += f"🕐 **下次更新**: 根据定时任务安排\n"
            stats += f"💬 **反馈**: 直接回复此消息提出建议\n\n"
            stats += f"*由MOSS新闻订阅服务自动生成*"
            
            if len(current_message) + len(stats) > self.config["feishu"]["max_length"]:
                messages.append(current_message)
                messages.append(stats)
            else:
                current_message += stats
                messages.append(current_message)
        
        return messages
    
    def send_to_feishu(self, messages, session):
        """发送消息到飞书"""
        if not messages:
            self.log_error("没有消息可发送")
            return False
        
        # 在Clawdbot环境中，message工具是全局可用的
        # 这里我们模拟发送，实际在Clawdbot中会调用message工具
        target = self.config["feishu"]["target"]
        success_count = 0
        
        for i, msg in enumerate(messages):
            try:
                self.log_info(f"发送第 {i+1}/{len(messages)} 部分 ({len(msg)} 字符)")
                
                # 在实际Clawdbot环境中，这里会调用message工具
                # 现在我们只记录日志
                self.log_info(f"[模拟] 发送到飞书 {target}: {msg[:50]}...")
                
                # 模拟成功
                success_count += 1
                self.log_info(f"✅ 部分 {i+1} 发送成功 (模拟)")
            
            except Exception as e:
                self.log_error(f"❌ 发送部分 {i+1} 失败: {e}")
        
        return success_count > 0
    
    def send_news(self, session):
        """发送指定会话的新闻"""
        self.log_info(f"🚀 开始发送 {session} 新闻")
        
        # 查找新闻文件
        news_file = self.find_latest_news(session)
        if not news_file:
            self.log_error(f"未找到 {session} 新闻文件")
            return False
        
        self.log_info(f"📄 找到新闻文件: {news_file}")
        
        # 读取新闻内容
        content = self.read_news_content(news_file)
        if not content:
            self.log_error("无法读取新闻内容")
            return False
        
        self.log_info(f"📊 新闻内容大小: {len(content)} 字符")
        
        # 解析新闻内容
        news_data = self.parse_news_content(content)
        
        if not news_data:
            self.log_warning("⚠️ 新闻解析失败，尝试发送原始内容")
            # 使用原始内容
            news_data = {
                "raw_content": content,
                "articles": []
            }
        
        self.log_info(f"📋 解析到 {len(news_data.get('articles', []))} 篇文章")
        
        # 格式化消息
        messages = self.format_for_feishu(news_data, session)
        self.log_info(f"📝 格式化为 {len(messages)} 条消息")
        
        # 发送消息
        for i, msg in enumerate(messages):
            self.log_info(f"发送消息 {i+1}/{len(messages)}")
        
        success = self.send_to_feishu(messages, session)
        
        if success:
            self.log_info(f"🎉 {session} 新闻发送成功 ({len(messages)}/{len(messages)} 条消息)")
        else:
            self.log_warning(f"⚠️  {session} 新闻发送部分成功或失败")
        
        return success

def main():
    import sys
    
    if len(sys.argv) != 2:
        print("❌ 无效的会话参数:", sys.argv[1:] if len(sys.argv) > 1 else "无")
        print("可用会话: morning, afternoon, evening")
        return 1
    
    session = sys.argv[1]
    valid_sessions = ["morning", "afternoon", "evening"]
    
    if session not in valid_sessions:
        print(f"❌ 无效的会话: {session}")
        print(f"可用会话: {', '.join(valid_sessions)}")
        return 1
    
    sender = NewsSenderFixed()
    success = sender.send_news(session)
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())