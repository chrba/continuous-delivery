#!/bin/sh
set -e

SOURCES=$1
if [ -z $SOURCES ]; then
	echo "Path to source dir must be provided"
	exit 1
fi

if [ -z $GO_PIPELINE_COUNTER ];then
	echo "Evn GO_PIPELINE_COUNTER must be defined"
	exit 1
fi

echo "Using: SOURCES=$SOURCES"
echo "Using: GO_PIPELINE_COUNTER=$GO_PIPELINE_COUNTER"
cd $SOURCES

old_version=$(sed -e "s/xmlns/ignored/" "pom.xml"  |xmllint --xpath "/project/version/text()" -)
if [[ $old_version != *SNAPSHOT* ]];then
	echo "Not a snapshot version: $old_version"
	exit 1
fi

new_version=$(echo "$old_version"|sed "s/-SNAPSHOT/.$GO_PIPELINE_COUNTER/")
echo "Setting version $old_version to $new_version"
mvn -f pom.xml versions:set -DnewVersion=$new_version

echo "deploy to staging"
mvn clean deploy -DaltDeploymentRepository="staging::default::file://$PWD/staging"

if [ $? -gt 0 ]; then
	exit $?
fi

TAG_NAME="v$new_version"
echo "using tagname $TAG_NAME"
(git add pom.xml && git commit -m "Release version $new_version" && git tag $TAG_NAME) 
echo "creating git stating artifact"
git init --bare tag-artifact.git
git push tag-artifact.git $TAG_NAME
git push tag-artifact.git HEAD:MASTER


