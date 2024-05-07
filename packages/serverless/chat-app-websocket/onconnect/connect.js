const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: process.env.AWS_REGION });

exports.handler = async (event) => {
  // console.log(event);
  console.log(event.queryStringParameters);

  // CONNECTION SAVE
  const putParams = {
    TableName: process.env.TABLE_NAME,
    Item: {
      roomId: event.queryStringParameters.roomId,
      connectionId: event.requestContext.connectionId,
    },
  };

  console.log(putParams);

  try {
    await ddb.put(putParams).promise();
  } catch (err) {
    console.log(err);
    return { statusCode: 500, body: 'Failed to connect: ' + JSON.stringify(err) };
  }

  const apigwManagementApi = new AWS.ApiGatewayManagementApi({
    apiVersion: '2018-11-29',
    endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
  });

  try {
    await apigwManagementApi.postToConnection({ ConnectionId: 'connectionId', Data: 'postData' }).promise();
  } catch (e) {
  }

  return { statusCode: 200, body: 'Connected.' };
};
