rm myFunction.zip
npm install
zip -r myFunction.zip ./
aws lambda --region=us-east-1 update-function-code --function-name ResizingImages --zip-file fileb://myFunction.zip --profile picnic
rm myFunction.zip
