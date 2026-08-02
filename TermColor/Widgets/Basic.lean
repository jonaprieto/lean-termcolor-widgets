/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColor.Layout

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
  if label.segments.all (·.text.isEmpty) then Text.empty else label ++ Text.plain " "

private def afterFrameLabel (label : Text) : Text :=
  if label.segments.all (·.text.isEmpty) then Text.empty else Text.plain " " ++ label

/-- State displayed by a progress bar. `current` is clamped to `total` when rendered. -/
structure ProgressState where
  current : Nat := 0
  total : Nat := 0
  label : Text := Text.empty
  deriving BEq, DecidableEq, Repr

instance : Inhabited ProgressState := ⟨{}⟩

/-- Rendering choices for a progress bar. `width` is the display width without brackets or
suffixes. -/
structure ProgressConfig where
  width : Nat := 30
  filledChar : Char := '━'
  emptyChar : Char := '─'
  filledStyle : Style := Style.green
  emptyStyle : Style := Style.dim
  percentageStyle : Style := {}
  showPercentage : Bool := true
  indeterminateWidth : Nat := 8
  deriving BEq, DecidableEq, Repr

instance : Inhabited ProgressConfig := ⟨{}⟩

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
  deriving BEq, DecidableEq, Repr

instance : Inhabited IndeterminateProgressState := ⟨{}⟩

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
  deriving BEq, DecidableEq, Repr

instance : Inhabited SpinnerState := ⟨{}⟩

/-- Rendering choices for a spinner. Empty frame lists render as an empty frame safely. -/
structure SpinnerConfig where
  frames : List Text := defaultSpinnerFrames
  prefixText : Text := Text.empty
  suffixText : Text := Text.empty
  deriving BEq, DecidableEq, Repr

instance : Inhabited SpinnerConfig := ⟨{}⟩

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
  deriving BEq, DecidableEq, Repr, Inhabited

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
  Layout.joinLines (rows.map fun row => Layout.columns widths gap row alignments)

/-- Keyboard input understood by pure interactive widgets. -/
inductive Key where
  | char (value : Char)
  | left
  | right
  | up
  | down
  | enter
  | backspace
  | delete
  | tab
  | escape
  deriving BEq, DecidableEq, Repr

/-- State for a single-line text input. `cursor` is a code-point offset. -/
structure TextInputState where
  value : String := ""
  cursor : Nat := 0
  deriving BEq, DecidableEq, Repr

instance : Inhabited TextInputState := ⟨{}⟩

/-- Rendering and input limits for a text input. -/
structure TextInputConfig where
  width : Nat := 20
  maxLength : Nat := 80
  label : Text := Text.empty
  textStyle : Style := {}
  cursorStyle : Style := Style.reverse
  deriving BEq, DecidableEq, Repr

instance : Inhabited TextInputConfig := ⟨{}⟩

private def clampCursor (state : TextInputState) : Nat :=
  min state.cursor state.value.toList.length

private def insertChar (value : String) (index : Nat) (character : Char) : String :=
  let characters := value.toList
  String.ofList (characters.take index ++ [character] ++ characters.drop index)

private def deleteChar (value : String) (index : Nat) : String :=
  let characters := value.toList
  String.ofList (characters.take index ++ characters.drop (index + 1))

/-- Apply one key to a text input. Input is limited by `maxLength`. -/
def updateTextInput (config : TextInputConfig) (key : Key) (state : TextInputState) :
    TextInputState :=
  let cursor := clampCursor state
  let length := state.value.toList.length
  match key with
  | .char character =>
      if length < config.maxLength then
        { value := insertChar state.value cursor character, cursor := cursor + 1 }
      else
        { state with cursor }
  | .left => { state with cursor := cursor.pred }
  | .right => { state with cursor := min length (cursor + 1) }
  | .backspace =>
      if cursor == 0 then
        { state with cursor }
      else
        { value := deleteChar state.value (cursor - 1), cursor := cursor - 1 }
  | .delete =>
      if cursor < length then
        { value := deleteChar state.value cursor, cursor }
      else
        { state with cursor }
  | _ => { state with cursor }

