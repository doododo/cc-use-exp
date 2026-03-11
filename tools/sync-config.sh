#!/usr/bin/env bash
set -euo pipefail

# 同步 .claude 和 .gemini 配置到用户根目录

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}=== 配置同步工具 ===${NC}"
echo -e "源目录: ${SCRIPT_DIR}"
echo -e "目标目录: ${HOME}"
echo ""

# --- Claude Code ---
if [[ -d "${SCRIPT_DIR}/.claude" ]]; then
    echo -e "${GREEN}[Claude Code] 开始同步${NC}"

    # 确保目标目录存在
    mkdir -p ~/.claude

    # 删除旧配置目录（保留历史记录、projects 等）
    rm -rf ~/.claude/rules ~/.claude/skills ~/.claude/commands ~/.claude/templates ~/.claude/tasks
    echo -e "${YELLOW}  已清理旧配置目录${NC}"

    # 复制配置目录
    cp -r "${SCRIPT_DIR}/.claude/rules" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/skills" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/commands" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/templates" ~/.claude/
    cp -r "${SCRIPT_DIR}/.claude/tasks" ~/.claude/
    cp "${SCRIPT_DIR}/.claude/CLAUDE.md" ~/.claude/

    echo -e "${GREEN}  ✓ rules/ skills/ commands/ templates/ tasks/ CLAUDE.md${NC}"

    # --- Claude Code 插件检测 ---
    PLUGIN_JSON="${SCRIPT_DIR}/.claude/plugins.json"
    INSTALLED_JSON="${HOME}/.claude/plugins/installed_plugins.json"
    if ! command -v claude &>/dev/null; then
        echo ""
        echo -e "${YELLOW}[Claude Code] 未检测到 claude 命令，跳过插件检测${NC}"
        echo -e "${YELLOW}  安装方式: npm install -g @anthropic-ai/claude-code${NC}"
    elif ! command -v python3 &>/dev/null; then
        echo ""
        echo -e "${YELLOW}[Claude Code] 未检测到 python3，跳过插件检测${NC}"
        echo -e "${YELLOW}  插件检测需要 python3 解析 JSON，请安装后重试${NC}"
        echo -e "${YELLOW}  macOS: brew install python3 | Ubuntu: sudo apt install python3${NC}"
    elif [[ -f "$PLUGIN_JSON" ]]; then
        echo ""
        echo -e "${YELLOW}[Claude Code] 正在检测推荐插件...${NC}"

        # 使用 python3 解析 JSON 检查缺失插件
        MISSING_PLUGINS=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        recommended = json.load(f)
    installed = {}
    try:
        with open(sys.argv[2]) as f:
            installed = json.load(f).get('plugins', {})
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    for p in recommended.get('recommendations', []):
        key = p['id'] + '@' + p['marketplace']
        if key not in installed:
            print(p['id'] + '|' + p['name'] + '|' + p['marketplace'])
except Exception:
    pass
" "$PLUGIN_JSON" "$INSTALLED_JSON")

        if [[ -n "$MISSING_PLUGINS" ]]; then
            echo -e "${YELLOW}检测到以下推荐插件尚未安装：${NC}"
            IFS=$'\n'
            for item in $MISSING_PLUGINS; do
                IFS='|' read -r id name marketplace <<< "$item"
                echo -e "  - ${YELLOW}$name${NC} ($id)"
            done

            echo ""
            read -p "是否现在安装上述缺失的插件？[Y/n] " confirm
            if [[ "$confirm" =~ ^[Yy]$ || "$confirm" == "" ]]; then
                IFS=$'\n'
                for item in $MISSING_PLUGINS; do
                    IFS='|' read -r id name marketplace <<< "$item"
                    echo -e "${GREEN}正在安装 $name...${NC}"
                    INSTALL_OUTPUT=$(claude plugin install "${id}@${marketplace}" 2>&1) || {
                        if echo "$INSTALL_OUTPUT" | grep -qi "auth\|login\|token\|credential\|unauthorized\|forbidden"; then
                            echo -e "${RED}错误: Claude Code 未认证，请先运行 'claude login' 登录${NC}"
                            break
                        elif echo "$INSTALL_OUTPUT" | grep -qi "already installed\|already exists"; then
                            echo -e "${YELLOW}  $name 已安装，跳过${NC}"
                        else
                            echo -e "${YELLOW}警告: $name 安装失败 — $INSTALL_OUTPUT${NC}"
                        fi
                    }
                done
                echo -e "${GREEN}✓ 插件安装完成${NC}"
            else
                echo -e "${YELLOW}已跳过插件安装。你可以之后手动安装。${NC}"
            fi
        else
            echo -e "${GREEN}✓ 所有推荐插件已安装${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[Claude Code] 源目录不存在，跳过${NC}"
fi

echo ""

