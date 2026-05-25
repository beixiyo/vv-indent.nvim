# Changelog

## [Unreleased]

### Added

- **scope 展开动画**：光标进入新 scope 时，彩色竖线从光标位置逐行向外展开（类似 snacks.nvim），而非瞬间全部出现。基于 `vv-utils.animate` 引擎驱动
- **`config.animate` 配置组**：支持 `enabled` / `step_ms` / `total_ms` / `style`（out/down/up）/ `easing`（linear/outQuad/outCubic 等）
- 设置 `animate.enabled = false` 可回退到原先的即时显示行为
