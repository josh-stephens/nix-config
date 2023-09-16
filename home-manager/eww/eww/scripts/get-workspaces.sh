#!/bin/bash

# Define the workspace-icon mapping
WORKSPACE_ICONS=$(jq -n '{
  "1": "",
  "2": "",
  "3": "",
  "4": "",
  "5": "",
  "6": "",
}')

spaces (){
  WORKSPACE_WINDOWS=$(hyprctl workspaces -j | jq 'map({key: .id | tostring, value: .windows}) | from_entries')
  ACTIVE_WORKSPACE_DATA=$(hyprctl activeworkspace -j)
  ACTIVE_WORKSPACE_ID=$(echo "${ACTIVE_WORKSPACE_DATA}" | jq -r '.id | tostring')
  ACTIVE_WORKSPACE_WINDOWS=$(echo "${ACTIVE_WORKSPACE_DATA}" | jq --argjson icons "${WORKSPACE_ICONS}" '{id: .id | tostring, windows: .windows, icon: ($icons[.id | tostring]//null)}')
  WORKSPACE_JSON=$(seq 1 10 | jq --argjson icons "${WORKSPACE_ICONS}" --argjson windows "${WORKSPACE_WINDOWS}" --slurp -Mc 'map(tostring) | map({id: ., windows: ($windows[.]//0), icon: ($icons[.]//null)}) | map(select(.windows != 0))')
  FINAL_JSON=$(echo "${WORKSPACE_JSON}" | jq -Mc --argjson active "${ACTIVE_WORKSPACE_WINDOWS}" '. + [$active] | unique_by(.id) | sort_by(.id)')


  echo "${FINAL_JSON}"
}

spaces
socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
	spaces
done
