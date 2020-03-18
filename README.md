# Welcome to Azure Event Hub Tests 👋

> This project is for testing our ability to run multiple instances of webjob's on the same Event Hub consumer group. We want to understand 2 things: 1. does it maintain order and 2. does it achieve higher throughput.

## Prerequisites

- Azure subscription
- Azure CLI
- Terraform >= v0.12.19

## Usage

Steps to test:
1. Create azure resources
```sh
terraform apply -var name=ehconsumer -var rg=sandbox-resource-group -var eh_namespace=my-event-hub-namespace
```
2. Update app settings - use example in `local.settings.dist.json`
3. Deploy code - execute deploy shell script
```
# from solution root

EventHubConsumer/deploy.sh
```
4. Stop web job
```
az webapp webjob continuous stop -w ehconsumer -g sandbox-resource-group -n ehconsumer
```
4. Generate 10,000 events
5. Increment `Settings:TestRun` in app settings
```
az webapp config appsettings set -g sandbox-resource-group -n ehconsumer --settings Settings:TestRun=2
```
6. Scale out app service instances to desired n+1 count for test - via Azure Portal or Terraform
7. Start web job
```
az webapp webjob continuous start -w ehconsumer -g sandbox-resource-group -n ehconsumer
```
8. Repeat 4-7 incrementing n each time
9. Compare app insights


## Author

👤 **Gabriel Chaney**


***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
