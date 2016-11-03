GitHubOrg='GHOrgName'
GitHubUser=$(cat credentials_github_api_username.txt)
GitHubToken=$(cat credentials_github_api_token.txt)
KilnBaseUrl=$(cat kiln_base_url.txt)
KilnApiBaseUrl="$KilnBaseUrl/kiln/Api/1.0"
KilnApiToken=$(cat credentials_kiln_api_token.txt)
BitbucketBaseURL=$(cat bitbucket_base_url.txt)
BitbucketApiBaseURL="$BitbucketBaseURL/rest/api/1.0"
BitbucketUser=$(cat credentials_bitbucket_api_username.txt)
BitbucketPassword=$(cat credentials_bitbucket_api_password.txt)

MigrationType='ghc_bbs'
MigrationId='001'
BitbucketProjectName='BBProjectName'
GitHubOrBitbucketTeamName='TeamName'

#./migrate_${MigrationType}.sh ./migrations/${MigrationId}_2migrate_${GitHubOrBitbucketTeamName}.txt $GitHubOrg $GitHubUser $GitHubToken $BitbucketApiBaseURL $BitbucketProjectName $BitbucketUser $BitbucketPassword $GitHubOrBitbucketTeamName > ./migrate_with_parameters/OUTPUT_mwp_${MigrationId}.txt 2>&1
