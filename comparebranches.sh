#!/bin/bash
# Created by Justin Todd
# 06/12/2019
# Version 1.3

#VARIABLES FOR ERROR COLORS
ACTION='\033[1;90m'
FINISHED='\033[1;96m'
READY='\033[1;92m'
NOCOLOR='\033[0m' # No Color
ERROR='\033[0;31m'
DT=$(date '+%F %H:%M:%S')

#VARIABLES FOR REPORTING/BRANCH/GIT DIR LOCATION/HOSTS
DIRECTORY="/var/www/<website>/"
FROM="admin@hostname.com.com"
TO="admin@hostname.com"
SEND="/usr/sbin/sendmail"
ERROR_MESSAGE="WARNING #1 -- $HOSTNAME current branch is not up to date with latest $BRANCH branch."
NOTICE="INFO #1 -- $HOSTNAME current branch is up to date with the latest $BRANCH branch."
CHECKOUT_PRODUCTION="WARNING #1 -- $HOSTNAME not on Production Branch. Checking out $BRANCH branch!"
CHECKOUT_MASTER="WARNING #1 -- $HOSTNAME not on Master Branch. Checking out $BRANCH branch!"
HOST_ERROR="WARNING #1 -- Script doesn't include this hostname $HOSTNAME. Aborting hash check!"
#BRANCHES
PROD_BRANCH="production"
MASTER_BRANCH="master"
# DEPLOY CLIENT AND SECRET KEY
CLIENT_ID="bitbucket Client ID"
SECRET="bitbucket secret key"
DIR="/var/www/<website>/"

#PRODUCTION HOSTNAMES
PRODBRANCH_HOSTS=(
	'prod01.hostname.com'
	'prod02.hostname.com'
		)
#STAGING HOSTS
MASTBRANCH_HOSTS=(
	'mast01.hostname.com'
	'mast02.hostname.com'
		)

#SWITCH TO DIRECTORY TO GET CURRENT BRANCH
cd $DIRECTORY
#GET BRANCH
BRANCH=$(git rev-parse --abbrev-ref HEAD)

#BEGINNING INFORMATION
echo
echo -e "${ACTION}Checking Git repo at: $DT"
echo -e "==================================================${NOCOLOR}"
echo

#FUNCTION TO BEGIN CHECK DEPENDING HOSTNAME
BEGIN () {
if [[ ${PRODBRANCH_HOSTS[@]} =~ $HOSTNAME ]]; then
	echo -e "${ACTION}Checking Host..${NOCOLOR}"
    	for HOSTS in "${PRODBRANCH_HOSTS[@]}"
		do
        		if [[ $HOSTS == $HOSTNAME ]]; then
            		echo -e "${READY}Match: $HOSTNAME uses Production Branch ${NOCOLOR}"
			CHECK_PROD_BRANCH
        		fi
    		done
fi

if [[ ${MASTBRANCH_HOSTS[@]} =~ $HOSTNAME ]]; then
	echo -e "${ACTION}Checking Host..${NOCOLOR}"
    	for HOSTS in "${MASTBRANCH_HOSTS[@]}"
    		do
        		if [[ $HOSTS == $HOSTNAME ]]; then
            		echo -e "${READY}Match: $HOSTNAME uses Master Branch ${NOCOLOR}"
			CHECK_MASTER_BRANCH
        		fi
    		done
fi

}

