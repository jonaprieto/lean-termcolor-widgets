import Lake
open Lake DSL

package «termcolor-widgets» where
  version := v!"0.1.1"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "847c5fa"

require «termcolor» from git
  "https://github.com/jonaprieto/lean-termcolor.git" @ "dc1f73e"

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
