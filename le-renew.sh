#!/bin/bash

# Author	:  Ken Cascio
# Description	:  Script to process:  letsencrypt renew
# Description	:  Original Pythong Script did not provide propr PATH, Logging,
# Description	:  or Email Notification.
# Date  	:  06/05/17
# Version	:  01

# letsencrypt renew is a python script that requires root enviornment PATH to function.
# this restores the root PATH so the call works properly and includes proper logging/email.

export PATH="$PATH"

# Variables

log=/var/log/le-renew.log
output=$(/usr/bin/letsencrypt renew)
success=$(printf "$output" | grep 'success')
failure=$(printf "$output" | grep 'failure')
skipped=$(printf "$output" | grep 'skipped')
results="$success$failure$skipped"
mailsubject=""
logged='F'
now=$(date)

# Restart Services

if [[ $success != "" ]]
then
    apachectl -k restart
#    apachectl -k graceful
#    service apache2 reload
#    service postfix reload
fi

# Logging

if [[ $results != "" ]]  # success / failure / skipped
then
    if [[ $success != "" ]] # Success
    then
        mailsubject="[`hostname`] Certificate renewals: SUCCESSFUL"
        printf "[$now] Renewal succeeded for the following certificates:\n$success\n" >> $log
	logged='T'
    fi

    if [[ $failure != "" ]] # Failure
    then
	case "$logged" in
	    F) mailsubject="[`hostname`] Certificate renewals: FAILED"
               ;;
	    T) mailsubject="$mailsubject / FAILED"
	       ;;
	esac

    	printf "[$now] Renewal failed for the following certificates:\n$failure\n" >> $log
	logged="T"
    fi

    if [[ $skipped != "" ]] # Skipped
    then
	case "$logged" in
            F) mailsubject="[`hostname`] Certificate renewals: SKIPPED"
               ;;
            T) mailsubject="$mailsubject / SKIPPED"
               ;;
        esac

        printf "[$now] Renewal failed for the following certificates:\n$skipped\n" >> $log
	logged="T"
    fi
else
    mailsubject="[`hostname`] Certificate renewals: NO ACTION/ERRORS"
    printf "[$now] No certificates were renewed\n" >> $log
fi

# Email Results

if [[ $mailsubject != "" ]]
then
    printf "$now\n\n$output" | mail -s "$mailsubject" root@localhost
fi

# Exit Script

exit 0

