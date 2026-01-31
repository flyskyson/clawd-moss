/**
 * 配置覆盖器
 * 应用skills.entries配置覆盖
 */

class ConfigOverrider {
  /**
   * 构造函数
   * @param {object} config - Clawdbot配置
   */
  constructor(config = {}) {
    this.config = config;
  }
  
  /**
   * 应用配置覆盖
   * @param {object} skillInfo - 原始技能信息
   * @returns {object} 应用覆盖后的技能信息
   */
  applyOverrides(skillInfo) {
    const skillName = skillInfo.name;
    const skillConfig = this.getSkillConfig(skillName);
    
    // 如果没有配置覆盖，返回原始信息
    if (!skillConfig) {
      return {
        ...skillInfo,
        enabled: true,
        configApplied: false
      };
    }
    
    // 检查是否被禁用
    if (skillConfig.enabled === false) {
      return {
        ...skillInfo,
        enabled: false,
        configApplied: true,
        disabledByConfig: true
      };
    }
    
    // 应用覆盖
    const overriddenSkill = { ...skillInfo };
    
    // 应用环境变量覆盖
    overriddenSkill.env = this.applyEnvOverrides(skillInfo, skillConfig);
    
    // 应用API密钥覆盖
    overriddenSkill.apiKey = this.applyApiKeyOverride(skillInfo, skillConfig);
    
    // 应用自定义配置
    overriddenSkill.customConfig = this.applyCustomConfig(skillInfo, skillConfig);
    
    // 标记配置已应用
    overriddenSkill.enabled = true;
    overriddenSkill.configApplied = true;
    overriddenSkill.configSource = 'skills.entries';
    
    return overriddenSkill;
  }
  
  /**
   * 获取技能配置
   * @param {string} skillName - 技能名称
   * @returns {object|null} 技能配置
   */
  getSkillConfig(skillName) {
    // 直接通过技能名称查找
    if (this.config.skills?.entries?.[skillName]) {
      return this.config.skills.entries[skillName];
    }
    
    // 尝试通过skillKey查找
    const skillKey = this.findSkillKey(skillName);
    if (skillKey && this.config.skills?.entries?.[skillKey]) {
      return this.config.skills.entries[skillKey];
    }
    
    return null;
  }
  
  /**
   * 查找技能键（通过metadata.openclaw.skillKey）
   * @param {string} skillName - 技能名称
   * @returns {string|null} 技能键
   */
  findSkillKey(skillName) {
    // 这里需要从技能信息中获取skillKey
    // 暂时返回null，实际实现需要访问技能信息
    return null;
  }
  
  /**
   * 应用环境变量覆盖
   * @param {object} skillInfo - 技能信息
   * @param {object} skillConfig - 技能配置
   * @returns {object} 合并后的环境变量
   */
  applyEnvOverrides(skillInfo, skillConfig) {
    const mergedEnv = {};
    
    // 1. 从技能metadata中获取需要的环境变量
    const requiredEnv = skillInfo?.metadata?.openclaw?.requires?.env || [];
    
    // 2. 首先设置进程环境变量（如果存在）
    for (const envVar of requiredEnv) {
      if (process.env[envVar]) {
        mergedEnv[envVar] = process.env[envVar];
      }
    }
    
    // 3. 应用配置中的env覆盖
    if (skillConfig.env && typeof skillConfig.env === 'object') {
      Object.assign(mergedEnv, skillConfig.env);
    }
    
    // 4. 应用apiKey到primaryEnv
    const primaryEnv = skillInfo?.metadata?.openclaw?.primaryEnv;
    if (primaryEnv && skillConfig.apiKey && !mergedEnv[primaryEnv]) {
      mergedEnv[primaryEnv] = skillConfig.apiKey;
    }
    
    return mergedEnv;
  }
  
  /**
   * 应用API密钥覆盖
   * @param {object} skillInfo - 技能信息
   * @param {object} skillConfig - 技能配置
   * @returns {string|null} API密钥
   */
  applyApiKeyOverride(skillInfo, skillConfig) {
    if (skillConfig.apiKey) {
      return skillConfig.apiKey;
    }
    
    // 如果没有直接提供apiKey，尝试从env中获取
    const primaryEnv = skillInfo?.metadata?.openclaw?.primaryEnv;
    if (primaryEnv && skillConfig.env?.[primaryEnv]) {
      return skillConfig.env[primaryEnv];
    }
    
    return null;
  }
  
  /**
   * 应用自定义配置
   * @param {object} skillInfo - 技能信息
   * @param {object} skillConfig - 技能配置
   * @returns {object} 自定义配置
   */
  applyCustomConfig(skillInfo, skillConfig) {
    const customConfig = {};
    
    // 从技能metadata中继承配置
    if (skillInfo.metadata?.openclaw) {
      Object.assign(customConfig, skillInfo.metadata.openclaw);
    }
    
    // 应用配置覆盖
    if (skillConfig.config && typeof skillConfig.config === 'object') {
      Object.assign(customConfig, skillConfig.config);
    }
    
    return customConfig;
  }
  
