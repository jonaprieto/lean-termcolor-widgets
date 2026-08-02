/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColor.Widgets
import TermColor.ColorScheme
import TermColor.Detect

open TermColor
open TermColor.Widgets
open scoped TermColor.Style

private def demoPalette : ColorScheme := ColorScheme.catppuccin

private def heading (title : String) : Text :=
  Text.styled ("\n" ++ title ++ "\n") (Style.bold <+> Style.fg demoPalette.foreground)

private def renderLine (target : RenderTarget) (text : Text) : IO Unit :=
  IO.print (Text.render target (text ++ Text.plain "\n"))

def main : IO Unit := do
  let target ← TermColor.target
  renderLine target (Text.styled "termcolor-widgets" (Style.bold <+> Style.fg demoPalette.cyan))
  renderLine target (Text.plain "Pure CLI display rendering")
  renderLine target (heading "progress bars")
  renderLine target (progressBar { width := 28 }
    { current := 7, total := 10, label := Text.styled "download" (Style.fg demoPalette.cyan) })
  renderLine target (progressBar
    { width := 28, filledStyle := Style.fg demoPalette.blue
      , emptyStyle := Style.dim <+> Style.fg demoPalette.comment }
    { current := 3, total := 10, label := Text.styled "compile" (Style.fg demoPalette.yellow) })
  renderLine target (progressBar { width := 28, showPercentage := false }
    { current := 5, total := 10
      , label := Text.styled "quiet" (Style.dim <+> Style.fg demoPalette.comment) })
  renderLine target (progressBar
    { width := 28, filledChar := '#', emptyChar := '.'
      , filledStyle := Style.fg demoPalette.green
      , emptyStyle := Style.fg demoPalette.comment
      , percentageStyle := Style.bold <+> Style.fg demoPalette.foreground }
    { current := 2, total := 10, label := Text.styled "custom glyphs" (Style.fg demoPalette.cyan) })
  renderLine target (progressBar { width := 28 }
    { current := 0, total := 0, label := Text.styled "nothing to do" (Style.fg demoPalette.green) })
  renderLine target (progressBar { width := 28 }
    { current := 12, total := 10, label := Text.styled "clamped" (Style.fg demoPalette.purple) })
  renderLine target (indeterminateProgressBar { width := 28, indeterminateWidth := 7 }
    { frame := 8, label := Text.styled "unknown progress" (Style.fg demoPalette.cyan) })
  renderLine target (heading "spinners")
  renderLine target (renderSpinner { prefixText := Text.plain "  " }
    { frame := 3, label := Text.styled "default braille frame" (Style.fg demoPalette.green) })
  renderLine target (renderSpinner
    { frames := [Text.styled "◐" (Style.fg demoPalette.cyan)
      , Text.styled "◓" (Style.fg demoPalette.cyan)
      , Text.styled "◑" (Style.fg demoPalette.cyan)
      , Text.styled "◒" (Style.fg demoPalette.cyan)]
      prefixText := Text.plain "  ", suffixText := Text.plain " ..." }
    { frame := 6
      , label := Text.styled "custom frames" (Style.bold <+> Style.fg demoPalette.purple) })
  renderLine target (renderSpinner { frames := [Text.plain "|", Text.plain "/", Text.plain "-"] }
    { frame := 10, label := Text.plain "frame indices wrap" })
  renderLine target (heading "status messages")
  renderLine target (renderStatus .success
    (Text.styled "build complete" (Style.fg demoPalette.green)))
  renderLine target (renderStatus .warning
    (Text.styled "using a fallback" (Style.fg demoPalette.yellow)))
  renderLine target (renderStatus .error (Text.styled "build failed" (Style.fg demoPalette.red)))
  renderLine target (heading "tables")
  renderLine target (renderTable [14, 10, 8]
    [[Text.styled "task" (Style.bold <+> Style.fg demoPalette.purple)
      , Text.styled "status" (Style.bold <+> Style.fg demoPalette.purple)
      , Text.styled "time" (Style.bold <+> Style.fg demoPalette.purple)]
     , [Text.plain "download", Text.styled "done" (Style.fg demoPalette.green), Text.plain "2.1s"]
     , [Text.plain "compile", Text.styled "running" (Style.fg demoPalette.yellow),
        Text.plain "..."]])
  renderLine target (heading "pure controls")
  let nameConfig : TextInputConfig :=
    { width := 16, maxLength := 16
      , label := Text.styled "name: " (Style.fg demoPalette.cyan) }
  let name := updateTextInput nameConfig (.char 'L') {}
  let name := updateTextInput nameConfig (.char 'e') name
  let name := updateTextInput nameConfig (.char 'a') name
  renderLine target (renderTextInput nameConfig name true)
  let sliderConfig : SliderConfig :=
    { width := 12, label := Text.styled "volume: " (Style.fg demoPalette.blue) }
  let volume := updateSlider sliderConfig .right { value := 6 }
  renderLine target (renderSlider sliderConfig volume)
  let enabled := updateCheckbox (.char ' ') {}
  renderLine target
    (renderCheckbox { label := Text.styled "enabled" (Style.fg demoPalette.green) } enabled)
  renderLine target (renderButton (Text.styled "save" (Style.fg demoPalette.purple)) true)
  renderLine target (heading "plain rendering")
  renderLine target (Text.plain "Text.plainText removes styles while preserving visible output.")
