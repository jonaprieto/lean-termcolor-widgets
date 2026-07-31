# termcolor-widgets

Pure progress bars and spinners for Lean 4. Rendering returns styled `TermColor.Text`; the caller
owns timing, terminal size, and output. There is no IO, cursor control, timer, or FFI dependency.

The package depends on [`termcolor-layout`](https://github.com/jonaprieto/termcolor-layout) for
styled text and display-width-aware layout.

```lean
import TermColorWidgets

open TermColor
open TermColor.Widgets

def progress : Text :=
  progressBar { width := 24 }
    { current := 7, total := 10, label := Text.styled "download" Style.cyan }

def spinner : Text :=
  renderSpinner {}
    { frame := 3, label := Text.styled "working" Style.dim }

#eval progress.plainText -- download [━━━━━━━━━━━━━━━━────────] 70%
#eval spinner.plainText -- ⠸ working
```

`ProgressConfig.width` is the bar width excluding brackets, labels, and the percentage suffix.
Progress values are clamped to 100%; a zero total is treated as completed work and renders 100%.
Spinner frame indices wrap around the configured list, while an empty frame list renders safely as
an empty frame.

Build and run the full demo:

```sh
lake build TermColorWidgets WidgetsProperties demo
lake exe demo
```

`WidgetsProperties` contains machine-checked rendering examples. `examples/Demo.lean` exercises
default and custom progress bars, styled labels and bars, hidden percentages, zero and overflow
totals, default and custom spinners, frame wrapping, and plain rendering.

## License

Apache-2.0.
