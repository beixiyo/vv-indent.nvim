-- vv-indent.nvim 变更验证脚本
-- 用法：nvim --headless -u NONE -l tests/test_smoke.lua

local passed, failed = 0, 0

local function assert_match(name, str, pattern)
  if str:find(pattern) then
    passed = passed + 1
    print('[PASS] ' .. name)
  else
    failed = failed + 1
    print(('[FAIL] %s\n  未匹配到: %s\n  内容: %s'):format(name, pattern, str))
  end
end

local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')

-- =============================================
-- FIX 2 (#72): WinClosed 同步清理 win_state，避免关窗后陈旧条目泄漏
-- =============================================
local render_path = root .. '/lua/vv-indent/render.lua'
local render = table.concat(vim.fn.readfile(render_path), '\n')

-- 仅截取 WinClosed 回调片段（到 decoration provider 之前），避免误匹配 on_win 里的 win_state 清理
local winclosed = render:match("WinClosed.-nvim_set_decoration_provider") or ''

assert_match(
  '#72 WinClosed 回调清理 win_state[winid]',
  winclosed,
  'win_state%[winid%] = nil'
)

-- 回归：原有三处 per-winid 清理仍在同一回调内
assert_match('WinClosed 仍清理 last_row[winid]', winclosed, 'last_row%[winid%] = nil')
assert_match('WinClosed 仍清理 prev_scope[winid]', winclosed, 'prev_scope%[winid%] = nil')
assert_match('WinClosed 仍调用 clear_anim(winid)', winclosed, 'clear_anim%(winid%)')

-- =============================================
-- 汇总
-- =============================================
print(('\n总计: %d 通过, %d 失败'):format(passed, failed))
if failed > 0 then
  vim.cmd('cquit 1')
end
