#!/usr/bin/env bash
# =============================================================================
# bored-prompt  —  Oh My Zsh setup
# =============================================================================
set -euo pipefail

R=$'\033[0;31m'  Y=$'\033[0;33m'  G=$'\033[0;32m'
C=$'\033[0;36m'  D=$'\033[0;90m'  B=$'\033[1m'  RST=$'\033[0m'

title()  { echo; echo "${B}${C}$*${RST}"; }
sec()    { echo; echo "${B}$*${RST}"; echo "${D}$(printf '─%.0s' $(seq 1 50))${RST}"; }
ok()     { echo "${G}✓${RST} $*"; }
info()   { echo "${D}  $*${RST}"; }
warn()   { echo "${Y}! $*${RST}"; }
ask()    { printf "${B}$*${RST} "; }
bail()   { echo "${R}✗ $*${RST}"; exit 1; }

pick() {
  # pick <varname> <default_index 1-based> <prompt> <options...>
  local var=$1 default_idx=$2 prompt=$3; shift 3
  local opts=("$@")
  echo; echo "${B}${prompt}${RST}"
  for i in "${!opts[@]}"; do
    local num=$((i+1))
    if (( num == default_idx )); then
      printf "  ${D}[${RST}${B}%s${RST}${D}]${RST} %s ${D}(default)${RST}\n" "$num" "${opts[$i]}"
    else
      printf "  ${D}[${RST}${B}%s${RST}${D}]${RST} %s\n" "$num" "${opts[$i]}"
    fi
  done
  while true; do
    ask "→ "; read -r choice
    [[ -z "$choice" ]] && choice=$default_idx
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#opts[@]} )); then
      printf -v "$var" '%s' "${opts[$((choice-1))]}"; return
    fi
    warn "Pick a number between 1 and ${#opts[@]}."
  done
}

yesno() {
  local var=$1 prompt=$2 default=${3:-y}
  local hint="[Y/n]"; [[ "$default" == n ]] && hint="[y/N]"
  while true; do
    ask "${prompt} ${D}${hint}${RST} "; read -r ans
    ans=${ans:-$default}
    case "$ans" in
      [yY]*) printf -v "$var" 'y'; return ;;
      [nN]*) printf -v "$var" 'n'; return ;;
      *) warn "Please answer y or n." ;;
    esac
  done
}

# =============================================================================
# Banner
# =============================================================================
clear
echo
echo "${B}${C}  bored-prompt  ${RST}${D}× Oh My Zsh edition${RST}"
echo

# =============================================================================
# Check / install OMZ
# =============================================================================
sec "Oh My Zsh"

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

if [[ -d "$OMZ_DIR" ]]; then
  ok "Found Oh My Zsh at ${OMZ_DIR}"
else
  warn "Oh My Zsh doesn't seem to be installed."
  yesno INSTALL_OMZ "Install it now?" y
  if [[ "$INSTALL_OMZ" == y ]]; then
    info "Running the official OMZ installer..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
  else
    bail "Oh My Zsh is required. Re-run when it's installed."
  fi
fi

THEME_DIR="${OMZ_DIR}/custom/themes"
THEME_FILE="${THEME_DIR}/bored.zsh-theme"
mkdir -p "$THEME_DIR"

# =============================================================================
# 1. Separator
# =============================================================================
sec "1 / 4  Separator"
info "A dividing line printed before each prompt."
echo
yesno USE_SEP "Enable separator?" y

SEP_CHAR="─"
SEP_COND=""
SEP_SCOPE="All terminals"

if [[ "$USE_SEP" == y ]]; then
  pick SEP_CHAR_LABEL 1 "Character:" \
    "─  thin" "━  thick" "═  double" "·  dots" "Custom…"
  case "$SEP_CHAR_LABEL" in
    "─"*) SEP_CHAR="─" ;; "━"*) SEP_CHAR="━" ;;
    "═"*) SEP_CHAR="═" ;; "·"*) SEP_CHAR="·" ;;
    "Custom…") ask "Character/string: "; read -r SEP_CHAR ;;
  esac

  pick SEP_SCOPE 1 "Show in which terminals?" \
    "iTerm2" "Ghostty" "WezTerm" "Alacritty" "Kitty" \
    "Multiple — I'll pick" "All terminals"

  case "$SEP_SCOPE" in
    "iTerm2")     SEP_COND='[[ "$TERM_PROGRAM" == "iTerm.app" ]]' ;;
    "Ghostty")    SEP_COND='[[ "$TERM_PROGRAM" == "ghostty" ]]' ;;
    "WezTerm")    SEP_COND='[[ "$TERM_PROGRAM" == "WezTerm" ]]' ;;
    "Alacritty")  SEP_COND='[[ "${ALACRITTY_WINDOW_ID:-}" != "" ]]' ;;
    "Kitty")      SEP_COND='[[ "$TERM" == "xterm-kitty" ]]' ;;
    "All"*)       SEP_COND="" ;;
    "Multiple"*)
      info "Space-separated TERM_PROGRAM values (e.g.: iTerm.app ghostty WezTerm)"
      ask "→ "; read -r raw_terms
      parts=()
      for t in $raw_terms; do parts+=("\"$TERM_PROGRAM\" == \"$t\""); done
      SEP_COND="[[ $(IFS=" || "; echo "${parts[*]}") ]]"
      ;;
  esac
  ok "Separator '${SEP_CHAR}' — ${SEP_SCOPE}"
