#!/bin/bash

echo "🔑 GitHub SSH密钥配置脚本 v1.0"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否已有密钥
echo -e "${BLUE}📁 检查现有SSH密钥...${NC}"

if [ -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}⚠️  发现现有SSH密钥：${NC}"
    echo "  私钥: ~/.ssh/id_ed25519"
    echo "  公钥: ~/.ssh/id_ed25519.pub"
    echo ""
    echo -e "${YELLOW}是否重新生成？(y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        echo "备份旧密钥..."
        mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.backup.$TIMESTAMP
        mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub.backup.$TIMESTAMP
        echo -e "${GREEN}✅ 旧密钥已备份${NC}"
    else
        echo -e "${YELLOW}使用现有密钥...${NC}"
    fi
fi

# 生成新密钥（如果需要）
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e "${BLUE}🔐 生成ED25519密钥对...${NC}"
    echo -e "${YELLOW}GitHub用户名: flyskyson${NC}"
    echo -e "${YELLOW}仓库: clawd-moss${NC}"
    ssh-keygen -t ed25519 -C "clawd-moss@flyskyson" -f ~/.ssh/id_ed25519 -N ""
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH密钥生成成功！${NC}"
    else
        echo -e "${RED}❌ SSH密钥生成失败${NC}"
        exit 1
    fi
fi

# 启动ssh-agent
echo -e "${BLUE}🚀 启动ssh-agent...${NC}"
eval "$(ssh-agent -s)" > /dev/null 2>&1

# 添加私钥
echo -e "${BLUE}🔑 添加私钥到ssh-agent...${NC}"
ssh-add ~/.ssh/id_ed25519

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 私钥添加成功${NC}"
else
    echo -e "${RED}❌ 私钥添加失败${NC}"
    exit 1
fi

# 显示公钥
echo ""
echo -e "${GREEN}🎉 SSH密钥配置完成！${NC}"
echo ""
echo -e "${BLUE}📋 请将以下公钥添加到GitHub：${NC}"
echo "1. 访问 https://github.com/settings/keys"
echo "2. 点击 'New SSH key'"
echo "3. 标题: clawd-moss-$(hostname)"
echo "4. 密钥类型: Authentication Key"
echo "5. 粘贴以下内容："
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
cat ~/.ssh/id_ed25519.pub
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}💡 提示：${NC}"
echo "- 添加完成后，按回车继续测试连接"
echo "- 如果遇到问题，请检查网络连接"
echo ""
echo -e "${YELLOW}添加完成后按回车继续...${NC}"
read

# 测试连接
echo -e "${BLUE}🔗 测试SSH连接...${NC}"
ssh -T git@github.com

if [ $? -eq 1 ]; then
    echo -e "${GREEN}✅ SSH连接测试成功！${NC}"
    echo "虽然显示 'permission denied'，但连接已建立"
else
    echo -e "${YELLOW}⚠️  SSH连接测试返回非标准状态${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ SSH密钥配置完成！${NC}"
echo -e "${GREEN}下一步：切换到SSH远程仓库URL${NC}"
echo -e "${GREEN}========================================${NC}"