// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient({
    apiVersion: "2012-08-10",
    region: process.env.AWS_REGION,
});
const {CONNECTIONS_TABLE_NAME, MESSAGES_TABLE_NAME} =
    process.env;

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));
    let connections = [];

    console.log(event.body);

    const id = JSON.parse(event.body).id;
    const message = JSON.parse(event.body).message;
    const roomId = JSON.parse(event.body).roomId;
    const userName = JSON.parse(event.body).userName;
    const createdAt = Date.now();


    ////////////////////////////////
    // SOCKET WRITE ( PROMISE )
    ////////////////////////////////
    try {
        connections = await ddb
            .query({
                TableName: CONNECTIONS_TABLE_NAME,
                IndexName: "connections-roodId-index",
                ProjectionExpression: "connectionId",
                KeyConditionExpression: "roomId = :roomId",
                ExpressionAttributeValues: {
                    ":roomId": roomId,
                }
            })
            .promise();
    } catch (e) {
        console.log(e);
        return {statusCode: 500, body: e.stack};
    }
    console.log(connections.Items);

    try {
        await ddb.put({
            TableName: MESSAGES_TABLE_NAME,
            Item: {
                id: id,
                message: message,
                roomId: roomId,
                userName: userName,
                createdAt: createdAt,
                ip: event.requestContext.identity.sourceIp
            },
        }).promise();

    } catch (e) {
        console.log(e);
        return {statusCode: 500, body: e.stack};
    }


    const apigwManagementApi = new AWS.ApiGatewayManagementApi({
        apiVersion: "2018-11-29",
        endpoint:
            event.requestContext.domainName + "/" + event.requestContext.stage,
    });

    const postCalls = connections.Items.map(async ({connectionId}) => {
        try {
            await apigwManagementApi
                .postToConnection({
                    ConnectionId: connectionId,
                    Data: JSON.stringify({
                        message: message,
                        userName: userName,
                        roomId: roomId,
                        ip: event.requestContext.identity.sourceIp,
                        id: id,
                        createdAt: createdAt,
                    }),
                })
                .promise();
        } catch (e) {
            if (e.statusCode === 410) {
                console.log(`Found stale connection, deleting ${connectionId}`);
                await ddb
                    .delete({TableName: CONNECTIONS_TABLE_NAME, Key: {connectionId}})
                    .promise();
            } else {
                throw e;
            }
        }
    });

    try {
        await Promise.all(postCalls);
    } catch (e) {
        console.log(e);
        return {statusCode: 500, body: e.stack};
    }

    return {statusCode: 200, body: "Data sent."};
};
