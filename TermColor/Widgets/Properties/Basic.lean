/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColor.Widgets

set_option maxRecDepth 10000

namespace TermColor
namespace Widgets

theorem zero_total_is_complete :
    (progressBar { width := 8 } { total := 0 }).plainText = "[━━━━━━━━] 100%" := by
  decide

theorem progress_clamps_overflow :
    (progressBar { width := 4 } { current := 9, total := 4 }).plainText = "[━━━━] 100%" := by
  decide

theorem progress_rounds_down :
    (progressBar { width := 5 } { current := 1, total := 3 }).plainText = "[━────] 33%" := by
  decide

theorem progress_wide_glyph_keeps_width :
    let text := progressBar { width := 5, filledChar := '界', emptyChar := '.' }
      { current := 1, total := 2 }
    text.plainText = "[界...] 50%" ∧ text.width = 11 := by
  decide

theorem progress_can_hide_percentage :
    (progressBar { width := 5, showPercentage := false } { current := 2, total := 4 }).plainText =
      "[━━───]" := by
  decide

theorem indeterminate_progress_moves_forward_and_back :
    let config : ProgressConfig := { width := 8, indeterminateWidth := 3 }
    indeterminateProgressOffset config { frame := 2 } = 2 ∧
      indeterminateProgressOffset config { frame := 5 } = 5 ∧
      indeterminateProgressOffset config { frame := 8 } = 2 := by
  decide

theorem indeterminate_progress_renders_without_percentage :
    (indeterminateProgressBar { width := 8, indeterminateWidth := 3 }
      { frame := 2 }).plainText = "[──━━━───]" := by
  decide

theorem progress_preserves_label_style :
    Text.render RenderTarget.ansi16
      (progressBar { width := 2 }
        { current := 1, total := 2, label := Text.styled "build" Style.bold }) =
      "\u001b[1mbuild\u001b[0m [\u001b[32m━\u001b[0m\u001b[2m─\u001b[0m] 50%" := by
  decide

theorem progress_preserves_bar_styles :
    Text.render RenderTarget.ansi16
      (progressBar { width := 1, percentageStyle := Style.cyan } { current := 1, total := 1 }) =
      "[\u001b[32m━\u001b[0m] \u001b[36m100%\u001b[0m" := by
  decide

theorem spinner_frames_wrap :
    (spinnerFrame { frames := [Text.plain "a", Text.plain "b", Text.plain "c"] } 4).plainText =
      "b" := by
  decide

theorem empty_spinner_is_safe :
    (spinnerFrame { frames := [] } 10).plainText = "" := by
  decide

theorem spinner_render_example :
    (renderSpinner
      { frames := [Text.plain "-", Text.plain "+"], prefixText := Text.plain "[",
        suffixText := Text.plain "]" }
      { frame := 1, label := Text.plain "work" }).plainText = "[+ work]" := by
  decide

theorem spinner_preserves_style :
    Text.render RenderTarget.ansi16
      (renderSpinner { frames := [Text.styled "*" Style.yellow] }
        { label := Text.styled "loading" Style.dim }) =
      "\u001b[33m*\u001b[0m \u001b[2mloading\u001b[0m" := by
  decide

theorem status_renders_marker_and_message :
    (renderStatus .warning (Text.plain "slow connection")).plainText =
      "[warn] slow connection" := by
  decide

theorem table_renders_fixed_width_rows :
    (renderTable [5, 5] [[Text.plain "name", Text.plain "state"],
      [Text.plain "build", Text.plain "done"]]).plainText =
      "name   state\nbuild  done " := by
  decide

theorem table_wraps_cells :
    (renderTable [4] [[Text.plain "hello"]]).plainText = "hell\no   " := by
  decide

end Widgets
end TermColor
