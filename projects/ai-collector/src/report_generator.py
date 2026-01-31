#!/usr/bin/env python3
# report_generator.py
# AI技术动态报告生成器

import json
from datetime import datetime
import os

class AITechReportGenerator:
    """AI技术动态报告生成器"""
    
    def __init__(self):
        """初始化生成器"""
        pass
    
    def generate_markdown_report(self, articles, date=None):
        """生成Markdown格式报告"""
        if not date:
            date = datetime.now().strftime('%Y年%m月%d日')
        
        report_time = datetime.now().strftime('%H:%M')
        
        # 统计信息
        total_articles = len(articles)
        
        # 按分类统计
        category_stats = {}
        for article in articles:
            for category in article.get('categories', []):
                category_stats[category] = category_stats.get(category, 0) + 1
        
        # 生成报告
        report = f"""# 🤖 AI技术动态日报

## 📅 报告信息
- **报告日期**: {date}
- **生成时间**: {report_time}
- **文章总数**: {total_articles}篇
- **数据来源**: RSS订阅 + AI过滤

## 📊 今日概览

### 分类分布
"""
        
        # 添加分类统计
        for category, count in sorted(category_stats.items(), key=lambda x: x[1], reverse=True):
            percentage = (count / total_articles * 100) if total_articles > 0 else 0
            report += f"- **{category}**: {count}篇 ({percentage:.1f}%)\n"
        
        report += f"""
### 高质量文章推荐
基于AI相关度评分，推荐以下高质量文章：
"""
        
        # 按AI评分排序，取前5篇
        sorted_articles = sorted(articles, key=lambda x: x.get('ai_score', 0), reverse=True)
        top_articles = sorted_articles[:5]
        
        for i, article in enumerate(top_articles, 1):
            report += f"""
#### {i}. {article['title']}

**来源**: {article['source']}  
**分类**: {', '.join(article.get('categories', ['其他']))}  
**AI相关度**: {article.get('ai_score', 0)}/10  
**发布时间**: {article.get('published', '未知')}

**摘要**: {article.get('processed_summary', article.get('summary', '暂无摘要'))}

[阅读原文]({article['link']})

---
"""
        
        report += """
## 📰 全部文章列表

按分类组织：
"""
        
        # 按分类组织文章
        articles_by_category = {}
        for article in articles:
            categories = article.get('categories', ['其他'])
            primary_category = categories[0] if categories else '其他'
            
            if primary_category not in articles_by_category:
                articles_by_category[primary_category] = []
            articles_by_category[primary_category].append(article)
        
        # 按分类输出文章
        for category, cat_articles in sorted(articles_by_category.items()):
            report += f"\n### {category} ({len(cat_articles)}篇)\n\n"
            
            for i, article in enumerate(cat_articles, 1):
                # 简化显示
                title = article['title']
                if len(title) > 60:
                    title = title[:57] + "..."
                
                source = article['source']
                ai_score = article.get('ai_score', 0)
                
                report += f"{i}. **{title}** - {source} (AI:{ai_score}/10)  \n"
                report += f"   [{article['link'][:50]}...]({article['link']})\n\n"
        
        report += f"""
## 📈 今日总结

今日共收集到 **{total_articles}** 篇AI技术相关文章，涵盖{len(category_stats)}个分类。

### 重点关注：
"""
        
        # 找出最多的分类
        if category_stats:
            top_category = max(category_stats.items(), key=lambda x: x[1])
            report += f"1. **{top_category[0]}** 领域最为活跃，共有{top_category[1]}篇文章\n"
        
        # 找出AI评分最高的文章
        if articles:
            top_ai_article = max(articles, key=lambda x: x.get('ai_score', 0))
            report += f"2. **AI相关度最高**的文章是：{top_ai_article['title'][:40]}... (评分:{top_ai_article.get('ai_score', 0)}/10)\n"
        
        report += f"""
### 明日预告
明天将继续为您收集最新的AI技术动态，重点关注技术突破和行业应用。

---
*报告由MOSS AI技术动态收集系统自动生成*  
*生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*
"""
        
        return report
    
    def generate_html_report(self, articles, date=None):
        """生成HTML格式报告（简化版）"""
        markdown_report = self.generate_markdown_report(articles, date)
        
        # 简单的Markdown转HTML
        html_report = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI技术动态日报 - {date if date else datetime.now().strftime('%Y年%m月%d日')}</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }}
        h1 {{ color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 30px; }}
        h3 {{ color: #666; }}
        .article {{ margin: 20px 0; padding: 15px; background: #f9f9f9; border-left: 4px solid #4CAF50; }}
        .stats {{ background: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }}
        a {{ color: #2196F3; text-decoration: none; }}
        a:hover {{ text-decoration: underline; }}
        .footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #777; font-size: 0.9em; }}
    </style>
</head>
<body>
"""
        
        # 简单的Markdown转HTML转换
        lines = markdown_report.split('\n')
        in_list = False
        
        for line in lines:
            if line.startswith('# '):
                html_report += f'<h1>{line[2:]}</h1>\n'
            elif line.startswith('## '):
                html_report += f'<h2>{line[3:]}</h2>\n'
            elif line.startswith('### '):
                html_report += f'<h3>{line[4:]}</h3>\n'
            elif line.startswith('- '):
                if not in_list:
                    html_report += '<ul>\n'
                    in_list = True
                html_report += f'<li>{line[2:]}</li>\n'
            elif line.strip() == '' and in_list:
                html_report += '</ul>\n'
                in_list = False
            elif line.startswith('   '):
                html_report += f'<p style="margin-left: 20px;">{line.strip()}</p>\n'
            elif line.startswith('**') and line.endswith('**'):
                content = line[2:-2]
                html_report += f'<p><strong>{content}</strong></p>\n'
            elif line.startswith('[') and '](' in line:
                # 链接处理
                import re
                link_pattern = r'\[([^\]]+)\]\(([^)]+)\)'
                matches = re.findall(link_pattern, line)
                if matches:
                    for text, url in matches:
                        line = line.replace(f'[{text}]({url})', f'<a href="{url}">{text}</a>')
                    html_report += f'<p>{line}</p>\n'
                else:
                    html_report += f'<p>{line}</p>\n'
            elif line.strip():
                html_report += f'<p>{line}</p>\n'
            else:
                html_report += '<br>\n'
        
        if in_list:
            html_report += '</ul>\n'
        
        html_report += f"""
    <div class="footer">
        <p>报告由MOSS AI技术动态收集系统自动生成</p>
        <p>生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
</body>
</html>"""
        
        return html_report
    
    def save_report(self, report, report_type='markdown', date=None):
        """保存报告到文件"""
        if not date:
            date = datetime.now().strftime('%Y%m%d')
        
        timestamp = datetime.now().strftime('%H%M%S')
        
        # 确定文件扩展名
        if report_type == 'markdown':
            ext = 'md'
            subdir = 'markdown'
        elif report_type == 'html':
            ext = 'html'
            subdir = 'html'
        else:
            ext = 'txt'
            subdir = 'text'
        
        # 创建目录
        report_dir = f"../reports/{subdir}"
        os.makedirs(report_dir, exist_ok=True)
        
        # 生成文件名
        filename = f"{report_dir}/ai_report_{date}_{timestamp}.{ext}"
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(report)
            
            print(f"💾 报告已保存: {filename}")
            return filename
            
        except Exception as e:
            print(f"❌ 保存报告失败: {e}")
            return None
    
    def generate_and_save(self, articles, date=None):
        """生成并保存报告"""
        print("📝 生成AI技术动态报告...")
        
        # 生成Markdown报告
        markdown_report = self.generate_markdown_report(articles, date)
        md_file = self.save_report(markdown_report, 'markdown', date)
        
        # 生成HTML报告
        html_report = self.generate_html_report(articles, date)
        html_file = self.save_report(html_report, 'html', date)
        
        print(f"✅ 报告生成完成!")
        print(f"   Markdown: {md_file}")
        print(f"   HTML: {html_file}")
        
        return {
            'markdown': md_file,
            'html': html_file,
            'report_date': date if date else datetime.now().strftime('%Y年%m月%d日'),
            'article_count': len(articles)
        }

def main():
    """主函数"""
    print("=" * 60)
    print("📊 AI技术动态报告生成器 v1.0")
    print("=" * 60)
    
    # 测试数据文件
    test_file = "../data/processed_articles_test.json"
    
    if not os.path.exists(test_file):
        print(f"⚠️ 测试文件不存在: {test_file}")
        print("请先运行 content_processor.py 处理数据")
        return
    
    try:
        # 加载处理后的文章
        with open(test_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            articles = data.get('articles', [])
        
        print(f"📂 加载文章: {len(articles)}篇")
        
        if articles:
            # 创建生成器
            generator = AITechReportGenerator()
            
            # 生成并保存报告
            result = generator.generate_and_save(articles)
            
            # 显示报告预览
            print("\n📰 报告预览:")
            markdown_report = generator.generate_markdown_report(articles)
            preview_lines = markdown_report.split('\n')[:15]
            for line in preview_lines:
                print(f"   {line}")
            print("   ...")
            
            print(f"\n✅ 报告生成成功!")
            print(f"   日期: {result['report_date']}")
            print(f"   文章数: {result['article_count']}")
            
            return result
        else:
            print("❌ 没有文章可生成报告")
            return None
            
    except Exception as e:
        print(f"❌ 生成报告失败: {e}")
        return None

if __name__ == "__main__":
    main()