#!/usr/bin/env python3
# run_collector.py
# AI技术动态收集系统主脚本

import sys
import os
from datetime import datetime

# 添加src目录到Python路径
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from rss_collector import AITechRSSCollector
from content_processor import AITechContentProcessor
from report_generator import AITechReportGenerator

def run_full_pipeline():
    """运行完整的收集处理管道"""
    print("=" * 70)
    print("🚀 MOSS AI技术动态收集系统 v1.0")
    print("=" * 70)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # 步骤1: 收集RSS数据
    print("📡 步骤1: 收集RSS数据")
    print("-" * 40)
    collector = AITechRSSCollector()
    raw_articles = collector.fetch_all_feeds()
    
    if not raw_articles:
        print("❌ 没有收集到文章，流程终止")
        return None
    
    # 保存原始数据
    raw_data_file = f"data/raw_articles_{timestamp}.json"
    collector.save_articles(raw_data_file)
    
    print(f"✅ 步骤1完成: 收集到 {len(raw_articles)} 篇文章")
    print()
    
    # 步骤2: 处理内容
    print("🧠 步骤2: 处理内容")
    print("-" * 40)
    processor = AITechContentProcessor()
    processed_articles = processor.process_articles(raw_articles)
    
    if not processed_articles:
        print("❌ 没有处理后的文章，流程终止")
        return None
    
    # 保存处理后的数据
    processed_data = {
        'processed_at': datetime.now().isoformat(),
        'article_count': len(processed_articles),
        'articles': processed_articles
    }
    
    processed_data_file = f"data/processed_articles_{timestamp}.json"
    os.makedirs(os.path.dirname(processed_data_file), exist_ok=True)
    
    import json
    with open(processed_data_file, 'w', encoding='utf-8') as f:
        json.dump(processed_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 步骤2完成: 处理了 {len(processed_articles)} 篇文章")
    print()
    
    # 步骤3: 生成报告
    print("📊 步骤3: 生成报告")
    print("-" * 40)
    generator = AITechReportGenerator()
    result = generator.generate_and_save(processed_articles)
    
    if not result:
        print("❌ 报告生成失败")
        return None
    
    print(f"✅ 步骤3完成: 生成 {result['article_count']} 篇文章的报告")
    print()
    
    # 总结
    print("🎯 流程总结")
    print("-" * 40)
    print(f"   开始时间: {datetime.now().strftime('%H:%M:%S')}")
    print(f"   原始文章: {len(raw_articles)} 篇")
    print(f"   处理文章: {len(processed_articles)} 篇")
    print(f"   报告文件: {result.get('markdown', 'N/A')}")
    print(f"   完成时间: {datetime.now().strftime('%H:%M:%S')}")
    print()
    
    # 返回结果
    return {
        'success': True,
        'timestamp': timestamp,
        'raw_articles': len(raw_articles),
        'processed_articles': len(processed_articles),
        'raw_data_file': raw_data_file,
        'processed_data_file': processed_data_file,
        'report_files': result,
        'execution_time': datetime.now().strftime('%H:%M:%S')
    }

def test_system():
    """测试系统功能"""
    print("🧪 测试AI技术动态收集系统...")
    print()
    
    # 测试RSS收集器
    print("1. 测试RSS收集器...")
    collector = AITechRSSCollector()
    test_feeds = [feed for feed in collector.feeds if feed.get('enabled', True)][:2]  # 只测试前2个
    
    test_articles = []
    for feed in test_feeds:
        articles = collector.fetch_feed(feed)
        test_articles.extend(articles)
    
    print(f"✅ RSS收集器测试完成: {len(test_articles)} 篇文章")
    print()
    
    # 测试内容处理器
    print("2. 测试内容处理器...")
    processor = AITechContentProcessor()
    processed = processor.process_articles(test_articles)
    
    print(f"✅ 内容处理器测试完成: {len(processed)} 篇文章")
    print()
    
    # 测试报告生成器
    print("3. 测试报告生成器...")
    generator = AITechReportGenerator()
    
    if processed:
        report = generator.generate_markdown_report(processed[:3])  # 只测试3篇
        print("✅ 报告生成器测试完成")
        print()
        
        # 显示报告预览
        print("📄 测试报告预览:")
        print("-" * 40)
        lines = report.split('\n')[:10]
        for line in lines:
            print(f"   {line}")
        print("   ...")
        print()
        
        return True
    else:
        print("❌ 没有处理后的文章，报告生成测试失败")
        return False

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='AI技术动态收集系统')
    parser.add_argument('--test', action='store_true', help='测试系统功能')
    parser.add_argument('--run', action='store_true', help='运行完整收集流程')
    parser.add_argument('--quick', action='store_true', help='快速测试（只测试2个源）')
    
    args = parser.parse_args()
    
    if args.test or args.quick:
        success = test_system()
        if success:
            print("🎉 系统测试通过!")
        else:
            print("❌ 系统测试失败")
            sys.exit(1)
    
    elif args.run:
        result = run_full_pipeline()
        if result:
            print("🎉 AI技术动态收集完成!")
            print(f"   报告文件: {result['report_files']['markdown']}")
        else:
            print("❌ 收集流程失败")
            sys.exit(1)
    
    else:
        # 默认运行完整流程
        result = run_full_pipeline()
        if result:
            print("🎉 AI技术动态收集完成!")
        else:
            print("❌ 收集流程失败")
            sys.exit(1)

if __name__ == "__main__":
    main()