#!/usr/bin/env python3
"""
openclaw-docs-monitor.py
监控OpenClaw官方文档更新并通知飞天主人
"""

import os
import sys
import subprocess
import requests
import hashlib
import json
from pathlib import Path
from datetime import datetime, timedelta

class OpenClawDocsMonitor:
    def __init__(self):
        self.docs_url = "https://docs.openclaw.ai/"
        self.state_file = Path.home() / "clawd" / "state" / "openclaw-docs-state.json"
        self.log_file = Path.home() / "clawd" / "logs" / "openclaw-docs-monitor.log"
        
        # 创建必要目录
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        
        # 知识库文件
        self.knowledge_base = Path.home() / "clawd" / "docs" / "openclaw-knowledge-base.md"
        
    def log(self, message, level="INFO"):
        """记录日志"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry)
        
        print(f"{level}: {message}")
    
    def fetch_docs_hash(self):
        """获取文档内容的hash"""
        try:
            response = requests.get(self.docs_url, timeout=30)
            response.raise_for_status()
            content = response.text
            content_hash = hashlib.md5(content.encode('utf-8')).hexdigest()
            return {
                'hash': content_hash,
                'length': len(content),
                'fetched_at': datetime.now().isoformat()
            }
        except Exception as e:
            self.log(f"获取文档失败: {e}", "ERROR")
            return None
    
    def load_state(self):
        """加载上次状态"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                self.log(f"加载状态失败: {e}", "WARNING")
                return {'last_hash': None, 'last_check': None}
        return {'last_hash': None, 'last_check': None}
    
    def save_state(self, state):
        """保存当前状态"""
        try:
            with open(self.state_file, 'w', encoding='utf-8') as f:
                json.dump(state, f, indent=2, ensure_ascii=False)
        except Exception as e:
            self.log(f"保存状态失败: {e}", "ERROR")
    
    def check_for_changes(self, current_hash):
        """检查是否有变化"""
        state = self.load_state()
        last_hash = state.get('last_hash')
        
        if last_hash and last_hash != current_hash:
            self.log("检测到文档变化！", "INFO")
            return True, state
        elif last_hash == current_hash:
            self.log("文档无变化", "INFO")
            return False, state
        else:
            self.log("首次检查，建立基准", "INFO")
            return False, state
    
    def detect_changes(self, old_hash, current_info):
        """尝试检测具体变化"""
        self.log("尝试检测文档内容变化...", "INFO")
        
        # 这里可以添加更详细的内容对比
        # 暂时只记录hash变化
        changes = {
            'hash_changed': True,
            'length_change': current_info['length'] - getattr(self, 'last_length', 0),
            'detected_at': datetime.now().isoformat()
        }
        
        self.last_length = current_info['length']
        return changes
    
    def send_notification(self, has_changes, changes_info, current_info):
        """发送通知到飞书"""
        if not has_changes:
            return
        
        try:
            # 导入message模块（Clawdbot环境）
            from message import message
            
            # 构建通知消息
            message_content = f"""# 🔔 **OpenClaw官方文档更新通知**

**检测时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 📄 **文档状态**

### **文档URL**
{self.docs_url}

### **变化详情**
- **上次hash**: 已存储
- **当前hash**: {current_info['hash']}
- **文档长度**: {current_info['length']} 字符
- **检测时间**: {current_info['fetched_at']}

## 💡 **建议操作**

### 立即行动
1. **查看最新文档**: 访问 [OpenClaw文档](https://docs.openclaw.ai/)
2. **更新知识库**: 根据最新文档更新 `openclaw-knowledge-base.md`
3. **评估影响**: 评估文档更新对现有系统的影响

### 关键检查点
- **新特性**: 检查是否有新的功能特性
- **Breaking Changes**: 检查是否有破坏性变更
- **安全更新**: 检查是否有重要的安全更新
- **技能系统**: 检查技能系统的更新和变化

## 📊 **变化类型**

### 可能的内容更新
- 🆕 **新功能**: 新增的功能和特性
- 🔧 **改进优化**: 性能改进和bug修复
- 📝 **文档更新**: 文档内容的改进和补充
- 🔒 **安全更新**: 安全相关的更新
- 🛠️ **API变化**: API接口的变化

## 🎯 **行动计划**

### 今天
1. **阅读更新**: 详细阅读文档更新内容
2. **影响评估**: 评估对当前项目的具体影响
3. **更新计划**: 调整后续实施计划

### 本周
1. **知识库更新**: 同步知识库内容
2. **技能系统调整**: 根据文档更新调整技能系统
3. **测试验证**: 测试受影响的功能

## 🔄 **监控状态**

### 下次检查
- **时间**: 明天相同时间
- **状态**: 已启用自动监控
- **历史**: {self.log_file}

---

*由OpenClaw文档监控器自动发送*
*检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*
"""
            
            # 发送通知
            result = message(
                action="send",
                channel="feishu",
                target="ou_8924c5894c324474511b00980af769ee",
                message=message_content
            )
            
            if result and "messageId" in result.get("result", {}):
                self.log("通知发送成功", "INFO")
                return True
            else:
                self.log("通知发送失败", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"发送通知时导入message模块失败: {e}", "ERROR")
            # 如果message模块不可用，记录到日志
            self.log(f"通知内容:\n{message_content}", "INFO")
            return False
    
    def check_once(self):
        """执行一次检查"""
        self.log("开始检查OpenClaw文档...", "INFO")
        
        # 获取当前文档
        current_info = self.fetch_docs_hash()
        
        if not current_info:
            self.log("获取文档失败，跳过本次检查", "WARNING")
            return False
        
        # 检查变化
        has_changes, state = self.check_for_changes(current_info['hash'])
        
        # 更新状态
        state['last_check'] = datetime.now().isoformat()
        state['last_hash'] = current_info['hash']
        self.save_state(state)
        
        if has_changes:
            changes_info = self.detect_changes(state.get('last_hash'), current_info)
            self.send_notification(True, changes_info, current_info)
        else:
            self.log("文档无变化，无需通知", "INFO")
        
        return has_changes
    
    def start_monitoring(self, interval_hours=24):
        """启动定期监控"""
        self.log(f"启动定期监控，检查间隔: {interval_hours}小时", "INFO")
        
        import time
        
        try:
            while True:
                self.check_once()
                
                # 计算下次检查时间
                next_check = datetime.now() + timedelta(hours=interval_hours)
                wait_seconds = (next_check - datetime.now()).total_seconds()
                
                self.log(f"下次检查时间: {next_check.strftime('%Y-%m-%d %H:%M:%S')}", "INFO")
                
                # 等待
                time.sleep(wait_seconds)
                
        except KeyboardInterrupt:
            self.log("监控被用户中断", "INFO")
            return

