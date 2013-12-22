#!/bin/sh

if [ "${__yasl_locking_loaded}" == "1" ]; then
  return
fi

# TODO(osharoiko): convert echo to logging
lock() {
  local _lockfile
  local _non_blocking
  local _pid
  local _tmpfile

  # options parsing
  # TODO(osharoiko): maybe move into separate function
  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        shift
        break
      ;;
      [^-]*)
        break
      ;;
      -u)
        _non_blocking=1
      ;;
      -*)
        echo "lock: unknown option $1" 1>&2
      ;;
    esac
    shift
  done

  _lockfile="$1"

  if [ -z "${_lockfile}" ]; then
    echo "lock: lockfile not specified"
    return 255
  fi

  rc=0
  _tmpfile=$(mktemp "${_lockfile}.XXXXXXXX")
  echo $$ > "${_tmpfile}"
  while ! ln "${_tmpfile}" "${_lockfile}" 1>/dev/null 2>&1; do
    _pid=$(cat "${_lockfile}" 2>/dev/null)
    if [ -z "${_pid}" ]; then
      # TODO(osharoiko): add a log record here
      # informing about existing lockfile without pid
    elif ! kill -0 "${_pid}" 1>/dev/null 2>&1; then
      # TODO(osharoiko): add a log record here
      # informing about stale lockfile
      if ! rm -f "${_lockfile}" 1>/dev/null 2>&1; then
        echo "lock: couldn't delete unused ${_lockfile}"
        rc=255
        break
      fi
    else
      if [ -n "${_non_blocking}" ]; then
        rc=1
        break
      fi
      sleep 1
    fi
  done

  rm -f "${_tmpfile}" 1>/dev/null 2>&1
  return ${rc}
}

unlock() {
  local _lockfile

  # options parsing
  # TODO(osharoiko): maybe move into separate function
  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        shift
        break
      ;;
      [^-]*)
        break
      ;;
      -*)
        echo "unlock: unknown option $1" 1>&2
      ;;
    esac
    shift
  done

  _lockfile="$1"

  if [ -z "${_lockfile}" ]; then
    echo "unlock: lockfile not specified"
    return 255
  fi

  rm -f "${_lockfile}" 1>/dev/null 2>&1
}
