/**
 * 需求检查器
 * 执行技能门控检查：二进制依赖、环境变量、配置项
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class RequirementChecker {
  /**
   * 构造函数
   * @param {object} config - Clawdbot配置
   */
  constructor(config = {}) {
    this.config = config;
    this.cache = {
      bins: new Map(),
      env: new Map()
    };
  }
  
  /**
   * 检查技能需求
   * @param {object} skillInfo - 技能信息
   * @param {string} skillName - 技能名称（用于配置覆盖）
   * @returns {object} 检查结果
   */
  checkRequirements(skillInfo, skillName = '') {
    const requirements = skillInfo?.metadata?.openclaw?.requires;
    
    // 如果没有需求定义，直接通过
    if (!requirements) {
      return {
        passed: true,
        missing: [],
        warnings: [],
        details: { message: 'No requirements defined' }
      };
    }
    
    const results = {
      passed: true,
      missing: [],
      warnings: [],
      details: {}
    };
    
    // 检查二进制依赖
    if (requirements.bins && Array.isArray(requirements.bins)) {
      const binResults = this.checkBins(requirements.bins);
      if (!binResults.allAvailable) {
        results.passed = false;
        results.missing.push(`Missing binaries: ${binResults.missing.join(', ')}`);
      }
      results.details.bins = binResults;
    }
    
    // 检查环境变量
    if (requirements.env && Array.isArray(requirements.env)) {
      const envResults = this.checkEnv(requirements.env, skillName);
      if (!envResults.allAvailable) {
        results.passed = false;
        results.missing.push(`Missing environment variables: ${envResults.missing.join(', ')}`);
      }
      results.details.env = envResults;
    }
    
    // 检查配置项
    if (requirements.config && Array.isArray(requirements.config)) {
      const configResults = this.checkConfig(requirements.config);
      if (!configResults.allAvailable) {
        results.passed = false;
        results.missing.push(`Missing config items: ${configResults.missing.join(', ')}`);
      }
      results.details.config = configResults;
    }
    
    // 检查anyBins（至少一个二进制存在）
    if (requirements.anyBins && Array.isArray(requirements.anyBins)) {
      const anyBinResults = this.checkAnyBins(requirements.anyBins);
      if (!anyBinResults.anyAvailable) {
        results.passed = false;
        results.missing.push(`None of these binaries are available: ${requirements.anyBins.join(', ')}`);
      }
      results.details.anyBins = anyBinResults;
    }
    
    // 检查操作系统限制
    if (requirements.os && Array.isArray(requirements.os)) {
      const osResult = this.checkOS(requirements.os);
      if (!osResult.supported) {
        results.passed = false;
        results.missing.push(`Unsupported OS: ${osResult.current}. Required: ${requirements.os.join(', ')}`);
      }
      results.details.os = osResult;
    }
    
    // 如果设置了always: true，跳过所有检查
    if (skillInfo?.metadata?.openclaw?.always === true) {
      results.passed = true;
      results.warnings.push('Skill has always: true, skipping all requirement checks');
      results.details.always = true;
    }
    
    return results;
  }
  
  /**
   * 检查二进制依赖
   * @param {Array} bins - 二进制文件列表
   * @returns {object} 检查结果
   */
  checkBins(bins) {
    const result = {
      allAvailable: true,
      available: [],
      missing: [],
      details: {}
    };
    
    for (const bin of bins) {
      const isAvailable = this.isBinaryAvailable(bin);
      result.details[bin] = isAvailable;
      
      if (isAvailable) {
        result.available.push(bin);
      } else {
        result.allAvailable = false;
        result.missing.push(bin);
      }
    }
    
    return result;
  }
  
  /**
   * 检查环境变量
   * @param {Array} envVars - 环境变量列表
   * @param {string} skillName - 技能名称
   * @returns {object} 检查结果
   */
  checkEnv(envVars, skillName) {
    const result = {
      allAvailable: true,
      available: [],
      missing: [],
      details: {}
    };
    
    for (const envVar of envVars) {
      let isAvailable = false;
      let source = '';
      
      // 1. 检查进程环境变量
      if (process.env[envVar]) {
        isAvailable = true;
        source = 'process.env';
      }
      // 2. 检查技能配置中的env
      else if (this.config.skills?.entries?.[skillName]?.env?.[envVar]) {
        isAvailable = true;
        source = 'skills.entries.env';
      }
      // 3. 检查技能配置中的apiKey（如果定义了primaryEnv）
      else if (this.config.skills?.entries?.[skillName]?.apiKey && 
               skillName && 
               this.getPrimaryEnv(skillName) === envVar) {
        isAvailable = true;
        source = 'skills.entries.apiKey';
      }
      
      result.details[envVar] = { available: isAvailable, source };
      
      if (isAvailable) {
        result.available.push(envVar);
      } else {
        result.allAvailable = false;
        result.missing.push(envVar);
      }
    }
    
    return result;
  }
  
  /**
   * 检查配置项
   * @param {Array} configPaths - 配置路径列表
   * @returns {object} 检查结果
   */
  checkConfig(configPaths) {
    const result = {
      allAvailable: true,
      available: [],
      missing: [],
      details: {}
    };
    
    for (const configPath of configPaths) {
      const value = this.getConfigValue(configPath);
      const isAvailable = Boolean(value);
      
      result.details[configPath] = {
        available: isAvailable,
        value: value
      };
      
      if (isAvailable) {
        result.available.push(configPath);
      } else {
        result.allAvailable = false;
        result.missing.push(configPath);
      }
    }
    
    return result;
  }
  
  /**
   * 检查anyBins（至少一个存在）
   * @param {Array} bins - 二进制文件列表
   * @returns {object} 检查结果
   */
  checkAnyBins(bins) {
    const result = {
      anyAvailable: false,
      available: [],
      missing: [],
      details: {}
    };
    
    for (const bin of bins) {
      const isAvailable = this.isBinaryAvailable(bin);
      result.details[bin] = isAvailable;
      
      if (isAvailable) {
        result.anyAvailable = true;
        result.available.push(bin);
      } else {
        result.missing.push(bin);
      }
    }
    
    return result;
  }
  
  /**
   * 检查操作系统支持
   * @param {Array} supportedOS - 支持的操作系统列表
   * @returns {object} 检查结果
   */
  checkOS(supportedOS) {
    const currentOS = process.platform;
    const isSupported = supportedOS.includes(currentOS);
    
    return {
      supported: isSupported,
      current: currentOS,
      required: supportedOS
    };
  }
  
  /**
   * 检查二进制是否可用
   * @param {string} bin - 二进制文件名
   * @returns {boolean} 是否可用
   */
  isBinaryAvailable(bin) {
    // 检查缓存
    if (this.cache.bins.has(bin)) {
      return this.cache.bins.get(bin);
    }
    
    let isAvailable = false;
    
    try {
      // 使用which命令检查二进制是否存在
      if (process.platform === 'win32') {
        execSync(`where ${bin}`, { stdio: 'ignore' });
      } else {
        execSync(`which ${bin}`, { stdio: 'ignore' });
      }
      isAvailable = true;
    } catch (error) {
      // which命令失败，尝试直接执行
      try {
        execSync(`${bin} --version`, { stdio: 'ignore', timeout: 1000 });
        isAvailable = true;
      } catch {
        isAvailable = false;
      }
    }
    
    // 缓存结果
    this.cache.bins.set(bin, isAvailable);
    
    return isAvailable;
  }
  
  /**
   * 获取配置值
   * @param {string} configPath - 配置路径（点分隔）
   * @returns {any} 配置值
   */
  getConfigValue(configPath) {
    const parts = configPath.split('.');
    let current = this.config;
    
    for (const part of parts) {
      if (current && typeof current === 'object' && part in current) {
        current = current[part];
      } else {
        return undefined;
      }
    }
    
    return current;
  }
  
  /**
   * 获取主要环境变量（从metadata.openclaw.primaryEnv）
   * @param {string} skillName - 技能名称
   * @returns {string|null} 主要环境变量名
   */
  getPrimaryEnv(skillName) {
    // 这里需要从技能信息中获取，暂时返回null
    // 实际实现需要访问完整的技能信息
    return null;
  }
  
  /**
   * 清除缓存
   */
  clearCache() {
    this.cache.bins.clear();
    this.cache.env.clear();
  }
  
  /**
   * 获取缓存统计
   * @returns {object} 缓存统计信息
   */
  getCacheStats() {
    return {
      bins: this.cache.bins.size,
      env: this.cache.env.size,
      binHits: Array.from(this.cache.bins.values()).filter(v => v).length,
      binMisses: Array.from(this.cache.bins.values()).filter(v => !v).length
    };
  }
  
  /**
   * 生成检查报告
   * @param {object} checkResult - 检查结果
   * @returns {string} 格式化报告
   */
  generateReport(checkResult) {
    const lines = [];
    
    lines.push('📋 Requirement Check Report');
    lines.push('='.repeat(50));
    
    if (checkResult.passed) {
      lines.push('✅ All requirements passed');
    } else {
      lines.push('❌ Some requirements failed');
    }
    
    if (checkResult.missing.length > 0) {
      lines.push('\n❌ Missing requirements:');
      checkResult.missing.forEach(item => lines.push(`  - ${item}`));
    }
    
    if (checkResult.warnings.length > 0) {
      lines.push('\n⚠️  Warnings:');
      checkResult.warnings.forEach(warning => lines.push(`  - ${warning}`));
    }
    
    // 添加详细信息
    if (checkResult.details.bins) {
      lines.push('\n🔧 Binary dependencies:');
      const { available, missing } = checkResult.details.bins;
      if (available.length > 0) {
        lines.push(`  ✅ Available: ${available.join(', ')}`);
      }
      if (missing.length > 0) {
        lines.push(`  ❌ Missing: ${missing.join(', ')}`);
      }
    }
    
    if (checkResult.details.env) {
      lines.push('\n🌐 Environment variables:');
      const { available, missing } = checkResult.details.env;
      if (available.length > 0) {
        lines.push(`  ✅ Available: ${available.join(', ')}`);
      }
      if (missing.length > 0) {
        lines.push(`  ❌ Missing: ${missing.join(', ')}`);
      }
    }
    
    if (checkResult.details.config) {
      lines.push('\n⚙️  Configuration items:');
      const { available, missing } = checkResult.details.config;
      if (available.length > 0) {
        lines.push(`  ✅ Available: ${available.join(', ')}`);
      }
      if (missing.length > 0) {
        lines.push(`  ❌ Missing: ${missing.join(', ')}`);
      }
    }
    
    lines.push('\n' + '='.repeat(50));
    
    return lines.join('\n');
  }
}

module.exports = RequirementChecker;