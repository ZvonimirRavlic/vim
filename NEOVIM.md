# Neovim setup (IntelliJ / IdeaVim mirror)

Neovim config in `nvim/` that reproduces `.ideavimrc` and the IntelliJ **"macOS copy"** keymap.
It's a standalone [lazy.nvim](https://github.com/folke/lazy.nvim) config (not LazyVim), so every mapping lives in
`nvim/lua/config/keymaps.lua` and nothing is hidden.

Legend: ✅ same behaviour · ≈ close equivalent (see note) · ❌ not mapped

## Install

```sh
brew install neovim ripgrep fd lazygit tree-sitter-cli   # already done
mv ~/.config/nvim ~/.config/nvim.lazyvim-starter          # old unused LazyVim starter
ln -s ~/vim/nvim ~/.config/nvim
nvim                                                       # plugins, parsers and language servers install on first start
```

The first time you open a Java file, jdtls imports the Gradle/Maven project (about 1 minute). Progress shows in the
bottom-right corner, like IntelliJ indexing. Each project root gets its own workspace in `~/.cache/nvim/jdtls/`.
Lombok works out of the box.

Leader is `Space`. `notimeout` is on, like in IdeaVim, and which-key pops up right away after `Space` or `g`.
`Space ?` searches every keymap.

## `.ideavimrc` → Neovim

### Settings

| IdeaVim                          | Neovim                                     |   |
|----------------------------------|--------------------------------------------|---|
| `relativenumber`, `number`       | same                                       | ✅ |
| `hlsearch`, `incsearch`          | same                                       | ✅ |
| `scrolloff=10`                   | same                                       | ✅ |
| `showmode`, `showcmd`            | same                                       | ✅ |
| `visualbell`                     | `belloff=all` (no bell at all)             | ≈ |
| `clipboard+=unnamed`             | `clipboard=unnamedplus` (system clipboard) | ✅ |
| `ideajoin`                       | `formatoptions+=j`: `J` removes comment leaders. No IntelliJ smart join for strings or `if` blocks | ≈ |
| `notimeout`                      | `timeout=false` (+ short `ttimeoutlen` so Alt keys stay fast) | ✅ |
| `which-key`, `WhichKey_ShowVimActions` | which-key.nvim (shows built-in vim actions too) | ✅ |
| `NERDTreeShowHidden`             | nvim-tree shows dotfiles and git-ignored files | ✅ |
| `surround`                       | nvim-surround (`ys`, `cs`, `ds`, visual `S`) | ✅ |
| `easymotion`                     | flash.nvim                                 | ✅ |
| `Plug 'machakann/vim-highlightedyank'` | built-in `vim.hl.on_yank` autocmd   | ✅ |
| `Plug 'preservim/nerdtree'`      | nvim-tree.lua                              | ✅ |
| `sethandler <c-j>/<c-k> a:vim`   | not needed, vim owns every key             | ✅ |

### Mappings

