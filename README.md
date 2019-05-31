# Script compares LOCAL and REMOTE branch hash values to make sure there are in sync.
If they LOCAL branch isn't in sync with REMOTE branch HASH then it will send out alert via SENDMAIL to designated email.
It checks to make sure that the current local repository is on the correct branch. If not, then it will checkout the proper branch.


This is newer version with functions and better logic. comparebranches.sh
This is the older version without functions. comparelocalremote.sh
