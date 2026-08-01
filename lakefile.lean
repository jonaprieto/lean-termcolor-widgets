import Lake
open Lake DSL

package «termcolor-widgets» where
  version := v!"0.1.0"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "7c627ca1785694d634baaf1ac3ea33a106902d87"

require «termcolor» from git
  "https://github.com/jonaprieto/lean-termcolor.git" @ "1d78a0ce44f3f97fe55f5b02d13fa42af55e8229"

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