| Key | IntelliJ action | Neovim | |
|---|---|---|---|
| `Space j` | easymotion-s | `flash.jump()` | ✅ |
| `Space t` | ActivateTerminalToolWindow | bottom terminal panel with tabs (`Terminal 1  Terminal 2` bar). `Esc` focuses the editor; `Ctrl Alt h/l` switch terminal tabs inside it; `exit` closes a tab. Its height is remembered (also across restarts) after you resize it with the mouse, `:resize` or `Ctrl w +/-` | ✅ |
| `Cmd t` (in terminal) | New terminal tab | new tab in the terminal panel (opens the panel if needed). Passed through by WezTerm; `Space T` also works | ✅ |
| `Space c` | Open Claude in terminal | removed on request, Claude plugin uninstalled. Run `claude` in the terminal panel (`Space t`) instead | ❌ |
| `Space v` | MoveTabRight | move the current buffer into a new right split; the left split shows the previous buffer | ✅ |
| `Space h` | MoveTabDown | same, split below | ✅ |
| `Space u` | Unsplit | `:only` | ✅ |
| `Space m` | MoveEditorToOppositeTabGroup | move the buffer into the next split; the source split closes when it has nothing else to show | ✅ |
| `Space s` | CodeCompletion | enters insert after the cursor and opens the completion menu | ≈ |
| `Alt h/j/k/l` | window left/down/up/right | `<C-w>h/j/k/l`, also works from inside terminals | ✅ |
| `Ctrl Alt h` / `Ctrl Alt l` | PreviousTab / NextTab | bufferline previous/next. WezTerm doesn't bind these, so they always reach nvim | ✅ |
| `Ctrl o` / `Ctrl i` | Back / Forward | native jumplist (also covers LSP jumps) | ✅ |
| `Cmd w` | CloseContent | close the buffer and keep the layout. In the terminal panel it closes that terminal tab; other tool windows (tree, help) get hidden. Passed through by WezTerm; `Space w` also works | ✅ |
| `Esc` | `:noh` | same | ✅ |
| `Space l` | ReformatCode | conform.nvim (prettier for web files, stylua, LSP/jdtls for Java); works on a visual selection too | ✅ |
| `Space o` | OptimizeImports | jdtls organize imports; other languages use the LSP `source.organizeImports` | ✅ |
| `Space p` | SelectInProjectView | `:NvimTreeFindFile` | ✅ |
| `Space e` | RecentFiles | Telescope oldfiles (current project only) | ✅ |
| `Space f` | Find | Telescope fuzzy find in the current buffer | ≈ |
| `Space F` | FindInPath | Telescope live_grep (ripgrep) | ✅ |
| `Space ar` | Run | reruns the last run configuration (asks the first time) | ≈ |
| `Space ad` | Debug | `dap.continue()`; Java main classes are detected automatically by jdtls | ✅ |
| `Space ac` | Run configuration selector | picker: Gradle bootRun/build/test/clean build, Maven spring-boot:run/test/install, every `npm` script, JUnit class or nearest method (Java buffer), custom command | ≈ |
| `Space as` | Stop | sends Ctrl-C to the run terminal and stops the debug session | ✅ |
| `gi` | GotoImplementation | Telescope LSP implementations | ✅ |
| `gs` | GotoSuperMethod | jdtls `super_implementation`; other languages use the LSP supertypes hierarchy | ✅ |
| `gu` | GotoDeclaration | jumps to the declaration. **On the declaration itself it shows usages**, like IntelliJ | ✅ |
| `ge` / `gE` | Next / previous error | `vim.diagnostic.jump` over warnings and errors, opens the float | ✅ |
| `gn`, `gc` | GotoClass | fuzzy match on the **class name only** (`enpulseapp` → `EnpulseServiceApplication`). **Project classes always rank first**, then library classes (JDK, Spring, …) from jdtls as you type. Within each group: exact name, then names starting with your text, then other fuzzy matches. Tests are tagged `test`, libraries `library` | ✅ |
| `gf` | GotoFile | Telescope find_files (hidden files included) | ✅ |
| `gr` | GotoRelated | Java/Kotlin: `Foo` ↔ `FooTest`/`FooTests`/`FooIT`. Other languages: sibling files with the same stem (`x.component.ts` ↔ `.html`/`.scss`/`.spec.ts`) | ≈ |
| `gc` | ActivateAIAssistantToolWindow | changed on request: `gc` is now **Goto class** (same as `gn`) | ❌ |
| `Ctrl t` | NERDTree | `:NvimTreeToggle` | ✅ |
| `Ctrl d` / `Ctrl u` | half page + `zz` | same | ✅ |
| `Space rn` | RenameElement | LSP rename | ✅ |
| `Space rm` | ExtractMethod | jdtls extract method (normal and visual); other languages use an LSP extract code action | ✅ |
| `Space rv` | IntroduceVariable | jdtls extract variable (replaces all occurrences) | ✅ |
| `Space rf` | IntroduceField | LSP refactor code actions filtered to "field" | ≈ |
| `Space rs` | ChangeSignature | LSP refactor code actions filtered to "signature". jdtls has no IntelliJ-style dialog | ≈ |
| `Space rc` | CodeCleanup | organize imports, then reformat. Inspection-based cleanups don't exist | ≈ |
| `Space rr` | Refactor This… | LSP code action menu, refactor kinds only | ✅ |
| `Space gu` | Update Project | `:Git pull` (fugitive) | ✅ |
| `Space gb` | Git Branches | Telescope git_branches (Enter checks out) | ✅ |
| `Space gc` | Commit | `:Git` status window (`s` stage, `cc` commit, `=` inline diff) | ≈ |
| `Space gp` | Push | `:Git push` | ✅ |
| `Space gr` | PR review in editor | `:Octo review start` (octo.nvim, uses your `gh` auth) | ≈ |

