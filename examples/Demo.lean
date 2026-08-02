/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColor.Widgets
import TermColor.Detect

open TermColor
open TermColor.Widgets
open scoped TermColor.Style

private def heading (title : String) : Text :=
  Text.styled ("\n" ++ title ++ "\n") (Style.bold <+> Style.fg (.indexed 250))

private def renderLine (target : RenderTarget) (text : Text) : IO Unit :=
  IO.print (Text.render target (text ++ Text.plain "\n"))

private def nameConfig : TextInputConfig :=
  { width := 16, maxLength := 16, label := Text.plain "name: " }

private def sliderConfig : SliderConfig :=
  { width := 12, label := Text.plain "volume: " }

private structure DemoState where
  name : TextInputState := {}
  volume : SliderState := { value := 5 }
  enabled : CheckboxState := {}
  focus : Nat := 0

private def renderForm (target : RenderTarget) (state : DemoState) : IO Unit := do
  renderLine target (heading "interactive controls")
  renderLine target (renderTextInput nameConfig state.name (state.focus == 0))
  renderLine target (renderSlider sliderConfig state.volume)
  renderLine target (renderCheckbox { label := Text.plain "enabled" } state.enabled)
  renderLine target (renderButton (Text.plain "save") (state.focus == 3))

private def commandKey (input : String) : Option Key :=
  match input.trimAscii.toString with
  | "tab" => some .tab
  | "left" => some .left
  | "right" => some .right
  | "up" => some .up
  | "down" => some .down
  | "backspace" => some .backspace
  | "delete" => some .delete
  | "space" => some (.char ' ')
  | "enter" => some .enter
  | command =>
      match command.toList with
      | [character] => some (.char character)
      | _ => none

private def applyKey (state : DemoState) (key : Key) : DemoState × Bool :=
  match key with
  | .tab => ({ state with focus := (state.focus + 1) % 4 }, false)
  | _ =>
      match state.focus with
      | 0 => ({ state with name := updateTextInput nameConfig key state.name }, false)
      | 1 => ({ state with volume := updateSlider sliderConfig key state.volume }, false)
      | 2 => ({ state with enabled := updateCheckbox key state.enabled }, false)
      | _ => (state, buttonActivated key)

private def interactiveDemo (target : RenderTarget) : IO Unit := do
  IO.println "Interactive mode. Commands: tab, left, right, up, down, backspace, space, enter."
  IO.println "Use `text VALUE` to replace the name, `q` to quit."
  let mut state : DemoState := {}
  let mut finished := false
  while !finished do
    renderForm target state
    IO.print "command> "
    let input ← (← IO.getStdin).getLine
    let command := input.trimAscii.toString
    if command == "q" then
      finished := true
    else if command.startsWith "text " then
      let value := (command.drop 5).toString
      state := { state with name := { value, cursor := value.toList.length } }
    else
      match commandKey input with
      | some key =>
          let (next, activated) := applyKey state key
          state := next
          finished := activated
      | none => IO.println "Unknown command. Use `tab`, `text VALUE`, or `q`."
  IO.println "Done."

private def renderDemo (target : RenderTarget) : IO Unit := do
  renderLine target (Text.styled "termcolor-widgets" (Style.bold <+> Style.fg (.indexed 45)))
  renderLine target (Text.plain "Pure CLI display rendering")
  renderLine target (heading "progress bars")
  renderLine target (progressBar { width := 28 }
    { current := 7, total := 10, label := Text.styled "download" Style.cyan })
  renderLine target (progressBar { width := 28, filledStyle := Style.blue, emptyStyle := Style.dim }
    { current := 3, total := 10, label := Text.styled "compile" Style.yellow })
  renderLine target (progressBar { width := 28, showPercentage := false }
    { current := 5, total := 10, label := Text.styled "quiet" Style.dim })
  renderLine target (progressBar
    { width := 28, filledChar := '#', emptyChar := '.', percentageStyle := Style.bold }
    { current := 2, total := 10, label := Text.styled "custom glyphs" Style.cyan })
  renderLine target (progressBar { width := 28 }
    { current := 0, total := 0, label := Text.styled "nothing to do" Style.green })
  renderLine target (progressBar { width := 28 }
    { current := 12, total := 10, label := Text.styled "clamped" Style.magenta })
  renderLine target (indeterminateProgressBar { width := 28, indeterminateWidth := 7 }
    { frame := 8, label := Text.styled "unknown progress" Style.cyan })
  renderLine target (heading "spinners")
  renderLine target (renderSpinner { prefixText := Text.plain "  " }
    { frame := 3, label := Text.styled "default braille frame" Style.green })
  renderLine target (renderSpinner
    { frames := [Text.styled "◐" Style.cyan, Text.styled "◓" Style.cyan
      , Text.styled "◑" Style.cyan, Text.styled "◒" Style.cyan]
      prefixText := Text.plain "  ", suffixText := Text.plain " ..." }
    { frame := 6, label := Text.styled "custom frames" Style.bold })
  renderLine target (renderSpinner { frames := [Text.plain "|", Text.plain "/", Text.plain "-"] }
    { frame := 10, label := Text.plain "frame indices wrap" })
  renderLine target (heading "status messages")
  renderLine target (renderStatus .success (Text.plain "build complete"))
  renderLine target (renderStatus .warning (Text.plain "using a fallback"))
  renderLine target (renderStatus .error (Text.plain "build failed"))
  renderLine target (heading "tables")
  renderLine target (renderTable [14, 10, 8]
    [[Text.styled "task" Style.bold, Text.styled "status" Style.bold,
      Text.styled "time" Style.bold],
     [Text.plain "download", Text.styled "done" Style.green, Text.plain "2.1s"],
     [Text.plain "compile", Text.styled "running" Style.yellow, Text.plain "..."]])
  renderLine target (heading "interactive controls")
  let previewState : DemoState :=
    { name := { value := "Lea", cursor := 3 }, volume := { value := 7 },
      enabled := { checked := true } }
  renderLine target (renderTextInput nameConfig previewState.name true)
  renderLine target (renderSlider sliderConfig previewState.volume)
  renderLine target (renderCheckbox { label := Text.plain "enabled" } previewState.enabled)
  renderLine target (renderButton (Text.plain "save") true)
  renderLine target (heading "plain rendering")
  renderLine target (Text.plain "Text.plainText removes styles while preserving visible output.")

def main : IO Unit := do
  let target ← TermColor.target
  let stdinIsTty ← (← IO.getStdin).isTty
  let forcedNonInteractive := (← IO.getEnv "TERMCOLOR_WIDGETS_NONINTERACTIVE").isSome
  let runningInCi := (← IO.getEnv "CI").isSome
  if stdinIsTty && !forcedNonInteractive && !runningInCi then
    interactiveDemo target
  else
    renderDemo target
