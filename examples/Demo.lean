/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColorWidgets

open TermColor
open TermColor.Widgets
open scoped TermColor.Style

private def heading (title : String) : Text :=
  Text.styled ("\n" ++ title ++ "\n") (Style.bold <+> Style.fg (.indexed 250))

private def renderLine (text : Text) : IO Unit :=
  IO.print (Text.render RenderTarget.ansi16 (text ++ Text.plain "\n"))

def main : IO Unit := do
  renderLine (Text.styled "termcolor-widgets" (Style.bold <+> Style.fg (.indexed 45)))
  renderLine (Text.plain "Pure progress and spinner rendering")
  renderLine (heading "progress bars")
  renderLine (progressBar { width := 28 }
    { current := 7, total := 10, label := Text.styled "download" Style.cyan })
  renderLine (progressBar { width := 28, filledStyle := Style.blue, emptyStyle := Style.dim }
    { current := 3, total := 10, label := Text.styled "compile" Style.yellow })
  renderLine (progressBar { width := 28, showPercentage := false }
    { current := 5, total := 10, label := Text.styled "quiet" Style.dim })
  renderLine (progressBar
    { width := 28, filledChar := '#', emptyChar := '.', percentageStyle := Style.bold }
    { current := 2, total := 10, label := Text.styled "custom glyphs" Style.cyan })
  renderLine (progressBar { width := 28 }
    { current := 0, total := 0, label := Text.styled "nothing to do" Style.green })
  renderLine (progressBar { width := 28 }
    { current := 12, total := 10, label := Text.styled "clamped" Style.magenta })
  renderLine (heading "spinners")
  renderLine (renderSpinner { prefixText := Text.plain "  " }
    { frame := 3, label := Text.styled "default braille frame" Style.green })
  renderLine (renderSpinner
    { frames := [Text.styled "◐" Style.cyan, Text.styled "◓" Style.cyan
      , Text.styled "◑" Style.cyan, Text.styled "◒" Style.cyan]
      prefixText := Text.plain "  ", suffixText := Text.plain " ..." }
    { frame := 6, label := Text.styled "custom frames" Style.bold })
  renderLine (renderSpinner { frames := [Text.plain "|", Text.plain "/", Text.plain "-"] }
    { frame := 10, label := Text.plain "frame indices wrap" })
  renderLine (heading "plain rendering")
  renderLine (Text.plain "Text.plainText removes styles while preserving visible output.")