else
  ok "Separator off"
fi

# =============================================================================
# 2. Git
# =============================================================================
sec "2 / 4  Git info"
yesno USE_GIT "Show git branch + status?" y
USE_ASYNC=n
if [[ "$USE_GIT" == y ]]; then
  yesno USE_ASYNC "Async (non-blocking, recommended)?" y
fi

# =============================================================================
# 3. Execution time
# =============================================================================
sec "3 / 4  Execution time"
yesno USE_TIME "Show how long the last command took?" y
TIME_THRESHOLD=3
if [[ "$USE_TIME" == y ]]; then
  ask "Minimum seconds to show ${D}[default: 3]${RST}: "; read -r t_raw
  [[ "$t_raw" =~ ^[0-9]+$ ]] && TIME_THRESHOLD=$t_raw
fi

# =============================================================================
# 4. Style
# =============================================================================
sec "4 / 4  Style"

pick PROMPT_CHAR_LABEL 1 "Prompt character:" \
  "·  dot" "❯  chevron" "→  arrow" "λ  lambda" "Custom…"
case "$PROMPT_CHAR_LABEL" in
  "·"*) PC="·" ;; "❯"*) PC="❯" ;; "→"*) PC="→" ;;
  "λ"*) PC="λ" ;; "Custom…") ask "Char: "; read -r PC ;;
esac

pick COLOR_LABEL 1 "Color scheme:" \
  "Muted — sage / olive / mauve" \
  "Vibrant — green / yellow / magenta" \
  "Monochrome — all grey" \
  "Pastel — blue / pink / peach"
case "$COLOR_LABEL" in
  "Muted"*)      C_OK=65;  C_WARN=101; C_ERR=95;  C_META=242 ;;
  "Vibrant"*)    C_OK=40;  C_WARN=220; C_ERR=201; C_META=248 ;;
  "Monochrome"*) C_OK=245; C_WARN=245; C_ERR=245; C_META=242 ;;
  "Pastel"*)     C_OK=110; C_WARN=217; C_ERR=217; C_META=146 ;;
esac

yesno USE_JOBS "Show background job count?" y

# =============================================================================
# Generate theme file
# =============================================================================
sec "Writing theme"

if [[ -f "$THEME_FILE" ]]; then
  warn "bored.zsh-theme already exists at ${THEME_FILE}"
  pick OVERWRITE_ACTION 1 "What do you want to do?" \
    "Overwrite it" \
    "Back it up, then overwrite" \
    "Abort — keep existing theme"
  case "$OVERWRITE_ACTION" in
    "Abort"*)
      ok "Keeping existing theme. ZSH_THEME will still be set to \"bored\"."
      SKIP_WRITE=y
      ;;
    "Back it up"*)
      BK="${THEME_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
      cp "$THEME_FILE" "$BK"
      ok "Backed up → ${BK}"
      SKIP_WRITE=n
      ;;
    *)
      SKIP_WRITE=n
      ;;
  esac
else
  SKIP_WRITE=n
fi

THEME_CONTENT="# ============================================================
# bored — Oh My Zsh custom theme
# generated $(date '+%Y-%m-%d')
# ============================================================
"

# -- git ----------------------------------------------------------------------
if [[ "$USE_GIT" == y ]]; then
  THEME_CONTENT+="
# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------
_git_async_pid=0
_git_async_tmp=\"\"

