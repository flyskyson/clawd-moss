#!/usr/bin/env python3
"""
convert-to-skill-md.py
将现有技能转换为OpenClaw SKILL.md标准格式
"""

import os
import json
import re
import yaml
from pathlib import Path
from datetime import datetime

class SkillConverter:
    def __init__(self, skill_dir):
        self.skill_dir = Path(skill_dir).expanduser()
        self.skill_name = self.skill_dir.name
        self.output_file = self.skill_dir / "SKILL.md"
        
        # 技能类型映射
        self.skill_types = {
            'github': 'GitHub管理',
            'brave-search': '网页搜索',
            'web-search': '网页搜索',
            'notes-pkm': '笔记管理',
            'note-taking': '笔记记录',
            'process-watch': '系统监控',
            'system-monitor-community': '系统监控',
            'python-advanced': 'Python编程',
            'system-design': '系统设计',
            'data-processing': '数据处理'
        }
        
    def analyze_existing_skill(self):
        """分析现有技能结构"""
        print(f"🔍 分析技能: {self.skill_name}")
        
        skill_info = {
            'name': self.skill_name,
            'files': [],
            'has_skill_md': False,
            'skill_md_content': '',
            'other_files': []
        }
        
        # 检查文件
        for file_path in self.skill_dir.iterdir():
            if file_path.is_file():
                if file_path.name == "SKILL.md":
                    skill_info['has_skill_md'] = True
                    with open(file_path, 'r', encoding='utf-8') as f:
                        skill_info['skill_md_content'] = f.read()
                else:
                    skill_info['other_files'].append(file_path.name)
        
        skill_info['files'] = [f.name for f in self.skill_dir.iterdir() if f.is_file()]
        
        return skill_info
    
    def extract_metadata_from_content(self, content):
        """从现有内容提取元数据"""
        metadata = {
            'name': self.skill_name,
            'description': '',
            'metadata': {
                'openclaw': {
                    'requires': {'bins': []},
                    'emoji': self.get_skill_emoji(),
                    'homepage': ''
                }
            }
        }
        
        # 从内容提取描述
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('# '):
                title = line[2:].strip()
                metadata['description'] = f"{self.skill_types.get(self.skill_name, '工具')}: {title}"
                break
        
        # 如果没有找到描述，使用默认
        if not metadata['description']:
            metadata['description'] = f"{self.skill_types.get(self.skill_name, '工具')}技能"
        
        # 根据技能类型设置依赖
        self.set_skill_dependencies(metadata)
        
        return metadata
    
    def get_skill_emoji(self):
        """获取技能对应的emoji"""
        emoji_map = {
            'github': '🐙',
            'brave-search': '🔍',
            'web-search': '🌐',
            'notes-pkm': '📚',
            'note-taking': '📝',
            'process-watch': '🖥️',
            'system-monitor-community': '📊',
            'python-advanced': '🐍',
            'system-design': '🏗️',
            'data-processing': '📈'
        }
        return emoji_map.get(self.skill_name, '🔧')
    
    def set_skill_dependencies(self, metadata):
        """根据技能类型设置依赖"""
        dependencies = {
            'github': {'bins': ['gh']},
            'brave-search': {'bins': ['node', 'npm'], 'env': ['BRAVE_API_KEY']},
            'web-search': {'bins': ['python3']},
            'notes-pkm': {'bins': ['python3']},
            'note-taking': {'bins': ['python3']},
            'process-watch': {'bins': ['python3', 'ps']},
            'system-monitor-community': {'bins': ['python3', 'top', 'df']},
            'python-advanced': {'bins': ['python3', 'pip']},
            'system-design': {'bins': ['python3']},
            'data-processing': {'bins': ['python3', 'pandas']}
        }
        
        deps = dependencies.get(self.skill_name, {'bins': ['python3']})
        metadata['metadata']['openclaw']['requires'] = deps
    
    def create_skill_md_content(self, metadata, existing_content):
        """创建SKILL.md内容"""
        print(f"📝 创建SKILL.md内容: {self.skill_name}")
        
        # 构建frontmatter
        frontmatter = f"""---
name: {metadata['name']}
description: "{metadata['description']}"
metadata: {json.dumps(metadata['metadata'], ensure_ascii=False)}
---

# {metadata['name'].replace('-', ' ').title()} Skill

{metadata['description']}

## 功能特性

"""
        
        # 从现有内容提取功能描述
        features = self.extract_features_from_content(existing_content)
        
        # 构建主要内容
        main_content = ""
        
        if features:
            for feature in features:
                main_content += f"- {feature}\n"
            main_content += "\n"
        
        # 添加使用示例部分
        main_content += """## 使用示例

### 基本使用
```bash
# 根据具体技能提供示例
"""

        # 添加具体示例
        examples = self.get_skill_examples()
        main_content += examples
        
        main_content += """```

### 高级用法
```bash
# 高级功能和选项
# 根据具体技能提供
```

## 配置说明

### 环境变量
```bash
# 需要设置的环境变量
export KEY=value
```

### 配置文件
技能配置可以通过OpenClaw配置文件管理。

## 集成建议

### 与其他技能协同
- 可以与其他相关技能配合使用
- 支持工作流自动化

### 性能优化
- 建议的优化配置
- 性能调优建议

## 开发状态

✅ 核心功能完整
✅ 文档完善
🔜 高级功能开发中
🔜 性能优化进行中

*技能已转换为OpenClaw标准格式*
*转换时间: {datetime.now().strftime('%Y-%m-%d %H:%M')}*
""".format(datetime.now().strftime('%Y-%m-%d %H:%M'))
        
        return frontmatter + main_content
    
    def extract_features_from_content(self, content):
        """从现有内容提取功能特性"""
        features = []
        
        # 简单提取：查找包含功能描述的段落
        lines = content.split('\n')
        in_features_section = False
        
        for line in lines:
            if '功能' in line or '特性' in line or 'feature' in line.lower():
                in_features_section = True
                continue
            
            if in_features_section:
                if line.strip().startswith('-') or line.strip().startswith('*'):
                    feature = line.strip().lstrip('-* ').strip()
                    if feature and len(feature) > 5:
                        features.append(feature)
                elif line.strip() and not line.startswith('#'):
                    # 可能是功能描述
                    features.append(line.strip())
        
        # 如果没有提取到，使用默认
        if not features:
            features = [
                f"提供{self.skill_types.get(self.skill_name, '相关')}功能",
                "支持命令行调用",
                "可集成到自动化工作流",
                "包含详细的使用文档"
            ]
        
        return features[:5]  # 最多返回5个特性
    
    def get_skill_examples(self):
        """获取技能使用示例"""
        examples_map = {
            'github': """# 查看仓库信息
gh repo view owner/repo

# 管理Issue
gh issue list --repo owner/repo --limit 5

# 创建Pull Request
gh pr create --title "更新" --body "描述\"""",
            
            'brave-search': """# 搜索查询
brave-search "查询内容"

# 带选项搜索
brave-search "查询" --limit 10 --fresh\""",
            
            'notes-pkm': '''# 创建笔记
notes-pkm create "笔记内容" --tags "标签"

# 搜索笔记
notes-pkm search "关键词"

# 列出笔记
notes-pkm list --tag "分类"''',
            
            'python-advanced': """# 异步编程示例
import asyncio

async def main():
    # 异步操作
    await asyncio.sleep(1)

# 性能优化
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_function(x):
    return x * x\"""
        }
        
        return examples_map.get(self.skill_name, """# 基本命令
skill-name command

# 带参数命令
skill-name command --option value\""")
    
    def convert(self):
        """执行转换"""
        print(f"🔄 开始转换技能: {self.skill_name}")
        print(f"📁 技能目录: {self.skill_dir}")
        
        # 分析现有技能
        skill_info = self.analyze_existing_skill()
        
        if skill_info['has_skill_md']:
            print(f"✅ 技能已有SKILL.md文件")
            content = skill_info['skill_md_content']
            
            # 检查是否符合标准
            if self.is_standard_format(content):
                print(f"📋 SKILL.md已符合标准格式")
                return True
            else:
                print(f"⚠️  SKILL.md需要更新为标准格式")
                # 提取现有内容中的有用信息
                metadata = self.extract_metadata_from_content(content)
        else:
            print(f"📄 创建新的SKILL.md文件")
            # 使用默认内容创建元数据
            metadata = self.extract_metadata_from_content("")
        
        # 创建新的SKILL.md内容
        new_content = self.create_skill_md_content(
            metadata, 
            skill_info['skill_md_content'] if skill_info['has_skill_md'] else ""
        )
        
        # 保存文件
        self.save_skill_md(new_content)
        
        print(f"🎉 技能转换完成: {self.skill_name}")
        print(f"📄 输出文件: {self.output_file}")
        
        return True
    
    def is_standard_format(self, content):
        """检查是否为标准格式"""
        # 检查是否有frontmatter
        if content.startswith('---\n'):
            lines = content.split('\n')
            if '---' in lines[1:]:
                # 检查是否有metadata字段
                if 'metadata:' in content:
                    return True
        return False
    
    def save_skill_md(self, content):
        """保存SKILL.md文件"""
        try:
            with open(self.output_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"💾 已保存SKILL.md文件")
            
            # 显示文件预览
            print(f"\n📋 文件预览 (前20行):")
            print("-" * 50)
            for i, line in enumerate(content.split('\n')[:20]):
                print(f"{i+1:3}: {line}")
            print("-" * 50)
            
        except Exception as e:
            print(f"❌ 保存文件失败: {e}")
            return False
        
        return True
    
    def validate_conversion(self):
        """验证转换结果"""
        print(f"🔍 验证转换结果: {self.skill_name}")
        
        if not self.output_file.exists():
            print(f"❌ SKILL.md文件不存在")
            return False
        
        with open(self.output_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 检查基本要求
        checks = [
            ("有frontmatter", content.startswith('---\n')),
            ("有name字段", 'name:' in content),
            ("有description字段", 'description:' in content),
            ("有metadata字段", 'metadata:' in content),
            ("有功能描述", '功能特性' in content or '## ' in content),
            ("有使用示例", '使用示例' in content or '```' in content)
        ]
        
        all_passed = True
        for check_name, check_result in checks:
            status = "✅" if check_result else "❌"
            print(f"  {status} {check_name}")
            if not check_result:
                all_passed = False
        
        return all_passed

def convert_all_skills():
    """转换所有技能"""
    skills_dir = Path.home() / ".openclaw" / "skills"
    
    if not skills_dir.exists():
        print(f"❌ 技能目录不存在: {skills_dir}")
        return False
    
    print(f"🔄 开始转换所有技能")
    print(f"📁 技能目录: {skills_dir}")
    print()
    
    skills = []
    for skill_dir in skills_dir.iterdir():
        if skill_dir.is_dir():
            skills.append(skill_dir.name)
    
    print(f"📊 发现 {len(skills)} 个技能:")
    for skill in sorted(skills):
        print(f"  - {skill}")
    
    print()
    print("=" * 50)
    
    results = []
    for skill_name in sorted(skills):
        skill_path = skills_dir / skill_name
        converter = SkillConverter(skill_path)
        
        print(f"\n🎯 转换技能: {skill_name}")
        print("-" * 30)
        
        try:
            success = converter.convert()
            if success:
                valid = converter.validate_conversion()
                results.append((skill_name, success, valid))
            else:
                results.append((skill_name, False, False))
        except Exception as e:
            print(f"❌ 转换失败: {e}")
            results.append((skill_name, False, False))
    
    print()
    print("=" * 50)
    print("📊 转换结果汇总:")
    print("-" * 30)
    
    success_count = 0
    valid_count = 0
    
    for skill_name, converted, validated in results:
        status = "✅" if converted else "❌"
        valid_status = "✅" if validated else "❌"
        print(f"  {status} {skill_name:30} 转换: {status} 验证: {valid_status}")
        
        if converted:
            success_count += 1
        if validated:
            valid_count += 1
    
    print()
    print(f"🎉 转换完成:")
    print(f"  📈 总技能数: {len(skills)}")
    print(f"  ✅ 成功转换: {success_count}")
    print(f"  🔍 验证通过: {valid_count}")
    print(f"  📊 成功率: {success_count/len(skills)*100:.1f}%")
    
    return success_count == len(skills)

def main():
    """主函数"""
    print("🛠️  OpenClaw技能格式转换工具")
    print("=" * 50)
    print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    import sys
    
    if len(sys.argv) > 1:
        # 转换指定技能
        skill_path = sys.argv[1]
        converter = SkillConverter(skill_path)
        
        if converter.convert():
            converter.validate_conversion()
            print(f"\n🎉 技能转换完成!")
        else:
            print(f"\n❌ 技能转换失败!")
            return 1
    else:
        # 转换所有技能
        if convert_all_skills():
            print(f"\n🎉 所有技能转换完成!")
            
            # 生成报告
            report_path = Path.home() / "clawd" / "reports" / "skill-conversion-report.md"
            report_path.parent.mkdir(parents=True, exist_ok=True)
            
            report_content = f"""# 技能格式转换报告
## 转换时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
## 执行环境: {os.uname().sysname} {os.uname().release}

## 📊 转换统计
- 总技能数: {len(list((Path.home() / ".openclaw" / "skills").iterdir()))}
- 成功转换: 待统计
- 验证通过: 待统计
- 转换目录: ~/.openclaw/skills/

## 🎯 下一步行动
1. 测试转换后的技能功能
2. 更新技能加载器支持新格式
3. 创建技能开发指南
4. 集成ClawHub技能仓库

## 📝 注意事项
- 转换后的技能需要测试验证
- 可能需要调整技能加载逻辑
- 建议逐步迁移，保持兼容性

*报告生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*
"""
            
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(report_content)
            
            print(f"📄 报告已生成: {report_path}")
            
            return 0
        else:
            print(f"\n⚠️  部分技能转换失败!")
            return 1
    
    return 0

if __name__ == "__main__":
    exit(main())