#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

OldNewReposCsv=$1
GitHubOrg=$2
GitHubUser=$3
GitHubToken=$4
BitbucketBaseURL=$5
BitbucketProjectName=$6
BitbucketUser=$7
BitbucketPassword=$8
BitbucketTeamName=$9



printf "\nLine endings: "
CarriageReturns=`grep -r $'\r' $OldNewReposCsv | wc -l`
if [ $CarriageReturns -gt 0 ]; then
    echo 'Windows (FATAL ERROR)'
    exit 1
else
    echo 'Unix (OK)'
fi



printf "\nFix trailing new line\n"
tail -c1 $OldNewReposCsv | read -r _ || echo >> $OldNewReposCsv



printf "\ncurl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X GET \"$BitbucketBaseURL/projects?name=$BitbucketProjectName\" | $SCRIPT_DIR/jq -r '.values | map(select(.name == \"'$BitbucketProjectName'\"))[0].key'\n"
BitbucketProjectKey=`curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X GET "$BitbucketBaseURL/projects?name=$BitbucketProjectName" | $SCRIPT_DIR/jq -r '.values | map(select(.name == "'$BitbucketProjectName'"))[0].key'`
printf "BitbucketProjectKey: $BitbucketProjectKey"
if [ ! $BitbucketProjectKey ] || [ "$BitbucketProjectKey" == "null" ]; then
    printf "BitbucketProjectKey not found\n"
    exit 1
fi



printf "\ncurl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X GET \"$BitbucketBaseURL/groups?filter=$BitbucketTeamName\" | $SCRIPT_DIR/jq '.values | map(select(. == \"'$BitbucketTeamName'\")) | .[]'\n"
TeamPresent=`curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X GET "$BitbucketBaseURL/groups?filter=$BitbucketTeamName" | $SCRIPT_DIR/jq '.values | map(select(. == "'$BitbucketTeamName'")) | .[]'`
if [ ! $TeamPresent ]; then
    printf "Team does not exist\n"
    exit 1
fi



printf "\nCreating repos/hg and repos/git folders\n"
mkdir --parent $SCRIPT_DIR/repos/hg
mkdir --parent $SCRIPT_DIR/repos/git



