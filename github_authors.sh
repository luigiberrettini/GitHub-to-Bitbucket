#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

OldNewReposCsv=$1
GitHubOrg=$2
GitHubUser=$3
GitHubToken=$4



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



printf "\nCreating authors and repos/git folders\n"
mkdir --parent $SCRIPT_DIR/repos/git
mkdir --parent $SCRIPT_DIR/authors/git
mkdir --parent $SCRIPT_DIR/authors/last-migration



OIFS=$IFS
IFS=,
while read OldRepoName NewRepoName
do
    printf "\n********************\n"

    printf "\n01. git clone https://$GitHubUser:$GitHubToken@github.com/$GitHubOrg/$OldRepoName $SCRIPT_DIR/repos/git/$OldRepoName\n"
    git clone https://$GitHubUser:$GitHubToken@github.com/$GitHubOrg/$OldRepoName $SCRIPT_DIR/repos/git/$OldRepoName

    printf "\n02. git log --pretty=format:'%an <%ae>' | sort | uniq > $SCRIPT_DIR/authors/git/github_authors_${OldRepoName}.txt\n"
    git -C $SCRIPT_DIR/repos/git/$OldRepoName log --pretty=format:'%an <%ae>' | sort | uniq > $SCRIPT_DIR/authors/git/github_authors_${OldRepoName}.txt

    printf "\n03. cp $SCRIPT_DIR/authors/git/github_authors_${OldRepoName}.txt $SCRIPT_DIR/authors/last-migration\n"
    cp $SCRIPT_DIR/authors/git/github_authors_${OldRepoName}.txt $SCRIPT_DIR/authors/last-migration

    printf "\n04. rm -rf $SCRIPT_DIR/repos/git/$OldRepoName\n"
    rm -rf $SCRIPT_DIR/repos/git/$OldRepoName
done < $OldNewReposCsv
IFS=$OIFS



printf "\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
printf "\n$SCRIPT_DIR/authors/git/github_*.txt | sort | uniq > $SCRIPT_DIR/authors/git/all_github.txt\n"
cat $SCRIPT_DIR/authors/git/github_*.txt | sort | uniq > $SCRIPT_DIR/authors/git/all_github.txt

printf "\n$SCRIPT_DIR/authors/last-migration/github_*.txt | sort | uniq > $SCRIPT_DIR/authors/all_github_last-migration.txt\n"
cat $SCRIPT_DIR/authors/last-migration/github_*.txt | sort | uniq > $SCRIPT_DIR/authors/all_github_last-migration.txt

printf "\nrm -rf $SCRIPT_DIR/authors/last-migration\n"
rm -rf $SCRIPT_DIR/authors/last-migration


printf "\n"