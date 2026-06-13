# Changelog

## [Unreleased]

### Added

- **scope 展开动画**：光标进入新 scope 时，彩色竖线从光标位置逐行向外展开（类似 snacks.nvim），而非瞬间全部出现。基于 `vv-utils.animate` 引擎驱动
- **`config.animate` 配置组**：支持 `enabled` / `step_ms` / `total_ms` / `style`（out/down/up）/ `easing`（linear/outQuad/outCubic 等）
- 设置 `animate.enabled = false` 可回退到原先的即时显示行为

### Fixed

- `WinClosed` 回调此前只清理 `last_row` / `win_anim` / `prev_scope`，漏掉了同样按 winid 持有的 `win_state`，导致每开关一个窗口就泄漏一个陈旧条目（长会话单调累积，仅 `:VVIndentDisable` 才整表重置）；现补 `win_state[winid] = nil` 与其余清理对齐
- `hl.scope_hl` 此前对颜色列表长度无保护，当用户配置 `colors.scope = {}`（空列表）时 `(level-1) % 0` 得到 `nan`，生成不存在的高亮组 `VVIndentScopenan`（作用域竖线无色）；现 `count <= 0` 时回退到单色 `VVIndent` 组
- `animate.style = 'out'` 时，若在 ~500ms 展开动画进行中于同一 scope 内移动光标，高亮仍从动画开始时捕获的旧光标行向外扩散；现于 `win_anim` 存 `origin` 并在同 scope 移动时实时刷新，使展开中心跟随新光标位置
