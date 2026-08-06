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

/-- Rendering choices for a moving brightness highlight. A zero phase step makes it breathe. -/
structure ShimmerConfig where
  base : Color := .rgb 100 100 100
  highlight : Color := .rgb 255 255 255
  band : Nat := 6
  phaseStep : Nat := 1
  deriving BEq, DecidableEq, Repr

instance : Inhabited ShimmerConfig := ⟨{}⟩

/-- State displayed by a shimmer. `frame` selects the current highlight phase. -/
structure ShimmerState where
  frame : Nat := 0
  deriving BEq, DecidableEq, Repr

instance : Inhabited ShimmerState := ⟨{}⟩

private def colorRgb : Color → Nat × Nat × Nat
  | .default => (0, 0, 0)
  | .ansi intensity basic =>
      let rgb := Color.ansi256Rgb (Color.ansiIndex intensity basic)
      (rgb.1, rgb.2.1, rgb.2.2)
  | .indexed index =>
      let rgb := Color.ansi256Rgb index
      (rgb.1, rgb.2.1, rgb.2.2)
  | .rgb red green blue => (red.toNat, green.toNat, blue.toNat)

private def interpolateChannel (base highlight amount : Nat) : UInt8 :=
  UInt8.ofNat ((base * (255 - amount) + highlight * amount) / 255)

private def interpolateColor (base highlight : Color) (amount : Nat) : Color :=
  let amount := min 255 amount
  if base == highlight then base
  else if amount == 0 then base
  else if amount == 255 then highlight
  else
    let (baseRed, baseGreen, baseBlue) := colorRgb base
    let (highlightRed, highlightGreen, highlightBlue) := colorRgb highlight
    .rgb (interpolateChannel baseRed highlightRed amount)
      (interpolateChannel baseGreen highlightGreen amount)
      (interpolateChannel baseBlue highlightBlue amount)

private def naturalDistance (left right : Nat) : Nat :=
  if left < right then right - left else left - right

private def shimmerLevel (band phase position : Nat) : Nat :=
  if band == 0 then 0
  else
    let distance := naturalDistance (position + band) phase
    if distance >= band then 0 else (band - distance) * 255 / band

private def shimmerCharacters (config : ShimmerConfig) (phase : Nat) (position : Nat) :
    List (Char × Style × Option String) → List (Char × Style × Option String)
  | [] => []
  | (character, style, link) :: rest =>
      if character == '\n' then
        (character, style, link) :: shimmerCharacters config phase 0 rest
      else
        let amount := shimmerLevel config.band phase (position * config.phaseStep)
        let color := interpolateColor config.base config.highlight amount
        let style := Style.combine style (Style.fg color)
        (character, style, link) ::
          shimmerCharacters config phase (position + Layout.charWidth character) rest

/-- Render a display-width-aware shimmer while preserving non-color text styles. -/
def shimmer (config : ShimmerConfig) (state : ShimmerState) (text : Text) : Text :=
  let span := text.width * config.phaseStep + 2 * config.band
  let phase := state.frame % max 1 span
  let characters := text.segments.flatMap fun segment =>
    segment.text.toList.map fun character => (character, segment.style, segment.link)
  let characters := shimmerCharacters config phase 0 characters
  { segments := characters.map fun (character, style, link) =>
      { text := character.toString, style, link } }

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
  | ctrl (value : Char)
  | left
  | right
  | home
  | end
  | up
  | down
  | pageUp
  | pageDown
  | enter
  | backspace
  | delete
  | tab
  | shiftTab
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
  | .home | .ctrl 'a' => { state with cursor := 0 }
  | .end | .ctrl 'e' => { state with cursor := length }
  | .ctrl 'u' =>
      { value := String.ofList (state.value.toList.drop cursor), cursor := 0 }
  | .ctrl 'k' =>
      { value := String.ofList (state.value.toList.take cursor), cursor }
  | .ctrl 'w' =>
      let before := state.value.toList.take cursor
      let trimmed := List.dropWhile (fun character => character == ' ') before.reverse
      let keptWithSpace := List.reverse
        (List.dropWhile (fun character => character != ' ') trimmed)
      let kept := List.reverse
        (List.dropWhile (fun character => character == ' ') keptWithSpace.reverse)
      { value := String.ofList (kept ++ state.value.toList.drop cursor), cursor := kept.length }
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

/-- Render the fixed-width input body without a frame, for embedding in a caller-owned layout. -/
def textInputBody (config : TextInputConfig) (state : TextInputState)
    (focused : Bool) : Text :=
  if config.width == 0 then Text.empty else
    let allCharacters := state.value.toList
    let cursor := clampCursor state
    let offset := cursor + 1 - config.width
    let characters := allCharacters.drop offset |>.take config.width
    let cursor := cursor - offset
    let before := String.ofList (characters.take cursor)
    let cursorCharacter := (characters.drop cursor).head?.getD ' '
    let dropIndex := if focused && cursor < characters.length then Nat.succ cursor else cursor
    let after := String.ofList (characters.drop dropIndex)
    let cursorText := if focused then
        let style := Style.combine config.textStyle
          config.cursorStyle
        Text.styled (String.singleton cursorCharacter) style
      else Text.empty
    let renderedLength := before.length + (if focused then 1 else 0) + after.length
    Text.styled before config.textStyle ++
      (if focused then cursorText else Text.empty) ++
      Text.styled after config.textStyle ++
      Text.styled (String.ofList (List.replicate (config.width - renderedLength) ' '))
        config.textStyle

/-- Render a single-line input with an optional visible cursor. -/
def renderTextInput (config : TextInputConfig) (state : TextInputState)
    (focused : Bool := false) : Text :=
  withLabel config.label ++ Text.plain "[" ++ textInputBody config state focused ++ Text.plain "]"

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