_bored_compute_git() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch
  branch=\$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  local staged=0 unstaged=0 untracked=0 line
  while IFS= read -r line; do
    local x=\${line[1]} y=\${line[2]}
    [[ \$x != ' ' && \$x != '?' ]] && (( staged++ ))
    [[ \$y == 'M' || \$y == 'D' ]]  && (( unstaged++ ))
    [[ \$x == '?' ]]                && (( untracked++ ))
  done < <(git status --porcelain 2>/dev/null)
  local info=\"%F{${C_META}}(\${branch}\"
  (( staged    > 0 )) && info+=\" %F{${C_OK}}\${staged}+%F{${C_META}}\"
  (( unstaged  > 0 )) && info+=\" %F{${C_WARN}}\${unstaged}!%F{${C_META}}\"
  (( untracked > 0 )) && info+=\" %F{${C_ERR}}\${untracked}?%F{${C_META}}\"
  info+=\")%f\"
  echo \"\$info\"
}
"
  if [[ "$USE_ASYNC" == y ]]; then
    THEME_CONTENT+="
_bored_async_git() {
  (( _git_async_pid > 0 )) && kill \"\$_git_async_pid\" 2>/dev/null
  _git_info=\"\"
  _git_async_tmp=\$(mktemp)
  local tmp=\$_git_async_tmp
  ( _bored_compute_git > \"\$tmp\"; kill -USR1 \$\$ ) &!
  _git_async_pid=\$!
}
TRAPUSR1() {
  [[ -f \$_git_async_tmp ]] && _git_info=\$(cat \"\$_git_async_tmp\") && rm -f \"\$_git_async_tmp\"
  _git_async_pid=0
  zle && zle reset-prompt
}
"
  else
    THEME_CONTENT+="
_bored_async_git() { _git_info=\$(_bored_compute_git); }
"
  fi
fi

# -- execution time -----------------------------------------------------------
if [[ "$USE_TIME" == y ]]; then
  THEME_CONTENT+="
# ---------------------------------------------------------------------------
# Execution time
# ---------------------------------------------------------------------------
_bored_cmd_start=0
_bored_preexec() { _bored_cmd_start=\$EPOCHSECONDS }
"
fi

# -- hooks --------------------------------------------------------------------
THEME_CONTENT+="
# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------
_bored_first_prompt=1
_bored_precmd() {"

if [[ "$USE_SEP" == y ]]; then
  THEME_CONTENT+="
  if (( _bored_first_prompt )); then
    _bored_first_prompt=0
  else"
  if [[ -z "$SEP_COND" ]]; then
    THEME_CONTENT+="
    print -P \"%F{237}\${(l:\$COLUMNS::${SEP_CHAR}:):-}%f\""
  else
    THEME_CONTENT+="
    if ${SEP_COND}; then
      print -P \"%F{237}\${(l:\$COLUMNS::${SEP_CHAR}:):-}%f\"
    fi"
  fi
  THEME_CONTENT+="
  fi"
fi

if [[ "$USE_TIME" == y ]]; then
  THEME_CONTENT+="
  if (( _bored_cmd_start > 0 )); then
    local elapsed=\$(( EPOCHSECONDS - _bored_cmd_start ))
    (( elapsed >= ${TIME_THRESHOLD} )) && _cmd_time=\"%F{${C_META}} \${elapsed}s%f\" || _cmd_time=\"\"
    _bored_cmd_start=0
  else
    _cmd_time=\"\"
  fi"
fi

[[ "$USE_GIT" == y ]] && THEME_CONTENT+="
  _bored_async_git"

THEME_CONTENT+="
}

autoload -Uz add-zsh-hook
"

[[ "$USE_TIME" == y ]] && THEME_CONTENT+="add-zsh-hook preexec _bored_preexec
"
THEME_CONTENT+="add-zsh-hook precmd  _bored_precmd

"

# -- PROMPT -------------------------------------------------------------------
PROMPT_STR="%F{${C_META}}%~%f"
[[ "$USE_GIT"  == y ]] && PROMPT_STR+='${_git_info}'
[[ "$USE_JOBS" == y ]] && PROMPT_STR+="%(1j. %F{${C_META}}%j&%f.)"
[[ "$USE_TIME" == y ]] && PROMPT_STR+='${_cmd_time}'
PROMPT_STR+=" %(?.%F{${C_OK}}${PC}%f.%F{${C_ERR}}${PC}%f) "

THEME_CONTENT+="# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
setopt PROMPT_SUBST
PROMPT='${PROMPT_STR}'
RPROMPT=''
"

if [[ "$SKIP_WRITE" == n ]]; then
  echo "$THEME_CONTENT" > "$THEME_FILE"
  ok "Written → ${THEME_FILE}"
fi

# =============================================================================
# .zshrc bootstrap
# =============================================================================
sec "Activating theme"

if ! grep -q 'oh-my-zsh.sh' "$ZSHRC" 2>/dev/null; then
  warn "No OMZ bootstrap found in ${ZSHRC}."
  echo
  info "The following lines are needed at the top of your .zshrc:"
  echo
  echo "    ${B}export ZSH=\"\$HOME/.oh-my-zsh\"${RST}"
  echo "    ${B}ZSH_THEME=\"bored\"${RST}"
  echo "    ${B}source \$ZSH/oh-my-zsh.sh${RST}"
  echo
  pick BOOTSTRAP_ACTION 1 "What do you want to do?" \
    "Add them automatically (safe — prepends, doesn't touch existing content)" \
    "Overwrite .zshrc entirely with just the bootstrap (wipes existing content)" \
    "I'll add them myself — show me what to copy"

  case "$BOOTSTRAP_ACTION" in
    "Add them automatically"*)
      [[ -f "$ZSHRC" ]] && cp "$ZSHRC" "${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
      # Use a fixed temp file in $HOME to avoid mktemp/unbound issues
      tmp="$HOME/.zshrc.tmp.$$"
      {
        echo 'export ZSH="$HOME/.oh-my-zsh"'
        echo 'ZSH_THEME="bored"'
        echo 'source $ZSH/oh-my-zsh.sh'
        echo
        [[ -f "$ZSHRC" ]] && cat "$ZSHRC"
      } > "$tmp"
      mv "$tmp" "$ZSHRC"
      ok "Prepended OMZ bootstrap to ${ZSHRC}"
      ;;
    "Overwrite"*)
      yesno CONFIRM_WIPE "${R}This will delete everything in ${ZSHRC}. Are you sure?${RST}" n
      if [[ "$CONFIRM_WIPE" == y ]]; then
        cat > "$ZSHRC" <<ZSHRC_CONTENT
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="bored"
source \$ZSH/oh-my-zsh.sh
ZSHRC_CONTENT
        ok "Wrote clean .zshrc"
      else
        warn "Aborted. Nothing was changed."
        info "Add the lines above to ${ZSHRC} manually before the next step."
      fi
      ;;
    "I'll add them myself"*)
      echo
      echo "  Add these three lines to ${B}${ZSHRC}${RST}, at the top, before anything else:"
      echo
      echo "    ${B}export ZSH=\"\$HOME/.oh-my-zsh\"${RST}"
      echo "    ${B}ZSH_THEME=\"bored\"${RST}"
      echo "    ${B}source \$ZSH/oh-my-zsh.sh${RST}"
      echo
      warn "Skipping automatic .zshrc changes. Run setup again when done."
      exit 0
      ;;
  esac
