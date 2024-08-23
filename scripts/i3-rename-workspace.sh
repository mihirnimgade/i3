#!/bin/bash
### Move the focus to a particular workspace using dmenu.

I3INPUT=$(command -v i3-input) || exit 1
I3MSG=$(command -v i3-msg) || exit 1
JQ=$(command -v jq) || exit 2

# CURWORKSPACE=$($I3MSG -t get_workspaces | $JQ '.[] | select(.focused==true).name' | cut -d"\"" -f2 | awk '{ print $1 }')
CURALLOCATION=$($I3MSG -t get_workspaces | $JQ '.[] | select(.focused==true).num' | cut -d"\"" -f2 | awk '{ print $1 }')

# if the workspace is already allocated a number use that allocation
if [ "${CURALLOCATION}" -ne -1 ]; then
    STR="rename workspace to \"${CURALLOCATION}: %s\""
    $I3INPUT -F "$STR" -P "New name (using workspace ${CURALLOCATION}): "
    exit 0
fi

# if we've reached here, we need to find an allocation for the workspace we're renaming...
ALLOCATION=1

# step 1: call i3-msg -t get_workspaces and collect allocations into an array
readarray -t workspace_allocations < <($I3MSG -t get_workspaces | $JQ '.[].num')

# step 2: sort the list
workspace_allocations=($(printf '%s\n' "${workspace_allocations[@]}" | sort))

# step 3: iterate over the list and find out if there's any non-consecutive entries

# if the array length is 0, this loop won't run
for ((i=0; i<${#workspace_allocations[@]}; i++)); do
    cur_entry=${workspace_allocations[i]#10}

    # skip all unassigned workspaces
    if [ "${cur_entry}" -eq -1 ]; then
        continue
    fi

    # if the current allocation is equal to the current value, then increment the allocation
    if [ "${workspace_allocations[i]#10}" -eq $ALLOCATION ]; then
        ALLOCATION=$((ALLOCATION+1))
    # if not, then it is a valid allocation to make
    else
        break
    fi
done

STR="rename workspace to \"${ALLOCATION}: %s\""

## Using jq to extract the keys from the JSON array returned by i3-msg -t get_workspaces.
# $I3MSG workspace $($I3MSG -t get_workspaces | $JQ -M '.[] | .name' | tr -d '"' | sort -u | dmenu -sb "#534351" -p "goto" -i "$@")
$I3INPUT -F "$STR" -P "New name (using workspace ${ALLOCATION}): "
