#!/bin/bash
# Created by Justin Todd
# 05/29/2019
# Version 1.2
ACTION='\033[1;90m'
FINISHED='\033[1;96m'
READY='\033[1;92m'
NOCOLOR='\033[0m' # No Color
ERROR='\033[0;31m'
DT=$( date '+%F_%H:%M:%S' )
DIRECTORY="/var/www/website/"
FROM="alert@hostname.com"
TO="alert@hostname.com"
SEND="/usr/sbin/sendmail"
ERROR_MESSAGE="WARNING #1 -- $HOSTNAME current branch is not up to date with latest $BRANCH branch."
NOTICE="INFO #1 -- $HOSTNAME current branch is up to date with the latest $BRANCH branch."
CHECKOUT_PRODUCTION="WARNING #1 -- $HOSTNAME not on Production Branch. Checking out $BRANCH branch!"
CHECKOUT_MASTER="WARNING #1 -- $HOSTNAME not on Master Branch. Checking out $BRANCH branch!"
HOST_ERROR="WARNING #1 -- Script doesn't include this hostname $HOSTNAME. Aborting hash check!"
DEMO="demo.hostname.com"
DB_STAGING="db.staging.hostname.com"
WWW_STAGING="www.staging.hostname.com"
PROD_BRANCH="production"
MASTER_BRANCH="master"

#SWITCH TO DIRECTORY TO GET CURRENT BRANCH
cd $DIRECTORY
#GET BRANCH
BRANCH=$(git rev-parse --abbrev-ref HEAD)

#BEGINNING INFORMATION
echo
echo -e ${ACTION}Checking Git repo
echo -e =======================${NOCOLOR}
echo

#FUNCTION TO BEGIN CHECK DEPENDING HOSTNAME
BEGIN () {
if [[ "$HOSTNAME" == "$DEMO" ]]; then
        DEMO
fi

if [[ "${HOSTNAME}" == @($DB_STAGING|$WWW_STAGING) ]]; then
        STAGING
fi
}

#FUNCTION TO CHECK HOSTNAME
CHECK_HOSTNAMES () {
	if [[ "$HOSTNAME" != @($DEMO|$DB_STAGING|$WWW_STAGING) ]]; then
        	echo -e "${ERROR}WARNING #1 HOSTNAMES DON'T MATCH DEMO OR STAGING SERVERS"
        	echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
        	echo
        	exit 0
	fi
}

#Send EMAIL using SENDMAIL for WARNING notification function
WARN_EMAIL () {
echo -e "Subject:Monitor Warning Report \n\n $ERROR_MESSAGE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
#echo -e "SEND WARN EMAIL TEST"
}

#Send EMAIL using SENDMAIL for INFO notification function
INFO_EMAIL () {
#echo -e "Subject:Monitor Warning Report \n\n $NOTICE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
#echo -e "SEND INFO EMAIL TEST"
}

HASH () {
# GET LOCAL AND REMOTE HASH VALUES ON BRANCHES
LOCALHASH=$(git show-ref --heads --hash refs/heads/$BRANCH)
REMOTEHASH=$(git ls-remote origin -h refs/heads/$BRANCH | awk '{print $1}')
}

COMPARE () {
	if [ "$LOCALHASH" != "$REMOTEHASH" ]; then
        	WARN_EMAIL
        	echo -e "${ERROR}WARNING #1 -- Current branch is not up to date with the lastest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
        	echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
        	echo
        	exit 0
	else
        	INFO_EMAIL
        	echo -e "${FINISHED}INFO #1 -- Current local $BRANCH branch is up to date with the latest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
        	echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
        	echo
	fi
}

#CHECK STAGING REPO FOR MASTER BRANCH IF NOT THEN SWITCH TO MASTER
CHECK_STAGING () {
while [[ "$BRANCH" != "$MASTER_BRANCH" ]]
do
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        git checkout $MASTER_BRANCH
                if [[ "$BRANCH" == "$MASTER_BRANCH" ]]; then
                        break
                fi
done
#echo -e "CHECK STAGING"
STAGING
}

#CHECK FOR MASTER REPO AND THEN COMPARE HASH
STAGING () {
	if [[ "$BRANCH" == "$MASTER_BRANCH" ]]; then
                echo -e "${ACTION}Current branch is: $BRANCH ${NOCOLOR}"
                echo
		HASH
                COMPARE
        else
                echo -e "${ERROR}Switching to branch: $MASTER_BRANCH ${NOCOLOR}"
                echo
		CHECK_STAGING
        fi
#echo -e "TEST STAGING"
}

#CHECK DEMO REPO BRANCH FOR PRODUCTION IF NOT THEN SWITCH TO PRODUCTION
CHECK_DEMO () {
while [[ "$BRANCH" != "$PROD_BRANCH" ]]
do
	BRANCH=$(git rev-parse --abbrev-ref HEAD)
	git checkout $PROD_BRANCH
 		if [[ "$BRANCH" == "$PROD_BRANCH" ]]; then
    			break
  		fi
done
#echo -e "CHECK DEMO"
DEMO
}

#CHECK FOR PRODUCTION BRANCH AND THEN COMPARE HASH
DEMO () {
	if [[ "$BRANCH" == "$PROD_BRANCH" ]]; then
		echo -e "${ACTION}Current branch is: $BRANCH ${NOCOLOR}"
		echo
		HASH
		COMPARE
	else
		echo -e "${ERROR}Switching to branch: $PROD_BRANCH ${NOCOLOR}"
		echo
		CHECK_DEMO
	fi
}

#CALL FUNCTION CHECK HOST
CHECK_HOSTNAMES

#START FUNTIONM
BEGIN

#END OF INFORMATION
echo
echo -e "======================="
echo -e "${ACTION}Done Checking Git repo ${NOCOLOR}"
