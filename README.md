# lean-termcolor-widgets

[![CI](https://github.com/jonaprieto/lean-termcolor-widgets/actions/workflows/ci.yml/badge.svg)](https://github.com/jonaprieto/lean-termcolor-widgets/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/jonaprieto/lean-termcolor-widgets?display_name=tag&sort=semver)](https://github.com/jonaprieto/lean-termcolor-widgets/releases)
[![Lean 4](https://img.shields.io/badge/Lean%204-v4.33.1-6f42c1)](lean-toolchain)
[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-4c8bf5)](https://jonaprieto.github.io/lean-termcolor-widgets/)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

Pure terminal widgets for Lean 4. Rendering returns styled `TermColor.Text`; timing, terminal
size, focus, and output remain with the caller.

<p align="center"><img src="docs/assets/termcolor-widgets.png" alt="TermColor widgets demo" width="480"></p>

## Status and review

These libraries are actively evolving and are developed with AI assistance and human review.
CI and machine-checked proofs provide useful evidence, but do not guarantee correctness,
soundness, portability, performance, or suitability for every use case. Validate behavior
and assumptions before relying on a release.

Reviewer feedback is welcome, especially on correctness, proofs, API design, usability,
portability, performance, documentation, and real-world use. Please use the
[issue tracker](https://github.com/jonaprieto/lean-termcolor-widgets/issues) or open a PR with a
reproducible example and the expected behavior.

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
to live terminal output. [`termcolor`](https://github.com/jonaprieto/lean-termcolor) supplies the
text foundation; [`lean-calc-chat`](https://github.com/jonaprieto/lean-calc-chat) and
[`oatp`](https://github.com/jonaprieto/oatp) use the widgets in applications. Keep application
state and event handling outside this package.

## License

Apache-2.0.