else
  # OMZ is bootstrapped — just handle ZSH_THEME
  if grep -q 'ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
    CURRENT=$(grep 'ZSH_THEME=' "$ZSHRC" | head -1 | sed 's/.*ZSH_THEME="\(.*\)".*/\1/')
    if [[ "$CURRENT" == "bored" ]]; then
      ok "ZSH_THEME is already \"bored\""
    else
      warn "Current theme: \"${CURRENT}\""
      yesno FLIP "Switch ZSH_THEME to \"bored\"?" y
      if [[ "$FLIP" == y ]]; then
        cp "$ZSHRC" "${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
        sed -i.tmp 's/ZSH_THEME=".*"/ZSH_THEME="bored"/' "$ZSHRC" && rm -f "${ZSHRC}.tmp"
        ok "ZSH_THEME → \"bored\""
      else
        info "Add  ZSH_THEME=\"bored\"  to ${ZSHRC} manually, before the source line."
      fi
    fi
  else
    # Has OMZ source but no ZSH_THEME line — insert before source line
    cp "$ZSHRC" "${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
    sed -i.tmp 's|source \$ZSH/oh-my-zsh.sh|ZSH_THEME="bored"\nsource $ZSH/oh-my-zsh.sh|' "$ZSHRC" && rm -f "${ZSHRC}.tmp"
    ok "Inserted ZSH_THEME=\"bored\" into ${ZSHRC}"
  fi
fi

# =============================================================================
echo
echo "${B}${G}  Done!${RST}"
echo
echo "  ${D}Don't source .zshrc — it leaves stale state around.${RST}"
echo "  Run ${B}exec zsh${RST} instead: it replaces the current shell"
echo "  with a fresh one so everything loads cleanly."
echo
yesno DO_EXEC "Reload shell now with exec zsh?" y
if [[ "$DO_EXEC" == y ]]; then
  exec zsh -l
fi
echo
