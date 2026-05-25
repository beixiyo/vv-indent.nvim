-- 渲染层：decoration provider 按需绘制竖线 extmark
-- on_win: 每次重绘缓存 per-window 状态（scope / leftcol / shiftwidth）
-- on_line: 每行绘制若干 ephemeral extmark
-- CursorMoved 后需要强制整窗重绘，否则未被 nvim 重绘的行会保留上一帧的 scope 着色
-- 动画：scope 变更时通过 vv-utils.animate 逐行展开

local hl = require('vv-indent.hl')
local scope_mod = require('vv-indent.scope')
local animate = require('vv-utils.animate')

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

---@class VVIndentAnim
---@field from integer  当前动画可见的起始行（1-based）
---@field to integer    当前动画可见的结束行（1-based）
---@field scope VVIndentScope  动画目标 scope

---@type table<integer, VVIndentAnim|nil>
local win_anim = {}

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

---@param winid integer
---@param scope VVIndentScope
local function start_anim(winid, scope)
  local anim_cfg = config.animate
  if not anim_cfg.enabled then
    win_anim[winid] = { from = scope.from, to = scope.to, scope = scope }
    return
  end

  local size = scope.to - scope.from
  if size <= 1 then
    win_anim[winid] = { from = scope.from, to = scope.to, scope = scope }
    return
  end

  local ok_cur, cursor = pcall(vim.api.nvim_win_get_cursor, winid)
  local cursor_line = ok_cur and cursor[1] or scope.from

  local id = 'vv_indent_' .. winid
  animate.del(id)

  win_anim[winid] = { from = cursor_line, to = cursor_line, scope = scope }

  animate.add(0, size, function(value, ctx)
    if not vim.api.nvim_win_is_valid(winid) then
      animate.del(id)
      return
    end

    local anim = win_anim[winid]
    if not anim
      or anim.scope.from ~= scope.from
      or anim.scope.to ~= scope.to
      or anim.scope.level ~= scope.level
    then
      animate.del(id)
      return
    end

    local line = math.min(math.max(scope.from, cursor_line), scope.to)
    local style = anim_cfg.style

    if style == 'out' then
      anim.from = math.max(scope.from, line - value)
      anim.to = math.min(scope.to, line + value)
    elseif style == 'down' then
      anim.from = scope.from
      anim.to = math.min(scope.to, scope.from + value)
    elseif style == 'up' then
      anim.from = math.max(scope.from, scope.to - value)
      anim.to = scope.to
    end

    pcall(vim.api.nvim__redraw, {
      win = winid,
      range = { anim.from - 1, anim.to },
      valid = true,
      flush = false,
    })

    if ctx.done then
      anim.from = scope.from
      anim.to = scope.to
      pcall(vim.api.nvim__redraw, { win = winid, valid = false, flush = false })
    end
  end, {
    id = id,
    int = true,
    easing = anim_cfg.easing,
    duration = { step = anim_cfg.step_ms, total = anim_cfg.total_ms },
  })
end

---@param winid integer
local function clear_anim(winid)
  animate.del('vv_indent_' .. winid)
  win_anim[winid] = nil
end

---@type table<integer, VVIndentScope|nil>
local prev_scope = {}

---@param winid integer
---@param scope VVIndentScope|nil
local function on_scope_change(winid, scope)
  local prev = prev_scope[winid]
  prev_scope[winid] = scope

  if not scope then
    clear_anim(winid)
    if prev then
      pcall(vim.api.nvim__redraw, { win = winid, valid = false, flush = false })
    end
    return
  end

  if prev and prev.from == scope.from and prev.to == scope.to and prev.level == scope.level then
    return
  end

  start_anim(winid, scope)
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

      local bufnr = vim.api.nvim_win_get_buf(winid)
      if not buf_active(bufnr) then return end

      local state = build_state(winid, bufnr)
      if state then
        on_scope_change(winid, state.scope)
      end

      pcall(vim.api.nvim__redraw, { win = winid, valid = false, flush = false })
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(args)
      local winid = tonumber(args.match)
      if winid then
        last_row[winid] = nil
        clear_anim(winid)
        prev_scope[winid] = nil
      end
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

      local scope_col = -1
      local scope_level = 0
      local in_anim_range = true

      if scope and row1 >= scope.from and row1 <= scope.to and scope.level > 0 then
        local anim = win_anim[winid]
        if anim
          and anim.scope.from == scope.from
          and anim.scope.to == scope.to
          and anim.scope.level == scope.level
        then
          in_anim_range = row1 >= anim.from and row1 <= anim.to
        end

        if in_anim_range then
          scope_level = scope.level
          scope_col = (scope_level - 1) * sw
        end
      end

      local scope_hl = scope_level > 0
        and hl.scope_hl(scope_level, #config.colors.scope)
        or nil

      for lvl = 1, max_level do
        local buf_col = (lvl - 1) * sw
        local win_col = buf_col - state.leftcol
        if win_col >= 0 then
          local is_scope = buf_col == scope_col and in_anim_range
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

  for winid in pairs(win_anim) do
    clear_anim(winid)
  end
  win_state = {}
  last_row = {}
  prev_scope = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
end

return M
