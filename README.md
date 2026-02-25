# fleet-dotfiles

Unified CLI tooling experience across the home compute fleet.

## One-liner install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/speeed76/fleet-dotfiles/main/install.sh)
```

Or if already SSH'd in:
```bash
git clone https://github.com/speeed76/fleet-dotfiles ~/.fleet-dotfiles
bash ~/.fleet-dotfiles/install.sh
```

## What it installs

### zsh (`zsh/zshrc.shared`)
Appended to `~/.zshrc`. All aliases degrade gracefully if binary not present.

- **Modern tools**: `ls→eza`, `cat→bat`, `find→fd`, `grep→rg`, `cd→zoxide`
- **Git shortcuts**: `gs`, `ga`, `gaa`, `gc`, `gcm`, `gp`, `gpl`, `gl`, `gd`, `gco` …
- **Docker shortcuts**: `d`, `dc`, `dps`, `dlog`, `dexec`, `dclean`
- **System**: `ports`, `reload`, `path`, `myip`, `localip`
- **Safety nets**: `cp`, `mv`, `rm` with `-iv`
- **FZF**: fd-backed, 40% height, reverse layout
- **Zoxide**: replaces `cd` with smart jump
- **GCP/Claude**: `use-api-claude`, `use-sub-claude`, `_gcp_secret` (when fleet-agent-sa present)
- **Machine overrides**: `~/.zshrc.local` sourced last

### vim (`vim/vimrc`)
Symlinked to `~/.vimrc`. Works on vim 8+ and nvim.

- Plugin manager: vim-plug (auto-bootstraps)
- Colorscheme: catppuccin mocha
- Statusline: lightline
- Explorer: NERDTree
- Fuzzy: fzf.vim (`<leader>ff`, `<leader>fg`, `<leader>fb`)
- Git: fugitive + gitgutter
- Editor: surround, commentary, auto-pairs, undotree, editorconfig
- Leader: `Space`
- Escape: `jk` / `jj`

### nvim (`nvim/init.lua`)
Symlinked to `~/.config/nvim`. Requires nvim 0.9+.

- Plugin manager: lazy.nvim (auto-bootstraps)
- Colorscheme: catppuccin mocha
- Statusline: lualine
- Explorer: nvim-tree
- Fuzzy: telescope + fzf-native
- LSP + completion: mason + nvim-lspconfig + nvim-cmp (pyright, ts_ls, lua_ls, bashls)
- Treesitter highlighting + indent
- Git: gitsigns + fugitive
- Editor: surround, commentary, autopairs, undotree, indent-blankline, which-key
- Same leader/escape bindings as vim config

## Key bindings (shared vim + nvim)

| Key | Action |
|---|---|
| `Space` | Leader |
| `jk` / `jj` | Escape insert mode |
| `<leader>e` | File explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Grep / live grep |
| `<leader>fb` | Buffers |
| `<leader>gs` | Git status |
| `<leader>gd` | Git diff |
| `<leader>u` | Undo tree |
| `<C-h/j/k/l>` | Window navigation |
| `<S-h/l>` | Prev/next buffer |

## Machine-specific overrides

Create `~/.zshrc.local` for anything machine-specific (sourced last, wins over shared):

```bash
# Example: mac-studio ~/.zshrc.local
alias bob='bob-claude'
export OLLAMA_HOST=http://192.168.0.11:11434
```

### tmux (`tmux/tmux.conf`)
Symlinked to `~/.tmux.conf`. Requires tmux 3.2+. TPM auto-bootstraps.

| Key | Action |
|---|---|
| `Ctrl+a` | Prefix (replaces Ctrl+b) |
| `Prefix + \|` | Split vertical (current dir) |
| `Prefix + -` | Split horizontal (current dir) |
| `C-h/j/k/l` | Navigate panes (no prefix — transparent with vim/nvim) |
| `Prefix + h/j/k/l` | Navigate panes (with prefix) |
| `Prefix + H/J/K/L` | Resize panes |
| `Alt+h/l` | Prev/next window |
| `Prefix + Tab` | Last active window |
| `Prefix + r` | Reload config |
| `Prefix + z` | Zoom pane |
| `Prefix + m` | Toggle mouse |
| `Prefix + e` | Toggle pane sync |
| `Prefix + Enter` | Enter copy mode |
| `v / V / Ctrl+v` | Select / line / rect in copy mode |
| `y` | Yank to clipboard |

**Theme:** catppuccin mocha — matches vim/nvim.
**Plugins:** tmux-sensible, tmux-yank, tmux-resurrect (save sessions), tmux-continuum (auto-save every 15 min).

## Recommended tools to install

| Tool | macOS | Linux |
|---|---|---|
| eza | `brew install eza` | `cargo install eza` |
| bat | `brew install bat` | `apt install bat` / `cargo install bat` |
| fd | `brew install fd` | `apt install fd-find` |
| rg | `brew install ripgrep` | `apt install ripgrep` |
| fzf | `brew install fzf` | `apt install fzf` |
| zoxide | `brew install zoxide` | `cargo install zoxide` |
| htop | `brew install htop` | `apt install htop` |
| nvim | `brew install neovim` | `snap install nvim --classic` |
