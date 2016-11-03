#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

GitHubOrg=$1
GitHubUser=$2
GitHubToken=$3
ReposToDelete=$4

# cd $SCRIPT_DIR/repos/git/
# find -mindepth 1 -maxdepth 1 -type d -printf '%f\n' > $ReposToDelete
# cd $SCRIPT_DIR

OIFS=$IFS
IFS=,
while read RepoToDelete
do
    printf "curl --silent --user \"$GitHubUser:$GitHubToken\" \"https://api.github.com/repos/$GitHubOrg/${RepoToDelete}\" --request DELETE\n"
    curl --silent --user "$GitHubUser:$GitHubToken" "https://api.github.com/repos/$GitHubOrg/${RepoToDelete}" --request DELETE
done < $ReposToDelete
IFS=$OIFS