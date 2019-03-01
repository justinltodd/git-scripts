#!/bin/bash
# Created by Justin Todd
# 02/25/2019
ACTION='\033[1;90m'
FINISHED='\033[1;96m'
READY='\033[1;92m'
NOCOLOR='\033[0m' # No Color
ERROR='\033[0;31m'
DT=$( date '+%F_%H:%M:%S' )
DIRECTORY="<REPO DIRECTORY>"
FROM="FROM EMAIL"
TO="TO EMAIL"
SEND="/usr/sbin/sendmail"
ERROR_MESSAGE="WARNING #1 -- $HOSTNAME current branch is not up to date with latest $BRANCH branch."
NOTICE="INFO #1 -- $HOSTNAME current branch is up to date with the latest $BRANCH branch."
ABORT_MESSAGE="WARNING #1 -- $HOSTNAME not on Production Branch. Aborting hash check!"
HOST1="hostname.example.com"
HOST2="hostname.example.com"
HOST3="hostname.example.com"

cd $DIRECTORY

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo
echo -e ${ACTION}Checking Git repo
echo -e =======================${NOCOLOR}
echo

LOCALHASH=$(git show-ref --heads --hash refs/heads/$BRANCH)
REMOTEHASH=$(git ls-remote origin -h refs/heads/$BRANCH | awk '{print $1}')

#Check if hostname is equal to either HOST1 or HOST2
if [ "$HOSTNAME" == "$HOST1" ] || [ "$HOST2" ]; then
        #Check if current Branch is MASTER
        if [ "$BRANCH" == "master" ]; then
                #Compare LOCAL GIT HASH TO REMOTE GIT HASH
                if [ "$LOCALHASH" != "$REMOTEHASH" ]; then
                        echo -e "${ERROR}WARNING #1 -- Current branch is not up to date with the lastest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
                        #Send EMAIL using SENDMAIL for WARNING notification
                        echo -e "Subject:SMART Monitor Warning Report \n\n $ERROR_MESSAGE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
                        echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
			echo
                        exit 0
                else
                        echo -e "${FINISHED}INFO #1 -- Current local $BRANCH branch is up to date with the latest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
			#Send EMAIL using SENDMAIL for INFO notification
                        echo -e "Subject:SMART Monitor Warning Report \n\n $NOTICE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
                        echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
			echo
                fi
        #Check if hostname is equak to HOST3
        elif  [ "$HOSTNAME" == "$HOST3" ]; then
                #Check if current Branch is PRODUCTION
                if [ "$BRANCH" == "production" ]; then
                        #Compare LOCAL GIT HASH TO REMOTE GIT HASH
                        if [ "$LOCALHASH" != "$REMOTEHASH" ]; then
                                echo -e "${ERROR}WARNING #1 -- Current branch is not up to date with the lastest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
                                #Send EMAIL using SENDMAIL for WARNING notification
                                echo -e "Subject:SMART Monitor Warning Report \n\n $ERROR_MESSAGE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
                                echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
				echo
                                exit 0
                        else
                                echo -e "${FINISHED}INFO #1 -- Current local $BRANCH branch is up to date with the latest remote $BRANCH branch. Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
				#Send EMAIL using SENDMAIL for INFO notification
                                echo -e "Subject:SMART Monitor Warning Report \n\n $NOTICE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
                                echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
				echo
                        fi
                else
                        echo -e "This isn't the right hosts to run the script"
                        exit 0
                fi
        else
                #ABORT if not branch isn't either master or propduction
                echo -e "${ERROR}Not on the correct Branch. Aborting. ${NOCOLOR}"
                #Send EMAIL using SENDMAIL for ABORT notification
                echo -e "Subject:SMART Monitor Warning Report \n\n $ABORT_MESSAGE" | $SEND -F $FROM -f $FROM  -t $TO
                echo -e "${FINISHED}Time: $DT ${NOCOLOR}"
		echo
                exit 0
        fi
fi
