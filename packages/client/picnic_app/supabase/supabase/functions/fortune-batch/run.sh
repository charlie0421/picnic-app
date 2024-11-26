curl -i --request POST 'https://api.picnic.fan/functions/v1/fortune-batch' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0aWp0ZWZjeWNvZXFsdWRsbmdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU4OTEyNzQsImV4cCI6MjAzMTQ2NzI3NH0.k0Viu8kgOnkJ7-tnrDTmqpe6TdtZCYkqmH_5vUvcv_k' \
  --data '{"artist_id": 1, "year": 2025}'
