-- ================================
-- vv-indent.nvim - 缩进参考线 + 光标作用域彩虹高亮
-- ================================
-- 基于缩进层级的作用域检测（而非 treesitter），光标上下移动时
-- 当前作用域的竖线颜色按深度循环，其余竖线用灰色。
require('vv-indent.types')

local M = {}

local STYLE_CHARS = { dashed = '┆', solid = '│' }

---@type VVIndent.Config
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

---@type VVIndent.Config
local config

---@param opts VVIndent.Config|nil
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

---@return VVIndent.Config
function M.get_config()
  return vim.deepcopy(config)
end

return M
