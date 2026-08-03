import Lake
open Lake DSL

package «termcolor-widgets» where
  version := v!"0.1.3"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "d45b699afecb7cca8328778b1f7cc6a793b43dcd"

require «termcolor» from git
  "https://github.com/jonaprieto/lean-termcolor.git"
  @ "ac9a102562fa65435365758cf5fe5ac95c6a7a92"

@[default_target]
lean_lib «TermColor.Widgets» where
  roots := #[`TermColor.Widgets]
  globs := #[.andSubmodules `TermColor.Widgets]

lean_lib «TermColor.Widgets.Properties» where
  roots := #[`TermColor.Widgets.Properties]
  globs := #[.andSubmodules `TermColor.Widgets.Properties]

lean_exe «demo» where
  root := `Demo
  srcDir := "examples"