OIFS=$IFS
IFS=,
while read OldRepoName NewRepoName
do
    printf "\n********************\n"

    printf "\n01. git clone --bare https://$GitHubUser:$GitHubToken@github.com/$GitHubOrg/$OldRepoName $SCRIPT_DIR/repos/git/$OldRepoName\n"
    git clone --bare https://$GitHubUser:$GitHubToken@github.com/$GitHubOrg/$OldRepoName $SCRIPT_DIR/repos/git/$OldRepoName

    printf "\n02. curl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X PUT \"$BitbucketBaseURL/repos?projectname=$BitbucketProjectName&name=$NewRepoName\" | $SCRIPT_DIR/jq '.values | map(select(.name == \"'$NewRepoName'\"))[0].slug'\n"
    NewRepoNeedsSuffix=`curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X PUT "$BitbucketBaseURL/repos?projectname=$BitbucketProjectName&name=$NewRepoName" | $SCRIPT_DIR/jq '.values | map(select(.name == "'$NewRepoName'"))[0].slug'`

    UUID=$(uuidgen -r)
    printf "\n03. if [ $NewRepoNeedsSuffix -ne 0 ]; then NewRepoName=\"${NewRepoName}_${UUID}\"; fi\n"
    if [ $NewRepoNeedsSuffix ] && [ "$NewRepoNeedsSuffix" != "null" ]; then NewRepoName="${NewRepoName}_${UUID}"; fi

    printf "\n04. mv $SCRIPT_DIR/repos/git/$OldRepoName $SCRIPT_DIR/repos/git/$NewRepoName\n"
    mv $SCRIPT_DIR/repos/git/$OldRepoName $SCRIPT_DIR/repos/git/$NewRepoName

    printf "\n05. cd $SCRIPT_DIR/repos/git/$NewRepoName\n"
    cd $SCRIPT_DIR/repos/git/$NewRepoName

    printf "\n06. curl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X POST -d \"{ \\\"name\\\": \\\"$NewRepoName\\\", \\\"scmId\\\": \\\"git\\\", \\\"forkable\\\": true }\" \"$BitbucketBaseURL/projects/$BitbucketProjectKey/repos\"\n"
    curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X POST -d "{ \"name\": \"$NewRepoName\", \"scmId\": \"git\", \"forkable\": true }" "$BitbucketBaseURL/projects/$BitbucketProjectKey/repos" > /dev/null

    printf "\n07. curl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X PUT \"$BitbucketBaseURL/repos?projectname=$BitbucketProjectName&name=$NewRepoName\" | $SCRIPT_DIR/jq '.values | map(select(.name == \"'$NewRepoName'\"))[0].slug'\n"
    NewRepoSlug=`curl --silent --user "$BitbucketUser:$BitbucketPassword" -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -X PUT "$BitbucketBaseURL/repos?projectname=$BitbucketProjectName&name=$NewRepoName" | $SCRIPT_DIR/jq '.values | map(select(.name == "'$NewRepoName'"))[0].slug'`
    if [ ! $NewRepoSlug ] || [ "$NewRepoSlug" == "null" ]; then
        printf "New repo was not created\n"
        exit 1
    fi

    printf "\n08. curl --silent --user \"$BitbucketUser:BitbucketPassword\" -H \"X-Atlassian-Token: nocheck\" -H \"Content-Type: application/json\" -X PUT \"$BitbucketBaseURL/projects/$BitbucketProjectKey/repos/$NewRepoSlug/permissions/groups?name=$BitbucketTeamName&permission=REPO_ADMIN\"\n"
    curl -H "X-Atlassian-Token: nocheck" -H "Content-Type: application/json" -H "Authorization Basic $authCredentials" -X PUT "$BitbucketBaseURL/projects/$BitbucketProjectKey/repos/$NewRepoSlug/permissions/groups?name=$BitbucketTeamName&permission=REPO_ADMIN" > /dev/null

    RemoteOrigin="$BitbucketBaseURL/scm/$BitbucketProjectKey/${NewRepoName}.git"
    printf "\n09. git remote add bitbktsrv \"$RemoteOrigin\"\n    git remote -v\n    git push --all bitbktsrv\n    git push --tags bitbktsrv\n"
    git remote add bitbktsrv "$RemoteOrigin"
    git remote -v
    git push --all bitbktsrv
    git push --tags bitbktsrv

    printf "\n10. Teams=curl --silent --user \"$GitHubUser:$GitHubToken\" \"https://api.github.com/repos/$GitHubOrg/$OldRepoName/teams\" | ./jq -c '.[] | {id, name}'\n"
    Teams=curl --silent --user "$GitHubUser:$GitHubToken" "https://api.github.com/repos/$GitHubOrg/$OldRepoName/teams" | ./jq -c '.[] | {id, name}'

    printf "\n11. TeamIds=curl --silent --user \"$GitHubUser:$GitHubToken\" \"https://api.github.com/repos/$GitHubOrg/$OldRepoName/teams\" | ./jq '.[].id'\n"
    TeamIds=curl --silent --user "$GitHubUser:$GitHubToken" "https://api.github.com/repos/$GitHubOrg/$OldRepoName/teams" | ./jq '.[].id'

    printf "\n12. Remove permissions for all teams\n"
    echo "$TeamIds" | while read -r TeamId; do
        printf "    curl --silent -H \"Accept: application/vnd.github.v3+json\" --user \"$GitHubUser:$GitHubToken\" \"https://api.github.com/teams/$TeamId/repos/YTech/$OldRepoName\" --request DELETE > /dev/null\n"
        curl --silent -H "Accept: application/vnd.github.v3+json" --user "$GitHubUser:$GitHubToken" "https://api.github.com/teams/$TeamId/repos/YTech/$OldRepoName" --request DELETE > /dev/null
    done

    printf "\n13. curl --silent --user \"$GitHubUser:$GitHubToken\" \"https://api.github.com/repos/$GitHubOrg/$OldRepoName\" --request PATCH --data '{\"name\": \"$OldRepoName_MigratedToBitbucket\"}'\n"
    curl --silent --user "$GitHubUser:$GitHubToken" "https://api.github.com/repos/$GitHubOrg/$OldRepoName" --request PATCH --data "{\"name\": \"$OldRepoName_MigratedToBitbucket\"}" > /dev/null

    printf "\n14. git filter-branch --env-filter to rewrite history mapping GitHub users to Bitbucket ones\n"
    MailmapFilePath="$SCRIPT_DIR/authors/authors_mailmap.txt"
    if [ -f $MailmapFilePath ]; then
        git filter-branch --env-filter '
            R=`echo "$GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>" | git -c mailmap.file='$MailmapFilePath' check-mailmap --stdin`
            export GIT_AUTHOR_NAME="${R% <*@*>}"
            R="${R##* <}"
            export GIT_AUTHOR_EMAIL="${R%>}"
            R=`echo "$GIT_COMMITTER_NAME <$GIT_COMMITTER_EMAIL>" | git -c mailmap.file='$MailmapFilePath' check-mailmap --stdin`
            export GIT_COMMITTER_NAME="${R% <*@*>}"
            R="${R##* <}"
            export GIT_COMMITTER_EMAIL="${R%>}"
        ' -- --all
    fi

    printf "\n15. cd $SCRIPT_DIR\n"
    cd $SCRIPT_DIR
done < $OldNewReposCsv
IFS=$OIFS



printf "\n"