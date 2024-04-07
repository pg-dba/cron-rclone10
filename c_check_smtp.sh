#!/bin/bash
# c_check_smtp.sh

RELAY=$(cat /etc/postfix/main.cf | grep relayhost | sed 's/relayhost = //')
((count = 3))                           # Maximum number to try.
while [[ $count -ne 0 ]] ; do
    ping -c 1 ${RELAY} 2>&1 1>/dev/null  # Try once.
    RC=$?
    if [[ $RC -eq 0 ]] ; then
        ((count = 1))                    # If okay, flag loop exit.
    else
        sleep 1                          # Minimise network storm.
    fi
    ((count = count - 1))                # So we don't go forever.
done

if [[ $RC -eq 0 ]] ; then                # Make final determination.
    echo "[ping]  ${RELAY} is Ok."
else
    echo "[ping]  ${RELAY} is Bad."
fi

exit ${RC}
