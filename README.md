# termcolor-widgets

[![CI](https://github.com/jonaprieto/lean-termcolor-widgets/actions/workflows/ci.yml/badge.svg)](https://github.com/jonaprieto/lean-termcolor-widgets/actions/workflows/ci.yml)
[![Lean 4](https://img.shields.io/badge/Lean%204-library-5f5f5f)](lean-toolchain)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

Pure terminal widgets for Lean 4. Rendering returns styled `TermColor.Text`; timing, terminal
size, focus, and output remain with the caller.

Version: `v0.1.9`

## Widgets

Progress bars, indeterminate progress, spinners, status messages, tables, text input, sliders,
checkboxes, and buttons. Width-aware layout comes from
[`termcolor-layout`](https://github.com/jonaprieto/lean-termcolor-layout).

```lean
import TermColor.Widgets

open TermColor TermColor.Widgets

def progress : Text := progressBar { width := 24 }
  { current := 7, total := 10, label := Text.plain "download" }

#eval progress.plainText
```

## Build

```sh
lake build TermColor.Widgets TermColor.Widgets.Properties demo
lake exe demo
```

## Related projects

[`termcolor-terminal`](https://github.com/jonaprieto/lean-termcolor-terminal) connects widgets
to live terminal output. Keep application state and event handling outside this package.

## License

Apache-2.0.
