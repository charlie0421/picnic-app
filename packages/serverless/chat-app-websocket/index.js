#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const aws_lambda_1 = require("aws-cdk-lib/aws-lambda");
const aws_apigatewayv2_1 = require("aws-cdk-lib/aws-apigatewayv2");
const aws_cdk_lib_1 = require("aws-cdk-lib");
const aws_iam_1 = require("aws-cdk-lib/aws-iam");
const aws_dynamodb_1 = require("aws-cdk-lib/aws-dynamodb");
const config = {
    "stage": "dev",
    "region": "ap-northeast-2",
    "account_id": "355508260517"
};
class ChatAppStack extends aws_cdk_lib_1.Stack {
    constructor(scope, id, props) {
        super(scope, id, props);
        const connectionsTableName = "chat_connections";
        const membersTableName = "chat_members";
        const messagesTableName = "chat_messages";
        // initialise api
        const name = id + "-api";
        const api = new aws_apigatewayv2_1.CfnApi(this, name, {
            name: "chat-app-websocket",
            protocolType: "WEBSOCKET",
            routeSelectionExpression: "$request.body.action",
        });
        //////////////////////////////////////////
        // TABLES
        //////////////////////////////////////////
        const connectionsTable = new aws_dynamodb_1.Table(this, `${name}-table-connections`, {
            tableName: connectionsTableName,
            partitionKey: {
                name: "connectionId",
                type: aws_dynamodb_1.AttributeType.STRING,
            },
            readCapacity: 5,
            writeCapacity: 5,
            removalPolicy: aws_cdk_lib_1.RemovalPolicy.DESTROY
        });
        connectionsTable.addGlobalSecondaryIndex({
            indexName: "connections-roodId-index",
            partitionKey: {
                name: "roomId",
                type: aws_dynamodb_1.AttributeType.STRING,
            },
            readCapacity: 5,
            writeCapacity: 5,
        });
        const messagesTable = new aws_dynamodb_1.Table(this, `${name}-table-messages`, {
            tableName: messagesTableName,
            partitionKey: {
                name: "roomId",
                type: aws_dynamodb_1.AttributeType.STRING,
            },
            sortKey: {
                name: "createdAt",
                type: aws_dynamodb_1.AttributeType.NUMBER,
            },
            readCapacity: 5,
            writeCapacity: 5,
            removalPolicy: aws_cdk_lib_1.RemovalPolicy.DESTROY
        });
        //////////////////////////////////////////
        // LAMBDA FUNCTIONS
        //////////////////////////////////////////
        const connectFunc = new aws_lambda_1.Function(this, 'connect-lambda', {
            code: new aws_lambda_1.AssetCode('./onconnect'),
            handler: 'connect.handler',
            runtime: aws_lambda_1.Runtime.NODEJS_18_X,
            timeout: aws_cdk_lib_1.Duration.seconds(300),
            memorySize: 256,
            environment: {
                "TABLE_NAME": connectionsTableName,
            }
        });
        connectionsTable.grantReadWriteData(connectFunc);
        const disconnectFunc = new aws_lambda_1.Function(this, 'disconnect-lambda', {
            code: new aws_lambda_1.AssetCode('./ondisconnect'),
            handler: 'disconnect.handler',
            runtime: aws_lambda_1.Runtime.NODEJS_18_X,
            timeout: aws_cdk_lib_1.Duration.seconds(300),
            memorySize: 256,
            environment: {
                "TABLE_NAME": connectionsTableName,
            }
        });
        connectionsTable.grantReadWriteData(disconnectFunc);
        const messageFunc = new aws_lambda_1.Function(this, 'message-lambda', {
            code: new aws_lambda_1.AssetCode('./sendmessage'),
            handler: 'sendmessage.handler',
            runtime: aws_lambda_1.Runtime.NODEJS_18_X,
            timeout: aws_cdk_lib_1.Duration.seconds(300),
            memorySize: 256,
            initialPolicy: [
                new aws_iam_1.PolicyStatement({
                    actions: [
                        'execute-api:ManageConnections'
                    ],
                    resources: [
                        "arn:aws:execute-api:" + config["region"] + ":" + config["account_id"] + ":" + api.ref + "/*"
                    ],
                    effect: aws_iam_1.Effect.ALLOW,
                })
            ],
            environment: {
                "MEMBERS_TABLE_NAME": membersTableName,
                "MESSAGES_TABLE_NAME": messagesTableName,
                "CONNECTIONS_TABLE_NAME": connectionsTableName,
            }
        });
        messagesTable.grantReadWriteData(messageFunc);
        connectionsTable.grantReadWriteData(messageFunc);
        // access role for the socket api to access the socket lambda
        const policy = new aws_iam_1.PolicyStatement({
            effect: aws_iam_1.Effect.ALLOW,
            resources: [
                connectFunc.functionArn,
                disconnectFunc.functionArn,
                messageFunc.functionArn
            ],
            actions: ["lambda:InvokeFunction"]
        });
        const role = new aws_iam_1.Role(this, `${name}-iam-role`, {
            assumedBy: new aws_iam_1.ServicePrincipal("apigateway.amazonaws.com")
        });
        role.addToPolicy(policy);
        //////////////////////////////////////////
        // LAMBDA INTEGRATIONS
        //////////////////////////////////////////
        const connectIntegration = new aws_apigatewayv2_1.CfnIntegration(this, "connect-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + connectFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn,
        });
        const disconnectIntegration = new aws_apigatewayv2_1.CfnIntegration(this, "disconnect-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + disconnectFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn
        });
        const messageIntegration = new aws_apigatewayv2_1.CfnIntegration(this, "message-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + messageFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn
        });
        //////////////////////////////////////////
        // CONNECTIONS ROUTES
        //////////////////////////////////////////
        const connectRoute = new aws_apigatewayv2_1.CfnRoute(this, "connect-route", {
            apiId: api.ref,
            routeKey: "$connect",
            authorizationType: "NONE",
            target: "integrations/" + connectIntegration.ref,
        });
        const disconnectRoute = new aws_apigatewayv2_1.CfnRoute(this, "disconnect-route", {
            apiId: api.ref,
            routeKey: "$disconnect",
            authorizationType: "NONE",
            target: "integrations/" + disconnectIntegration.ref,
        });
        const messageRoute = new aws_apigatewayv2_1.CfnRoute(this, "message-route", {
            apiId: api.ref,
            routeKey: "sendmessage",
            authorizationType: "NONE",
            target: "integrations/" + messageIntegration.ref,
        });
        //////////////////////////////////////////
        // DEPLOYMENT
        //////////////////////////////////////////
        const deployment = new aws_apigatewayv2_1.CfnDeployment(this, `${name}-deployment`, {
            apiId: api.ref
        });
        new aws_apigatewayv2_1.CfnStage(this, `${name}-stage`, {
            apiId: api.ref,
            autoDeploy: true,
            deploymentId: deployment.ref,
            stageName: "dev",
        });
        deployment.node.addDependency(connectRoute);
        deployment.node.addDependency(disconnectRoute);
        deployment.node.addDependency(messageRoute);
    }
}
const app = new aws_cdk_lib_1.App();
new ChatAppStack(app, `chat-app-websocket-stack`);
app.synth();
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyJpbmRleC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOzs7QUFDQSx1REFBb0U7QUFDcEUsbUVBQXVHO0FBQ3ZHLDZDQUE0RTtBQUM1RSxpREFBb0Y7QUFDcEYsMkRBQThEO0FBRzlELE1BQU0sTUFBTSxHQUFHO0lBQ1gsT0FBTyxFQUFFLEtBQUs7SUFDZCxRQUFRLEVBQUUsZ0JBQWdCO0lBQzFCLFlBQVksRUFBRSxjQUFjO0NBQy9CLENBQUE7QUFDRCxNQUFNLFlBQWEsU0FBUSxtQkFBSztJQUM1QixZQUFZLEtBQWdCLEVBQUUsRUFBVSxFQUFFLEtBQWtCO1FBQ3hELEtBQUssQ0FBQyxLQUFLLEVBQUUsRUFBRSxFQUFFLEtBQUssQ0FBQyxDQUFDO1FBQ3hCLE1BQU0sb0JBQW9CLEdBQUcsa0JBQWtCLENBQUM7UUFDaEQsTUFBTSxnQkFBZ0IsR0FBRyxjQUFjLENBQUM7UUFDeEMsTUFBTSxpQkFBaUIsR0FBRyxlQUFlLENBQUM7UUFFMUMsaUJBQWlCO1FBQ2pCLE1BQU0sSUFBSSxHQUFHLEVBQUUsR0FBRyxNQUFNLENBQUE7UUFDeEIsTUFBTSxHQUFHLEdBQUcsSUFBSSx5QkFBTSxDQUFDLElBQUksRUFBRSxJQUFJLEVBQUU7WUFDL0IsSUFBSSxFQUFFLG9CQUFvQjtZQUMxQixZQUFZLEVBQUUsV0FBVztZQUN6Qix3QkFBd0IsRUFBRSxzQkFBc0I7U0FDbkQsQ0FBQyxDQUFDO1FBRUgsMENBQTBDO1FBQzFDLFNBQVM7UUFDVCwwQ0FBMEM7UUFDMUMsTUFBTSxnQkFBZ0IsR0FBRyxJQUFJLG9CQUFLLENBQUMsSUFBSSxFQUFFLEdBQUcsSUFBSSxvQkFBb0IsRUFBRTtZQUNsRSxTQUFTLEVBQUUsb0JBQW9CO1lBQy9CLFlBQVksRUFBRTtnQkFDVixJQUFJLEVBQUUsY0FBYztnQkFDcEIsSUFBSSxFQUFFLDRCQUFhLENBQUMsTUFBTTthQUM3QjtZQUNELFlBQVksRUFBRSxDQUFDO1lBQ2YsYUFBYSxFQUFFLENBQUM7WUFDaEIsYUFBYSxFQUFFLDJCQUFhLENBQUMsT0FBTztTQUN2QyxDQUFDLENBQUM7UUFFSCxnQkFBZ0IsQ0FBQyx1QkFBdUIsQ0FBQztZQUNyQyxTQUFTLEVBQUUsMEJBQTBCO1lBQ3JDLFlBQVksRUFBRTtnQkFDVixJQUFJLEVBQUUsUUFBUTtnQkFDZCxJQUFJLEVBQUUsNEJBQWEsQ0FBQyxNQUFNO2FBQzdCO1lBQ0QsWUFBWSxFQUFFLENBQUM7WUFDZixhQUFhLEVBQUUsQ0FBQztTQUNuQixDQUFDLENBQUM7UUFFSCxNQUFNLGFBQWEsR0FBRyxJQUFJLG9CQUFLLENBQUMsSUFBSSxFQUFFLEdBQUcsSUFBSSxpQkFBaUIsRUFBRTtZQUM1RCxTQUFTLEVBQUUsaUJBQWlCO1lBQzVCLFlBQVksRUFBRTtnQkFDVixJQUFJLEVBQUUsUUFBUTtnQkFDZCxJQUFJLEVBQUUsNEJBQWEsQ0FBQyxNQUFNO2FBQzdCO1lBQ0QsT0FBTyxFQUFFO2dCQUNMLElBQUksRUFBRSxXQUFXO2dCQUNqQixJQUFJLEVBQUUsNEJBQWEsQ0FBQyxNQUFNO2FBQzdCO1lBQ0QsWUFBWSxFQUFFLENBQUM7WUFDZixhQUFhLEVBQUUsQ0FBQztZQUNoQixhQUFhLEVBQUUsMkJBQWEsQ0FBQyxPQUFPO1NBQ3ZDLENBQUMsQ0FBQztRQUVILDBDQUEwQztRQUMxQyxtQkFBbUI7UUFDbkIsMENBQTBDO1FBRTFDLE1BQU0sV0FBVyxHQUFHLElBQUkscUJBQVEsQ0FBQyxJQUFJLEVBQUUsZ0JBQWdCLEVBQUU7WUFDckQsSUFBSSxFQUFFLElBQUksc0JBQVMsQ0FBQyxhQUFhLENBQUM7WUFDbEMsT0FBTyxFQUFFLGlCQUFpQjtZQUMxQixPQUFPLEVBQUUsb0JBQU8sQ0FBQyxXQUFXO1lBQzVCLE9BQU8sRUFBRSxzQkFBUSxDQUFDLE9BQU8sQ0FBQyxHQUFHLENBQUM7WUFDOUIsVUFBVSxFQUFFLEdBQUc7WUFDZixXQUFXLEVBQUU7Z0JBQ1QsWUFBWSxFQUFFLG9CQUFvQjthQUNyQztTQUNKLENBQUMsQ0FBQztRQUVILGdCQUFnQixDQUFDLGtCQUFrQixDQUFDLFdBQVcsQ0FBQyxDQUFBO1FBR2hELE1BQU0sY0FBYyxHQUFHLElBQUkscUJBQVEsQ0FBQyxJQUFJLEVBQUUsbUJBQW1CLEVBQUU7WUFDM0QsSUFBSSxFQUFFLElBQUksc0JBQVMsQ0FBQyxnQkFBZ0IsQ0FBQztZQUNyQyxPQUFPLEVBQUUsb0JBQW9CO1lBQzdCLE9BQU8sRUFBRSxvQkFBTyxDQUFDLFdBQVc7WUFDNUIsT0FBTyxFQUFFLHNCQUFRLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQztZQUM5QixVQUFVLEVBQUUsR0FBRztZQUNmLFdBQVcsRUFBRTtnQkFDVCxZQUFZLEVBQUUsb0JBQW9CO2FBQ3JDO1NBQ0osQ0FBQyxDQUFDO1FBRUgsZ0JBQWdCLENBQUMsa0JBQWtCLENBQUMsY0FBYyxDQUFDLENBQUE7UUFFbkQsTUFBTSxXQUFXLEdBQUcsSUFBSSxxQkFBUSxDQUFDLElBQUksRUFBRSxnQkFBZ0IsRUFBRTtZQUNyRCxJQUFJLEVBQUUsSUFBSSxzQkFBUyxDQUFDLGVBQWUsQ0FBQztZQUNwQyxPQUFPLEVBQUUscUJBQXFCO1lBQzlCLE9BQU8sRUFBRSxvQkFBTyxDQUFDLFdBQVc7WUFDNUIsT0FBTyxFQUFFLHNCQUFRLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQztZQUM5QixVQUFVLEVBQUUsR0FBRztZQUNmLGFBQWEsRUFBRTtnQkFDWCxJQUFJLHlCQUFlLENBQUM7b0JBQ2hCLE9BQU8sRUFBRTt3QkFDTCwrQkFBK0I7cUJBQ2xDO29CQUNELFNBQVMsRUFBRTt3QkFDUCxzQkFBc0IsR0FBRyxNQUFNLENBQUMsUUFBUSxDQUFDLEdBQUcsR0FBRyxHQUFHLE1BQU0sQ0FBQyxZQUFZLENBQUMsR0FBRyxHQUFHLEdBQUcsR0FBRyxDQUFDLEdBQUcsR0FBRyxJQUFJO3FCQUNoRztvQkFDRCxNQUFNLEVBQUUsZ0JBQU0sQ0FBQyxLQUFLO2lCQUN2QixDQUFDO2FBQ0w7WUFDRCxXQUFXLEVBQUU7Z0JBQ1Qsb0JBQW9CLEVBQUUsZ0JBQWdCO2dCQUN0QyxxQkFBcUIsRUFBRSxpQkFBaUI7Z0JBQ3hDLHdCQUF3QixFQUFFLG9CQUFvQjthQUNqRDtTQUNKLENBQUMsQ0FBQztRQUVILGFBQWEsQ0FBQyxrQkFBa0IsQ0FBQyxXQUFXLENBQUMsQ0FBQTtRQUM3QyxnQkFBZ0IsQ0FBQyxrQkFBa0IsQ0FBQyxXQUFXLENBQUMsQ0FBQTtRQUVoRCw2REFBNkQ7UUFDN0QsTUFBTSxNQUFNLEdBQUcsSUFBSSx5QkFBZSxDQUFDO1lBQy9CLE1BQU0sRUFBRSxnQkFBTSxDQUFDLEtBQUs7WUFDcEIsU0FBUyxFQUFFO2dCQUNQLFdBQVcsQ0FBQyxXQUFXO2dCQUN2QixjQUFjLENBQUMsV0FBVztnQkFDMUIsV0FBVyxDQUFDLFdBQVc7YUFDMUI7WUFDRCxPQUFPLEVBQUUsQ0FBQyx1QkFBdUIsQ0FBQztTQUNyQyxDQUFDLENBQUM7UUFFSCxNQUFNLElBQUksR0FBRyxJQUFJLGNBQUksQ0FBQyxJQUFJLEVBQUUsR0FBRyxJQUFJLFdBQVcsRUFBRTtZQUM1QyxTQUFTLEVBQUUsSUFBSSwwQkFBZ0IsQ0FBQywwQkFBMEIsQ0FBQztTQUM5RCxDQUFDLENBQUM7UUFDSCxJQUFJLENBQUMsV0FBVyxDQUFDLE1BQU0sQ0FBQyxDQUFDO1FBRXpCLDBDQUEwQztRQUMxQyxzQkFBc0I7UUFDdEIsMENBQTBDO1FBQzFDLE1BQU0sa0JBQWtCLEdBQUcsSUFBSSxpQ0FBYyxDQUFDLElBQUksRUFBRSw0QkFBNEIsRUFBRTtZQUM5RSxLQUFLLEVBQUUsR0FBRyxDQUFDLEdBQUc7WUFDZCxlQUFlLEVBQUUsV0FBVztZQUM1QixjQUFjLEVBQUUscUJBQXFCLEdBQUcsTUFBTSxDQUFDLFFBQVEsQ0FBQyxHQUFHLG9DQUFvQyxHQUFHLFdBQVcsQ0FBQyxXQUFXLEdBQUcsY0FBYztZQUMxSSxjQUFjLEVBQUUsSUFBSSxDQUFDLE9BQU87U0FDL0IsQ0FBQyxDQUFBO1FBQ0YsTUFBTSxxQkFBcUIsR0FBRyxJQUFJLGlDQUFjLENBQUMsSUFBSSxFQUFFLCtCQUErQixFQUFFO1lBQ3BGLEtBQUssRUFBRSxHQUFHLENBQUMsR0FBRztZQUNkLGVBQWUsRUFBRSxXQUFXO1lBQzVCLGNBQWMsRUFBRSxxQkFBcUIsR0FBRyxNQUFNLENBQUMsUUFBUSxDQUFDLEdBQUcsb0NBQW9DLEdBQUcsY0FBYyxDQUFDLFdBQVcsR0FBRyxjQUFjO1lBQzdJLGNBQWMsRUFBRSxJQUFJLENBQUMsT0FBTztTQUMvQixDQUFDLENBQUE7UUFDRixNQUFNLGtCQUFrQixHQUFHLElBQUksaUNBQWMsQ0FBQyxJQUFJLEVBQUUsNEJBQTRCLEVBQUU7WUFDOUUsS0FBSyxFQUFFLEdBQUcsQ0FBQyxHQUFHO1lBQ2QsZUFBZSxFQUFFLFdBQVc7WUFDNUIsY0FBYyxFQUFFLHFCQUFxQixHQUFHLE1BQU0sQ0FBQyxRQUFRLENBQUMsR0FBRyxvQ0FBb0MsR0FBRyxXQUFXLENBQUMsV0FBVyxHQUFHLGNBQWM7WUFDMUksY0FBYyxFQUFFLElBQUksQ0FBQyxPQUFPO1NBQy9CLENBQUMsQ0FBQTtRQUVGLDBDQUEwQztRQUMxQyxxQkFBcUI7UUFDckIsMENBQTBDO1FBQzFDLE1BQU0sWUFBWSxHQUFHLElBQUksMkJBQVEsQ0FBQyxJQUFJLEVBQUUsZUFBZSxFQUFFO1lBQ3JELEtBQUssRUFBRSxHQUFHLENBQUMsR0FBRztZQUNkLFFBQVEsRUFBRSxVQUFVO1lBQ3BCLGlCQUFpQixFQUFFLE1BQU07WUFDekIsTUFBTSxFQUFFLGVBQWUsR0FBRyxrQkFBa0IsQ0FBQyxHQUFHO1NBQ25ELENBQUMsQ0FBQztRQUVILE1BQU0sZUFBZSxHQUFHLElBQUksMkJBQVEsQ0FBQyxJQUFJLEVBQUUsa0JBQWtCLEVBQUU7WUFDM0QsS0FBSyxFQUFFLEdBQUcsQ0FBQyxHQUFHO1lBQ2QsUUFBUSxFQUFFLGFBQWE7WUFDdkIsaUJBQWlCLEVBQUUsTUFBTTtZQUN6QixNQUFNLEVBQUUsZUFBZSxHQUFHLHFCQUFxQixDQUFDLEdBQUc7U0FDdEQsQ0FBQyxDQUFDO1FBRUgsTUFBTSxZQUFZLEdBQUcsSUFBSSwyQkFBUSxDQUFDLElBQUksRUFBRSxlQUFlLEVBQUU7WUFDckQsS0FBSyxFQUFFLEdBQUcsQ0FBQyxHQUFHO1lBQ2QsUUFBUSxFQUFFLGFBQWE7WUFDdkIsaUJBQWlCLEVBQUUsTUFBTTtZQUN6QixNQUFNLEVBQUUsZUFBZSxHQUFHLGtCQUFrQixDQUFDLEdBQUc7U0FDbkQsQ0FBQyxDQUFDO1FBQ0gsMENBQTBDO1FBQzFDLGFBQWE7UUFDYiwwQ0FBMEM7UUFFMUMsTUFBTSxVQUFVLEdBQUcsSUFBSSxnQ0FBYSxDQUFDLElBQUksRUFBRSxHQUFHLElBQUksYUFBYSxFQUFFO1lBQzdELEtBQUssRUFBRSxHQUFHLENBQUMsR0FBRztTQUNqQixDQUFDLENBQUM7UUFFSCxJQUFJLDJCQUFRLENBQUMsSUFBSSxFQUFFLEdBQUcsSUFBSSxRQUFRLEVBQUU7WUFDaEMsS0FBSyxFQUFFLEdBQUcsQ0FBQyxHQUFHO1lBQ2QsVUFBVSxFQUFFLElBQUk7WUFDaEIsWUFBWSxFQUFFLFVBQVUsQ0FBQyxHQUFHO1lBQzVCLFNBQVMsRUFBRSxLQUFLO1NBQ25CLENBQUMsQ0FBQztRQUVILFVBQVUsQ0FBQyxJQUFJLENBQUMsYUFBYSxDQUFDLFlBQVksQ0FBQyxDQUFBO1FBQzNDLFVBQVUsQ0FBQyxJQUFJLENBQUMsYUFBYSxDQUFDLGVBQWUsQ0FBQyxDQUFBO1FBQzlDLFVBQVUsQ0FBQyxJQUFJLENBQUMsYUFBYSxDQUFDLFlBQVksQ0FBQyxDQUFBO0lBRS9DLENBQUM7Q0FDSjtBQUVELE1BQU0sR0FBRyxHQUFHLElBQUksaUJBQUcsRUFBRSxDQUFDO0FBQ3RCLElBQUksWUFBWSxDQUFDLEdBQUcsRUFBRSwwQkFBMEIsQ0FBQyxDQUFDO0FBQ2xELEdBQUcsQ0FBQyxLQUFLLEVBQUUsQ0FBQyIsInNvdXJjZXNDb250ZW50IjpbIiMhL3Vzci9iaW4vZW52IG5vZGVcbmltcG9ydCB7QXNzZXRDb2RlLCBGdW5jdGlvbiwgUnVudGltZX0gZnJvbSBcImF3cy1jZGstbGliL2F3cy1sYW1iZGFcIjtcbmltcG9ydCB7Q2ZuQXBpLCBDZm5EZXBsb3ltZW50LCBDZm5JbnRlZ3JhdGlvbiwgQ2ZuUm91dGUsIENmblN0YWdlfSBmcm9tIFwiYXdzLWNkay1saWIvYXdzLWFwaWdhdGV3YXl2MlwiO1xuaW1wb3J0IHtBcHAsIER1cmF0aW9uLCBSZW1vdmFsUG9saWN5LCBTdGFjaywgU3RhY2tQcm9wc30gZnJvbSAnYXdzLWNkay1saWInO1xuaW1wb3J0IHtFZmZlY3QsIFBvbGljeVN0YXRlbWVudCwgUm9sZSwgU2VydmljZVByaW5jaXBhbH0gZnJvbSBcImF3cy1jZGstbGliL2F3cy1pYW1cIjtcbmltcG9ydCB7QXR0cmlidXRlVHlwZSwgVGFibGV9IGZyb20gXCJhd3MtY2RrLWxpYi9hd3MtZHluYW1vZGJcIjtcbmltcG9ydCB7Q29uc3RydWN0fSBmcm9tICdjb25zdHJ1Y3RzJztcblxuY29uc3QgY29uZmlnID0ge1xuICAgIFwic3RhZ2VcIjogXCJkZXZcIixcbiAgICBcInJlZ2lvblwiOiBcImFwLW5vcnRoZWFzdC0yXCIsXG4gICAgXCJhY2NvdW50X2lkXCI6IFwiMzU1NTA4MjYwNTE3XCJcbn1cbmNsYXNzIENoYXRBcHBTdGFjayBleHRlbmRzIFN0YWNrIHtcbiAgICBjb25zdHJ1Y3RvcihzY29wZTogQ29uc3RydWN0LCBpZDogc3RyaW5nLCBwcm9wcz86IFN0YWNrUHJvcHMpIHtcbiAgICAgICAgc3VwZXIoc2NvcGUsIGlkLCBwcm9wcyk7XG4gICAgICAgIGNvbnN0IGNvbm5lY3Rpb25zVGFibGVOYW1lID0gXCJjaGF0X2Nvbm5lY3Rpb25zXCI7XG4gICAgICAgIGNvbnN0IG1lbWJlcnNUYWJsZU5hbWUgPSBcImNoYXRfbWVtYmVyc1wiO1xuICAgICAgICBjb25zdCBtZXNzYWdlc1RhYmxlTmFtZSA9IFwiY2hhdF9tZXNzYWdlc1wiO1xuXG4gICAgICAgIC8vIGluaXRpYWxpc2UgYXBpXG4gICAgICAgIGNvbnN0IG5hbWUgPSBpZCArIFwiLWFwaVwiXG4gICAgICAgIGNvbnN0IGFwaSA9IG5ldyBDZm5BcGkodGhpcywgbmFtZSwge1xuICAgICAgICAgICAgbmFtZTogXCJjaGF0LWFwcC13ZWJzb2NrZXRcIixcbiAgICAgICAgICAgIHByb3RvY29sVHlwZTogXCJXRUJTT0NLRVRcIixcbiAgICAgICAgICAgIHJvdXRlU2VsZWN0aW9uRXhwcmVzc2lvbjogXCIkcmVxdWVzdC5ib2R5LmFjdGlvblwiLFxuICAgICAgICB9KTtcblxuICAgICAgICAvLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy9cbiAgICAgICAgLy8gVEFCTEVTXG4gICAgICAgIC8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuICAgICAgICBjb25zdCBjb25uZWN0aW9uc1RhYmxlID0gbmV3IFRhYmxlKHRoaXMsIGAke25hbWV9LXRhYmxlLWNvbm5lY3Rpb25zYCwge1xuICAgICAgICAgICAgdGFibGVOYW1lOiBjb25uZWN0aW9uc1RhYmxlTmFtZSxcbiAgICAgICAgICAgIHBhcnRpdGlvbktleToge1xuICAgICAgICAgICAgICAgIG5hbWU6IFwiY29ubmVjdGlvbklkXCIsXG4gICAgICAgICAgICAgICAgdHlwZTogQXR0cmlidXRlVHlwZS5TVFJJTkcsXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgcmVhZENhcGFjaXR5OiA1LFxuICAgICAgICAgICAgd3JpdGVDYXBhY2l0eTogNSxcbiAgICAgICAgICAgIHJlbW92YWxQb2xpY3k6IFJlbW92YWxQb2xpY3kuREVTVFJPWVxuICAgICAgICB9KTtcblxuICAgICAgICBjb25uZWN0aW9uc1RhYmxlLmFkZEdsb2JhbFNlY29uZGFyeUluZGV4KHtcbiAgICAgICAgICAgIGluZGV4TmFtZTogXCJjb25uZWN0aW9ucy1yb29kSWQtaW5kZXhcIixcbiAgICAgICAgICAgIHBhcnRpdGlvbktleToge1xuICAgICAgICAgICAgICAgIG5hbWU6IFwicm9vbUlkXCIsXG4gICAgICAgICAgICAgICAgdHlwZTogQXR0cmlidXRlVHlwZS5TVFJJTkcsXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgcmVhZENhcGFjaXR5OiA1LFxuICAgICAgICAgICAgd3JpdGVDYXBhY2l0eTogNSxcbiAgICAgICAgfSk7XG5cbiAgICAgICAgY29uc3QgbWVzc2FnZXNUYWJsZSA9IG5ldyBUYWJsZSh0aGlzLCBgJHtuYW1lfS10YWJsZS1tZXNzYWdlc2AsIHtcbiAgICAgICAgICAgIHRhYmxlTmFtZTogbWVzc2FnZXNUYWJsZU5hbWUsXG4gICAgICAgICAgICBwYXJ0aXRpb25LZXk6IHtcbiAgICAgICAgICAgICAgICBuYW1lOiBcInJvb21JZFwiLFxuICAgICAgICAgICAgICAgIHR5cGU6IEF0dHJpYnV0ZVR5cGUuU1RSSU5HLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIHNvcnRLZXk6IHtcbiAgICAgICAgICAgICAgICBuYW1lOiBcImNyZWF0ZWRBdFwiLFxuICAgICAgICAgICAgICAgIHR5cGU6IEF0dHJpYnV0ZVR5cGUuTlVNQkVSLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIHJlYWRDYXBhY2l0eTogNSxcbiAgICAgICAgICAgIHdyaXRlQ2FwYWNpdHk6IDUsXG4gICAgICAgICAgICByZW1vdmFsUG9saWN5OiBSZW1vdmFsUG9saWN5LkRFU1RST1lcbiAgICAgICAgfSk7XG5cbiAgICAgICAgLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG4gICAgICAgIC8vIExBTUJEQSBGVU5DVElPTlNcbiAgICAgICAgLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG5cbiAgICAgICAgY29uc3QgY29ubmVjdEZ1bmMgPSBuZXcgRnVuY3Rpb24odGhpcywgJ2Nvbm5lY3QtbGFtYmRhJywge1xuICAgICAgICAgICAgY29kZTogbmV3IEFzc2V0Q29kZSgnLi9vbmNvbm5lY3QnKSxcbiAgICAgICAgICAgIGhhbmRsZXI6ICdjb25uZWN0LmhhbmRsZXInLFxuICAgICAgICAgICAgcnVudGltZTogUnVudGltZS5OT0RFSlNfMThfWCxcbiAgICAgICAgICAgIHRpbWVvdXQ6IER1cmF0aW9uLnNlY29uZHMoMzAwKSxcbiAgICAgICAgICAgIG1lbW9yeVNpemU6IDI1NixcbiAgICAgICAgICAgIGVudmlyb25tZW50OiB7XG4gICAgICAgICAgICAgICAgXCJUQUJMRV9OQU1FXCI6IGNvbm5lY3Rpb25zVGFibGVOYW1lLFxuICAgICAgICAgICAgfVxuICAgICAgICB9KTtcblxuICAgICAgICBjb25uZWN0aW9uc1RhYmxlLmdyYW50UmVhZFdyaXRlRGF0YShjb25uZWN0RnVuYylcblxuXG4gICAgICAgIGNvbnN0IGRpc2Nvbm5lY3RGdW5jID0gbmV3IEZ1bmN0aW9uKHRoaXMsICdkaXNjb25uZWN0LWxhbWJkYScsIHtcbiAgICAgICAgICAgIGNvZGU6IG5ldyBBc3NldENvZGUoJy4vb25kaXNjb25uZWN0JyksXG4gICAgICAgICAgICBoYW5kbGVyOiAnZGlzY29ubmVjdC5oYW5kbGVyJyxcbiAgICAgICAgICAgIHJ1bnRpbWU6IFJ1bnRpbWUuTk9ERUpTXzE4X1gsXG4gICAgICAgICAgICB0aW1lb3V0OiBEdXJhdGlvbi5zZWNvbmRzKDMwMCksXG4gICAgICAgICAgICBtZW1vcnlTaXplOiAyNTYsXG4gICAgICAgICAgICBlbnZpcm9ubWVudDoge1xuICAgICAgICAgICAgICAgIFwiVEFCTEVfTkFNRVwiOiBjb25uZWN0aW9uc1RhYmxlTmFtZSxcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSk7XG5cbiAgICAgICAgY29ubmVjdGlvbnNUYWJsZS5ncmFudFJlYWRXcml0ZURhdGEoZGlzY29ubmVjdEZ1bmMpXG5cbiAgICAgICAgY29uc3QgbWVzc2FnZUZ1bmMgPSBuZXcgRnVuY3Rpb24odGhpcywgJ21lc3NhZ2UtbGFtYmRhJywge1xuICAgICAgICAgICAgY29kZTogbmV3IEFzc2V0Q29kZSgnLi9zZW5kbWVzc2FnZScpLFxuICAgICAgICAgICAgaGFuZGxlcjogJ3NlbmRtZXNzYWdlLmhhbmRsZXInLFxuICAgICAgICAgICAgcnVudGltZTogUnVudGltZS5OT0RFSlNfMThfWCxcbiAgICAgICAgICAgIHRpbWVvdXQ6IER1cmF0aW9uLnNlY29uZHMoMzAwKSxcbiAgICAgICAgICAgIG1lbW9yeVNpemU6IDI1NixcbiAgICAgICAgICAgIGluaXRpYWxQb2xpY3k6IFtcbiAgICAgICAgICAgICAgICBuZXcgUG9saWN5U3RhdGVtZW50KHtcbiAgICAgICAgICAgICAgICAgICAgYWN0aW9uczogW1xuICAgICAgICAgICAgICAgICAgICAgICAgJ2V4ZWN1dGUtYXBpOk1hbmFnZUNvbm5lY3Rpb25zJ1xuICAgICAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgICAgICAgICByZXNvdXJjZXM6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgIFwiYXJuOmF3czpleGVjdXRlLWFwaTpcIiArIGNvbmZpZ1tcInJlZ2lvblwiXSArIFwiOlwiICsgY29uZmlnW1wiYWNjb3VudF9pZFwiXSArIFwiOlwiICsgYXBpLnJlZiArIFwiLypcIlxuICAgICAgICAgICAgICAgICAgICBdLFxuICAgICAgICAgICAgICAgICAgICBlZmZlY3Q6IEVmZmVjdC5BTExPVyxcbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgXSxcbiAgICAgICAgICAgIGVudmlyb25tZW50OiB7XG4gICAgICAgICAgICAgICAgXCJNRU1CRVJTX1RBQkxFX05BTUVcIjogbWVtYmVyc1RhYmxlTmFtZSxcbiAgICAgICAgICAgICAgICBcIk1FU1NBR0VTX1RBQkxFX05BTUVcIjogbWVzc2FnZXNUYWJsZU5hbWUsXG4gICAgICAgICAgICAgICAgXCJDT05ORUNUSU9OU19UQUJMRV9OQU1FXCI6IGNvbm5lY3Rpb25zVGFibGVOYW1lLFxuICAgICAgICAgICAgfVxuICAgICAgICB9KTtcblxuICAgICAgICBtZXNzYWdlc1RhYmxlLmdyYW50UmVhZFdyaXRlRGF0YShtZXNzYWdlRnVuYylcbiAgICAgICAgY29ubmVjdGlvbnNUYWJsZS5ncmFudFJlYWRXcml0ZURhdGEobWVzc2FnZUZ1bmMpXG5cbiAgICAgICAgLy8gYWNjZXNzIHJvbGUgZm9yIHRoZSBzb2NrZXQgYXBpIHRvIGFjY2VzcyB0aGUgc29ja2V0IGxhbWJkYVxuICAgICAgICBjb25zdCBwb2xpY3kgPSBuZXcgUG9saWN5U3RhdGVtZW50KHtcbiAgICAgICAgICAgIGVmZmVjdDogRWZmZWN0LkFMTE9XLFxuICAgICAgICAgICAgcmVzb3VyY2VzOiBbXG4gICAgICAgICAgICAgICAgY29ubmVjdEZ1bmMuZnVuY3Rpb25Bcm4sXG4gICAgICAgICAgICAgICAgZGlzY29ubmVjdEZ1bmMuZnVuY3Rpb25Bcm4sXG4gICAgICAgICAgICAgICAgbWVzc2FnZUZ1bmMuZnVuY3Rpb25Bcm5cbiAgICAgICAgICAgIF0sXG4gICAgICAgICAgICBhY3Rpb25zOiBbXCJsYW1iZGE6SW52b2tlRnVuY3Rpb25cIl1cbiAgICAgICAgfSk7XG5cbiAgICAgICAgY29uc3Qgcm9sZSA9IG5ldyBSb2xlKHRoaXMsIGAke25hbWV9LWlhbS1yb2xlYCwge1xuICAgICAgICAgICAgYXNzdW1lZEJ5OiBuZXcgU2VydmljZVByaW5jaXBhbChcImFwaWdhdGV3YXkuYW1hem9uYXdzLmNvbVwiKVxuICAgICAgICB9KTtcbiAgICAgICAgcm9sZS5hZGRUb1BvbGljeShwb2xpY3kpO1xuXG4gICAgICAgIC8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuICAgICAgICAvLyBMQU1CREEgSU5URUdSQVRJT05TXG4gICAgICAgIC8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuICAgICAgICBjb25zdCBjb25uZWN0SW50ZWdyYXRpb24gPSBuZXcgQ2ZuSW50ZWdyYXRpb24odGhpcywgXCJjb25uZWN0LWxhbWJkYS1pbnRlZ3JhdGlvblwiLCB7XG4gICAgICAgICAgICBhcGlJZDogYXBpLnJlZixcbiAgICAgICAgICAgIGludGVncmF0aW9uVHlwZTogXCJBV1NfUFJPWFlcIixcbiAgICAgICAgICAgIGludGVncmF0aW9uVXJpOiBcImFybjphd3M6YXBpZ2F0ZXdheTpcIiArIGNvbmZpZ1tcInJlZ2lvblwiXSArIFwiOmxhbWJkYTpwYXRoLzIwMTUtMDMtMzEvZnVuY3Rpb25zL1wiICsgY29ubmVjdEZ1bmMuZnVuY3Rpb25Bcm4gKyBcIi9pbnZvY2F0aW9uc1wiLFxuICAgICAgICAgICAgY3JlZGVudGlhbHNBcm46IHJvbGUucm9sZUFybixcbiAgICAgICAgfSlcbiAgICAgICAgY29uc3QgZGlzY29ubmVjdEludGVncmF0aW9uID0gbmV3IENmbkludGVncmF0aW9uKHRoaXMsIFwiZGlzY29ubmVjdC1sYW1iZGEtaW50ZWdyYXRpb25cIiwge1xuICAgICAgICAgICAgYXBpSWQ6IGFwaS5yZWYsXG4gICAgICAgICAgICBpbnRlZ3JhdGlvblR5cGU6IFwiQVdTX1BST1hZXCIsXG4gICAgICAgICAgICBpbnRlZ3JhdGlvblVyaTogXCJhcm46YXdzOmFwaWdhdGV3YXk6XCIgKyBjb25maWdbXCJyZWdpb25cIl0gKyBcIjpsYW1iZGE6cGF0aC8yMDE1LTAzLTMxL2Z1bmN0aW9ucy9cIiArIGRpc2Nvbm5lY3RGdW5jLmZ1bmN0aW9uQXJuICsgXCIvaW52b2NhdGlvbnNcIixcbiAgICAgICAgICAgIGNyZWRlbnRpYWxzQXJuOiByb2xlLnJvbGVBcm5cbiAgICAgICAgfSlcbiAgICAgICAgY29uc3QgbWVzc2FnZUludGVncmF0aW9uID0gbmV3IENmbkludGVncmF0aW9uKHRoaXMsIFwibWVzc2FnZS1sYW1iZGEtaW50ZWdyYXRpb25cIiwge1xuICAgICAgICAgICAgYXBpSWQ6IGFwaS5yZWYsXG4gICAgICAgICAgICBpbnRlZ3JhdGlvblR5cGU6IFwiQVdTX1BST1hZXCIsXG4gICAgICAgICAgICBpbnRlZ3JhdGlvblVyaTogXCJhcm46YXdzOmFwaWdhdGV3YXk6XCIgKyBjb25maWdbXCJyZWdpb25cIl0gKyBcIjpsYW1iZGE6cGF0aC8yMDE1LTAzLTMxL2Z1bmN0aW9ucy9cIiArIG1lc3NhZ2VGdW5jLmZ1bmN0aW9uQXJuICsgXCIvaW52b2NhdGlvbnNcIixcbiAgICAgICAgICAgIGNyZWRlbnRpYWxzQXJuOiByb2xlLnJvbGVBcm5cbiAgICAgICAgfSlcblxuICAgICAgICAvLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy9cbiAgICAgICAgLy8gQ09OTkVDVElPTlMgUk9VVEVTXG4gICAgICAgIC8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL1xuICAgICAgICBjb25zdCBjb25uZWN0Um91dGUgPSBuZXcgQ2ZuUm91dGUodGhpcywgXCJjb25uZWN0LXJvdXRlXCIsIHtcbiAgICAgICAgICAgIGFwaUlkOiBhcGkucmVmLFxuICAgICAgICAgICAgcm91dGVLZXk6IFwiJGNvbm5lY3RcIixcbiAgICAgICAgICAgIGF1dGhvcml6YXRpb25UeXBlOiBcIk5PTkVcIixcbiAgICAgICAgICAgIHRhcmdldDogXCJpbnRlZ3JhdGlvbnMvXCIgKyBjb25uZWN0SW50ZWdyYXRpb24ucmVmLFxuICAgICAgICB9KTtcblxuICAgICAgICBjb25zdCBkaXNjb25uZWN0Um91dGUgPSBuZXcgQ2ZuUm91dGUodGhpcywgXCJkaXNjb25uZWN0LXJvdXRlXCIsIHtcbiAgICAgICAgICAgIGFwaUlkOiBhcGkucmVmLFxuICAgICAgICAgICAgcm91dGVLZXk6IFwiJGRpc2Nvbm5lY3RcIixcbiAgICAgICAgICAgIGF1dGhvcml6YXRpb25UeXBlOiBcIk5PTkVcIixcbiAgICAgICAgICAgIHRhcmdldDogXCJpbnRlZ3JhdGlvbnMvXCIgKyBkaXNjb25uZWN0SW50ZWdyYXRpb24ucmVmLFxuICAgICAgICB9KTtcblxuICAgICAgICBjb25zdCBtZXNzYWdlUm91dGUgPSBuZXcgQ2ZuUm91dGUodGhpcywgXCJtZXNzYWdlLXJvdXRlXCIsIHtcbiAgICAgICAgICAgIGFwaUlkOiBhcGkucmVmLFxuICAgICAgICAgICAgcm91dGVLZXk6IFwic2VuZG1lc3NhZ2VcIixcbiAgICAgICAgICAgIGF1dGhvcml6YXRpb25UeXBlOiBcIk5PTkVcIixcbiAgICAgICAgICAgIHRhcmdldDogXCJpbnRlZ3JhdGlvbnMvXCIgKyBtZXNzYWdlSW50ZWdyYXRpb24ucmVmLFxuICAgICAgICB9KTtcbiAgICAgICAgLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG4gICAgICAgIC8vIERFUExPWU1FTlRcbiAgICAgICAgLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vXG5cbiAgICAgICAgY29uc3QgZGVwbG95bWVudCA9IG5ldyBDZm5EZXBsb3ltZW50KHRoaXMsIGAke25hbWV9LWRlcGxveW1lbnRgLCB7XG4gICAgICAgICAgICBhcGlJZDogYXBpLnJlZlxuICAgICAgICB9KTtcblxuICAgICAgICBuZXcgQ2ZuU3RhZ2UodGhpcywgYCR7bmFtZX0tc3RhZ2VgLCB7XG4gICAgICAgICAgICBhcGlJZDogYXBpLnJlZixcbiAgICAgICAgICAgIGF1dG9EZXBsb3k6IHRydWUsXG4gICAgICAgICAgICBkZXBsb3ltZW50SWQ6IGRlcGxveW1lbnQucmVmLFxuICAgICAgICAgICAgc3RhZ2VOYW1lOiBcImRldlwiLFxuICAgICAgICB9KTtcblxuICAgICAgICBkZXBsb3ltZW50Lm5vZGUuYWRkRGVwZW5kZW5jeShjb25uZWN0Um91dGUpXG4gICAgICAgIGRlcGxveW1lbnQubm9kZS5hZGREZXBlbmRlbmN5KGRpc2Nvbm5lY3RSb3V0ZSlcbiAgICAgICAgZGVwbG95bWVudC5ub2RlLmFkZERlcGVuZGVuY3kobWVzc2FnZVJvdXRlKVxuXG4gICAgfVxufVxuXG5jb25zdCBhcHAgPSBuZXcgQXBwKCk7XG5uZXcgQ2hhdEFwcFN0YWNrKGFwcCwgYGNoYXQtYXBwLXdlYnNvY2tldC1zdGFja2ApO1xuYXBwLnN5bnRoKCk7XG4iXX0=