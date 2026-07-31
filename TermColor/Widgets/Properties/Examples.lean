/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jonathan Prieto-Cubides
-/

import TermColor.Widgets.Properties.Basic

set_option maxRecDepth 10000

namespace TermColor
namespace Widgets

theorem styled_progress_example :
    Text.plainText (progressBar
      { width := 10, filledStyle := Style.cyan, emptyStyle := Style.dim }
      { current := 7, total := 10, label := Text.plain "download" }) =
      "download [━━━━━━━───] 70%" := by
  decide

theorem custom_spinner_example :
    (renderSpinner
      { frames := [Text.plain "◐", Text.plain "◓", Text.plain "◑", Text.plain "◒"] }
      { frame := 6, label := Text.plain "sync" }).plainText = "◑ sync" := by
  decide

end Widgets
end TermColor
