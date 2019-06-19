# Script compares LOCAL and REMOTE branch hash values to make sure there are in sync.
If the LOCAL branch isn't in sync with REMOTE branch HASH then it will send out alert via SENDMAIL to designated email. Script will compare the hash values and if it doesn't match will git reset. It will do a git pull as well. Can be configured as a cron.



# comparebranches.sh v1.5
# This is the older version without functions. comparelocalremote.sh
