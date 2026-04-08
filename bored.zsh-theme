# ============================================================
# bored — Oh My Zsh custom theme
# generated 2026-04-08
# ============================================================

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------
_git_async_pid=0
_git_async_tmp=""

_bored_compute_git() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  local staged=0 unstaged=0 untracked=0 line
  while IFS= read -r line; do
    local x=${line[1]} y=${line[2]}
    [[ $x != ' ' && $x != '?' ]] && (( staged++ ))
    [[ $y == 'M' || $y == 'D' ]]  && (( unstaged++ ))
    [[ $x == '?' ]]                && (( untracked++ ))
  done < <(git status --porcelain 2>/dev/null)
  local info="%F{242}(${branch}"
  (( staged    > 0 )) && info+=" %F{65}${staged}+%F{242}"
  (( unstaged  > 0 )) && info+=" %F{101}${unstaged}!%F{242}"
  (( untracked > 0 )) && info+=" %F{95}${untracked}?%F{242}"
  info+=")%f"
  echo "$info"
}

_bored_async_git() {
  (( _git_async_pid > 0 )) && kill "$_git_async_pid" 2>/dev/null
  _git_info=""
  _git_async_tmp=$(mktemp)
  local tmp=$_git_async_tmp
  ( _bored_compute_git > "$tmp"; kill -USR1 $$ ) &!
  _git_async_pid=$!
}
TRAPUSR1() {
  [[ -f $_git_async_tmp ]] && _git_info=$(cat "$_git_async_tmp") && rm -f "$_git_async_tmp"
  _git_async_pid=0
  zle && zle reset-prompt
}

# ---------------------------------------------------------------------------
# Execution time
# ---------------------------------------------------------------------------
_bored_cmd_start=0
_bored_preexec() { _bored_cmd_start=$EPOCHSECONDS }

# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------
_bored_first_prompt=1
_bored_precmd() {
  if (( _bored_first_prompt )); then
    _bored_first_prompt=0
  else
    print -P "%F{237}${(l:$COLUMNS::─:):-}%f"
  fi
  if (( _bored_cmd_start > 0 )); then
    local elapsed=$(( EPOCHSECONDS - _bored_cmd_start ))
    (( elapsed >= 0 )) && _cmd_time="%F{242} ${elapsed}s%f" || _cmd_time=""
    _bored_cmd_start=0
  else
    _cmd_time=""
  fi
  _bored_async_git
}

add-zsh-hook preexec _bored_preexec
add-zsh-hook precmd  _bored_precmd

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
PROMPT='%F{242}%~%f\${_git_info}%(1j. %F{242}%j&%f.)\${_cmd_time} %(?.%F{65}·%f.%F{95}·%f) '
RPROMPT=''

