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
  let marker := fun (index : Nat) => Text.plain (if state.focus == index then "> " else "  ")
  renderLine target (marker 0 ++ renderTextInput nameConfig state.name (state.focus == 0))
  renderLine target (marker 1 ++ renderSlider sliderConfig state.volume)
  renderLine target (marker 2 ++ renderCheckbox { label := Text.plain "enabled" } state.enabled)
  renderLine target (marker 3 ++ renderButton (Text.plain "save") (state.focus == 3))
  renderLine target (Text.styled "Tab focus  •  arrows edit  •  Enter save  •  Esc quit" Style.dim)

private def applyKey (state : DemoState) (key : Key) : DemoState × Bool :=
  match key with
  | .tab => ({ state with focus := (state.focus + 1) % 4 }, false)
  | _ =>
      match state.focus with
      | 0 => ({ state with name := updateTextInput nameConfig key state.name }, false)
      | 1 => ({ state with volume := updateSlider sliderConfig key state.volume }, false)
      | 2 => ({ state with enabled := updateCheckbox key state.enabled }, false)
      | _ => (state, buttonActivated key)

private def stty (command : String) : IO IO.Process.Output :=
  IO.Process.output { cmd := "sh", args := #["-c", command] }

private def withRawInput (action : IO Unit) : IO Unit := do
  let saved ← stty "stty -g < /dev/tty"
  if saved.exitCode != 0 then
    throw (IO.userError "could not read terminal settings")
  let configured ← stty "stty -echo -icanon min 1 time 1 < /dev/tty"
  if configured.exitCode != 0 then
    throw (IO.userError "could not configure raw terminal input")
  try
    action
  finally
    let restore := "stty " ++ saved.stdout.trimAscii.toString ++ " < /dev/tty"
    let _ ← stty restore

private def readByte : IO (Option UInt8) := do
  let bytes ← (← IO.getStdin).read 1
  pure bytes[0]?

private def readKey : IO (Option Key) := do
  match ← readByte with
  | none => pure none
  | some 27 =>
      match ← readByte with
      | some 91 =>
          match ← readByte with
          | some 65 => pure (some .up)
          | some 66 => pure (some .down)
          | some 67 => pure (some .right)
          | some 68 => pure (some .left)
          | _ => pure (some .escape)
      | _ => pure (some .escape)
  | some 13 | some 10 => pure (some .enter)
  | some 8 | some 127 => pure (some .backspace)
  | some 9 => pure (some .tab)
  | some byte =>
      if byte.toNat < 128 then
        pure (some (.char (Char.ofNat byte.toNat)))
      else
        pure none

private def interactiveDemo (target : RenderTarget) : IO Unit := withRawInput do
  IO.print "\u001b[?25l"
  try
    let mut state : DemoState := {}
    let mut finished := false
    while !finished do
      IO.print "\u001b[2J\u001b[H"
      renderForm target state
      match ← readKey with
      | none | some .escape => finished := true
      | some key =>
          let (next, activated) := applyKey state key
          state := next
          finished := activated
  finally
    IO.print "\u001b[?25h\u001b[2J\u001b[H"

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