# RETRIEVE ACCESS/REFRESH TOKEN
RETRIEVE_ACCESS_TOKEN () {
OAUTH_TOKEN=$(curl -s https://bitbucket.org/site/oauth2/access_token -d grant_type=client_credentials -u $CLIENT_ID:$SECRET)
ACCESS_TOKEN=$(echo $OAUTH_TOKEN | grep -oP 'access_token"\s*:\s*"\K(.*)"' | cut -f1 -d',' | tr -d '"')
REFRESH_TOKEN=$(echo $OAUTH_TOKEN | grep -oP 'refresh_token"\s*:\s*"\K(.*)"' | cut -f1 -d',' | tr -d '"')
}

#Send EMAIL USING SENDMAIL FOR WARNING NOTIFICATION FUNCTION
WARN_EMAIL () {
#echo -e "Subject:Monitor Warning Report \n\n $ERROR_MESSAGE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
echo -e "${ERROR}WARNING #1 -- No Match: Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
echo
echo -e "${ACTION}==================================================${NOCOLOR}"
echo -e "${FINISHED}Done comparing Hashes at: $DT  ${NOCOLOR}"
echo
}

#Send EMAIL using SENDMAIL for INFO notification function
INFO_EMAIL () {
#echo -e "Subject:Monitor INFO  Report \n\n $NOTICE Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH" | $SEND -F $FROM -f $FROM -t $TO
echo -e "${READY}INFO #1 -- Match: Remote $BRANCH: $REMOTEHASH -- Local $BRANCH: $LOCALHASH.${NOCOLOR}"
echo
echo -e "${ACTION}==================================================${NOCOLOR}"
echo -e "${FINISHED}Done comparing Hashes at: $DT ${NOCOLOR}"
echo
}

HASH () {
# GET LOCAL AND REMOTE HASH values for BRANCH
LOCALHASH=$(git show-ref --heads --hash refs/heads/$BRANCH)
REMOTEHASH=$(git ls-remote origin -h refs/heads/$BRANCH | awk '{print $1}')
}

#SET GIT REMOTE ORIGIN
SET_ORIGIN () {
cd $DIRECTORY
echo -e "${READY}Setting remote origin: @bitbucket.org/repo.git ${NOCOLOR}"
echo
RETRIEVE_ACCESS_TOKEN
git remote rm origin
git remote add origin "https://x-token-auth:{$ACCESS_TOKEN}@bitbucket.org/repo.git"
}

GIT_PULL () {
echo -e "${READY}Git Pulling $BRANCH at: $DT ${NOCOLOR}"
echo -e "${FINISHED}Current HEAD at origin/$BRANCH: $REMOTEHASH ${NOCOLOR}"
echo -e "${READY}"
git pull origin $BRANCH
git reset --hard $REMOTEHASH
echo -e "${NOCOLOR}"
echo -e "${ACTION}==================================================${NOCOLOR}"
echo -e "${FINISHED}Git Pull of $BRANCH Done at: $DT ${NOCOLOR}"
echo
}

COMPARE () {
        if [[ "$LOCALHASH" != "$REMOTEHASH" ]]; then
                WARN_EMAIL
        else
                INFO_EMAIL
		SET_ORIGIN
		GIT_PULL
        fi
}

#CHECK DEMO REPO BRANCH FOR PRODUCTION IF NOT THEN SWITCH TO PRODUCTION
CHANGE_TO_MASTER () {
while [[ "$BRANCH" != "$MASTER_BRANCH" ]]
do
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        git checkout $MASTER_BRANCH
                if [[ "$BRANCH" == "$MASTER_BRANCH" ]]; then
                        break
                fi
done
#echo -e "CHECK STAGING"
CHECK_MASTER_BRANCH
}

#CHECK FOR MASTER BRANCH AND THEN COMPARE HASH
CHECK_MASTER_BRANCH () {
	if [[ "$BRANCH" == "$MASTER_BRANCH" ]]; then
                echo -e "${ACTION}Current branch is: $BRANCH ${NOCOLOR}"
                echo
		HASH
                COMPARE
        else
                echo -e "${ERROR}Host's branch is set to "$BRANCH". Required Branch: $MASTER_BRANCH ${NOCOLOR}"
		echo -e "${READY}Switching to branch: $MASTER_BRANCH ${NOCOLOR}"
                echo
		CHANGE_TO_MASTER
        fi
#echo -e "TEST STAGING"
}

#CHECKOUT PRODUCTION BRANCH
CHANGE_TO_PROD_BRANCH () {
while [[ "$BRANCH" != "$PROD_BRANCH" ]]
do
	BRANCH=$(git rev-parse --abbrev-ref HEAD)
	git checkout $PROD_BRANCH
 		if [[ "$BRANCH" == "$PROD_BRANCH" ]]; then
    			break
  		fi
done
#echo -e "CHECK DEMO"
CHECK_PROD_BRANCH
}

#CHECK FOR PRODUCTION BRANCH AND THEN COMPARE HASH
CHECK_PROD_BRANCH () {
	if [[ "$BRANCH" == "$PROD_BRANCH" ]]; then
		echo -e "${ACTION}Current branch is: $BRANCH ${NOCOLOR}"
		echo
		HASH
		COMPARE
	else
		echo -e "${ERROR}Host's branch is set to "$BRANCH". Required Branch: $PROD_BRANCH ${NOCOLOR}"
		echo -e "${READY}Switching to branch: $PROD_BRANCH ${NOCOLOR}"
		echo
		CHANGE_TO_PROD_BRANCH
	fi
}

#START FUNTION
BEGIN
