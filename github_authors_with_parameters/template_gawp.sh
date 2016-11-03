GitHubOrg='GHOrgName'
GitHubUser=$(cat credentials_github_api_username.txt)
GitHubToken=$(cat credentials_github_api_token.txt)

./github_authors.sh ./github_repoList.txt $GitHubOrg $GitHubUser $GitHubToken
