export WEBJOB=ehconsumer
export WEBJOB_OUTPUT_PATH=.deploy/app_data/Jobs/Continuous/$WEBJOB
mkdir .deploy
dotnet publish --configuration Release -o $WEBJOB_OUTPUT_PATH
cp run.cmd $WEBJOB_OUTPUT_PATH
# this is the only way archive only the contents of .deploy so that it isn't the root directory when deployed (see https://askubuntu.com/a/743860/812363)
cd .deploy ; zip -r ../deploy.zip . * ; cd ..
az webapp deployment source config-zip -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_SERVICE --src ./deploy.zip