def main():
    """主函数"""
    print("🔔 OpenClaw文档监控器")
    print("=" * 50)
    print(f"启动时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    import sys
    
    monitor = OpenClawDocsMonitor()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "check":
            # 单次检查
            has_changes = monitor.check_once()
            
            if has_changes:
                print("\n🎉 检测到文档更新！")
            else:
                print("\n✅ 文档无变化")
                
        elif command == "monitor":
            # 启动定期监控
            interval = 24  # 默认24小时
            
            if len(sys.argv) > 2:
                try:
                    interval = int(sys.argv[2])
                except ValueError:
                    print("⚠️  无效的间隔参数，使用默认24小时")
            
            print(f"\n🔄 启动定期监控 (间隔: {interval}小时)")
            print("按 Ctrl+C 停止监控\n")
            
            monitor.start_monitoring(interval)
            
        else:
            print("⚠️  未知命令")
            print("\n使用方法:")
            print("  python3 openclaw-docs-monitor.py check      # 单次检查")
            print("  python3 openclaw-docs-monitor.py monitor    # 启动定期监控")
            print("  python3 openclaw-docs-monitor.py monitor 12  # 每12小时检查")
            
            return 1
    else:
        # 默认执行单次检查
        has_changes = monitor.check_once()
        
        print("\n📋 可用命令:")
        print("  python3 openclaw-docs-monitor.py check      # 单次检查")
        print("  python3 openclaw-docs-monitor.py monitor    # 启动定期监控")
        
        return 0

if __name__ == "__main__":
    exit(main())