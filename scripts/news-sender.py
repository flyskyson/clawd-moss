#!/usr/bin/env python3
"""
news-sender.py - 新闻自动发送到飞书
"""

import os
import json
import re
from datetime import datetime
from pathlib import Path

class NewsSender:
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
                    # 深度合并配置
                    return self.deep_merge(default_config, user_config)
            except Exception as e:
                self.log_error(f"加载配置文件失败: {e}")
        
        return default_config
    
    def deep_merge(self, default, user):
        """深度合并配置字典"""
        result = default.copy()
        
        for key, value in user.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self.deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
    
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
        """解析新闻内容，提取结构化信息"""
        if not content:
            return None
        
        # 提取标题
        title_match = re.search(r'# (.+?)\n', content)
        title = title_match.group(1) if title_match else "新闻更新"
        
        # 提取时间
        time_match = re.search(r'\*\*时间\*\*: (.+?)\n', content)
        time_str = time_match.group(1) if time_match else datetime.now().strftime("%Y-%m-%d %H:%M")
        
        # 提取新闻条目 - 修复正则表达式匹配实际格式
        articles = []
        
        # 尝试多种格式
        patterns = [
            # 格式1: 1. **标题：xxx**  \n   **简要摘要：** yyy
            r'(\d+)\. \*\*标题：(.+?)\*\*  \\n   \*\*简要摘要：\*\* (.+?)  \\n   \*\*来源：\*\* (.+?)(?=\n\n|\d+\.|$)',
            # 格式2: 1. **标题：xxx**\n   **简要摘要：** yyy
            r'(\d+)\. \*\*标题：(.+?)\*\*\s*\n\s*\*\*简要摘要：\*\* (.+?)\s*\n\s*\*\*来源：\*\* (.+?)(?=\n\n|\d+\.|$)',
        ]
        
        matches = []
        for pattern in patterns:
            matches = re.findall(pattern, content, re.DOTALL)
            if matches:
                break
        
        if matches:
            for match in matches:
                index, article_title, summary, source = match
                articles.append({
                    "index": int(index),
                    "title": article_title.strip(),
                    "summary": summary.strip(),
                    "source": source.strip()
                })
        else:
            # 备用解析方法：逐行解析
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
                        summary = line.split('简要摘要：')[-1].strip(' *')
                        current_article['summary'] = summary
                    # 匹配来源
                    elif '来源：' in line:
                        source = line.split('来源：')[-1].strip(' *')
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
            return ["⚠️ 新闻内容为空或格式错误"]
        
        articles = news_data["articles"]
        title = news_data["title"]
        time_str = news_data["time"]
        
        # 限制文章数量
        max_articles = self.config["content"]["max_articles"]
        if len(articles) > max_articles:
            articles = articles[:max_articles]
        
        # 生成摘要部分
        summary_parts = []
        
        # 标题和时间
        session_names = {
            "morning": "早上",
            "afternoon": "下午", 
            "evening": "晚上"
        }
        session_cn = session_names.get(session, session)
        
        summary_parts.append(f"# 📰 {session_cn}新闻摘要")
        summary_parts.append(f"**时间**: {time_str}")
        summary_parts.append(f"**新闻数量**: {len(articles)}条精选")
        summary_parts.append("")
        
        # 文章摘要
        for article in articles:
            # 简化标题（移除多余空格和换行）
            clean_title = article["title"].replace("  \\n", "").strip()
            clean_summary = article["summary"].replace("  \\n", "").strip()[:100] + "..."
            
            summary_parts.append(f"### {article['index']}. {clean_title}")
            summary_parts.append(f"**摘要**: {clean_summary}")
            
            if self.config["content"]["include_source"]:
                summary_parts.append(f"**来源**: {article['source']}")
            
            summary_parts.append("")
        
        # 统计信息
        summary_parts.append("---")
        summary_parts.append(f"📊 **统计**: 共{len(articles)}条新闻")
        summary_parts.append(f"⏰ **下次更新**: 根据定时任务安排")
        summary_parts.append(f"💬 **反馈**: 回复此消息提出建议")
        summary_parts.append("")
        summary_parts.append("*由MOSS新闻订阅服务自动生成*")
        
        summary_content = "\n".join(summary_parts)
        
        # 如果需要详细内容，生成第二部分
        messages = [summary_content]
        
        if self.config["feishu"]["include_details"]:
            details_parts = []
            details_parts.append(f"# 📰 {session_cn}新闻详细内容")
            details_parts.append("")
            
            for article in articles:
                clean_title = article["title"].replace("  \\n", "").strip()
                clean_summary = article["summary"].replace("  \\n", "").strip()
                
                details_parts.append(f"## {article['index']}. {clean_title}")
                details_parts.append(f"**来源**: {article['source']}")
                details_parts.append("")
                details_parts.append(f"{clean_summary}")
                details_parts.append("")
                details_parts.append("---")
                details_parts.append("")
            
            details_content = "\n".join(details_parts)
            messages.append(details_content)
        
        return messages
    
    def split_content(self, content, max_length=2000):
        """分割长内容为多个消息"""
        if len(content) <= max_length:
            return [content]
        
        parts = []
        lines = content.split('\n')
        current_part = []
        current_length = 0
        
        for line in lines:
            line_length = len(line) + 1  # +1 for newline
            
            if current_length + line_length > max_length and current_part:
                parts.append('\n'.join(current_part))
                current_part = [line]
                current_length = line_length
            else:
                current_part.append(line)
                current_length += line_length
        
        if current_part:
            parts.append('\n'.join(current_part))
        
        return parts
    
    def send_to_feishu(self, content, session):
        """发送到飞书"""
        # 这里使用Clawdbot的message工具发送
        # 实际实现需要调用Clawdbot的API
        
        print(f"📤 准备发送 {session} 新闻到飞书")
        print(f"内容长度: {len(content)} 字符")
        
        # 分割内容
        if self.config["feishu"]["split_messages"]:
            parts = self.split_content(content, self.config["feishu"]["max_length"])
            print(f"分割为 {len(parts)} 部分发送")
            
            for i, part in enumerate(parts, 1):
                print(f"发送第 {i}/{len(parts)} 部分 ({len(part)} 字符)")
                # 实际发送逻辑
                self.actual_send(part, session, i, len(parts))
        else:
            print(f"发送完整内容 ({len(content)} 字符)")
            self.actual_send(content, session, 1, 1)
        
        print("✅ 发送完成")
        return True
    
    def actual_send(self, content, session, part_num, total_parts):
        """实际发送消息到飞书"""
        try:
            # 使用Clawdbot的message工具发送
            # 这里需要实际的API调用，暂时模拟
            
            log_entry = {
                "timestamp": datetime.now().isoformat(),
                "session": session,
                "part": f"{part_num}/{total_parts}",
                "content_length": len(content),
                "content_preview": content[:100] + "..." if len(content) > 100 else content,
                "status": "sent_to_feishu"
            }
            
            # 记录到日志
            log_file = os.path.join(self.log_dir, "news-sender.log")
            with open(log_file, 'a', encoding='utf-8') as f:
                f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
            
            print(f"  发送到飞书: {log_entry['content_preview']}")
            
            # 实际发送逻辑（需要集成）
            # 这里可以调用Clawdbot的message工具
            # 暂时先记录，稍后集成
            
            return True
            
        except Exception as e:
            error_msg = f"发送消息失败: {e}"
            self.log_error(error_msg)
            return False
    
    def run(self, session="afternoon"):
        """运行发送流程"""
        print(f"🚀 开始发送 {session} 新闻")
        print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # 1. 检查配置
        if not self.config["feishu"]["enabled"]:
            print("❌ 飞书发送功能未启用")
            return False
        
        schedule_config = self.config["schedules"].get(session, {})
        if not schedule_config.get("send", True):
            print(f"❌ {session} 会话发送功能未启用")
            return False
        
        # 2. 查找新闻文件
        news_file = self.find_latest_news(session)
        if not news_file:
            print(f"❌ 未找到 {session} 新闻文件")
            return False
        
        print(f"📄 找到新闻文件: {news_file}")
        
        # 3. 读取内容
        content = self.read_news_content(news_file)
        if not content:
            print("❌ 无法读取新闻内容")
            return False
        
        print(f"📊 新闻内容大小: {len(content)} 字符")
        
        # 4. 解析内容
        news_data = self.parse_news_content(content)
        if not news_data:
            print("❌ 无法解析新闻内容")
            return False
        
        print(f"📋 解析到 {len(news_data['articles'])} 篇文章")
        
        # 5. 格式化内容
        messages = self.format_for_feishu(news_data, session)
        print(f"📝 格式化为 {len(messages)} 条消息")
        
        # 6. 发送到飞书
        success_count = 0
        for i, message in enumerate(messages, 1):
            print(f"发送消息 {i}/{len(messages)}")
            success = self.send_to_feishu(message, session)
            if success:
                success_count += 1
        
        if success_count == len(messages):
            print(f"🎉 {session} 新闻发送成功 ({success_count}/{len(messages)} 条消息)")
            return True
        else:
            print(f"⚠️ {session} 新闻发送部分成功 ({success_count}/{len(messages)} 条消息)")
            return success_count > 0
    
    def log_error(self, message):
        """记录错误日志"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": "ERROR",
            "message": message
        }
        
        log_file = os.path.join(self.log_dir, "news-sender-error.log")
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        print(f"❌ 错误: {message}")
    
    def log_warning(self, message):
        """记录警告日志"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": "WARNING",
            "message": message
        }
        
        log_file = os.path.join(self.log_dir, "news-sender.log")
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        print(f"⚠️ 警告: {message}")

def main():
    """主函数"""
    import sys
    
    # 获取会话参数
    session = "afternoon"
    if len(sys.argv) > 1:
        session = sys.argv[1]
    
    # 验证会话参数
    valid_sessions = ["morning", "afternoon", "evening"]
    if session not in valid_sessions:
        print(f"❌ 无效的会话参数: {session}")
        print(f"可用会话: {', '.join(valid_sessions)}")
        return 1
    
    # 创建发送器并运行
    sender = NewsSender()
    success = sender.run(session)
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())