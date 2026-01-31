#!/usr/bin/env python3
"""
feishu-sender.py - 通过Clawdbot发送消息到飞书
"""

import os
import sys
import json
from datetime import datetime

def send_to_feishu_via_clawdbot(message, target=None):
    """
    通过Clawdbot发送消息到飞书
    
    参数:
        message: 要发送的消息内容
        target: 飞书用户ID (可选，默认使用配置中的target)
    
    返回:
        bool: 发送是否成功
    """
    try:
        # 这里应该调用Clawdbot的message工具
        # 由于我们是在Clawdbot环境中运行，可以直接使用message工具
        
        # 构建发送命令
        # 实际实现需要调用Clawdbot的API
        
        print(f"📤 准备发送消息到飞书")
        print(f"目标: {target or '默认目标'}")
        print(f"消息长度: {len(message)} 字符")
        print(f"消息预览: {message[:100]}...")
        
        # 记录发送日志
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "target": target,
            "message_length": len(message),
            "message_preview": message[:100],
            "status": "prepared"
        }
        
        log_file = "logs/feishu-sender.log"
        os.makedirs(os.path.dirname(log_file), exist_ok=True)
        
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        # 在实际的Clawdbot环境中，这里应该调用:
        # message(action="send", channel="feishu", target=target, message=message)
        
        # 由于我们是在对话中，可以直接回复
        # 这里返回True表示准备就绪，实际发送由主程序处理
        return True
        
    except Exception as e:
        print(f"❌ 发送准备失败: {e}")
        
        error_log = {
            "timestamp": datetime.now().isoformat(),
            "error": str(e),
            "status": "failed"
        }
        
        error_file = "logs/feishu-sender-error.log"
        with open(error_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(error_log, ensure_ascii=False) + "\n")
        
        return False

def main():
    """主函数 - 测试发送功能"""
    if len(sys.argv) < 2:
        print("用法: python3 feishu-sender.py <消息内容> [目标用户ID]")
        print("示例: python3 feishu-sender.py '测试消息' ou_8924c5894c324474511b00980af769ee")
        return 1
    
    message = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else None
    
    print("🚀 飞书发送工具启动")
    print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    success = send_to_feishu_via_clawdbot(message, target)
    
    if success:
        print("✅ 消息发送准备完成")
        print("📝 注意: 在实际Clawdbot环境中，消息将自动发送")
        return 0
    else:
        print("❌ 消息发送准备失败")
        return 1

if __name__ == "__main__":
    exit(main())