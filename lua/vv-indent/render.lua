-- 渲染层：decoration provider 按需绘制竖线 extmark
-- on_win: 每次重绘缓存 per-window 状态（scope / leftcol / shiftwidth）
-- on_line: 每行绘制若干 ephemeral extmark
-- CursorMoved 后需要强制整窗重绘，否则未被 nvim 重绘的行会保留上一帧的 scope 着色

local hl = require('vv-indent.hl')
local scope_mod = require('vv-indent.scope')

local M = {}

local ns = vim.api.nvim_create_namespace('vv-indent')
local augroup = vim.api.nvim_create_augroup('vv-indent.render', { clear = true })
local enabled = false

---@type VVIndentConfig
local config

---@type table<integer, integer> 每个 window 上次光标所在行，用于换行时才刷新
local last_row = {}

---@class VVIndentWinState
---@field scope VVIndentScope|nil
---@field leftcol integer
---@field sw integer

---@type table<integer, VVIndentWinState|nil>
local win_state = {}

---@param bufnr integer
---@return boolean
local function buf_active(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.b[bufnr].vv_indent_disabled then return false end
  local bt = vim.bo[bufnr].buftype
  for _, v in ipairs(config.exclude_bt) do
    if v == bt then return false end
  end
  local ft = vim.bo[bufnr].filetype
  for _, v in ipairs(config.exclude_ft) do
    if v == ft then return false end
  end
  return true
end

---@param winid integer
---@param bufnr integer
---@return VVIndentWinState|nil
local function build_state(winid, bufnr)
  local ok_cur, cursor = pcall(vim.api.nvim_win_get_cursor, winid)
  if not ok_cur then return nil end

  local scope = scope_mod.find(bufnr, cursor[1])
  -- 若 scope 起始行在闭合 fold 中，抑制作用域高亮
  if scope then
    local closed = vim.api.nvim_buf_call(bufnr, function()
      return vim.fn.foldclosed(scope.from)
    end)
    if closed ~= -1 then scope = nil end
  end

  local view = vim.api.nvim_win_call(winid, vim.fn.winsaveview)
  return {
    scope = scope,
    leftcol = view.leftcol or 0,
    sw = scope_mod.get_shiftwidth(bufnr),
  }
end

---@param config_ VVIndentConfig
function M.setup(config_)
  config = config_
end

function M.enable()
  if enabled then return end
  enabled = true

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = augroup,
    callback = function()
      local winid = vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(winid) then return end

      local row = vim.api.nvim_win_get_cursor(winid)[1]
      if last_row[winid] == row then return end
      last_row[winid] = row

      pcall(vim.api.nvim__redraw, { win = winid, valid = false, flush = false })
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(args)
      last_row[tonumber(args.match)] = nil
    end,
  })

  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, winid, bufnr, _, _)
      if not buf_active(bufnr) then
        win_state[winid] = nil
        return false
      end
      win_state[winid] = build_state(winid, bufnr)
      return win_state[winid] ~= nil
    end,
    on_line = function(_, winid, bufnr, row)
      local state = win_state[winid]
      if not state then return end

      local sw = state.sw
      local row1 = row + 1
      local eff_indent = scope_mod.effective_indent(bufnr, row1)
      if eff_indent < sw then return end

      local max_level = math.floor(eff_indent / sw)
      local scope = state.scope

      -- 作用域竖线位于 (scope.level - 1) * sw（比 body 浅一级）
      local scope_col = -1
      local scope_level = 0
      if scope and row1 >= scope.from and row1 <= scope.to and scope.level > 0 then
        scope_level = scope.level
        scope_col = (scope_level - 1) * sw
      end

      local scope_hl = scope_level > 0
        and hl.scope_hl(scope_level, #config.colors.scope)
        or nil

      for lvl = 1, max_level do
        local buf_col = (lvl - 1) * sw
        local win_col = buf_col - state.leftcol
        if win_col >= 0 then
          local is_scope = buf_col == scope_col
          local group = is_scope and scope_hl or hl.INDENT
          local char = is_scope and config.char.scope or config.char.indent
          vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
            virt_text = { { char, group } },
            virt_text_pos = 'overlay',
            virt_text_win_col = win_col,
            hl_mode = 'combine',
            ephemeral = true,
            priority = is_scope and config.scope_priority or config.priority,
            strict = false,
          })
        end
      end
    end,
  })
end

function M.disable()
  if not enabled then return end
  enabled = false
  vim.api.nvim_clear_autocmds({ group = augroup })
  vim.api.nvim_set_decoration_provider(ns, {})
  win_state = {}
  last_row = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
end

return M
