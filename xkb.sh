#!/bin/sh

#
# xkb_component_append reads on standard input an xkb keymap defenition
# and appends a suffix to one of the keymap components. Modified keymap
# definition is written to standard output. Component to modify and suffix
# are given as command line arguments. Purpose of this is to tune existing
# keymap without having to specify the full configuration.
#
# Expected format of xkb keymap definition is the output of "setxkbmap -print".
#
# Arguments
#   xkb component     Component of xkb keymap to add suffix to.
#                     Usual components include keycodes, types, compat,
#                     symbols and geometry.
#   suffix            Suffix to be appended to a given xkb component.
#                     This suffix will be appended using + operation.
# Return values
#   0                 Success
#   1                 Error
#
# Example
#
# The following command
#
# xkb_component_append "symbols" "+group(toggle)"
#
# will transform
#
# xkb_keymap {
#   xkb_keycodes  { include "evdev+aliases(qwerty)" };
#   xkb_types     { include "complete"  };
#   xkb_compat    { include "complete"  };
#   xkb_symbols   { include "pc+us+inet(evdev)" };
#   xkb_geometry  { include "pc(pc105)" };
# };
#
# into
#
# xkb_keymap {
#   xkb_keycodes  { include "evdev+aliases(qwerty)" };
#   xkb_types     { include "complete"  };
#   xkb_compat    { include "complete"  };
#   xkb_symbols   { include "pc+us+inet(evdev)+group(toggle)" };
#   xkb_geometry  { include "pc(pc105)" };
# };
#

xkb_component_append() {
  if [ $# -lt 2 ]; then
    echo "xkb_component_append requires 2 arguments: xkb component and suffix." 1>&2
    return 1
  fi
  local component="$1"
  local suffix="$2"
  pattern_before="^[[:space:]]*xkb_keymap[[:space:]]*\\{[[:space:]]*.*xkb_${component}[[:space:]]*\\{[[:space:]]*include[[:space:]]*\"[^\"]+"
  pattern_after="\"[[:space:]]*\\};[[:space:]]*.*\\};[[:space:]]*$"
  sed -E ":a;N;\$!ba;s/(${pattern_before})(${pattern_after})/\1${suffix}\2/"
}
