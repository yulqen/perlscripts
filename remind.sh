#!/bin/sh -e

# to echo from stdin
#stdin=$(cat)

# if [ -z $stdin ] ; then
#     echo "No stdin set"
# fi

# echo $stdin

# DESCRIPTION=$1
# echo $DESCRIPTION

if [[ "$#" < 3 ]] ; then
    echo "You need to give me more parameters"
fi

PARAMS=$@
echo $@

if [[ -z "${TW_HOOK_REMIND_REMOTE_HOST}" ]] ; then
    echo "There is not TW_HOOK_REMIND_REMOTE_HOST variable set."
    exit 1;
else
    echo "TW_HOOK_REMIND_REMOTE_HOST set"
fi

ssh $TW_HOOK_REMIND_REMOTE_HOST '
cat ~/.reminders/work.rem
'