  /**
   * 检查技能是否被允许（针对捆绑技能）
   * @param {object} skillInfo - 技能信息
   * @returns {boolean} 是否允许
   */
  isSkillAllowed(skillInfo) {
    const skillName = skillInfo.name;
    
    // 检查allowBundled白名单
    const allowBundled = this.config.skills?.allowBundled;
    
    if (Array.isArray(allowBundled)) {
      // 如果设置了allowBundled，只允许列表中的技能
      return allowBundled.includes(skillName);
    }
    
    // 如果没有设置allowBundled，默认允许所有技能
    return true;
  }
  
  /**
   * 获取技能最终配置
   * @param {string} skillName - 技能名称
   * @returns {object} 最终配置
   */
  getFinalConfig(skillName) {
    const skillConfig = this.getSkillConfig(skillName);
    
    if (!skillConfig) {
      return {
        enabled: true,
        env: {},
        apiKey: null,
        config: {}
      };
    }
    
    return {
      enabled: skillConfig.enabled !== false,
      env: skillConfig.env || {},
      apiKey: skillConfig.apiKey || null,
      config: skillConfig.config || {}
    };
  }
  
  /**
   * 生成配置报告
   * @param {object} skillInfo - 技能信息
   * @returns {string} 配置报告
   */
  generateConfigReport(skillInfo) {
    const skillName = skillInfo.name;
    const skillConfig = this.getSkillConfig(skillName);
    const finalConfig = this.getFinalConfig(skillName);
    
    const lines = [];
    
    lines.push(`📋 Configuration Report for: ${skillName}`);
    lines.push('='.repeat(50));
    
    // 基本状态
    lines.push(`Status: ${finalConfig.enabled ? '✅ Enabled' : '❌ Disabled'}`);
    
    if (skillConfig) {
      lines.push('Config source: skills.entries');
    } else {
      lines.push('Config source: Default (no override)');
    }
    
    // 环境变量
    if (finalConfig.env && Object.keys(finalConfig.env).length > 0) {
      lines.push('\n🌐 Environment variables:');
      for (const [key, value] of Object.entries(finalConfig.env)) {
        const maskedValue = this.maskSensitiveValue(key, value);
        lines.push(`  ${key}=${maskedValue}`);
      }
    }
    
    // API密钥
    if (finalConfig.apiKey) {
      lines.push(`\n🔑 API Key: ${this.maskSensitiveValue('apiKey', finalConfig.apiKey)}`);
    }
    
    // 自定义配置
    if (finalConfig.config && Object.keys(finalConfig.config).length > 0) {
      lines.push('\n⚙️  Custom configuration:');
      for (const [key, value] of Object.entries(finalConfig.config)) {
        lines.push(`  ${key}: ${JSON.stringify(value)}`);
      }
    }
    
    // 原始metadata
    if (skillInfo.metadata?.openclaw) {
      lines.push('\n📄 Original metadata:');
      lines.push(JSON.stringify(skillInfo.metadata.openclaw, null, 2));
    }
    
    lines.push('\n' + '='.repeat(50));
    
    return lines.join('\n');
  }
  
  /**
   * 掩码敏感值
   * @param {string} key - 键名
   * @param {string} value - 值
   * @returns {string} 掩码后的值
   */
  maskSensitiveValue(key, value) {
    if (!value || typeof value !== 'string') {
      return String(value);
    }
    
    // 识别敏感键
    const sensitiveKeys = ['key', 'token', 'secret', 'password', 'api', 'auth'];
    const isSensitive = sensitiveKeys.some(sensitive => 
      key.toLowerCase().includes(sensitive)
    );
    
    if (isSensitive && value.length > 8) {
      return `${value.substring(0, 4)}...${value.substring(value.length - 4)}`;
    }
    
    return value;
  }
  
  /**
   * 验证配置
   * @param {object} config - 要验证的配置
   * @returns {object} 验证结果
   */
  validateConfig(config) {
    const errors = [];
    const warnings = [];
    
    if (!config) {
      return { isValid: true, errors, warnings };
    }
    
    // 验证enabled字段
    if ('enabled' in config && typeof config.enabled !== 'boolean') {
      warnings.push('enabled should be boolean');
    }
    
    // 验证env字段
    if (config.env && typeof config.env !== 'object') {
      errors.push('env must be an object');
    }
    
    // 验证config字段
    if (config.config && typeof config.config !== 'object') {
      errors.push('config must be an object');
    }
    
    // 验证apiKey字段
    if (config.apiKey && typeof config.apiKey !== 'string') {
      warnings.push('apiKey should be string');
    }
    
    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }
  
  /**
   * 获取所有技能配置
   * @returns {object} 所有技能配置
   */
  getAllSkillConfigs() {
    return this.config.skills?.entries || {};
  }
  
  /**
   * 获取启用的技能列表
   * @returns {Array} 启用的技能名称列表
   */
  getEnabledSkills() {
    const entries = this.config.skills?.entries || {};
    const enabledSkills = [];
    
    for (const [skillName, config] of Object.entries(entries)) {
      if (config.enabled !== false) {
        enabledSkills.push(skillName);
      }
    }
    
    return enabledSkills;
  }
  
  /**
   * 获取禁用的技能列表
   * @returns {Array} 禁用的技能名称列表
   */
  getDisabledSkills() {
    const entries = this.config.skills?.entries || {};
    const disabledSkills = [];
    
    for (const [skillName, config] of Object.entries(entries)) {
      if (config.enabled === false) {
        disabledSkills.push(skillName);
      }
    }
    
    return disabledSkills;
  }
}

module.exports = ConfigOverrider;