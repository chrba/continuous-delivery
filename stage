#!/bin/bash
set -e

#######################################################################
#                       Usage
########################################################################

function usage {
	cat <<EOF

Usage:$0 [OPTIONS] [SOURCE]
	
	Creates a maven staging artifact and a git artifact that can be pushed to nexus and to the master git
	repository at a later time. The source directory must be a git maven project.
	
	OPTIONS

	-o <OUTPUT> The output directory. Default is the current working directory.

	-b <BUILD_ID> A unique build id that will be used to determine a release version number. If not provided
	    the environment variable GO_PIPELINE_COUNTER will be used.
	
	-x Do not copy source directory to tmp. This will result in modifications on the pom files and changes
	   on the local git repository

	-v Verbose output.

	-vv Even more output
EOF

	exit 1
	
}


function quiet {
    if [ $VERBOSE -lt 2 ]; then
        "$@" > /dev/null
    else
        "$@"
    fi
}

#######################################################################
#                       Parameter parsing
########################################################################

OUTPUT_DIR=$(pwd)
BUILD_ID=$GO_PIPELINE_COUNTER
VERBOSE=0
COPY_SOURCES=1
while getopts "vo:b:hx\?" options; do
	case $options in
		o ) OUTPUT_DIR=$(cd $OPTARG ; pwd);;
		b ) BUILD_ID=$OPTARG;;
		v ) VERBOSE=$(($VERBOSE+1));;
		h ) usage;;
		x ) COPY_SOURCES=0;;
		
	esac
done

STD_OUT_RD=""
if [ $VERBOSE -gt 1 ];then
	STD_OUT_RD="> /dev/null"
fi

SOURCES=$(cd "${@:$OPTIND:1}";pwd)

if [ "$#" == 0 ]; then
	usage
fi

if [ ! -d $SOURCES ];then
	echo "No source directory provided"
	exit 1
fi

if [ -z $BUILD_ID ];then
	echo "No build id provided and environment variable GO_PIPELINE_COUNTER is not defined"
	exit 1
fi
 
if [ $VERBOSE -gt 0 ]; then
	echo ""
	echo "Using source directory=$SOURCES"
	echo "Using build id=$BUILD_ID"
	echo "Using output directory=$OUTPUT_DIR"
	echo ""
fi

DIR=$(pwd)
#######################################################################
#                       Create working git directoy 
########################################################################

if [ $COPY_SOURCES == 1 ]; 
	then
		TMP="/tmp/stage"
		if [ $VERBOSE -gt 0 ]; then
			echo "Copy source to tmp directory $TMP"
		fi

		if [[ -d $TMP ]];then
			rm -rf $TMP
		fi
		mkdir $TMP
		cp -r "${SOURCES}/."   $TMP
		cd "$TMP"
	else
		cd "$SOURCES"
fi

#######################################################################
#                       Transform maven pom files
########################################################################

old_version=$(sed -e "s/xmlns/ignored/" "pom.xml"  |xmllint --xpath "/project/version/text()" -)
if [[ $old_version != *SNAPSHOT* ]];then
	echo "Aborting: not a snapshot version: $old_version"
	exit 1
fi

new_version=$(echo "$old_version"|sed "s/-SNAPSHOT/.$BUILD_ID/")
if [ $VERBOSE -gt 0 ]; then
	echo "Setting version $old_version to $new_version"
fi
quiet mvn -f pom.xml versions:set -DnewVersion=$new_version 
#######################################################################
#                       Create git artifact
########################################################################

ARTIFACTS_DIR="$OUTPUT_DIR/artifacts"
if [ -d "$ARTIFACTS_DIR" ]; then
	if [ $VERBOSE -gt 0 ];then
		echo "Cleaning up $ARTIFACTS_DIR"
	fi
	rm -rf "$ARTIFACTS_DIR"
fi

mkdir "$ARTIFACTS_DIR"

TAG_NAME="v$new_version"

if [ $VERBOSE -gt 0 ]; then
	echo "Using tagname $TAG_NAME"
fi

(quiet git add . && quiet git commit -m "Release version $new_version" && quiet git tag $TAG_NAME) 


if [ $VERBOSE -gt 0 ]; then
	echo "Creating git stating artifact"
fi
quiet git init --bare tag-artifact.git
quiet git push tag-artifact.git $TAG_NAME 
quiet git push tag-artifact.git HEAD:MASTER

mv tag-artifact.git "$ARTIFACTS_DIR/"
################################s#######################################
#                       Maven deploy to staging directory
########################################################################

if [ $VERBOSE -gt 0 ]; then
	echo "Deploy to staging"
fi
quiet mvn clean deploy -DaltDeploymentRepository="staging::default::file://$PWD/staging"

if [ $? -gt 0 ]; then
	exit $?
fi

mv staging "$ARTIFACTS_DIR"

#clean up tmp
if [ $VERBOSE -gt 0 ]; then
	echo "Cleaning up tmp directory"
fi

rm -rf /tmp/stage

echo ""
echo "Artifacts successfully created. You can find the artifacts in $OUTPUT_DIR"
