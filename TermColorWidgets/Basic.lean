/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColorLayout

/-!
# TermColor.Widgets.Basic: pure progress and spinner rendering

Widgets own state-to-text rendering. A caller owns timers, terminal width, and output.
-/

namespace TermColor
namespace Widgets

private def repeatToWidth (character : Char) (style : Style) (width : Nat) : Text :=
  let characterWidth := Layout.charWidth character
  if characterWidth == 0 then
    Text.styled (String.ofList (List.replicate width ' ')) style
  else
    let count := width / characterWidth
    let used := count * characterWidth
    let glyphs := List.replicate count character ++ List.replicate (width - used) ' '
    Text.styled (String.ofList glyphs) style

private def withLabel (label : Text) : Text :=
  if label.plainText == "" then Text.empty else label ++ Text.plain " "

private def afterFrameLabel (label : Text) : Text :=
  if label.plainText == "" then Text.empty else Text.plain " " ++ label

private def joinTextLines : List Text → Text
  | [] => Text.empty
  | first :: rest => rest.foldl (fun result line => result ++ Text.plain "\n" ++ line) first

/-- State displayed by a progress bar. `current` is clamped to `total` when rendered. -/
structure ProgressState where
  current : Nat := 0
  total : Nat := 0
  label : Text := Text.empty

/-- Rendering choices for a progress bar. `width` is the display width without brackets or
suffixes. -/
structure ProgressConfig where
  width : Nat := 30
  indeterminateWidth : Nat := 8
  filledChar : Char := '━'
  emptyChar : Char := '─'
  filledStyle : Style := Style.green
  emptyStyle : Style := Style.dim
  percentageStyle : Style := {}
  showPercentage : Bool := true

/-- Percentage shown by a progress bar. Zero total means no work remains, so it is complete. -/
def progressPercent (state : ProgressState) : Nat :=
  if state.total == 0 then 100 else min 100 (state.current * 100 / state.total)

/-- Render a progress bar as styled text. The caller supplies the desired bar width explicitly. -/
def progressBar (config : ProgressConfig) (state : ProgressState) : Text :=
  let percent := progressPercent state
  let filled := config.width * percent / 100
  let empty := config.width - filled
  let bar := Text.plain "[" ++
    repeatToWidth config.filledChar config.filledStyle filled ++
    repeatToWidth config.emptyChar config.emptyStyle empty ++ Text.plain "]"
  let suffix := if config.showPercentage then
      Text.plain " " ++ Text.styled (toString percent ++ "%") config.percentageStyle
    else Text.empty
  withLabel state.label ++ bar ++ suffix

/-- State displayed by an indeterminate progress bar. The frame moves back and forth. -/
structure IndeterminateProgressState where
  frame : Nat := 0
  label : Text := Text.empty

/-- Moving segment offset for an indeterminate progress bar. -/
def indeterminateProgressOffset (config : ProgressConfig)
    (state : IndeterminateProgressState) : Nat :=
  let segmentWidth := min config.width (max 1 config.indeterminateWidth)
  let span := config.width - segmentWidth
  if span == 0 then 0
  else
    let position := state.frame % (2 * span)
    if position ≤ span then position else 2 * span - position

/-- Render a progress bar for work with no known total. The filled segment bounces at both ends.
The caller advances `state.frame`. -/
def indeterminateProgressBar (config : ProgressConfig)
    (state : IndeterminateProgressState) : Text :=
  let segmentWidth := min config.width (max 1 config.indeterminateWidth)
  let offset := indeterminateProgressOffset config state
  let trailing := config.width - offset - segmentWidth
  let bar := Text.plain "[" ++
    repeatToWidth config.emptyChar config.emptyStyle offset ++
    repeatToWidth config.filledChar config.filledStyle segmentWidth ++
    repeatToWidth config.emptyChar config.emptyStyle trailing ++ Text.plain "]"
  withLabel state.label ++ bar

/-- Default braille spinner frames. The caller advances the frame index. -/
def defaultSpinnerFrames : List Text :=
  [ Text.plain "⠋", Text.plain "⠙", Text.plain "⠹", Text.plain "⠸", Text.plain "⠼"
  , Text.plain "⠴", Text.plain "⠦", Text.plain "⠧", Text.plain "⠇", Text.plain "⠏" ]

/-- State displayed by a spinner. `frame` is selected modulo the configured frame count. -/
structure SpinnerState where
  frame : Nat := 0
  label : Text := Text.empty

/-- Rendering choices for a spinner. Empty frame lists render as an empty frame safely. -/
structure SpinnerConfig where
  frames : List Text := defaultSpinnerFrames
  prefixText : Text := Text.empty
  suffixText : Text := Text.empty

/-- Select a spinner frame, wrapping around the configured frame list. -/
def spinnerFrame (config : SpinnerConfig) (frame : Nat) : Text :=
  match config.frames with
  | [] => Text.empty
  | frames => frames.getD (frame % frames.length) Text.empty

/-- Render one spinner frame and its optional label as styled text. -/
def renderSpinner (config : SpinnerConfig) (state : SpinnerState) : Text :=
  config.prefixText ++ spinnerFrame config state.frame ++ afterFrameLabel state.label ++
    config.suffixText

/-- Common status markers for command-line messages. -/
inductive StatusKind where
  | success
  | info
  | warning
  | error

private def statusMarker : StatusKind → Text
  | .success => Text.styled "[ok]" Style.green
  | .info => Text.styled "[info]" Style.cyan
  | .warning => Text.styled "[warn]" Style.yellow
  | .error => Text.styled "[error]" Style.red

/-- Render a styled status marker followed by a message. -/
def renderStatus (kind : StatusKind) (message : Text) : Text :=
  statusMarker kind ++ Text.plain " " ++ message

/-- Render rows as fixed-width, display-aware columns. Cells wrap to their column width. -/
def renderTable (widths : List Nat) (rows : List (List Text))
    (gap : Nat := 2) (alignments : List Layout.Alignment := []) : Text :=
  joinTextLines (rows.map fun row => Layout.columns widths gap row alignments)

end Widgets
end TermColor