private def inputContent (config : TextInputConfig) (state : TextInputState)
    (focused : Bool) : Text :=
  let characters := state.value.toList.take config.width
  let cursor := min (clampCursor state) characters.length
  let before := String.ofList (characters.take cursor)
  let cursorCharacter := (characters.drop cursor).head?.getD ' '
  -- ponytail: code-point cursor; add grapheme/display-cell editing when Unicode input needs it.
  let dropIndex := if focused && cursor < characters.length then Nat.succ cursor else cursor
  let after := String.ofList (characters.drop dropIndex)
  let cursorText := if focused then
      let style := Style.combine config.textStyle config.cursorStyle
      Text.styled (String.singleton cursorCharacter) style
    else Text.empty
  Text.styled before config.textStyle ++
    (if focused then cursorText else Text.empty) ++
    Text.styled after config.textStyle ++
    Text.styled (String.ofList (List.replicate (config.width - characters.length) ' '))
      config.textStyle

/-- Render a single-line input with an optional visible cursor. -/
def renderTextInput (config : TextInputConfig) (state : TextInputState)
    (focused : Bool := false) : Text :=
  withLabel config.label ++ Text.plain "[" ++ inputContent config state focused ++ Text.plain "]"

/-- State for an integer slider. Values are clamped to the configured range. -/
structure SliderState where
  value : Nat := 0
  deriving BEq, DecidableEq, Repr

instance : Inhabited SliderState := ⟨{}⟩

/-- Rendering and movement choices for an integer slider. -/
structure SliderConfig where
  width : Nat := 12
  min : Nat := 0
  max : Nat := 10
  step : Nat := 1
  label : Text := Text.empty
  filledChar : Char := '━'
  emptyChar : Char := '─'
  filledStyle : Style := Style.cyan
  emptyStyle : Style := Style.dim
  valueStyle : Style := {}
  deriving BEq, DecidableEq, Repr

instance : Inhabited SliderConfig := ⟨{}⟩

private def sliderMax (config : SliderConfig) : Nat := max config.min config.max

/-- Clamp a slider value, treating a reversed range as a single-value range. -/
def sliderValue (config : SliderConfig) (state : SliderState) : Nat :=
  min (sliderMax config) (max config.min state.value)

/-- Apply one key to an integer slider. -/
def updateSlider (config : SliderConfig) (key : Key) (state : SliderState) : SliderState :=
  let value := sliderValue config state
  let high := sliderMax config
  match key with
  | .left | .down => { value := value - config.step }
  | .right | .up => { value := min high (value + config.step) }
  | _ => { value }

/-- Render an integer slider as a terminal bar and its current value. -/
def renderSlider (config : SliderConfig) (state : SliderState) : Text :=
  let value := sliderValue config state
  let high := sliderMax config
  let span := high - config.min
  let offset := value - config.min
  let filled := if span == 0 then 0 else config.width * offset / span
  let empty := config.width - filled
  withLabel config.label ++ Text.plain "[" ++
    repeatToWidth config.filledChar config.filledStyle filled ++
    repeatToWidth config.emptyChar config.emptyStyle empty ++ Text.plain "] " ++
    Text.styled (toString value) config.valueStyle

/-- State for a checkbox. -/
structure CheckboxState where
  checked : Bool := false
  deriving BEq, DecidableEq, Repr

instance : Inhabited CheckboxState := ⟨{}⟩

/-- Rendering choices for a checkbox. -/
structure CheckboxConfig where
  label : Text := Text.empty
  checkedText : Text := Text.plain "x"
  uncheckedText : Text := Text.plain " "
  deriving BEq, DecidableEq, Repr

instance : Inhabited CheckboxConfig := ⟨{}⟩

/-- Toggle a checkbox on activation. -/
def updateCheckbox (key : Key) (state : CheckboxState) : CheckboxState :=
  match key with
  | .char ' ' | .enter => { checked := !state.checked }
  | _ => state

/-- Render a checkbox with its label. -/
def renderCheckbox (config : CheckboxConfig) (state : CheckboxState) : Text :=
  Text.plain "[" ++ (if state.checked then config.checkedText else config.uncheckedText) ++
    Text.plain "]" ++ afterFrameLabel config.label

/-- Whether a key activates a button. -/
def buttonActivated : Key → Bool
  | .enter | .char ' ' => true
  | _ => false

/-- Render a terminal button, highlighting it when focused. -/
def renderButton (label : Text) (focused : Bool := false) : Text :=
  let content := Text.plain "[" ++ label ++ Text.plain "]"
  if focused then Text.styled content.plainText Style.reverse else content

end Widgets
end TermColor
