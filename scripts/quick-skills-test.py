#!/usr/bin/env python3
"""
quick-skills-test.py
快速技能测试 - 验证核心功能可用性
"""

import os
import sys
import json
from datetime import datetime

def test_skill_files():
    """测试技能文件完整性"""
    skills_dir = os.path.expanduser("~/.openclaw/skills")
    results = []
    
    print("📁 技能文件完整性测试")
    print("="*40)
    
    skill_dirs = [
        "github",
        "brave-search", 
        "web-search",
        "notes-pkm",
        "note-taking",
        "process-watch",
        "system-monitor-community"
    ]
    
    for skill in skill_dirs:
        skill_path = os.path.join(skills_dir, skill, "SKILL.md")
        
        if os.path.exists(skill_path):
            with open(skill_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            line_count = len(content.split('\n'))
            has_frontmatter = content.startswith('---\n')
            
            if line_count > 10:
                if has_frontmatter:
                    print(f"✅ {skill}: 文件完整 ({line_count}行)")
                    results.append({"skill": skill, "status": "PASS", "lines": line_count})
                else:
                    print(f"⚠️  {skill}: 文件存在但格式可能不标准")
                    results.append({"skill": skill, "status": "WARN", "lines": line_count})
            else:
                print(f"❌ {skill}: 文件过小或可能损坏")
                results.append({"skill": skill, "status": "FAIL", "lines": line_count})
        else:
            print(f"❌ {skill}: 文件不存在")
            results.append({"skill": skill, "status": "FAIL", "lines": 0})
    
    return results

def test_dependencies():
    """测试依赖工具"""
    print("\n🔧 依赖工具测试")
    print("="*40)
    
    results = []
    
    # 测试Python3
    try:
        import subprocess
        result = subprocess.run(["python3", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Python3: {result.stdout.strip()}")
            results.append({"tool": "python3", "status": "PASS", "version": result.stdout.strip()})
    except:
        print("❌ Python3: 未安装")
        results.append({"tool": "python3", "status": "FAIL", "version": None})
    
    # 测试Node.js
    try:
        result = subprocess.run(["node", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Node.js: {result.stdout.strip()}")
            results.append({"tool": "node", "status": "PASS", "version": result.stdout.strip()})
    except:
        print("⚠️  Node.js: 未安装（搜索技能需要）")
        results.append({"tool": "node", "status": "WARN", "version": None})
    
    # 测试系统工具
    system_tools = ["ps", "top", "df", "free"]
    for tool in system_tools:
        try:
            result = subprocess.run(["which", tool], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ {tool}: 已安装")
                results.append({"tool": tool, "status": "PASS"})
        except:
            print(f"⚠️  {tool}: 未安装")
            results.append({"tool": tool, "status": "WARN"})
    
    return results

def test_environment():
    """测试环境配置"""
    print("\n🔑 环境配置测试")
    print("="*40)
    
    results = []
    
    # 检查Brave API密钥
    brave_key = os.environ.get("BRAVE_API_KEY")
    if brave_key:
        if brave_key == "dummy_key_for_test":
            print("⚠️  Brave API: 测试密钥，需要替换为真实密钥")
            results.append({"config": "BRAVE_API_KEY", "status": "WARN", "value": "test_key"})
        else:
            print("✅ Brave API: 密钥已配置")
            results.append({"config": "BRAVE_API_KEY", "status": "PASS", "value": "configured"})
    else:
        print("❌ Brave API: 密钥未配置")
        results.append({"config": "BRAVE_API_KEY", "status": "FAIL", "value": None})
    
    # 检查GitHub配置
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token:
        print("✅ GitHub: 令牌已配置")
        results.append({"config": "GITHUB_TOKEN", "status": "PASS", "value": "configured"})
    else:
        print("⚠️  GitHub: 令牌未配置（部分功能受限）")
        results.append({"config": "GITHUB_TOKEN", "status": "WARN", "value": None})
    
    return results

def generate_approval_recommendation(skill_results, dep_results, config_results):
    """生成批准建议"""
    print("\n🎯 批准使用建议")
    print("="*40)
    
    # 统计结果
    total_skills = len(skill_results)
    pass_skills = sum(1 for r in skill_results if r["status"] == "PASS")
    fail_skills = sum(1 for r in skill_results if r["status"] == "FAIL")
    
    total_deps = len(dep_results)
    pass_deps = sum(1 for r in dep_results if r["status"] == "PASS")
    
    total_configs = len(config_results)
    fail_configs = sum(1 for r in config_results if r["status"] == "FAIL")
    
    # 评估批准状态
    if fail_skills == 0 and fail_configs == 0:
        if pass_skills == total_skills:
            approval = "✅ 完全批准"
            recommendation = "所有技能文件完整，可以立即使用"
        else:
            approval = "⚠️  有条件批准"
            recommendation = "技能基本可用，但有些警告需要注意"
    else:
        approval = "❌ 暂不批准"
        recommendation = "有失败项需要先解决"
    
    print(f"批准状态: {approval}")
    print(f"建议: {recommendation}")
    
    print("\n📊 统计摘要:")
    print(f"  技能文件: {pass_skills}/{total_skills} 通过")
    print(f"  依赖工具: {pass_deps}/{total_deps} 通过")
    print(f"  环境配置: {total_configs - fail_configs}/{total_configs} 通过")
    
    # 具体建议
    print("\n💡 具体建议:")
    
    if fail_skills > 0:
        print("  1. 修复失败的技能文件")
        for skill in skill_results:
            if skill["status"] == "FAIL":
                print(f"     - {skill['skill']}: 重新下载或创建SKILL.md文件")
    
    if fail_configs > 0:
        print("  2. 配置必要的环境变量")
        for config in config_results:
            if config["status"] == "FAIL":
                print(f"     - {config['config']}: 需要配置有效的API密钥")
    
    # 如果基本可用，提供使用建议
    if fail_skills == 0:
        print("\n🚀 可以立即使用的技能:")
        for skill in skill_results:
            if skill["status"] == "PASS":
                print(f"  - {skill['skill']}")
        
        print("\n🔧 需要配置后使用的技能:")
        for config in config_results:
            if config["status"] in ["WARN", "FAIL"]:
                print(f"  - {config['config']}相关技能")
    
    return approval

def main():
    """主函数"""
    print("🧪 快速技能测试")
    print("="*50)
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # 运行测试
    skill_results = test_skill_files()
    dep_results = test_dependencies()
    config_results = test_environment()
    
    # 生成建议
    approval = generate_approval_recommendation(skill_results, dep_results, config_results)
    
    # 保存结果
    results = {
        "timestamp": datetime.now().isoformat(),
        "approval_status": approval,
        "skills": skill_results,
        "dependencies": dep_results,
        "configurations": config_results
    }
    
    report_file = "reports/quick-skills-test.json"
    os.makedirs(os.path.dirname(report_file), exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n📁 测试报告已保存: {report_file}")
    
    # 返回退出码
    if "完全批准" in approval:
        return 0
    elif "有条件批准" in approval:
        return 1
    else:
        return 2

if __name__ == "__main__":
    sys.exit(main())