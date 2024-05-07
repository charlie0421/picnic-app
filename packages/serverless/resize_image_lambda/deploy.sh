rm myFunction.zip
zip -r myFunction.zip ./
aws lambda --region=us-east-1 update-function-code --function-name ResizingImages --zip-file fileb://myFunction.zip --profile 1stype-us