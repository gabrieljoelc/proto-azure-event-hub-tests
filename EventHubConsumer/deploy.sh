export WEBJOB=ehconsumer
export OUTPUT_PATH_ROOT=.deploy
export OUTPUT_PATH_WEBJOB=$OUTPUT_PATH_ROOT/app_data/Jobs/Continuous/$WEBJOB
mkdir $OUTPUT_PATH_ROOT
rm -R $OUTPUT_PATH_ROOT/*
dotnet publish --configuration Release -o $OUTPUT_PATH_WEBJOB
echo "dotnet eventhubconsumer.dll" >> $OUTPUT_PATH_WEBJOB/run.cmd
# this is the only way archive only the contents of .deploy so that it isn't the root directory when deployed (see https://askubuntu.com/a/743860/812363)
cd .deploy ; zip -r ../deploy.zip . * ; cd ..
az webapp deployment source config-zip -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_SERVICE --src ./deploy.zip