# --- Gemini CLI ---
if [[ -d "${SCRIPT_DIR}/.gemini" ]]; then
    echo -e "${GREEN}[Gemini CLI] 开始同步${NC}"

    # 确保目标目录存在
    mkdir -p ~/.gemini

    # 删除旧配置目录（保留认证信息）
    rm -rf ~/.gemini/commands ~/.gemini/skills ~/.gemini/rules ~/.gemini/policies
    echo -e "${YELLOW}  已清理旧配置目录${NC}"

    # 确保目标目录存在
    mkdir -p ~/.gemini/policies

    # 复制配置
    cp -r "${SCRIPT_DIR}/.gemini/commands" ~/.gemini/
    cp -r "${SCRIPT_DIR}/.gemini/skills" ~/.gemini/
    cp -r "${SCRIPT_DIR}/.gemini/rules" ~/.gemini/
    cp "${SCRIPT_DIR}/.gemini/GEMINI.md" ~/.gemini/
    cp "${SCRIPT_DIR}/.gemini/settings.json" ~/.gemini/

    # 策略同步逻辑：最新规范要求使用 policies 目录
    if [[ -d "${SCRIPT_DIR}/.gemini/policies" ]]; then
        cp -r "${SCRIPT_DIR}/.gemini/policies/"* ~/.gemini/policies/
    fi
    # 清理旧的全局策略文件以防冲突
    [ -f "${HOME}/.gemini/policy.toml" ] && rm "${HOME}/.gemini/policy.toml"
    if [[ -f "${HOME}/.gemini/policy.json" ]]; then
        mv "${HOME}/.gemini/policy.json" "${HOME}/.gemini/policy.json.bak_$(date +%F)"
    fi

    echo -e "${GREEN}  ✓ commands/ skills/ rules/ policies/ GEMINI.md settings.json${NC}"

    # --- MCP 扩展检测 ---
    EXT_JSON="${SCRIPT_DIR}/.gemini/extensions.json"
    if ! command -v gemini &>/dev/null; then
        echo ""
        echo -e "${YELLOW}[Gemini CLI] 未检测到 gemini 命令，跳过扩展检测${NC}"
        echo -e "${YELLOW}  安装方式: brew install gemini-cli (详见 README)${NC}"
    elif ! command -v python3 &>/dev/null; then
        echo ""
        echo -e "${YELLOW}[Gemini CLI] 未检测到 python3，跳过扩展检测${NC}"
        echo -e "${YELLOW}  扩展检测需要 python3 解析 JSON，请安装后重试${NC}"
        echo -e "${YELLOW}  macOS: brew install python3 | Ubuntu: sudo apt install python3${NC}"
    elif [[ -f "$EXT_JSON" ]]; then
        echo ""
        echo -e "${YELLOW}[Gemini CLI] 正在检测推荐扩展...${NC}"

        # 获取当前已安装的扩展列表（gemini extensions list 输出走 stderr）
        INSTALLED_EXTS=$(gemini extensions list 2>&1 || echo "")

        # 使用 python3 解析 JSON 并检查缺失
        # 优化匹配逻辑：检查 id 是否作为独立单词出现在已安装列表中
        MISSING_EXTS=$(python3 -c "
import json, sys, re
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    installed = sys.argv[2]
    for ext in data.get('recommendations', []):
        # 使用正则确保是完整匹配 ID
        if not re.search(r'\b' + re.escape(ext['id']) + r'\b', installed):
            print(ext['id'] + '|' + ext['name'] + '|' + ext['url'])
except Exception:
    pass
" "$EXT_JSON" "$INSTALLED_EXTS")

        if [[ -n "$MISSING_EXTS" ]]; then
            echo -e "${YELLOW}检测到以下推荐扩展尚未安装：${NC}"
            IFS=$'\n'
            for item in $MISSING_EXTS; do
                IFS='|' read -r id name url <<< "$item"
                echo -e "  - ${YELLOW}$name${NC} ($id)"
            done

            echo ""
            read -p "是否现在安装上述缺失的扩展？[Y/n] " confirm
            if [[ "$confirm" =~ ^[Yy]$ || "$confirm" == "" ]]; then
                IFS=$'\n'
                for item in $MISSING_EXTS; do
                    IFS='|' read -r id name url <<< "$item"
                    echo -e "${GREEN}正在安装 $name...${NC}"
                    INSTALL_OUTPUT=$(gemini extensions install "$url" 2>&1) || {
                        if echo "$INSTALL_OUTPUT" | grep -qi "auth\|login\|token\|credential\|unauthorized\|forbidden"; then
                            echo -e "${RED}错误: Gemini CLI 未认证，请先运行 'gemini auth login' 登录${NC}"
                            break
                        elif echo "$INSTALL_OUTPUT" | grep -qi "already installed\|already exists"; then
                            echo -e "${YELLOW}  $name 已安装，跳过${NC}"
                        else
                            echo -e "${YELLOW}警告: $name 安装失败 — $INSTALL_OUTPUT${NC}"
                        fi
                    }
                done
                echo -e "${GREEN}✓ 扩展安装完成${NC}"
            else
                echo -e "${YELLOW}已跳过扩展安装。你可以之后手动安装。${NC}"
            fi
        else
            echo -e "${GREEN}✓ 所有推荐扩展已安装${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[Gemini CLI] 源目录不存在，跳过${NC}"
fi

echo ""
echo -e "${GREEN}=== 同步完成 ===${NC}"
echo -e "${YELLOW}提示: 若在项目目录运行 gemini 出现 'Skill conflict detected' 警告：${NC}"
echo -e "  这是由于 Gemini CLI 同时加载了全局 (~/.gemini) 和局部 (.gemini) 配置，属于预期行为。"
echo -e "  局部配置将自动覆盖全局配置，不影响功能使用。"
