#!/usr/bin/env python3
"""
skills-integration-demo.py
展示新安装技能的使用示例
"""

import os
import subprocess
import json
from datetime import datetime

class SkillsDemo:
    def __init__(self):
        self.skills_dir = os.path.expanduser("~/.openclaw/skills")
        self.demo_results = []
        
    def list_installed_skills(self):
        """列出已安装的技能"""
        print("📦 已安装的技能列表:")
        print("="*50)
        
        skills = []
        for skill_name in os.listdir(self.skills_dir):
            skill_path = os.path.join(self.skills_dir, skill_name, "SKILL.md")
            if os.path.exists(skill_path):
                skills.append(skill_name)
                print(f"✅ {skill_name}")
        
        print(f"\n总计: {len(skills)} 个技能")
        return skills
    
    def demo_github_skill(self):
        """演示GitHub技能使用"""
        print("\n🚀 GitHub技能演示:")
        print("-"*30)
        
        # GitHub技能使用示例
        examples = [
            "gh repo view clawdbot/clawdbot --json name,description,stargazersCount",
            "gh issue list --repo clawdbot/clawdbot --limit 5",
            "gh pr list --repo clawdbot/clawdbot --limit 3 --state all",
        ]
        
        print("可用命令示例:")
        for cmd in examples:
            print(f"  $ {cmd}")
        
        # 实际执行一个简单命令
        try:
            result = subprocess.run(
                ["gh", "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                print(f"\n✅ GitHub CLI已安装: {result.stdout.split()[2]}")
            else:
                print("⚠️  GitHub CLI未安装或需要配置")
        except Exception as e:
            print(f"⚠️  执行GitHub命令时出错: {e}")
        
        self.demo_results.append({
            "skill": "github",
            "status": "ready",
            "examples": examples
        })
    
    def demo_search_skill(self):
        """演示搜索技能使用"""
        print("\n🔍 搜索技能演示:")
        print("-"*30)
        
        # 搜索技能使用示例
        examples = [
            "brave-search 'AI技术最新进展'",
            "web-search '机器学习趋势 2026'",
            "# 需要配置API密钥后使用"
        ]
        
        print("搜索功能示例:")
        for cmd in examples:
            print(f"  $ {cmd}")
        
        print("\n📝 配置说明:")
        print("  1. 获取Brave Search API密钥")
        print("  2. 设置环境变量: export BRAVE_API_KEY=your_key")
        print("  3. 测试搜索功能")
        
        self.demo_results.append({
            "skill": "search",
            "status": "needs_config",
            "examples": examples
        })
    
    def demo_notes_skill(self):
        """演示笔记技能使用"""
        print("\n📝 笔记管理技能演示:")
        print("-"*30)
        
        # 笔记技能使用示例
        examples = [
            "note-taking '灵感记录: {内容}'",
            "notes-pkm categorize --tag 'AI学习'",
            "notes-pkm search '关键词'"
        ]
        
        print("笔记管理示例:")
        for cmd in examples:
            print(f"  $ {cmd}")
        
        print("\n💡 使用场景:")
        print("  1. 记录学习笔记和灵感")
        print("  2. 分类整理知识内容")
        print("  3. 快速检索历史记录")
        
        self.demo_results.append({
            "skill": "notes",
            "status": "ready",
            "examples": examples
        })
    
    def demo_monitor_skill(self):
        """演示监控技能使用"""
        print("\n🖥️ 系统监控技能演示:")
        print("-"*30)
        
        # 监控技能使用示例
        examples = [
            "process-watch --cpu --memory",
            "system-monitor --all",
            "process-watch --disk --network"
        ]
        
        print("系统监控示例:")
        for cmd in examples:
            print(f"  $ {cmd}")
        
        print("\n🔧 监控维度:")
        print("  1. CPU使用率监控")
        print("  2. 内存使用情况")
        print("  3. 磁盘空间监控")
        print("  4. 网络连接状态")
        
        self.demo_results.append({
            "skill": "monitor",
            "status": "ready",
            "examples": examples
        })
    
    def create_integration_example(self):
        """创建集成使用示例"""
        print("\n🔄 技能集成示例:")
        print("="*50)
        
        integration_scenario = """
## 场景: AI学习日报自动生成

### 工作流程:
1. 🔍 使用搜索技能收集AI最新动态
   $ brave-search 'AI研究论文 最新'

2. 📝 使用笔记技能记录关键信息
   $ note-taking '今日AI动态: {摘要}'

3. 💻 使用GitHub技能管理学习代码
   $ gh issue create --repo my-learning --title '学习任务' --body '内容'

4. 🖥️ 使用监控技能确保系统稳定
   $ process-watch --alert --threshold 80

5. 📊 自动生成学习报告并发送
   # 集成到现有新闻发送系统
"""
        
        print(integration_scenario)
        
        # 创建集成脚本示例
        integration_script = """#!/bin/bash
# AI学习日报自动生成脚本
# 集成多个技能的工作流

echo "🤖 AI学习日报生成中..."

# 1. 搜索最新AI动态
AI_NEWS=$(brave-search "AI技术动态" | head -5)

# 2. 记录到笔记系统
echo "📝 记录AI动态..."
note-taking "AI动态: $AI_NEWS"

# 3. 创建GitHub学习任务
echo "💻 创建学习任务..."
gh issue create --repo my-ai-learning \\
  --title "学习任务 $(date +%Y-%m-%d)" \\
  --body "今日学习内容: $AI_NEWS"

# 4. 检查系统状态
echo "🖥️ 检查系统状态..."
process-watch --quick

# 5. 生成报告
echo "📊 生成学习日报..."
REPORT_FILE="ai_learning_$(date +%Y%m%d).md"
cat > "$REPORT_FILE" << EOF
# AI学习日报 - $(date +%Y-%m-%d)

## 今日AI动态
$AI_NEWS

## 学习任务
- 研究最新AI技术
- 实践相关代码
- 整理学习笔记

## 系统状态
正常

*报告自动生成*
EOF

echo "✅ 学习日报已生成: $REPORT_FILE"
"""
        
        print("\n示例脚本:")
        print("-"*30)
        print(integration_script)
        
        # 保存示例脚本
        script_path = "scripts/ai-learning-daily.sh"
        os.makedirs(os.path.dirname(script_path), exist_ok=True)
        
        with open(script_path, "w") as f:
            f.write(integration_script)
        
        print(f"\n📁 示例脚本已保存: {script_path}")
        
        self.demo_results.append({
            "skill": "integration",
            "status": "example_created",
            "script": script_path
        })
    
    def generate_report(self):
        """生成演示报告"""
        print("\n📊 技能演示总结报告:")
        print("="*50)
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_skills": len(self.demo_results),
            "skills": self.demo_results,
            "recommendations": [
                "立即配置搜索技能API密钥",
                "测试GitHub技能与现有仓库集成",
                "将笔记技能集成到知识管理系统",
                "设置系统监控告警阈值"
            ]
        }
        
        print(f"生成时间: {report['timestamp']}")
        print(f"演示技能数: {report['total_skills']}")
        
        print("\n🎯 推荐下一步:")
        for i, rec in enumerate(report['recommendations'], 1):
            print(f"{i}. {rec}")
        
        # 保存报告
        report_path = "reports/skills-demo-report.json"
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        
        with open(report_path, "w") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📁 详细报告已保存: {report_path}")
        
        return report
    
    def run_all_demos(self):
        """运行所有演示"""
        print("🎬 开始技能演示...")
        print("="*50)
        
        # 列出技能
        self.list_installed_skills()
        
        # 运行各技能演示
        self.demo_github_skill()
        self.demo_search_skill()
        self.demo_notes_skill()
        self.demo_monitor_skill()
        
        # 创建集成示例
        self.create_integration_example()
        
        # 生成报告
        report = self.generate_report()
        
        print("\n🎉 技能演示完成!")
        return report

def main():
    """主函数"""
    print("🤖 Clawdbot技能集成演示")
    print("="*50)
    
    demo = SkillsDemo()
    report = demo.run_all_demos()
    
    print("\n🚀 下一步建议:")
    print("1. 配置必要的API密钥")
    print("2. 测试各技能功能")
    print("3. 集成到现有系统")
    print("4. 开发自动化工作流")
    
    return 0

if __name__ == "__main__":
    exit(main())