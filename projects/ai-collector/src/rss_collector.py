#!/usr/bin/env python3
# rss_collector.py
# AI技术动态RSS收集器

import feedparser
import time
from datetime import datetime
import json
import os

class AITechRSSCollector:
    """AI技术动态RSS收集器"""
    
    def __init__(self, config_file=None):
        """初始化收集器"""
        self.feeds = self.load_feeds(config_file)
        self.articles = []
        
    def load_feeds(self, config_file=None):
        """加载RSS源配置"""
        # 默认的AI技术RSS源
        default_feeds = [
            {
                'name': 'MIT Technology Review AI',
                'url': 'https://www.technologyreview.com/topic/artificial-intelligence/feed/',
                'category': '技术媒体',
                'enabled': True
            },
            {
                'name': 'AI Trends',
                'url': 'https://aitrends.com/feed/',
                'category': '专业媒体',
                'enabled': True
            },
            {
                'name': 'The Batch by deeplearning.ai',
                'url': 'https://www.deeplearning.ai/the-batch/feed/',
                'category': '教育机构',
                'enabled': True
            },
            {
                'name': 'OpenAI Blog',
                'url': 'https://openai.com/blog/rss/',
                'category': '公司博客',
                'enabled': True
            },
            {
                'name': 'Google AI Blog',
                'url': 'https://ai.googleblog.com/feeds/posts/default',
                'category': '公司博客',
                'enabled': True
            }
        ]
        
        # 如果有配置文件，从文件加载
        if config_file and os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    return config.get('feeds', default_feeds)
            except Exception as e:
                print(f"⚠️ 加载配置文件失败: {e}, 使用默认配置")
        
        return default_feeds
    
    def fetch_feed(self, feed_config):
        """获取单个RSS源的内容"""
        try:
            print(f"📡 正在获取: {feed_config['name']}...")
            feed = feedparser.parse(feed_config['url'])
            
            if feed.bozo:
                print(f"⚠️ 解析RSS失败: {feed.bozo_exception}")
                return []
            
            articles = []
            for entry in feed.entries[:10]:  # 每个源最多取10条
                # 提取文章信息
                article = {
                    'title': entry.get('title', '无标题'),
                    'link': entry.get('link', ''),
                    'published': entry.get('published', ''),
                    'summary': entry.get('summary', ''),
                    'content': entry.get('content', [{}])[0].get('value', '') if entry.get('content') else '',
                    'source': feed_config['name'],
                    'category': feed_config['category'],
                    'feed_url': feed_config['url'],
                    'collected_at': datetime.now().isoformat()
                }
                articles.append(article)
            
            print(f"✅ 获取成功: {feed_config['name']} - {len(articles)}篇文章")
            return articles
            
        except Exception as e:
            print(f"❌ 获取失败 {feed_config['name']}: {e}")
            return []
    
    def fetch_all_feeds(self):
        """获取所有启用的RSS源"""
        print("🚀 开始获取AI技术动态...")
        print(f"📊 配置了 {len(self.feeds)} 个RSS源")
        
        all_articles = []
        enabled_count = 0
        
        for feed in self.feeds:
            if not feed.get('enabled', True):
                continue
                
            enabled_count += 1
            articles = self.fetch_feed(feed)
            all_articles.extend(articles)
            
            # 避免请求过快
            time.sleep(1)
        
        print(f"🎯 完成获取: {enabled_count}个源, 共{len(all_articles)}篇文章")
        self.articles = all_articles
        return all_articles
    
    def save_articles(self, output_file=None):
        """保存文章到文件"""
        if not self.articles:
            print("⚠️ 没有文章可保存")
            return None
        
        if not output_file:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_file = f"../data/ai_articles_{timestamp}.json"
        
        # 确保目录存在
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump({
                    'collected_at': datetime.now().isoformat(),
                    'article_count': len(self.articles),
                    'articles': self.articles
                }, f, ensure_ascii=False, indent=2)
            
            print(f"💾 文章已保存到: {output_file}")
            return output_file
            
        except Exception as e:
            print(f"❌ 保存失败: {e}")
            return None
    
    def get_statistics(self):
        """获取统计信息"""
        if not self.articles:
            return {"total": 0}
        
        stats = {
            'total': len(self.articles),
            'by_source': {},
            'by_category': {}
        }
        
        for article in self.articles:
            # 按来源统计
            source = article['source']
            stats['by_source'][source] = stats['by_source'].get(source, 0) + 1
            
            # 按分类统计
            category = article['category']
            stats['by_category'][category] = stats['by_category'].get(category, 0) + 1
        
        return stats

def main():
    """主函数"""
    print("=" * 60)
    print("🤖 AI技术动态RSS收集器 v1.0")
    print("=" * 60)
    
    # 创建收集器
    collector = AITechRSSCollector()
    
    # 获取所有RSS源
    articles = collector.fetch_all_feeds()
    
    if articles:
        # 显示统计信息
        stats = collector.get_statistics()
        print("\n📊 收集统计:")
        print(f"   总文章数: {stats['total']}")
        print(f"   来源分布: {stats['by_source']}")
        print(f"   分类分布: {stats['by_category']}")
        
        # 保存文章
        output_file = collector.save_articles()
        
        # 显示前3篇文章
        print("\n📰 最新文章预览:")
        for i, article in enumerate(articles[:3], 1):
            print(f"   {i}. {article['title'][:50]}...")
            print(f"      来源: {article['source']}")
            print(f"      链接: {article['link'][:50]}...")
            print()
        
        print(f"✅ 收集完成! 共{len(articles)}篇文章")
        return output_file
    else:
        print("❌ 没有收集到文章")
        return None

if __name__ == "__main__":
    main()