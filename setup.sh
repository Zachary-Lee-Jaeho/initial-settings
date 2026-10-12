#!/usr/bin/env zsh
#
# JIS - Jaeho's Initial Settings
#
# Interactive installer for zsh (oh-my-zsh), tmux (tpm) and Neovim (NvChad).
# Supports Ubuntu/Debian (apt) and macOS (Homebrew).
#
#   zsh ./setup.sh
#
# The output of every command is written to ~/.cache/jis/setup-<timestamp>.log.

if [ -z "$ZSH_VERSION" ]; then
  echo "Please run this script with zsh:  zsh ./setup.sh" >&2
  exit 1
fi

zmodload zsh/datetime zsh/zselect
zmodload -F zsh/stat b:zstat
setopt extended_glob

REPO_DIR=${0:A:h}
NODE_MIN=22
TS=$(strftime '%Y%m%d-%H%M%S' $EPOCHSECONDS)
LOG_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/jis
LOG=$LOG_DIR/setup-$TS.log
mkdir -p -- $LOG_DIR && : >$LOG || exit 1
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/jis.XXXXXX") || exit 1
export GIT_TERMINAL_PROMPT=0

COMP_IDS=(prereq zsh tmux nvim)
typeset -A COMP_TITLE COMP_DESC STATUS SELECTED RESULT DETAIL
COMP_TITLE=(prereq Prerequisites zsh Zsh tmux Tmux nvim Neovim)
typeset -a NOTES SUDO
typeset -i COMP_WARNED BREW_UPDATED SUDO_READY SUDO_KEEPALIVE_PID
CUR_PID= PLATFORM= OS_NAME= ARCH= NVIM_LATEST= NVIM_ASSET= NVIM_ALIAS= LINK_RESULT=

if [[ -t 1 && -z ${NO_COLOR-} && $TERM != dumb ]]; then
  typeset -i FANCY=1
  R=$'\e[0m' B=$'\e[1m' D=$'\e[2m'
  RED=$'\e[31m' GRN=$'\e[32m' YLW=$'\e[33m' MAG=$'\e[35m' CYN=$'\e[36m'
  CR=$'\r' EL=$'\e[K'
else
  typeset -i FANCY=0
  R= B= D= RED= GRN= YLW= MAG= CYN= CR= EL=
fi

