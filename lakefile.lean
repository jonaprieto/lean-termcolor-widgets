import Lake
open Lake DSL

package «termcolor-widgets» where
  version := v!"0.1.4"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "56dfeb9bfc906c20ba79d2c9b0ab95152d532f0a"

require «termcolor» from git
  "https://github.com/jonaprieto/lean-termcolor.git"
  @ "0d5a6ba9ac64912a91fd724eb986a18fc0793b98"

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
