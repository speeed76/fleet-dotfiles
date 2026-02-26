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

# ── p10k ─────────────────────────────────────────────────────────────────────
install_p10k() {
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  local p10k_cfg="$HOME/.p10k.zsh"
  local zshrc="$HOME/.zshrc"

  # ── 1. Install Powerlevel10k theme ──────────────────────────────────────────
  if [ -d "$p10k_dir" ]; then
    ok "Powerlevel10k already installed"
  else
    log "Installing Powerlevel10k..."
    git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    ok "Powerlevel10k installed"
  fi

  # ── 2. Deploy shared .p10k.zsh (skip if user has their own) ─────────────────
  if [ -f "$p10k_cfg" ]; then
    ok "~/.p10k.zsh already exists — skipping (run with --p10k-force to overwrite)"
  else
    log "Deploying fleet .p10k.zsh..."
    cp "$DOTFILES_DIR/zsh/p10k.zsh" "$p10k_cfg"
    ok "~/.p10k.zsh deployed from fleet template (run 'p10k configure' to customise)"
  fi

  # ── 3. Patch ~/.zshrc ────────────────────────────────────────────────────────
  # 3a. Instant prompt block at the top (before anything else)
  if ! grep -q 'p10k-instant-prompt' "$zshrc" 2>/dev/null; then
    log "Prepending P10k instant prompt block to ~/.zshrc..."
    local tmp
    tmp=$(mktemp)
    cat > "$tmp" << 'BLOCK'
# Enable Powerlevel10k instant prompt. Must stay near the top of ~/.zshrc.
# Initialization code that may require console input must go above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

BLOCK
    cat "$zshrc" >> "$tmp"
    mv "$tmp" "$zshrc"
    ok "Instant prompt block prepended"
  else
    ok "Instant prompt block already present"
  fi

  # 3b. Switch ZSH_THEME to powerlevel10k
  if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$zshrc" 2>/dev/null; then
    ok "ZSH_THEME already set to powerlevel10k"
  elif grep -q 'ZSH_THEME=' "$zshrc" 2>/dev/null; then
    log "Switching ZSH_THEME to powerlevel10k..."
    sed -i.bak 's|ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
    ok "ZSH_THEME updated"
  else
    warn "ZSH_THEME not found in ~/.zshrc — add: ZSH_THEME=\"powerlevel10k/powerlevel10k\""
  fi

  # 3c. Source ~/.p10k.zsh at the bottom
  if grep -q 'source.*\.p10k\.zsh\|\.p10k\.zsh.*source' "$zshrc" 2>/dev/null; then
    ok "~/.p10k.zsh already sourced in ~/.zshrc"
  else
    log "Appending p10k source to ~/.zshrc..."
    printf '\n# To customise prompt, run `p10k configure` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n' >> "$zshrc"
    ok "~/.p10k.zsh source appended"
  fi

  # ── 4. Install Meslo NF fonts ────────────────────────────────────────────────
  local os
  os="$(uname -s)"

  if [ "$os" = "Darwin" ]; then
    if ls "$HOME/Library/Fonts/MesloLGS"* &>/dev/null 2>&1 || \
       ls "$HOME/Library/Fonts/MesloLGSNerd"* &>/dev/null 2>&1; then
      ok "Meslo NF fonts already installed"
    elif command -v brew &>/dev/null; then
      log "Installing Meslo NF fonts via Homebrew..."
      brew install --cask font-meslo-lg-nerd-font --quiet 2>/dev/null
      ok "Meslo NF fonts installed"
    else
      warn "Homebrew not found — install fonts manually: brew install --cask font-meslo-lg-nerd-font"
    fi

    # ── 5. iTerm2 DynamicProfile (macOS only) ───────────────────────────────
    local iterm_profiles="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    local profile_src="$DOTFILES_DIR/iterm2/fleet-default.json"
    if [ -f "$profile_src" ]; then
      mkdir -p "$iterm_profiles"
      cp "$profile_src" "$iterm_profiles/fleet-default.json"
      ok "iTerm2 DynamicProfile deployed (Fleet Default — MesloLGS Nerd Font Mono 13)"
    fi

  elif [ "$os" = "Linux" ]; then
    local font_dir="$HOME/.local/share/fonts"
    if ls "$font_dir"/MesloLGS* &>/dev/null 2>&1 || \
       ls "$font_dir"/MesloLGSNerd* &>/dev/null 2>&1; then
      ok "Meslo NF fonts already installed"
    else
      log "Downloading MesloLGS NF fonts for Linux..."
      mkdir -p "$font_dir"
      local base="https://github.com/romkatv/powerlevel10k-media/raw/master"
      curl -fsSL -o "$font_dir/MesloLGS NF Regular.ttf"     "$base/MesloLGS%20NF%20Regular.ttf"
      curl -fsSL -o "$font_dir/MesloLGS NF Bold.ttf"        "$base/MesloLGS%20NF%20Bold.ttf"
      curl -fsSL -o "$font_dir/MesloLGS NF Italic.ttf"      "$base/MesloLGS%20NF%20Italic.ttf"
      curl -fsSL -o "$font_dir/MesloLGS NF Bold Italic.ttf" "$base/MesloLGS%20NF%20Bold%20Italic.ttf"
      fc-cache -f "$font_dir" 2>/dev/null && ok "Meslo NF fonts installed + cache rebuilt" \
        || ok "Meslo NF fonts installed (run fc-cache -f to rebuild font cache)"
    fi
  fi
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
VIM_ONLY=0; ZSH_ONLY=0; NVIM_ONLY=0; TMUX_ONLY=0; P10K_ONLY=0; P10K_FORCE=0
for arg in "$@"; do
  case "$arg" in
    --vim-only)   VIM_ONLY=1 ;;
    --zsh-only)   ZSH_ONLY=1 ;;
    --nvim-only)  NVIM_ONLY=1 ;;
    --tmux-only)  TMUX_ONLY=1 ;;
    --p10k-only)  P10K_ONLY=1 ;;
    --p10k-force) P10K_FORCE=1 ;;
  esac
done

# --p10k-force: overwrite existing ~/.p10k.zsh with fleet template
if [ $P10K_FORCE -eq 1 ]; then
  log "Force-overwriting ~/.p10k.zsh with fleet template..."
  cp "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"
  ok "~/.p10k.zsh replaced"
fi

if   [ $VIM_ONLY  -eq 1 ]; then install_vim
elif [ $ZSH_ONLY  -eq 1 ]; then install_zsh
elif [ $NVIM_ONLY -eq 1 ]; then install_nvim
elif [ $TMUX_ONLY -eq 1 ]; then install_tmux
elif [ $P10K_ONLY -eq 1 ]; then install_p10k
else
  install_zsh
  install_p10k
  install_vim
  install_nvim
  install_tmux
fi

log "Done. Open a new shell or run: source ~/.zshrc"
