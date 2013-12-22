#!/bin/sh

ssh_agent_cache="${HOME}/.ssh/agent-cache.`hostname`"
ssh_agent_cache_sh="${ssh_agent_cache}.sh"
ssh_agent_cache_csh="${ssh_agent_cache}.csh"

ssh_add="ssh-add"
ssh_agent="ssh-agent"

# TODO: logging does not belong here
log_err() {
  logger -i -p user.err -t ssh-agent-init -s $@
}

log_info() {
  logger -i -p user.info -t ssh-agent-init $@
}

ssh_agent_check() {
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    log_info "SSH_AUTH_SOCK not defined or empty"
    return 1
  fi

  ${ssh_add} -l 1> /dev/null 2>&1
  if [ "$?" = "0" -o "$?" = "1" ]; then
    log_info "ssh-agent accessible."
    return 0
  fi

  log_info "ssh-agent not accessible."
  unset SSH_AUTH_SOCK
  unset SSH_AGENT_PID
  return 1
}

ssh_agent_init() {
  log_info "Checking current environment."
  if ssh_agent_check; then
    echo "Using ssh-agent described in current environment."
    return 0
  fi

  log_info "Checking ssh-agent cache."
  ssh_agent_cache_read
  if ssh_agent_check; then
    echo "Using ssh-agent described in cache."
    return 0
  fi

  log_info "Starting new instance of ssh-agent."
  eval `${ssh_agent}` >/dev/null

  log_info "Checking new ssh-agnet."
  if ssh_agent_check; then
    ssh_agent_cache_write
    echo "Using new ssh-agent."
    return 0
  fi

  log_err "Could not initialize ssh-agent."
}

ssh_agent_cache_read() {
  if [ -r "${ssh_agent_cache_sh}" ]; then
    . ${ssh_agent_cache_sh} > /dev/null
  else
    log_info "ssh-agent cache not found or is not readable."
  fi
}

ssh_agent_cache_write() {
  {
    echo "SSH_AUTH_SOCK=\"${SSH_AUTH_SOCK}\"; export SSH_AUTH_SOCK;"
    echo "SSH_AGENT_PID=\"${SSH_AGENT_PID}\"; export SSH_AGENT_PID;"
  } > ${ssh_agent_cache_sh}
  {
    echo "setenv SSH_AUTH_SOCK \"${SSH_AUTH_SOCK}\""
    echo "setenv SSH_AGENT_PID \"${SSH_AGENT_PID}\""
  } > ${ssh_agent_cache_csh}
}
