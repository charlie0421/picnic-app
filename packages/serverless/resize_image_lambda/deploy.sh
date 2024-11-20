# Set environment variables
DISTRIBUTION_ID="E3MO7SSKNHDE94"
ACCOUNT_ID="851725635868"
FUNCTION_NAME="ResizingImages"


rm myFunction.zip 2>/dev/null
npm install >/dev/null 2>&1
zip -r myFunction.zip ./ >/dev/null 2>&1

LATEST_VERSION=$(aws lambda --region=us-east-1 update-function-code --function-name $FUNCTION_NAME --zip-file fileb://myFunction.zip --profile picnic --no-cli-pager --publish | jq -r '.Version')

echo "⏳ Waiting for Lambda function update..."
while true; do
   STATUS=$(aws lambda --region=us-east-1 get-function --function-name $FUNCTION_NAME:$LATEST_VERSION --profile picnic --query 'Configuration.State' --output text 2>/dev/null)
   if [ "$STATUS" = "Active" ]; then
       break
   fi
   echo "⌛ Lambda update in progress... (Status: $STATUS)"
   sleep 1
done
echo "✅ Lambda function v$LATEST_VERSION deployed"

DIST_CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --profile picnic --output json)
ETAG=$(echo "$DIST_CONFIG" | jq -r '.ETag')
DIST_CONFIG_CONTENT=$(echo "$DIST_CONFIG" | jq -r '.DistributionConfig')
UPDATED_CONFIG=$(echo "$DIST_CONFIG_CONTENT" | jq '.DefaultCacheBehavior.LambdaFunctionAssociations = {"Quantity":1,"Items":[{"EventType":"origin-request","LambdaFunctionARN":"arn:aws:lambda:us-east-1:'$ACCOUNT_ID':function:'$FUNCTION_NAME':'$LATEST_VERSION'"}]}')
echo "$UPDATED_CONFIG" > dist-config-new.json
aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://dist-config-new.json --if-match $ETAG --profile picnic --no-cli-pager >/dev/null

echo "⏳ Waiting for CloudFront deployment..."
while true; do
   STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --profile picnic --query 'Distribution.Status' --output text 2>/dev/null)
   if [ "$STATUS" = "Deployed" ]; then
       break
   fi
   echo "⌛ CloudFront deployment in progress... (Status: $STATUS)"
   sleep 1
done
echo "✅ CloudFront deployment completed"

rm myFunction.zip dist-config-new.json 2>/dev/null
echo "✨ All deployments completed!"
