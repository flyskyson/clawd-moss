#!/usr/bin/env python3
# content_processor.py
# AI技术动态内容处理器

import json
import re
from datetime import datetime
import os

class AITechContentProcessor:
    """AI技术动态内容处理器"""
    
    def __init__(self):
        """初始化处理器"""
        # AI相关关键词
        self.ai_keywords = [
            'AI', '人工智能', '机器学习', '深度学习', '神经网络',
            '自然语言处理', '计算机视觉', '强化学习', '大语言模型',
            'GPT', 'Transformer', 'LLM', '生成式AI', 'AIGC',
            '自动驾驶', '机器人', '智能助手', 'AI Agent'
        ]
        
        # 分类关键词
        self.category_keywords = {
            '技术突破': ['突破', '创新', '新技术', '新算法', 'SOTA', 'state-of-the-art'],
            '应用案例': ['应用', '落地', '案例', '实践', '商用', '部署'],
            '学术研究': ['论文', '研究', '学术', 'arXiv', '预印本', '期刊'],
            '工具框架': ['工具', '框架', '库', '平台', '系统', '开源'],
            '行业动态': ['行业', '市场', '投资', '融资', '合作', '并购']
        }
    
    def load_articles(self, input_file):
        """从文件加载文章"""
        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            print(f"📂 加载文章: {len(data.get('articles', []))}篇")
            return data.get('articles', [])
            
        except Exception as e:
            print(f"❌ 加载文章失败: {e}")
            return []
    
    def filter_ai_articles(self, articles):
        """过滤AI相关文章"""
        print("🔍 过滤AI相关文章...")
        
        filtered_articles = []
        for article in articles:
            # 组合标题和摘要进行判断
            content = f"{article.get('title', '')} {article.get('summary', '')}"
            content_lower = content.lower()
            
            # 检查是否包含AI关键词
            is_ai_related = False
            for keyword in self.ai_keywords:
                if keyword.lower() in content_lower:
                    is_ai_related = True
                    break
            
            if is_ai_related:
                # 添加AI相关度评分
                ai_score = self.calculate_ai_score(content)
                article['ai_score'] = ai_score
                filtered_articles.append(article)
        
        print(f"✅ 过滤完成: {len(filtered_articles)}/{len(articles)} 篇AI相关")
        return filtered_articles
    
    def calculate_ai_score(self, content):
        """计算AI相关度评分"""
        content_lower = content.lower()
        score = 0
        
        for keyword in self.ai_keywords:
            if keyword.lower() in content_lower:
                score += 1
        
        # 归一化到0-10分
        normalized_score = min(score * 2, 10)
        return normalized_score
    
    def categorize_articles(self, articles):
        """对文章进行分类"""
        print("🏷️ 对文章进行分类...")
        
        for article in articles:
            content = f"{article.get('title', '')} {article.get('summary', '')}"
            content_lower = content.lower()
            
            # 初始化分类
            article['categories'] = []
            
            # 检查每个分类的关键词
            for category, keywords in self.category_keywords.items():
                for keyword in keywords:
                    if keyword.lower() in content_lower:
                        if category not in article['categories']:
                            article['categories'].append(category)
                        break
            
            # 如果没有分类，标记为"其他"
            if not article['categories']:
                article['categories'] = ['其他']
        
        return articles
    
    def generate_summary(self, text, max_length=200):
        """生成文章摘要"""
        if not text:
            return "暂无摘要"
        
        # 清理HTML标签
        clean_text = re.sub(r'<[^>]+>', '', text)
        
        # 清理多余空格和换行
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()
        
        # 截取指定长度
        if len(clean_text) > max_length:
            # 尝试在句子边界截断
            truncated = clean_text[:max_length]
            last_period = truncated.rfind('.')
            last_exclamation = truncated.rfind('!')
            last_question = truncated.rfind('?')
            
            cut_point = max(last_period, last_exclamation, last_question)
            if cut_point > max_length * 0.5:  # 确保截断点不要太靠前
                summary = truncated[:cut_point + 1]
            else:
                summary = truncated + "..."
        else:
            summary = clean_text
        
        return summary
    
    def process_articles(self, articles):
        """处理文章：过滤、分类、生成摘要"""
        print("🔄 开始处理文章...")
        
        # 1. 过滤AI相关文章
        ai_articles = self.filter_ai_articles(articles)
        
        # 2. 对文章进行分类
        categorized_articles = self.categorize_articles(ai_articles)
        
        # 3. 生成更好的摘要
        processed_articles = []
        for article in categorized_articles:
            # 使用摘要或内容生成更好的摘要
            raw_summary = article.get('summary', '') or article.get('content', '')
            better_summary = self.generate_summary(raw_summary, 150)
            article['processed_summary'] = better_summary
            
            processed_articles.append(article)
        
        print(f"✅ 处理完成: {len(processed_articles)}篇文章")
        return processed_articles
    
    def get_processing_statistics(self, articles):
        """获取处理统计信息"""
        if not articles:
            return {"total": 0}
        
        stats = {
            'total_processed': len(articles),
            'category_distribution': {},
            'ai_score_distribution': {'high': 0, 'medium': 0, 'low': 0}
        }
        
        for article in articles:
            # 分类分布
            for category in article.get('categories', []):
                stats['category_distribution'][category] = stats['category_distribution'].get(category, 0) + 1
            
            # AI评分分布
            ai_score = article.get('ai_score', 0)
            if ai_score >= 7:
                stats['ai_score_distribution']['high'] += 1
            elif ai_score >= 4:
                stats['ai_score_distribution']['medium'] += 1
            else:
                stats['ai_score_distribution']['low'] += 1
        
        return stats

def main():
    """主函数"""
    print("=" * 60)
    print("🧠 AI技术动态内容处理器 v1.0")
    print("=" * 60)
    
    # 测试数据文件
    test_file = "../data/ai_articles_test.json"
    
    if not os.path.exists(test_file):
        print(f"⚠️ 测试文件不存在: {test_file}")
        print("请先运行 rss_collector.py 收集数据")
        return
    
    # 创建处理器
    processor = AITechContentProcessor()
    
    # 加载文章
    articles = processor.load_articles(test_file)
    
    if articles:
        # 处理文章
        processed_articles = processor.process_articles(articles)
        
        # 显示统计信息
        stats = processor.get_processing_statistics(processed_articles)
        print("\n📊 处理统计:")
        print(f"   处理文章数: {stats['total_processed']}")
        print(f"   分类分布: {stats['category_distribution']}")
        print(f"   AI评分分布: {stats['ai_score_distribution']}")
        
        # 显示处理后的文章示例
        print("\n📝 处理后文章示例:")
        for i, article in enumerate(processed_articles[:2], 1):
            print(f"   {i}. {article['title'][:40]}...")
            print(f"      分类: {', '.join(article['categories'])}")
            print(f"      AI评分: {article.get('ai_score', 0)}/10")
            print(f"      摘要: {article['processed_summary'][:60]}...")
            print()
        
        print(f"✅ 处理完成!")
        return processed_articles
    else:
        print("❌ 没有文章可处理")
        return []

if __name__ == "__main__":
    main()