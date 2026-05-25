-- ================================
-- vv-indent.nvim - 缩进参考线 + 光标作用域彩虹高亮
-- ================================
-- 基于缩进层级的作用域检测（而非 treesitter），光标上下移动时
-- 当前作用域的竖线颜色按深度循环，其余竖线用灰色。

---@class VVIndentColors
---@field indent string            非作用域缩进线颜色 @default '#3B4048'
---@field scope string[]           作用域按深度循环使用的颜色列表 @default { '#E06C75', '#E5C07B', '#61AFEF', '#D19A66', '#98C379', '#C678DD', '#56B6C2' }

---@class VVIndentStyle
---@field scope 'dashed'|'solid'   当前作用域竖线风格 @default 'solid'
---@field indent 'dashed'|'solid'  非作用域缩进线风格 @default 'dashed'

---@class VVIndentChar
---@field scope string|nil         作用域竖线自定义字符，优先级高于 style.scope @default nil
---@field indent string|nil        非作用域缩进线自定义字符，优先级高于 style.indent @default nil

---@class VVIndentAnimate
---@field enabled boolean          是否启用 scope 展开动画 @default true
---@field step_ms number           每步间隔（ms） @default 20
---@field total_ms number          最大动画时长（ms） @default 500
---@field style 'out'|'down'|'up'  展开方向：out=从光标向两端，down=从顶向下，up=从底向上 @default 'out'
---@field easing string            缓动函数名 @default 'linear'

---@class VVIndentConfig
---@field enabled boolean @default true
---@field style VVIndentStyle
---@field char VVIndentChar
---@field priority integer         普通缩进线的 extmark 优先级 @default 1
---@field scope_priority integer   作用域线的 extmark 优先级（需高于普通） @default 200
---@field exclude_ft string[]      按 filetype 关闭 @default { 'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason', ... }
---@field exclude_bt string[]      按 buftype 关闭 @default { 'nofile', 'terminal', 'prompt', 'quickfix' }
---@field colors VVIndentColors
---@field animate VVIndentAnimate

local M = {}

local STYLE_CHARS = { dashed = '┆', solid = '│' }

---@type VVIndentConfig
local default_config = {
  enabled = true,
  style = {
    scope = 'solid',
    indent = 'dashed',
  },
  char = {
    scope = nil,
    indent = nil,
  },
  priority = 1,
  scope_priority = 200,
  exclude_ft = {
    'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason',
    'notify', 'toggleterm', 'lazyterm', 'gitcommit', 'man',
  },
  exclude_bt = { 'nofile', 'terminal', 'prompt', 'quickfix' },
  animate = {
    enabled = true,
    step_ms = 20,
    total_ms = 500,
    style = 'out',
    easing = 'linear',
  },
  colors = {
    indent = '#3B4048',
    scope = {
      '#E06C75', -- red
      '#E5C07B', -- yellow
      '#61AFEF', -- blue
      '#D19A66', -- orange
      '#98C379', -- green
      '#C678DD', -- violet
      '#56B6C2', -- cyan
    },
  },
}

---@type VVIndentConfig
local config

---@param opts VVIndentConfig|nil
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend('force', default_config, opts)
  local user_char = opts.char or {}
  if user_char.scope == nil then
    config.char.scope = STYLE_CHARS[config.style.scope] or STYLE_CHARS.solid
  end
  if user_char.indent == nil then
    config.char.indent = STYLE_CHARS[config.style.indent] or STYLE_CHARS.dashed
  end
  require('vv-indent.hl').setup(config)
  require('vv-indent.render').setup(config)
  if config.enabled then
    require('vv-indent.render').enable()
  end

  vim.api.nvim_create_user_command('VVIndentEnable', function() M.enable() end, {})
  vim.api.nvim_create_user_command('VVIndentDisable', function() M.disable() end, {})
  vim.api.nvim_create_user_command('VVIndentToggle', function() M.toggle() end, {})
end

function M.enable()
  config.enabled = true
  require('vv-indent.render').enable()
end

function M.disable()
  config.enabled = false
  require('vv-indent.render').disable()
end

function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end

---@return VVIndentConfig
function M.get_config()
  return vim.deepcopy(config)
end

return M
