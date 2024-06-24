#!/bin/bash
# Thanks https://binx.io/2021/03/10/how-to-tell-ansible-to-use-gcp-iap-tunneling/
# This is a wrapper script allowing to use GCP's IAP option to connect
# to our servers.

# Ansible passes a large number of SSH parameters along with the hostname as the
# second to last argument and the command as the last. We will pop the last two
# arguments off of the list and then pass all of the other SSH flags through
# without modification:
HOST="${@: -2: 1}"
CMD="${@: -1: 1}"

# Unfortunately ansible has hardcoded scp options, so we need to filter these out
# It's an ugly hack, but for now we'll only accept the options starting with '--'
declare -a OPTS
for SCP_ARG in "${@: 1: $# -3}" ; do
    if [[ "${SCP_ARG}" == --* ]] ; then
        OPTS+="${SCP_ARG} "
    fi
done

# Remove [] around our host, as gcloud scp doesn't understand this syntax
CMD=`echo "${CMD}" | tr -d []`

exec gcloud compute scp $OPTS "${HOST}" "${CMD}"
