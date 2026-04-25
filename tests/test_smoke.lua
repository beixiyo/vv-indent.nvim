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
-- 汇总
-- =============================================
print(('\n总计: %d 通过, %d 失败'):format(passed, failed))
if failed > 0 then
  vim.cmd('cquit 1')
end
