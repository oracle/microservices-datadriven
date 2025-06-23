# Create CloudBank Demo Workflow for Conductor

- cbank_workflow_demo: cloudbank demo workflow for integration with Parser
- first_cbank_workflow: cloudbank demo workflow
- first_sample_workflow: conductor sample workflow

To get access to Conductor Server create a port-forward for Conductor Service.

1- Adding the Workflow metadata

```shell
curl --location --request PUT 'http://localhost:8080/api/metadata/workflow' \
--header 'Content-Type: application/json' \
--data-raw '<cbank_workflow_demo.json content>'
```

2- Exec the workflow.

```shell
curl --location 'http://localhost:8080/api/workflow/cbank_workflow_demo' \
--header 'Content-Type: application/json' \
--data-raw '{
 "triggerName": "afterSave",
 "object": {
        "amount": 800,
        "destination": "andy@andy.com",
        "fromAccount": "bkzLp8cozi",
        "createdAt": "2023-06-20T15:48:41.730Z",
        "updatedAt": "2023-06-20T15:48:41.730Z",
        "objectId": "yH8iuP59Ct",
        "className": "CloudCashPayment"
    },
 "master": true,
 "log": {
    "options": {
    "jsonLogs": false,
    "logsFolder": "./logs",
    "verbose": false
 },
 "appId": "69uBOlaFBWds1KlMpcvSy5sPxsGNF0RXnkLqiO09"
 },
 "headers": {
    "host": "129.213.192.16",
    "x-request-id": "8d5d8a49ea6f7f842499f41865278fa1",
    "x-real-ip": "10.74.2.60",
    "x-forwarded-for": "10.74.2.60",
    "x-forwarded-host": "129.213.192.16",
    "x-forwarded-port": "80",
    "x-forwarded-proto": "http",
    "x-forwarded-scheme": "http",
    "x-scheme": "http",
    "x-original-forwarded-for": "85.146.237.253",
    "content-length": "342",
    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)   Chrome/108.0.0.0 Safari/537.36",
    "content-type": "text/plain",
    "accept": "*/*",
    "origin": "http://obaas",
    "referer": "http://obaas/",
    "accept-encoding": "gzip, deflate",
    "accept-language": "en,it;q=0.9"
 },
 "ip": "10.74.2.60",
 "context": {},
 "installationId": "b4bad867-de84-46ff-a531-b6c2e791ec83"
}'
```

The result should be the workflow instance ID : 1acc2a2f-8e38-49d7-b17d-e0a7b8e36d31 (for example)

3- Check the workflow State using instance ID

```shell
curl --location 'http://localhost:8080/api/workflow/1acc2a2f-8e38-49d7-b17d-e0a7b8e36d31?includeTasks=true'
```
