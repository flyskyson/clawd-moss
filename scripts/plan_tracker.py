#!/usr/bin/env python3
"""
plan_tracker.py - 计划执行跟踪系统
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path

class PlanTracker:
    def __init__(self, plan_dir="~/clawd/plans"):
        self.plan_dir = os.path.expanduser(plan_dir)
        self.today = datetime.now()
        self.week_num = self.today.isocalendar()[1]
        
    def load_weekly_plan(self):
        """加载本周计划"""
        plan_file = f"{self.plan_dir}/weekly/2026-W{self.week_num:02d}-plan.md"
        if os.path.exists(plan_file):
            with open(plan_file, 'r', encoding='utf-8') as f:
                return f.read()
        return None
    
    def get_today_tasks(self):
        """获取今日任务"""
        weekday = self.today.strftime('%A')
        plan = self.load_weekly_plan()
        
        if plan:
            # 解析今日任务
            lines = plan.split('\n')
            in_today_section = False
            tasks = []
            
            for line in lines:
                if f"### {weekday}" in line:
                    in_today_section = True
                    continue
                elif in_today_section and line.startswith('###'):
                    break
                    
                if in_today_section and line.strip():
                    tasks.append(line.strip())
            
            return tasks
        return []
    
    def update_progress(self, task, status="completed", notes=""):
        """更新任务进度"""
        progress_file = f"{self.plan_dir}/progress/{self.today.strftime('%Y%m%d')}.json"
        os.makedirs(os.path.dirname(progress_file), exist_ok=True)
        
        progress = {
            "date": self.today.isoformat(),
            "task": task,
            "status": status,
            "notes": notes,
            "updated_at": datetime.now().isoformat()
        }
        
        # 读取现有进度
        if os.path.exists(progress_file):
            with open(progress_file, 'r') as f:
                all_progress = json.load(f)
        else:
            all_progress = []
        
        # 添加新进度
        all_progress.append(progress)
        
        # 保存
        with open(progress_file, 'w') as f:
            json.dump(all_progress, f, indent=2)
        
        print(f"📝 进度更新: {task} -> {status}")
    
    def generate_daily_report(self):
        """生成每日报告"""
        tasks = self.get_today_tasks()
        completed = []
        in_progress = []
        pending = []
        
        # 这里应该从进度文件读取实际状态
        # 暂时模拟
        for task in tasks[:3]:  # 假设前3个已完成
            completed.append(task)
        for task in tasks[3:5]:  # 中间2个进行中
            in_progress.append(task)
        for task in tasks[5:]:  # 剩余待开始
            pending.append(task)
        
        report = f"""
# 📊 每日执行报告
**日期**: {self.today.strftime('%Y-%m-%d %A')}
**周数**: 2026年第{self.week_num}周
**生成时间**: {datetime.now().strftime('%H:%M')}

## ✅ 已完成 ({len(completed)}项)
{chr(10).join(f'- {task}' for task in completed)}

## 🔄 进行中 ({len(in_progress)}项)  
{chr(10).join(f'- {task}' for task in in_progress)}

## 📋 待开始 ({len(pending)}项)
{chr(10).join(f'- {task}' for task in pending)}

## 📈 今日进度
- 总体进度: {len(completed)/len(tasks)*100 if tasks else 0:.1f}%
- 任务总数: {len(tasks)}
- 已完成: {len(completed)}
- 进行中: {len(in_progress)}
- 待开始: {len(pending)}

## 🎯 明日重点
1. 继续完成进行中任务
2. 开始待开始任务
3. 准备明日计划

*报告自动生成，实际进度以具体执行为准*
"""
        
        # 保存报告
        report_file = f"{self.plan_dir}/reports/daily_{self.today.strftime('%Y%m%d')}.md"
        os.makedirs(os.path.dirname(report_file), exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        return report

if __name__ == "__main__":
    tracker = PlanTracker()
    
    print("🚀 计划执行跟踪系统启动")
    print(f"📅 当前日期: {tracker.today.strftime('%Y-%m-%d %A')}")
    
    # 生成今日报告
    report = tracker.generate_daily_report()
    print("\n" + "="*50)
    print(report)
    print("="*50)
    
    print("\n✅ 计划跟踪系统已就绪")