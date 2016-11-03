#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

OldNewTeamsCsv=$(cat github_teamList.txt)
BitbucketBaseURL=$(cat bitbucket_base_url.txt)
BitbucketApiBaseURL="$BitbucketBaseURL/rest/api/1.0"
BitbucketUser=$(cat credentials_bitbucket_api_username.txt)
BitbucketPassword=$(cat credentials_bitbucket_api_password.txt)

OIFS=$IFS
IFS=,
while read OldTeamName NewTeamName
do
    printf "\n********************\n"

    printf "\ncurl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X POST \"$BitbucketApiBaseURL/admin/groups?name=$NewTeamName\"\n"
    curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X POST "$BitbucketApiBaseURL/admin/groups?name=$NewTeamName"
done < $OldNewTeamsCsv
IFS=$OIFS
