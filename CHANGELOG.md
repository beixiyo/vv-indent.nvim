# Changelog

## [Unreleased]

### Added

- **scope 展开动画**：光标进入新 scope 时，彩色竖线从光标位置逐行向外展开（类似 snacks.nvim），而非瞬间全部出现。基于 `vv-utils.animate` 引擎驱动
- **`config.animate` 配置组**：支持 `enabled` / `step_ms` / `total_ms` / `style`（out/down/up）/ `easing`（linear/outQuad/outCubic 等）
- 设置 `animate.enabled = false` 可回退到原先的即时显示行为

### Fixed

- `WinClosed` 回调此前只清理 `last_row` / `win_anim` / `prev_scope`，漏掉了同样按 winid 持有的 `win_state`，导致每开关一个窗口就泄漏一个陈旧条目（长会话单调累积，仅 `:VVIndentDisable` 才整表重置）；现补 `win_state[winid] = nil` 与其余清理对齐
