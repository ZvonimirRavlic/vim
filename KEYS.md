# Keys: WezTerm, herdr, nvim

Each tool gets its own modifier, so they never fight over a key:

| Layer | Modifier | Config |
|---|---|---|
| **nvim** | `Space` leader, `Alt`, `Ctrl Alt h/l`, `Cmd T/W` | `nvim/`, full list in [NEOVIM.md](NEOVIM.md) |
| **herdr** (AI agents) | **`Cmd Alt`** (and the `Ctrl b` prefix) | `herdr/config.toml` → `~/.config/herdr/config.toml` |
| **WezTerm** | `Cmd Shift`, `Ctrl Shift` | `.wezterm.lua` → `~/.wezterm.lua` |

## herdr (`Cmd Alt`)

How to use it: run `herdr` in one WezTerm tab. One **workspace per repo**; in each workspace tab 1 is **nvim** and the other tabs are **agents**. Give each agent its own git worktree (`Ctrl b` `Shift g`), so agents work on separate branches and don't touch your checkout. The sidebar shows which agent is working, done or waiting.

No pane splits: herdr's sidebar lists **spaces** (one per repo) top to bottom, and each space has its
**tabs** (nvim, agents) side by side.

| Key | Action | Prefix equivalent |
|---|---|---|
| `Cmd Alt j` / `k` | Next / previous **space** (down / up the sidebar) | none |
| `Cmd Alt h` / `l` | Previous / next **tab** in the current space | `Ctrl b` `p` / `n` |
| `Cmd Alt n` / `p` | Next / previous **agent**, across all spaces | none |
| `Cmd Alt 1`–`9` | Go to tab N | `Ctrl b` `1`–`9` |
| `Cmd Alt t` | New tab | `Ctrl b` `c` |
| `Cmd Alt o` | Jump to the agent that's waiting for you (last notification) | `Ctrl b` `o` |
| `Cmd Alt s` | Space (project) picker | `Ctrl b` `w` |
| `Cmd Alt v` | **Copy mode**: navigate the pane's history (`hjkl`, `w/b/e`, `Ctrl u/d`, `/` search, `n/N`), `v` select, `y` copy, `q`/`Esc` back to typing | `Ctrl b` `[` |
| `Cmd Alt g` | lazygit in a popup | none |
| `Cmd Alt w` | **Close the current tab** (no confirmation, agent included) | `Ctrl b` `Shift x` |

Prefix-only (on purpose, so a slip can't kill an agent; `Cmd Alt w` above is the one exception):

| Key | Action |
|---|---|
| `Ctrl b` `Shift n` | New workspace |
| `Ctrl b` `Shift g` | New git worktree + workspace for an agent |
| `Ctrl b` `x` | Close pane |
| `Ctrl b` `Shift x` | Close tab |
| `Ctrl b` `Shift d` | Close workspace |
| `Ctrl b` `v` / `-` | Split right / down (not used day to day) |
| `Ctrl b` `h/j/k/l` | Move between split panes |
| `Ctrl b` `r` | Resize mode |
| `Ctrl b` `e` | Open scrollback in an editor |
| `Ctrl b` `b` | Toggle sidebar |
| `Ctrl b` `q` | Detach (agents keep running; `herdr` reattaches) |
| `Ctrl b` `?` | All bindings |

`Cmd T` / `Cmd W` keep their nvim meaning inside herdr: WezTerm forwards them through herdr to the focused pane.

## WezTerm

| Key | Action |
|---|---|
| `Cmd Shift h` / `l` | Previous / next WezTerm tab (always, also over nvim and herdr) |
| `Cmd Shift T` | New WezTerm tab (always) |
| `Cmd T` / `Cmd W` | New / close WezTerm tab, **except** when nvim or herdr runs in the tab (then they go to nvim) |
| `Cmd N` | New WezTerm window |
| `Ctrl Shift h/j/k/l` | WezTerm pane left / down / up / right |
| `Cmd Alt h/j/k/l` | Same as above when herdr isn't running; inside herdr they move between tabs and spaces |
| `Ctrl Shift T` / `Ctrl Shift W` | New / close WezTerm tab (WezTerm defaults) |

## nvim (most used)

Full list in [NEOVIM.md](NEOVIM.md).

| Key | Action |
|---|---|
| `Alt h/j/k/l` | Move between splits |
| `Ctrl Alt h` / `l` | Previous / next file tab |
| `Cmd T` / `Cmd W` | New terminal tab / close tab |
| `Space t` | Terminal panel |
| `gf` / `gn` / `gc` | Goto file / Goto class |
| `Space a…` | Run and debug |

## How the forwarding works

macOS terminals swallow `Cmd` keys, so `.wezterm.lua` sends them on itself, encoded the way terminals
report modified keys (CSI-u: `ESC [ <key code> ; <modifiers> u`):

- `Cmd T` / `Cmd W` → `\x1b[116;9u` / `\x1b[119;9u` (super), only when nvim or herdr is the foreground process.
- `Cmd Alt <key>` → `\x1b[<code>;11u` (super + alt), only when herdr is the foreground process.

Herdr only understands these when WezTerm has the **kitty keyboard protocol** on
(`config.enable_kitty_keyboard = true` in `.wezterm.lua`). Herdr asks for it when it starts, so after
changing that setting, detach (`Ctrl b` `q`) and run `herdr` again.

`use_dead_keys = false` is needed too: on the ABC layout `Option n` is a dead key (˜), which would
swallow `Cmd Alt n`. Inside WezTerm, `Option` therefore always acts as Alt (accented characters via
`Option` still work in other apps).

The `Cmd Alt` handlers are created from an ordered list. WezTerm numbers `action_callback` handlers in
creation order and evaluates the config more than once, so building them with `pairs()` (random order)
crossed the keys (`n` ran the `g` handler). After changing these handlers, restart WezTerm (`Cmd Q`) rather
than just reloading.

`.wezterm.lua` also watches `~/vim/.wezterm.lua` itself: WezTerm only watches the `~/.wezterm.lua`
symlink, so without this, edits wouldn't reload automatically.

## Not verified yet

These need a check in a real WezTerm window (an automated test can't drive herdr's shortcuts):

1. ~~herdr reacts to `Cmd Alt` keys~~: confirmed for `t`, `n`, `p`, `1`–`9`; the rest use the same mechanism.
2. `Cmd T` / `Cmd W` reach nvim when nvim runs inside a herdr pane.
3. macOS menus don't steal `Cmd Alt h` ("Hide Others") before WezTerm sees it.
4. `Alt h/j/k/l` in nvim still move between splits inside herdr (herdr's log once warned about `Esc`/`Alt` timing).