## IntelliJ keymap customisations ("macOS copy" + "Windows Proper Redo")

| IntelliJ shortcut | Action | Neovim | |
|---|---|---|---|
| `Ctrl Alt h/l`, `Ctrl ←/→` | PreviousTab / NextTab | bufferline cycle | ✅ |
| `Shift Cmd [` / `]` | PreviousTab / NextTab | — (WezTerm uses these) | ❌ |
| `Cmd Alt c` | AI Assistant | removed, Claude plugin uninstalled | ❌ |
| `Esc` / `Shift Esc` in terminal | Terminal → focus editor | `Esc` in the `Space t` shell. If you run `claude` there, it needs `Esc` too: leave the panel with `Alt h/j/k/l` instead | ≈ |
| `Alt j` / `Alt k` (insert) | EditorDown / EditorUp | insert mode `<Down>`/`<Up>` | ✅ |
| `Alt j` / `Alt k` in popups/lists | select next/previous row | completion menu and Telescope pickers | ✅ |
| `Alt d` (insert) | Delete line | `<C-o>dd` | ✅ |
| `Shift Ctrl z`, `Ctrl y` (Windows keymap) | Redo | vim `Ctrl r` | ❌ (Windows keymap isn't active) |

## Extras I added (not in your IntelliJ config)

| Key | What |
|---|---|
| `Space w` | Close tab, a terminal-friendly `Cmd w` |
| `Space T` | New terminal tab (same as `Cmd t`) |
| `Alt Enter` | Show intention actions (LSP code actions) |
| `Alt F7` | Find usages |
| `Shift F6` | Rename |
| `Ctrl Space` / `Tab` / `Enter` | Completion: open / accept |
| `Space /`, `Cmd /`, visual `gc` | Toggle comment (normal `gc`/`gcc` now go to Goto class) |
| `Space gg` | **LazyGit** (floating) |
| `Space gd` / `Space gh` | Diffview: working-tree diff / current file history |
| `Space gl` | Blame popup for the current line |
| `Space x` | Problems tool window (Trouble) |
| `Space ,` | Open tabs (buffer picker) |
| `Space .` | Resume the last Telescope search |
| `Space ?` | Search keymaps |
| `Space ab` | Toggle breakpoint |
| `Space au` | Toggle the debugger UI (it also opens and closes by itself) |
| `F8` / `F7` / `Shift F8` / `F9` | Step over / into / out / resume (IntelliJ macOS debug keys) |

Behaviour extras: **autosave** when leaving a buffer or when the terminal loses focus (like IntelliJ), files changed
on disk reload automatically, inline git blame (GitToolBox), rainbow brackets, indent guides, auto-closing brackets,
Gruvbox Dark Hard (your IntelliJ scheme), parameter hints while typing.

## Vim keys that are overridden on purpose (same as your `.ideavimrc`)

`gi` (insert at last insert spot), `gs` (sleep), `gu` (lowercase operator; `gU` still works), `ge`/`gE`
(backward word end), `gn` (select next match), `gc`/`gcc` in normal mode (comment; use `Space /` or visual `gc`), `gf` (open the path under the cursor), `gr` (virtual replace),
`Ctrl t` (tag stack). Neovim's default LSP keys
`grn`/`grr`/`gri`/`gra`/`grt` are removed so `gr` fires immediately.

## Not mapped / not reproduced

| IntelliJ thing | Why / alternative |
|---|---|
| Codeium / Full Line / AI inline completion | Not installed. `windsurf.nvim` or `copilot.lua` can be added |
| SonarLint | `sonarlint.nvim` exists but needs extra setup, so it's left out |
| JPA Buddy, RoboPOJOGenerator, Builder generator, java2json | No equivalent. jdtls code actions can generate getters/setters/constructors/`toString`/`equals` (`Alt Enter`) |
| MavenHelper (dependency tree) | Run `./gradlew dependencies` or `mvn dependency:tree` through `Space ac` → Custom command |
| REST Client (`.http` files) | Not added; `kulala.nvim` would cover it |
| CamelCase / case-conversion plugin | Not added; `text-case.nvim` would cover it |
| VisualVM launcher, Docker/Kubernetes tool windows | Use the terminal (`Space t`) or LazyGit-style TUIs (`lazydocker`, `k9s`) |
| Spring-aware run gutter icons, bean navigation | jdtls has no Spring Tools. Run apps through `Space ac` |
| `MoveTabRight` keeping the tab order | Neovim buffers are global, not per split; the split just shows the buffer |
| IntelliJ `Find` replace bar | Use `:%s/…/…/gc` |
| Default IntelliJ `Cmd`-based shortcuts (`Cmd e`, `Cmd Shift o`, …) | The terminal swallows `Cmd`; the leader equivalents above cover them |

## WezTerm notes

1. **Applied:** `Cmd t` and `Cmd w` in `~/.wezterm.lua` are nvim-aware. When nvim is the foreground process
   they go to nvim (`Cmd t` is sent as `\x1b[116;9u`, which nvim reads as `<D-t>`); otherwise they do the usual
   WezTerm thing (new tab / close tab). `Cmd w` is sent as `\x1b[119;9u` (`<D-w>`). See `nvim_aware` in `~/.wezterm.lua`.
   WezTerm tabs switch with `Cmd Shift h/l` (always, even over nvim); `Ctrl Alt h/l` is left to nvim.

2. Option works as Alt by default in WezTerm (`send_composed_key_when_left_alt_is_pressed = false`), so the
   `Alt h/j/k/l` window keys work. If they ever type `˙∆˚¬`, that setting changed.

## File layout

```
nvim/
├── init.lua
├── lazy-lock.json            # pinned plugin versions
└── lua/
    ├── config/
    │   ├── options.lua       # set … from .ideavimrc
    │   ├── keymaps.lua       # every mapping in this document
    │   ├── autocmds.lua      # highlight yank, autosave, reload
    │   └── lazy.lua          # plugin manager bootstrap
    ├── plugins/
    │   ├── ui.lua            # gruvbox, bufferline, lualine, which-key, rainbow, trouble
    │   ├── editor.lua        # nvim-tree, telescope, flash, surround, toggleterm
    │   ├── git.lua           # gitsigns, fugitive, diffview, lazygit, octo
    │   ├── lsp.lua           # mason, LSP servers, blink.cmp, conform, treesitter
    │   ├── java.lua          # nvim-jdtls (Lombok, debug + JUnit bundles)
    │   └── dap.lua           # debugger + UI
    └── util/
        ├── init.lua          # IntelliJ tab/split/goto helpers
        ├── run.lua           # run configurations
        └── terminal.lua      # terminal tool window
```
