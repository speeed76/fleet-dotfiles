#!/usr/bin/env bash
# ── Fleet Dotfiles — install.sh ──────────────────────────────────────────────
# Usage: bash install.sh [--vim-only] [--zsh-only] [--nvim-only] [--tmux-only]
set -euo pipefail

DOTFILES_DIR="${FLEET_DOTFILES_DIR:-$HOME/.fleet-dotfiles}"
REPO="https://github.com/speeed76/fleet-dotfiles.git"

log()  { printf '\033[0;34m[fleet-dotfiles]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[  ok  ]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[ warn ]\033[0m %s\n' "$*"; }

# ── Clone / update repo ──────────────────────────────────────────────────────
if [ -d "$DOTFILES_DIR/.git" ]; then
  log "Updating fleet-dotfiles..."
  git -C "$DOTFILES_DIR" pull --rebase --quiet
  ok "Updated"
else
  log "Cloning fleet-dotfiles to $DOTFILES_DIR..."
  git clone --quiet "$REPO" "$DOTFILES_DIR"
  ok "Cloned"
fi

# ── zsh ──────────────────────────────────────────────────────────────────────
install_zsh() {
  local marker="fleet-dotfiles/zsh/zshrc.shared"
  if grep -q "$marker" ~/.zshrc 2>/dev/null; then
    ok "zshrc.shared already sourced in ~/.zshrc"
  else
    log "Appending source block to ~/.zshrc..."
    cat >> ~/.zshrc << EOF

# ── Fleet Dotfiles (auto-managed) ───────────────────────────────────────────
# $marker
[ -f "$DOTFILES_DIR/zsh/zshrc.shared" ] && source "$DOTFILES_DIR/zsh/zshrc.shared"
EOF
    ok "zshrc.shared sourced"
  fi
}

# ── vim ──────────────────────────────────────────────────────────────────────
install_vim() {
  local marker="Fleet Dotfiles"
  if [ -f ~/.vimrc ] && grep -q "$marker" ~/.vimrc 2>/dev/null; then
    ok "vimrc already points to fleet-dotfiles"
  else
    if [ -f ~/.vimrc ]; then
      cp ~/.vimrc ~/.vimrc.bak-$(date +%Y%m%d)
      warn "Existing ~/.vimrc backed up"
    fi
    log "Installing fleet vimrc..."
    ln -sf "$DOTFILES_DIR/vim/vimrc" ~/.vimrc
    ok "~/.vimrc -> fleet vimrc"
    # Install plugins
    if command -v vim &>/dev/null; then
      log "Installing vim plugins (vim-plug)..."
      vim +PlugInstall +qall 2>/dev/null || warn "Plug install may need manual run: vim +PlugInstall"
    fi
  fi
}

# ── nvim ─────────────────────────────────────────────────────────────────────
install_nvim() {
  if ! command -v nvim &>/dev/null; then
    warn "nvim not installed — skipping nvim config"
    return
  fi
  local nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  if [ -d "$nvim_config" ] && [ ! -L "$nvim_config" ]; then
    cp -r "$nvim_config" "${nvim_config}.bak-$(date +%Y%m%d)"
    warn "Existing nvim config backed up to ${nvim_config}.bak"
    rm -rf "$nvim_config"
  fi
  mkdir -p "$(dirname "$nvim_config")"
  ln -sfn "$DOTFILES_DIR/nvim" "$nvim_config"
  ok "~/.config/nvim -> fleet nvim config"
  log "Plugins will install on first nvim launch (lazy.nvim)"
}

# ── tmux ─────────────────────────────────────────────────────────────────────
install_tmux() {
  if ! command -v tmux &>/dev/null; then
    warn "tmux not installed — skipping tmux config"
    warn "Install: brew install tmux  OR  sudo apt install tmux"
    return
  fi
  if [ -f ~/.tmux.conf ] && grep -q "Fleet Dotfiles" ~/.tmux.conf 2>/dev/null; then
    ok "tmux.conf already points to fleet-dotfiles"
  else
    if [ -f ~/.tmux.conf ]; then
      cp ~/.tmux.conf ~/.tmux.conf.bak-$(date +%Y%m%d)
      warn "Existing ~/.tmux.conf backed up"
    fi
    log "Installing fleet tmux.conf..."
    ln -sf "$DOTFILES_DIR/tmux/tmux.conf" ~/.tmux.conf
    ok "~/.tmux.conf -> fleet tmux config"
  fi
  # Bootstrap TPM
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    log "Installing TPM (tmux plugin manager)..."
    git clone --quiet https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ok "TPM installed — plugins will install on next tmux start (prefix + I)"
  else
    ok "TPM already present"
  fi
  # Reload if inside tmux
  if [ -n "${TMUX:-}" ]; then
    tmux source-file ~/.tmux.conf && log "tmux config reloaded"
  fi
}

# ── dispatch ─────────────────────────────────────────────────────────────────
VIM_ONLY=0; ZSH_ONLY=0; NVIM_ONLY=0; TMUX_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --vim-only)  VIM_ONLY=1 ;;
    --zsh-only)  ZSH_ONLY=1 ;;
    --nvim-only) NVIM_ONLY=1 ;;
    --tmux-only) TMUX_ONLY=1 ;;
  esac
done

if   [ $VIM_ONLY  -eq 1 ]; then install_vim
elif [ $ZSH_ONLY  -eq 1 ]; then install_zsh
elif [ $NVIM_ONLY -eq 1 ]; then install_nvim
elif [ $TMUX_ONLY -eq 1 ]; then install_tmux
else
  install_zsh
  install_vim
  install_nvim
  install_tmux
fi

log "Done. Open a new shell or run: source ~/.zshrc"
