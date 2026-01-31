#!/usr/bin/env node
/**
 * 更新Clawdbot配置，添加DeepSeek V3.2 Speciale模型
 */

const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.HOME, '.clawdbot', 'clawdbot.json');
const backupPath = configPath + '.backup-' + new Date().toISOString().replace(/[:.]/g, '-');

console.log('🔧 开始更新Clawdbot配置，添加DeepSeek V3.2 Speciale模型');
console.log(`📁 配置文件: ${configPath}`);
console.log(`💾 备份文件: ${backupPath}`);

// 读取当前配置
let config;
try {
    const configContent = fs.readFileSync(configPath, 'utf8');
    config = JSON.parse(configContent);
    console.log('✅ 配置文件读取成功');
} catch (error) {
    console.error('❌ 读取配置文件失败:', error.message);
    process.exit(1);
}

// 备份当前配置
try {
    fs.copyFileSync(configPath, backupPath);
    console.log('✅ 配置文件备份成功');
} catch (error) {
    console.error('❌ 备份配置文件失败:', error.message);
    process.exit(1);
}

// 添加DeepSeek V3.2 Speciale模型配置
const v3_2_speciale_model = {
    "id": "deepseek-v3.2-speciale",
    "name": "DeepSeek V3.2 Speciale",
    "reasoning": true,
    "input": ["text"],
    "cost": {
        "input": 0.28,
        "output": 0.42,
        "cacheRead": 0.028,
        "cacheWrite": 0.028
    },
    "contextWindow": 163800,
    "maxTokens": 163800
};

// 添加到models列表
if (config.models && config.models.providers && config.models.providers.deepseek) {
    const deepseekProvider = config.models.providers.deepseek;
    
    if (!deepseekProvider.models) {
        deepseekProvider.models = [];
    }
    
    // 检查是否已存在
    const existingIndex = deepseekProvider.models.findIndex(m => m.id === 'deepseek-v3.2-speciale');
    if (existingIndex >= 0) {
        console.log('⚠️  V3.2 Speciale模型已存在，更新配置');
        deepseekProvider.models[existingIndex] = v3_2_speciale_model;
    } else {
        console.log('✅ 添加V3.2 Speciale模型到列表');
        deepseekProvider.models.push(v3_2_speciale_model);
    }
    
    // 更新API密钥（使用用户提供的密钥）
    if (process.argv[2]) {
        const apiKey = process.argv[2];
        deepseekProvider.apiKey = apiKey;
        console.log('✅ 更新DeepSeek API密钥');
    } else {
        console.log('⚠️  未提供API密钥，使用现有密钥');
    }
} else {
    console.error('❌ 找不到DeepSeek provider配置');
    process.exit(1);
}

// 更新主模型设置
if (config.agents && config.agents.defaults && config.agents.defaults.model) {
    const modelConfig = config.agents.defaults.model;
    
    // 设置V3.2 Speciale为主模型
    modelConfig.primary = "deepseek/deepseek-v3.2-speciale";
    
    // 更新fallbacks，确保包含免费模型
    if (!modelConfig.fallbacks) {
        modelConfig.fallbacks = [];
    }
    
    // 确保包含免费模型作为备用
    const fallbacks = new Set(modelConfig.fallbacks);
    fallbacks.add("deepseek/deepseek-coder");
    fallbacks.add("zai/glm-4.7");
    modelConfig.fallbacks = Array.from(fallbacks);
    
    console.log('✅ 更新主模型配置:');
    console.log(`   🎯 主模型: ${modelConfig.primary}`);
    console.log(`   🔄 备用模型: ${modelConfig.fallbacks.join(', ')}`);
} else {
    console.error('❌ 找不到agents.defaults.model配置');
    process.exit(1);
}

// 添加模型别名
if (!config.models.models) {
    config.models.models = {};
}

config.models.models["deepseek/deepseek-v3.2-speciale"] = {
    "alias": "DS-V3.2"
};

console.log('✅ 添加模型别名: DS-V3.2');

// 写入更新后的配置
try {
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log('✅ 配置文件更新成功');
    
    // 显示配置摘要
    console.log('\n📊 配置更新摘要:');
    console.log('='.repeat(50));
    console.log('🎯 主模型: DeepSeek V3.2 Speciale (付费)');
    console.log('💰 价格: $0.28/M输入, $0.42/M输出');
    console.log('📚 上下文: 163.8K tokens');
    console.log('🔧 推理: 支持 (reasoning: true)');
    console.log('🔄 备用模型:');
    console.log('   - DeepSeek Coder (免费V2.5)');
    console.log('   - GLM-4.7 (免费)');
    console.log('💡 智能路由: 重要任务使用付费模型，日常任务使用免费模型');
    console.log('='.repeat(50));
    
    // 显示成本估算
    console.log('\n💰 成本估算 (每月):');
    console.log('   100万输入tokens: $0.28');
    console.log('   50万输出tokens: $0.21');
    console.log('   📊 总计: ~$0.49/月');
    console.log('   💰 比Gemini便宜: 75%');
    
    // 显示下一步操作
    console.log('\n🚀 下一步操作:');
    console.log('   1. 重启Clawdbot网关使配置生效');
    console.log('   2. 测试新模型性能');
    console.log('   3. 监控使用成本');
    console.log('   4. 根据需要调整模型使用策略');
    
    console.log('\n✅ 配置完成！需要重启Clawdbot网关。');
    
} catch (error) {
    console.error('❌ 写入配置文件失败:', error.message);
    
    // 尝试恢复备份
    try {
        fs.copyFileSync(backupPath, configPath);
        console.log('✅ 已恢复备份配置');
    } catch (restoreError) {
        console.error('❌ 恢复备份失败:', restoreError.message);
    }
    
    process.exit(1);
}