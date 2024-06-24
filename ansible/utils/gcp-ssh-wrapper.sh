#!/bin/bash
# This is a wrapper script allowing to use GCP's IAP option to connect
# to our servers.
# Ansible passes a large number of SSH parameters along with the hostname as the
# second to last argument and the command as the last. We will pop the last two
# arguments off of the list and then pass all of the other SSH flags through
# without modification:
# SC2124: Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
host="${*: -2: 1}"
cmd="${*: -1: 1}"

# Unfortunately ansible has hardcoded scp options, so we need to filter these out
# It's an ugly hack, but for now we'll only accept the options starting with '--'
declare -a opts
for s_arg in "${@: 1: $# -2}" ; do
    if [[ "${s_arg}" == --* ]] ; then
        opts+=("${s_arg}")
    fi
done

exec gcloud compute ssh "${opts[@]}" "${host}" --command "${cmd}"
