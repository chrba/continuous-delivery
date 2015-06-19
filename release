#!/bin/bash

set -e

########################################################################
#			Input parameter check
########################################################################

function usage {
	echo "Usage: $0 [STAGING_DIR] [GIT_ARTIFACT] [GIT_MASTER] [NEXUS_SERVER]"
	exit 1
}
if [ ! -d $1 ];then
	echo "No staging dir provided or directory does not exist"
	usage
fi

if [ ! -d $2 ]; then
	echo "No artifact git repository provided or directory does not exist"
	usage
fi

if [ ! -d $3 ]; then
	echo "No master git repository provided or directory does not exist"
	usage
fi

if [ -z $4 ]; then
	echo "You have to specify the address to the nexus server"
	usage
fi


########################################################################
#			Variable definitions
########################################################################

STAGING_DIR=$(cd "$1"; pwd)
GIT_ARTIFACT=$(cd "$2"; pwd)
GIT_MASTER_URI=$3
NEXUS=$4
HOST="$NEXUS/content/repositories/releases/"
DIR="$(pwd)"
########################################################################
#			Release all files to nexus using http PUT
########################################################################

echo "Releasing $STAGING_DIR to nexus"
cd $STAGING_DIR
for file in $(find . -type f); do
	curl "${HOST}${file:2}" --upload-file "$file"
done


########################################################################
#			Push all tags from staging artifact to master
########################################################################

echo "Push all tags from $GIT_ARTIFACT_DIR to master repository"

cd "$DIR"
git clone "$GIT_MASTER_URI" tmp
cd tmp
git remote add staging "$GIT_ARTIFACT"
git fetch staging
git merge staging/MASTER
git push origin --tags
git remote rm staging
cd ..
rm -rf tmp
