#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

GitHubOrg=$1
GitHubUser=$2
GitHubToken=$3
LastPage=$4

rm -rf "$SCRIPT_DIR/github_teamIdNamePairs.txt"

for i in $(seq 1 $LastPage); do
    curl --silent --user "$GitHubUser:$GitHubToken" "https://api.github.com/orgs/$GitHubOrg/teams?per_page=100&page=$i" | ./jq -c '.[] | {id,name}' >> "$SCRIPT_DIR/github_teamIdNamePairs.txt"
done

cat github_teamIdNamePairs.txt | ./jq -r '.name' | sed 's@\(.*\)@\1,\1@' | sort > "$SCRIPT_DIR/github_teamList.txt"
