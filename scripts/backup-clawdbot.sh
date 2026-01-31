#!/bin/bash
# backup-clawdbot.sh
# 备份Clawdbot配置和记忆文件
# 创建时间：2026-01-31
# 创建目的：定期备份重要数据，防止配置丢失

echo "💾 Clawdbot配置备份工具"
echo "================================"

# 设置备份目录
BACKUP_BASE="$HOME/clawd-backups"
BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="$HOME/.clawdbot"
WORKSPACE_DIR="$HOME/clawd"

echo "📁 备份目录: $BACKUP_DIR"
echo "⚙️  配置目录: $CONFIG_DIR"
echo "💼 工作空间: $WORKSPACE_DIR"
echo ""

# 检查源目录是否存在
echo "🔍 检查源文件..."
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 错误：配置目录不存在: $CONFIG_DIR"
    exit 1
fi

if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "❌ 错误：工作空间目录不存在: $WORKSPACE_DIR"
    exit 1
fi

# 创建备份目录
echo "📂 创建备份目录..."
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "❌ 错误：无法创建备份目录"
    exit 1
fi
echo "✅ 备份目录创建成功"

# 备份配置文件
echo ""
echo "📋 备份配置文件..."
if [ -f "$CONFIG_DIR/clawdbot.json" ]; then
    cp "$CONFIG_DIR/clawdbot.json" "$BACKUP_DIR/"
    echo "✅ clawdbot.json 已备份"
else
    echo "⚠️  警告：clawdbot.json 不存在"
fi

# 备份凭证目录（如果存在）
if [ -d "$CONFIG_DIR/credentials" ]; then
    cp -r "$CONFIG_DIR/credentials" "$BACKUP_DIR/"
    echo "✅ credentials/ 目录已备份"
fi

# 备份扩展目录（如果存在）
if [ -d "$CONFIG_DIR/extensions" ]; then
    cp -r "$CONFIG_DIR/extensions" "$BACKUP_DIR/"
    echo "✅ extensions/ 目录已备份"
fi

# 备份记忆文件
echo ""
echo "🧠 备份记忆文件..."
if [ -d "$WORKSPACE_DIR/memory" ]; then
    cp -r "$WORKSPACE_DIR/memory" "$BACKUP_DIR/"
    echo "✅ memory/ 目录已备份"
    
    # 统计记忆文件
    MEMORY_COUNT=$(find "$WORKSPACE_DIR/memory" -type f -name "*.md" | wc -l)
    echo "   包含 $MEMORY_COUNT 个记忆文件"
else
    echo "⚠️  警告：memory/ 目录不存在"
fi

# 备份其他重要文件
echo ""
echo "📄 备份其他重要文件..."
if [ -f "$WORKSPACE_DIR/AGENTS.md" ]; then
    cp "$WORKSPACE_DIR/AGENTS.md" "$BACKUP_DIR/"
    echo "✅ AGENTS.md 已备份"
fi

if [ -f "$WORKSPACE_DIR/USER.md" ]; then
    cp "$WORKSPACE_DIR/USER.md" "$BACKUP_DIR/"
    echo "✅ USER.md 已备份"
fi

if [ -f "$WORKSPACE_DIR/SOUL.md" ]; then
    cp "$WORKSPACE_DIR/SOUL.md" "$BACKUP_DIR/"
    echo "✅ SOUL.md 已备份"
fi

# 创建备份信息文件
echo ""
echo "📝 创建备份信息..."
BACKUP_INFO="$BACKUP_DIR/backup-info.txt"
{
    echo "=== Clawdbot备份信息 ==="
    echo "备份时间: $(date)"
    echo "备份目录: $BACKUP_DIR"
    echo "主机名: $(hostname)"
    echo "用户: $(whoami)"
    echo ""
    echo "=== 备份内容 ==="
    find "$BACKUP_DIR" -type f | sort
    echo ""
    echo "=== 磁盘使用 ==="
    du -sh "$BACKUP_DIR"
    echo ""
    echo "=== 恢复说明 ==="
    echo "要恢复配置，请执行："
    echo "cp $BACKUP_DIR/clawdbot.json ~/.clawdbot/"
    echo "cp -r $BACKUP_DIR/memory/* ~/clawd/memory/"
} > "$BACKUP_INFO"

echo "✅ 备份信息已保存到 backup-info.txt"

# 显示备份总结
echo ""
echo "🎉 备份完成！"
echo "================================"
echo "📊 备份总结："
echo "备份位置: $BACKUP_DIR"
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "备份大小: $BACKUP_SIZE"
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
echo "文件数量: $FILE_COUNT"
echo ""

# 显示最近的备份
echo "📅 最近的备份："
ls -lt "$BACKUP_BASE" 2>/dev/null | head -6 | tail -5

# 清理旧备份（保留最近7天）
echo ""
echo "🧹 清理旧备份（保留最近7天）..."
find "$BACKUP_BASE" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null
echo "✅ 旧备份清理完成"

echo ""
echo "📖 使用说明："
echo "1. 定期运行此脚本备份重要数据"
echo "2. 建议添加到cron定时任务："
echo "   0 2 * * * ~/scripts/backup-clawdbot.sh"
echo "3. 恢复时参考 backup-info.txt 中的说明"
echo ""
echo "🔄 更新记录："
echo "2026-01-31: 创建初始版本，包含完整备份和清理功能"