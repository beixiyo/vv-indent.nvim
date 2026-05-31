-- vv-indent.nvim 变更验证脚本
-- 用法：nvim --headless -u NONE -l tests/test_smoke.lua

local passed, failed = 0, 0

local function assert_eq(name, got, want)
  if got == want then
    passed = passed + 1
    print('[PASS] ' .. name)
  else
    failed = failed + 1
    print(('[FAIL] %s\n  期望: %s\n  实际: %s'):format(name, tostring(want), tostring(got)))
  end
end

local function assert_match(name, str, pattern)
  if str:find(pattern) then
    passed = passed + 1
    print('[PASS] ' .. name)
  else
    failed = failed + 1
    print(('[FAIL] %s\n  未匹配到: %s\n  内容: %s'):format(name, pattern, str))
  end
end

local function assert_no_match(name, str, pattern)
  if not str:find(pattern) then
    passed = passed + 1
    print('[PASS] ' .. name)
  else
    failed = failed + 1
    print(('[FAIL] %s\n  不应匹配到: %s\n  内容: %s'):format(name, pattern, str))
  end
end

-- =============================================
-- FIX 1: README 内容验证
-- =============================================
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
local readme_path = root .. '/README.md'
local readme = table.concat(vim.fn.readfile(readme_path), '\n')

-- 1a. 不再包含旧的 spec 文件路径引用
assert_no_match(
  'README 不包含旧 spec 路径',
  readme,
  'lua/plugins/specs/ui/indent%.lua'
)

-- 1b. 包含通用 lazy.nvim 安装示例
assert_match(
  'README 包含 lazy.nvim 安装格式',
  readme,
  'lazy%.nvim'
)

assert_match(
  'README 包含 event 配置',
  readme,
  "event = { 'BufReadPost', 'BufNewFile' }"
)

-- 1c. default = true 说明引用了 vv-utils.hl.register
assert_match(
  'README 说明 default=true 由 vv-utils.hl.register 设置',
  readme,
  'vv%-utils%.hl%.register'
)

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
