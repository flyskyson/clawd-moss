---
name: news-automation
description: 自动收集、处理和发送新闻到飞书
metadata: {"openclaw": {"requires": {"env": ["OPENROUTER_API_KEY"]}}}
---

# 新闻自动化技能

## 功能概述
自动定时收集新闻，智能处理，并发送到飞书。

## 工作流程
1. **定时收集**: 9:00, 15:00, 21:00
2. **智能处理**: 分类、摘要、评分
3. **自动发送**: 飞书消息推送
4. **用户反馈**: 收集偏好，持续优化

## 配置选项
- 新闻源: 科技、AI、财经、热点
- 发送时间: 收集后立即/定时发送
- 格式: Markdown/纯文本/摘要

## 使用示例
```
/news test - 测试新闻收集
/news config - 配置新闻偏好
/news stats - 查看新闻统计
```

## 技术实现
- 后端: Python + OpenRouter API
- 定时: cron任务
- 存储: 本地文件 + 日志
- 发送: 飞书API

## 开发状态
✅ 基础新闻收集已实现
✅ 定时任务已配置
🔜 自动发送到飞书 (开发中)
🔜 智能摘要生成 (计划中)

## 维护说明
- 日志位置: ~/clawd/logs/news-subscription.log
- 配置文件: ~/clawd/scripts/news-sender-config.json
- 新闻存储: ~/clawd/temp/news/