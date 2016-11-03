# GitHub-to-Bitbucket

```shell
MigrationId='0001'
GitHubTeamName='GHTeamName'

workDir=/gh_mig
cp -pr $workDir/migrations/template_2migrate.txt $workDir/migrations/${MigrationId}_2migrate_${GitHubTeamName}.txt
cp -pr $workDir/migrate_with_parameters/template_mwp.sh $workDir/migrations/mwp_${MigrationId}.sh
chmod +x $workDir/migrate_with_parameters/mwp_*.sh

vi $workDir/migrations/${MigrationId}_2migrate_${GitHubTeamName}.txt
# (UNIX EOL!!! and empty line at the end of the file)

vi $workDir/migrations/mwp_${MigrationId}.sh
# (UNIX EOL!!! and empty line at the end of the file)

cd $workDir
./migrate_with_parameters/mwp_${MigrationId}.sh
```