_locale=${LC_ALL:-${LC_CTYPE:-${LANG:-}}}
if [[ $OSTYPE == darwin* || $_locale == (#i)*utf(-|)8* ]]; then
  I_OK='✔' I_FAIL='✖' I_SKIP='–' I_WARN='▲' I_ASK='?' I_ARROW='›' I_ON='●' I_OFF='○'
  I_BAR='┆' I_DOT='·' I_TO='→'
  G_FULL='█' G_EMPTY='░' G_H='─' G_V='│' G_TL='╭' G_TR='╮' G_BL='╰' G_BR='╯'
  SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
else
  I_OK='+' I_FAIL='x' I_SKIP='-' I_WARN='!' I_ASK='?' I_ARROW='>' I_ON='*' I_OFF='.'
  I_BAR='|' I_DOT='-' I_TO='->'
  G_FULL='#' G_EMPTY='.' G_H='-' G_V='|' G_TL='+' G_TR='+' G_BL='+' G_BR='+'
  SPIN=('|' '/' '-' '\')
fi

ok()   { print -r -- "   ${GRN}${I_OK}${R} $*" }
skip() { print -r -- "   ${D}${I_SKIP} $*${R}" }
info() { print -r -- "     ${D}$*${R}" }
warn() { print -r -- "   ${YLW}${I_WARN}${R} $*"; COMP_WARNED=1 }
fail() { print -r -- "   ${RED}${I_FAIL}${R} $*" }
note() { NOTES+=("$*") }

repeat_str() { # char count -> REPLY
  local -i n=$2
  REPLY=
  while (( n-- > 0 )); do REPLY+=$1; done
}

elapsed() { # start_time -> REPLY ("3.2s" / "1m05s")
  local -F s=$(( EPOCHREALTIME - $1 ))
  local -i si=$s
  if (( si < 60 )); then
    printf -v REPLY '%.1fs' $s
  else
    printf -v REPLY '%dm%02ds' $(( si / 60 )) $(( si % 60 ))
  fi
}

mb() { printf -v REPLY '%.1f' $(( $1 / 1048576.0 )) }

dl_progress() { # file total_bytes -> REPLY (bar, percent, MB)
  local -i size=0 total=$2 pct fill w=20
  local -a st
  [[ -f $1 ]] && zstat -A st +size -- $1 2>/dev/null && size=${st[1]}
  mb $size; local got=$REPLY
  if (( total > 0 )); then
    pct=$(( size * 100 / total )); (( pct > 100 )) && pct=100
    fill=$(( pct * w / 100 ))
    repeat_str $G_FULL $fill; local on=$REPLY
    repeat_str $G_EMPTY $(( w - fill )); local off=$REPLY
    mb $total
    printf -v REPLY '%s%s%s%s%s %3d%%  %s%s/%s MB%s' \
      $GRN "$on" $D "$off" $R $pct $D $got $REPLY $R
  else
    REPLY="${D}$got MB${R}"
  fi
}

log_tail() {
  local line
  print -r -- "     ${D}${I_BAR} last lines of the log:${R}"
  for line in "${(@f)$(tail -n 8 -- $LOG)}"; do
    line=${line//$'\r'/}
    print -r -- "     ${D}${I_BAR}${R} ${line[1,110]}"
  done
  print -r -- "     ${D}${I_BAR} full log: ${(D)LOG}${R}"
}

# task [--watch FILE BYTES] LABEL COMMAND [ARGS...]
# Runs COMMAND in the background with its output in the log, showing a spinner
# (and a download bar with --watch) until it finishes.
task() {
  local watch=
  local -i total=0 i=1 rc=1
  if [[ $1 == --watch ]]; then watch=$2 total=$3; shift 3; fi
  local label=$1; shift
  local rcf=$TMP_DIR/rc.$EPOCHREALTIME t0=$EPOCHREALTIME extra
  print -r -- $'\n'"=== $(strftime '%H:%M:%S' $EPOCHSECONDS)  $label"$'\n'"\$ ${(j: :)${(q-)@}}" >>$LOG
  { "$@"; print -r -- $? >$rcf } </dev/null >>$LOG 2>&1 &
  CUR_PID=$!
  if (( FANCY )); then
    printf '\e[?25l'
    while kill -0 $CUR_PID 2>/dev/null; do
      extra=
      if [[ -n $watch ]]; then dl_progress $watch $total; extra="  $REPLY"; fi
      elapsed $t0
      printf '\r   %s%s%s %s%s  %s%s%s\e[K' $CYN ${SPIN[i]} $R "$label" "$extra" $D $REPLY $R
      (( i = i % $#SPIN + 1 ))
      zselect -t 8 2>/dev/null
    done
  fi
  wait $CUR_PID 2>/dev/null
  CUR_PID=
  [[ -s $rcf ]] && rc=$(<$rcf)
  elapsed $t0
  if (( rc == 0 )); then
    printf '%s   %s%s%s %s  %s%s%s%s\n' "$CR" $GRN $I_OK $R "$label" $D $REPLY $R "$EL"
  else
    printf '%s   %s%s%s %s  %s(exit %d, %s)%s%s\n' "$CR" $RED $I_FAIL $R "$label" $D $rc $REPLY $R "$EL"
    log_tail
  fi
  if (( FANCY )); then printf '\e[?25h'; fi
  return $rc
}

# choose DEFAULT QUESTION OPTION... -> REPLY (1-based index of the option)
choose() {
  local -i def=$1 n i lines=0
  local q=$2 ans
  shift 2
  n=$#
  print -r -- "   ${YLW}${I_ASK}${R} ${B}$q${R}"; (( lines++ ))
  for (( i = 1; i <= n; i++ )); do
    print -r -- "     ${CYN}$i)${R} ${argv[i]}"; (( lines++ ))
  done
  while true; do
    printf '   %s%s%s Select %s[%d]%s: ' $CYN $I_ARROW $R $D $def $R
    read -r ans || { ans=; print }
    (( lines++ ))
    [[ -z $ans ]] && ans=$def
    if [[ $ans == <-> ]] && (( ans >= 1 && ans <= n )); then break; fi
    print -r -- "     ${RED}Please type a number from 1 to $n.${R}"; (( lines++ ))
  done
  if (( FANCY )); then
    printf '\e[%dA\e[J' $lines
    print -r -- "   ${YLW}${I_ASK}${R} $q ${CYN}${I_ARROW}${R} ${B}${argv[ans]}${R}"
  fi
  REPLY=$ans
}

progress_header() { # done total title tag
  local -i done=$1 total=$2 w=24 fill pct
  fill=$(( done * w / total )); pct=$(( done * 100 / total ))
  repeat_str $G_FULL $fill; local on=$REPLY
  repeat_str $G_EMPTY $(( w - fill )); local off=$REPLY
  print
  printf '  %s%s%s%s  %s%-14s%s %s%s%s%s%s%s %s%3d%%%s\n' \
    $MAG $B "$4" $R $B "$3" $R $GRN "$on" $R $D "$off" $R $D $pct $R
}
section() { progress_header $(( $1 - 1 )) $2 $3 "[$1/$2]" }

detect_platform() {
  ARCH=$(uname -m)
  case $(uname -s) in
    (Darwin)
      PLATFORM=mac
      OS_NAME="macOS $(sw_vers -productVersion 2>/dev/null)" ;;
    (Linux)
      PLATFORM=linux
      OS_NAME=$( . /etc/os-release 2>/dev/null; print -r -- "${PRETTY_NAME:-Linux}" )
      case $ARCH in
        (x86_64|amd64) NVIM_ASSET=nvim-linux-x86_64 ;;
        (aarch64|arm64) NVIM_ASSET=nvim-linux-arm64 ;;
      esac ;;
    (*)
      print -r -- "Unsupported OS: $(uname -s)" >&2
      return 1 ;;
  esac
}

find_brew() {
  local b
  (( $+commands[brew] )) && return 0
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $b ]]; then
      eval "$($b shellenv)"
      return 0
    fi
  done
  return 1
}

node_major() { # -> REPLY (0 when node is missing)
  local v
  REPLY=0
  (( $+commands[node] )) || return 1
  v=$(node -v 2>/dev/null); v=${v#v}; v=${v%%.*}
  [[ $v == <-> ]] && REPLY=$v
}

nvim_version() { # [binary] -> REPLY, e.g. v0.11.4
  local out
  REPLY=
  out=$(${1:-nvim} --version 2>/dev/null) || return 1
  out=${out%%$'\n'*}
  [[ $out == NVIM\ v* ]] || return 1
  REPLY=${out#NVIM }
}

current_nvim() { # -> REPLY, version of the Neovim this script manages or finds
  REPLY=
  if [[ $PLATFORM == linux && -n $NVIM_ASSET && -x $REPO_DIR/neovim/$NVIM_ASSET/bin/nvim ]]; then
    nvim_version $REPO_DIR/neovim/$NVIM_ASSET/bin/nvim
    return
  fi
  (( $+commands[nvim] )) && nvim_version
}

fetch_latest_nvim() {
  local url
  url=$(curl -fsSI -m 8 -o /dev/null -w '%{redirect_url}' \
    https://github.com/neovim/neovim/releases/latest 2>/dev/null)
  NVIM_LATEST=${url##*/}
  [[ $NVIM_LATEST == v<->.<->.<-> ]] || NVIM_LATEST=
}

content_length() { # url -> REPLY (bytes, 0 when unknown)
  REPLY=$(curl -fsSIL -m 10 -- $1 2>/dev/null | tr -d '\r' |
    awk 'tolower($1) == "content-length:" { n = $2 } END { print n + 0 }')
}

detect_state() {
  local s cur
  local -i nm
  node_major; nm=$REPLY
  s=
  if [[ $PLATFORM == mac ]]; then
    if (( $+commands[brew] )); then s="${GRN}brew${R}"; else s="${YLW}no brew${R}"; fi
    s+=" ${D}${I_DOT}${R} "
  fi
  if (( nm >= NODE_MIN )); then s+="${GRN}node v$nm${R}"
  elif (( nm > 0 )); then s+="${YLW}node v$nm ${I_TO} v$NODE_MIN+${R}"
  else s+="${YLW}no node${R}"; fi
  STATUS[prereq]=$s

  if [[ -d $HOME/.oh-my-zsh ]]; then s="${GRN}oh-my-zsh${R}"; else s="${YLW}no oh-my-zsh${R}"; fi
  [[ ${SHELL:t} == zsh ]] || s+=" ${D}${I_DOT}${R} ${YLW}shell: ${SHELL:t}${R}"
  STATUS[zsh]=$s

  if (( $+commands[tmux] )); then s="${GRN}$(tmux -V)${R}"; else s="${YLW}not installed${R}"; fi
  STATUS[tmux]=$s

  current_nvim; cur=$REPLY
  if [[ -z $cur ]]; then s="${YLW}not installed${R}${NVIM_LATEST:+ ${D}${I_TO}${R} $NVIM_LATEST}"
  elif [[ -z $NVIM_LATEST ]]; then s="$cur ${D}(latest unknown)${R}"
  elif [[ $cur == "$NVIM_LATEST" ]]; then s="${GRN}$cur latest${R}"
  else s="${YLW}$cur ${I_TO} $NVIM_LATEST${R}"; fi
  STATUS[nvim]=$s
}

as_root() { "${SUDO[@]}" "$@" }
apt_install() { as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" }

ensure_sudo() {
  (( SUDO_READY )) && return 0
  SUDO=()
  if (( EUID != 0 )); then
    if (( $+commands[sudo] )); then
      print -r -- "   ${YLW}${I_ARROW}${R} sudo: administrator rights are needed for apt"
      if ! sudo -v; then
        fail "sudo authentication failed"
        return 1
      fi
      SUDO=(sudo -E -n)
      { while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done } &
      SUDO_KEEPALIVE_PID=$!
    else
      warn "sudo is not available - running apt without root"
    fi
  fi
  SUDO_READY=1
}

need_brew() {
  if ! find_brew; then
    fail "Homebrew is required on macOS - select Prerequisites to install it"
    return 1
  fi
  brew_update
}

brew_update() {
  (( BREW_UPDATED )) && return 0
  BREW_UPDATED=1
  task "Updating Homebrew" brew update --quiet ||
    warn "brew update failed - continuing with the current package index"
  export HOMEBREW_NO_AUTO_UPDATE=1
  return 0
}

install_node() { # INSTALL_COMMAND...
  node_major
  if (( REPLY >= NODE_MIN )); then
    skip "Node.js $(node -v) is already installed"
  else
    (( REPLY > 0 )) && info "Node.js $(node -v) is older than v$NODE_MIN"
    task "Installing Node.js v$NODE_MIN+" "$@" || return 1
    rehash
  fi
  DETAIL[prereq]="node $(node -v 2>/dev/null)"
}

link_config() { # SOURCE TARGET
  local src=$1 dst=$2 kind bak
  local pretty=${(D)dst}
  if [[ -L $dst && ${dst:A} == "${src:A}" ]]; then
    skip "$pretty already points to this repo"
    LINK_RESULT="already linked"
    return 0
  fi
  if [[ -L $dst || -e $dst ]]; then
    if [[ -L $dst ]]; then kind="symlink to ${(D)$(readlink -- $dst)}"
    elif [[ -d $dst ]]; then kind=directory
    else kind=file; fi
    choose 1 "$pretty already exists ($kind)." \
      "Back up and replace it with this repo's config (recommended)" \
      "Keep the existing one"
    if (( REPLY == 2 )); then
      skip "Kept the existing $pretty"
      LINK_RESULT=kept
      return 0
    fi
    bak=$dst.bak-$TS
    if ! mv -- $dst $bak; then
      fail "Could not move $pretty out of the way"
      return 1
    fi
    note "Backed up $pretty ${I_TO} ${(D)bak}"
  fi
  if ! { mkdir -p -- ${dst:h} && ln -s -- $src $dst }; then
    fail "Could not link $pretty"
    return 1
  fi
  ok "Linked $pretty ${D}${I_TO} ${(D)src}${R}"
  LINK_RESULT=linked
}

# Keeps the aliases in one marked block of ~/.zshrc so re-runs never duplicate them.
write_zshrc_aliases() {
  local rc=$HOME/.zshrc l
  local begin='# >>> initial-settings (setup.sh) >>>' end='# <<< initial-settings (setup.sh) <<<'
  local -a kept block
  local -i inside=0
  if [[ -s $rc ]]; then
    for l in "${(@f)$(<$rc)}"; do
      if [[ $l == "$begin" ]]; then inside=1
      elif [[ $l == "$end" ]]; then inside=0
      elif (( ! inside )); then kept+=("$l")
      fi
    done
  fi
  block=("$begin")
  [[ -n $NVIM_ALIAS ]] && block+=("alias nvim='$NVIM_ALIAS'")
  block+=("alias vim='nvim'" "$end")
  if ! print -rl -- "${kept[@]}" "${block[@]}" >$rc; then
    fail "Could not update ~/.zshrc"
    return 1
  fi
  ok "~/.zshrc: alias vim=nvim${NVIM_ALIAS:+, nvim ${I_TO} ${(D)NVIM_ALIAS}}"
}

report_nvim_version() { # BINARY
  if ! nvim_version $1; then
    warn "Neovim was installed, but ${(D)1} does not run on this system"
    DETAIL[nvim]="installed, but does not run"
    return 0
  fi
  if [[ -z $NVIM_LATEST || $REPLY == "$NVIM_LATEST" ]]; then
    ok "Neovim $REPLY${NVIM_LATEST:+ ${D}(latest)${R}}"
    DETAIL[nvim]="$REPLY${NVIM_LATEST:+ (latest)}"
  else
    warn "Neovim $REPLY is installed, but the latest release is $NVIM_LATEST"
    DETAIL[nvim]="$REPLY (latest is $NVIM_LATEST)"
  fi
}

comp_prereq() { prereq_$PLATFORM }

prereq_mac() {
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools"
  else
    warn "Xcode Command Line Tools are missing - opening the installer"
    xcode-select --install >>$LOG 2>&1
    info "Finish the installer window, then run this script again."
    return 1
  fi

  if find_brew; then
    ok "Homebrew ${D}(${commands[brew]})${R}"
  else
    choose 1 "Homebrew is not installed. tmux, Neovim and Node.js are installed with it." \
      "Install Homebrew now (recommended)" "Skip"
    if (( REPLY != 1 )); then
      warn "Skipped Homebrew - macOS packages cannot be installed"
      return 1
    fi
    info "Running the official Homebrew installer (it may ask for your password)"
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      fail "Homebrew installation failed"
      return 1
    fi
    if ! find_brew; then
      fail "brew is still not found after the installation"
      return 1
    fi
    local line="eval \"\$(${commands[brew]} shellenv)\""
    if ! grep -qsF -- "$line" $HOME/.zprofile; then
      print -r -- $line >>$HOME/.zprofile
      note "Added Homebrew to ~/.zprofile"
    fi
    ok "Homebrew installed"
  fi
  brew_update
  install_node brew install node
}

prereq_linux() {
  if (( ! $+commands[apt-get] )); then
    warn "apt-get not found - install git, curl, unzip, a C compiler and Node.js v$NODE_MIN+ yourself"
    return 1
  fi
  ensure_sudo || return 1
  task "Updating package lists (apt-get update)" as_root apt-get update || return 1
  task "Installing build tools (git curl unzip build-essential python3-venv)" \
    apt_install curl wget build-essential git python3-venv unzip || return 1
  install_node nodesource_node
}

nodesource_node() {
  curl -fsSL https://deb.nodesource.com/setup_$NODE_MIN.x -o $TMP_DIR/nodesource_setup.sh &&
    as_root bash $TMP_DIR/nodesource_setup.sh &&
    apt_install nodejs
}

comp_zsh() {
  local zsh_bin=${commands[zsh]:-/bin/zsh} shell_now=${SHELL:t}
  if [[ $shell_now == zsh ]]; then
    ok "Default shell is zsh ${D}($SHELL)${R}"
  else
    choose 1 "Your default shell is ${SHELL:-unknown}. Switch to zsh?" \
      "Yes, run: chsh -s $zsh_bin" "No, keep ${shell_now:-it}"
    if (( REPLY == 1 )); then
      info "chsh may ask for your password"
      if chsh -s $zsh_bin; then
        shell_now=zsh
        ok "Default shell set to $zsh_bin"
        note "Log out and back in to use zsh as the default shell"
      else
        warn "chsh failed - run it yourself: chsh -s $zsh_bin"
      fi
    else
      skip "Kept ${shell_now:-the current shell} as the default shell"
    fi
  fi

  if [[ -d $HOME/.oh-my-zsh ]]; then
    skip "oh-my-zsh is already installed"
  else
    local -i had_rc=0
    [[ -e $HOME/.zshrc ]] && had_rc=1
    task "Installing oh-my-zsh" install_omz || return 1
    if (( had_rc )) && [[ -e $HOME/.zshrc.pre-oh-my-zsh ]]; then
      note "oh-my-zsh saved the previous ~/.zshrc as ~/.zshrc.pre-oh-my-zsh"
    fi
  fi
  DETAIL[zsh]="oh-my-zsh, default shell: ${shell_now:-unknown}"
}

install_omz() {
  unset ZSH
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    -o $TMP_DIR/omz-install.sh &&
    sh $TMP_DIR/omz-install.sh --unattended
}

comp_tmux() {
  if (( $+commands[tmux] )); then
    ok "$(tmux -V) is installed"
  elif [[ $PLATFORM == mac ]]; then
    need_brew || return 1
    task "Installing tmux (brew)" brew install tmux || return 1
  else
    ensure_sudo || return 1
    task "Installing tmux (apt)" apt_install tmux || return 1
  fi
  rehash

  if [[ -d $HOME/.tmux/plugins/tpm ]]; then
    skip "tpm is already installed"
  else
    task "Installing tpm (tmux plugin manager)" \
      git clone --depth 1 https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm || return 1
  fi
  link_config $REPO_DIR/tmux/tmux.conf $HOME/.tmux.conf || return 1
  DETAIL[tmux]="${$(tmux -V 2>/dev/null):-tmux}, ~/.tmux.conf $LINK_RESULT"
}

comp_nvim() {
  NVIM_ALIAS=
  nvim_$PLATFORM || return 1
  link_config $REPO_DIR/neovim/nvim-settings $HOME/.config/nvim || return 1
  write_zshrc_aliases
}

nvim_mac() {
  need_brew || return 1
  if brew list --versions neovim >/dev/null 2>&1; then
    if [[ -n $(brew outdated --quiet neovim 2>/dev/null) ]]; then
      task "Upgrading Neovim (brew)" brew upgrade neovim || return 1
    else
      skip "Homebrew's Neovim is already the newest formula"
    fi
  elif (( $+commands[nvim] )); then
    nvim_version
    local cur=$REPLY where=${(D)commands[nvim]}
    if [[ -n $NVIM_LATEST && $cur == "$NVIM_LATEST" ]]; then
      skip "Neovim $cur ($where) is up to date"
    else
      choose 1 "Neovim ${cur:-(unknown version)} at $where was not installed with Homebrew." \
        "Install the latest Neovim with Homebrew (recommended)" "Keep $where"
      if (( REPLY == 1 )); then
        task "Installing Neovim (brew)" brew install neovim || return 1
      else
        skip "Kept $where"
      fi
    fi
  else
    task "Installing Neovim (brew)" brew install neovim || return 1
  fi
  rehash
  report_nvim_version ${commands[nvim]:-nvim}
}

nvim_linux() {
  if [[ -z $NVIM_ASSET ]]; then
    fail "There is no prebuilt Neovim for $ARCH - install it yourself"
    return 1
  fi
  local dir=$REPO_DIR/neovim/$NVIM_ASSET
  local bin=$dir/bin/nvim cur
  current_nvim; cur=$REPLY
  if [[ -n $cur && -n $NVIM_LATEST && $cur == "$NVIM_LATEST" ]]; then
    skip "Neovim $cur is already the latest release"
  else
    [[ -n $cur ]] && info "Updating Neovim $cur ${I_TO} ${NVIM_LATEST:-latest}"
    local url=https://github.com/neovim/neovim/releases/latest/download/$NVIM_ASSET.tar.gz
    local tgz=$TMP_DIR/$NVIM_ASSET.tar.gz
    content_length $url
    task --watch $tgz $REPLY "Downloading Neovim ${NVIM_LATEST:-latest}" \
      curl -fsSL -o $tgz $url || return 1
    task "Unpacking into ${(D)dir}" unpack_nvim $tgz $dir || return 1
  fi
  if [[ -x $bin ]]; then
    NVIM_ALIAS=$bin
    report_nvim_version $bin
  else
    report_nvim_version ${commands[nvim]:-nvim}
  fi
}

unpack_nvim() { # TARBALL DESTINATION_DIR
  local stage=$TMP_DIR/unpack
  rm -rf -- $stage && mkdir -p -- $stage && tar -xzf $1 -C $stage || return 1
  if [[ ! -x $stage/${2:t}/bin/nvim ]]; then
    print -r -- "unexpected archive layout: $(ls $stage)"
    return 1
  fi
  rm -rf -- $2 && mv -- $stage/${2:t} $2
}

banner() {
  local -i w=52
  local t1="JIS ${I_DOT} Jaeho's Initial Settings" t2="zsh ${I_DOT} tmux ${I_DOT} neovim"
  repeat_str $G_H $w; local hr=$REPLY
  print
  print -r -- "  ${CYN}${G_TL}${hr}${G_TR}${R}"
  repeat_str ' ' $(( w - 3 - ${(m)#t1} ))
  print -r -- "  ${CYN}${G_V}${R}   ${B}${t1}${R}${REPLY}${CYN}${G_V}${R}"
  repeat_str ' ' $(( w - 3 - ${(m)#t2} ))
  print -r -- "  ${CYN}${G_V}${R}   ${D}${t2}${R}${REPLY}${CYN}${G_V}${R}"
  print -r -- "  ${CYN}${G_BL}${hr}${G_BR}${R}"
  print -r -- "   ${D}System${R}  $OS_NAME ${D}($ARCH)${R}"
  print -r -- "   ${D}Repo  ${R}  ${(D)REPO_DIR}"
  print -r -- "   ${D}Log   ${R}  ${(D)LOG}"
  print
}

# Returns 1 when the user quits.
select_components() {
  local input tok id mark msg=
  local -i i n=$#COMP_IDS lines any eof
  while true; do
    print -r -- "  ${B}What should be installed?${R}"
    print -r -- "  ${D}numbers toggle (e.g. 2 4) ${I_DOT} a all ${I_DOT} n none ${I_DOT} Enter start ${I_DOT} q quit${R}"
    print
    lines=3
    for (( i = 1; i <= n; i++ )); do
      id=${COMP_IDS[i]}
      if (( SELECTED[$id] )); then mark="${GRN}${I_ON}${R}"; else mark="${D}${I_OFF}${R}"; fi
      printf '   %s%d%s  %s  %s%-13s%s %s%-30s%s %s\n' \
        $CYN $i $R "$mark" $B ${COMP_TITLE[$id]} $R $D "${COMP_DESC[$id]}" $R "${STATUS[$id]}"
      (( lines++ ))
    done
    print; (( lines++ ))
    if [[ -n $msg ]]; then print -r -- "   ${YLW}$msg${R}"; (( lines++ )); fi
    printf '   %s%s%s ' $CYN $I_ARROW $R
    eof=0
    read -r input || { eof=1; input=; print }
    (( lines++ ))
    msg=
    case $input in
      ('')
        any=0
        for id in $COMP_IDS; do (( SELECTED[$id] )) && any=1; done
        (( any )) && return 0
        (( eof )) && return 1
        msg="Select at least one component, or q to quit" ;;
      ([qQ]) return 1 ;;
      ([aA]) for id in $COMP_IDS; do SELECTED[$id]=1; done ;;
      ([nN]) for id in $COMP_IDS; do SELECTED[$id]=0; done ;;
      (*)
        for tok in ${=input//,/ }; do
          if [[ $tok == <-> ]] && (( tok >= 1 && tok <= n )); then
            id=${COMP_IDS[tok]}
            SELECTED[$id]=$(( ! SELECTED[$id] ))
          else
            msg="Unknown choice: $tok"
          fi
        done ;;
    esac
    if (( FANCY )); then printf '\e[%dA\e[J' $lines; fi
  done
}

# Returns 1 when a component failed.
summary() {
  local id icon text
  local -i failed=0 k=1
  progress_header 1 1 Done "[ $I_OK ]"
  print
  print -r -- "  ${B}Summary${R}"
  for id in $COMP_IDS; do
    case ${RESULT[$id]-} in
      (ok)   icon="${GRN}${I_OK}${R}"; text=${DETAIL[$id]:-done} ;;
      (warn) icon="${YLW}${I_WARN}${R}"; text=${DETAIL[$id]:-done with warnings} ;;
      (fail) icon="${RED}${I_FAIL}${R}"; text="failed - see the log"; failed=1 ;;
      (*)    icon="${D}${I_SKIP}${R}"; text="not selected" ;;
    esac
    printf '   %s %s%-14s%s %s%s%s\n' "$icon" $B ${COMP_TITLE[$id]} $R $D "$text" $R
  done

  if (( $#NOTES )); then
    print
    print -r -- "  ${B}Notes${R}"
    for text in $NOTES; do print -r -- "   ${D}${I_DOT}${R} $text"; done
  fi

  print
  print -r -- "  ${B}Next steps${R}"
  print -r -- "   ${CYN}$(( k++ )).${R} Open a new terminal ${D}(or run: exec zsh)${R}"
  if [[ ${RESULT[tmux]-} == (ok|warn) ]]; then
    print -r -- "   ${CYN}$(( k++ )).${R} Start ${B}tmux${R} and press ${B}F2${R} then ${B}Shift+I${R} to install the tmux plugins"
  fi
  if [[ ${RESULT[nvim]-} == (ok|warn) ]]; then
    print -r -- "   ${CYN}$(( k++ )).${R} Start ${B}nvim${R}, let the plugins install, then run ${B}:MasonInstallAll${R}"
    print -r -- "      ${D}NvChad: https://github.com/NvChad/NvChad/tree/v2.5${R}"
  fi
  if [[ $PLATFORM == mac && ${RESULT[tmux]-} == (ok|warn) ]]; then
    print
    print -r -- "  ${B}macOS keyboard tips${R}"
    print -r -- "   ${D}${I_DOT}${R} F2 needs ${B}fn${R} unless \"Use F1, F2, etc. keys as standard function keys\" is on"
    print -r -- "     ${D}System Settings ${I_ARROW} Keyboard ${I_ARROW} Keyboard Shortcuts ${I_ARROW} Function Keys${R}"
    print -r -- "   ${D}${I_DOT}${R} Alt+h/j/k/l pane moves need Option to work as Meta"
    print -r -- "     ${D}VS Code: \"terminal.integrated.macOptionIsMeta\": true${R}"
    print -r -- "     ${D}Terminal: Settings ${I_ARROW} Profiles ${I_ARROW} Keyboard ${I_ARROW} Use Option as Meta key${R}"
    print -r -- "     ${D}iTerm2: Settings ${I_ARROW} Profiles ${I_ARROW} Keys ${I_ARROW} Left Option key: Esc+${R}"
  fi
  print
  print -r -- "  ${D}Log: ${(D)LOG}${R}"
  print
  return $failed
}

cleanup() {
  if [[ -n $CUR_PID ]]; then
    pkill -P $CUR_PID 2>/dev/null
    kill $CUR_PID 2>/dev/null
  fi
  if (( SUDO_KEEPALIVE_PID )); then kill $SUDO_KEEPALIVE_PID 2>/dev/null; fi
  if (( FANCY )); then printf '\e[?25h'; fi
  rm -rf -- $TMP_DIR
}

on_interrupt() {
  print -r -- $'\n'"   ${RED}${I_FAIL} Aborted.${R} ${D}Log: ${(D)LOG}${R}"
  exit 130
}

main() {
  local id
  local -a todo
  local -i n=0

  detect_platform || return 1
  if [[ $PLATFORM == mac ]]; then
    COMP_DESC=(prereq "Xcode CLT, Homebrew, Node.js" zsh "oh-my-zsh, default shell"
               tmux "tmux, tpm, ~/.tmux.conf" nvim "latest release, NvChad config")
  else
    COMP_DESC=(prereq "apt build tools, Node.js v$NODE_MIN+" zsh "oh-my-zsh, default shell"
               tmux "tmux, tpm, ~/.tmux.conf" nvim "latest release, NvChad config")
  fi

  banner
  if (( FANCY )); then printf '   %s%s Checking the current setup...%s' $D ${SPIN[1]} $R; fi
  [[ $PLATFORM == mac ]] && find_brew
  fetch_latest_nvim
  detect_state
  if (( FANCY )); then printf '\r\e[K'; fi

  for id in $COMP_IDS; do SELECTED[$id]=1; done
  if ! select_components; then
    print -r -- "   Nothing to do. Bye."
    return 0
  fi

  for id in $COMP_IDS; do (( SELECTED[$id] )) && todo+=($id); done
  for id in $todo; do
    section $(( ++n )) $#todo ${COMP_TITLE[$id]}
    COMP_WARNED=0
    if comp_$id; then
      if (( COMP_WARNED )); then RESULT[$id]=warn; else RESULT[$id]=ok; fi
    else
      RESULT[$id]=fail
    fi
  done
  summary
}

trap cleanup EXIT
trap on_interrupt INT TERM
main "$@"
exit $?
