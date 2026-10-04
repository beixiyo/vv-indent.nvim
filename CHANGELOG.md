# Changelog

## 0.1.0 - 2026-07-13

### Added

- 新增 scope 展开动画及 `animate` 配置，可调整方向、时长与缓动；设 `animate.enabled = false` 恢复即时显示

### Fixed

- 关闭窗口时完整清理窗口状态，避免长会话持续累积陈旧条目
- `colors.scope = {}` 时回退到单色高亮，作用域竖线不再无色
- `animate.style = 'out'` 的展开中心实时跟随同一 scope 内的光标移动
