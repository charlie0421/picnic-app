import * as dynamoose from 'dynamoose';

export interface MessageKey {
    roomId: string;
    createdAt?: number;
}

export interface Message extends MessageKey {
    clientId?: string;
    connectionId?: string;
    message?: string;
    messageId?: string;
    profileImage?: string;
    userId?: string;
    userName?: string;
    ip?: string;
}

export const MessagesSchema = new dynamoose.Schema({
    roomId: {
        type: String,
        hashKey: true,
        required: true,
    },
    createdAt: {
        type: Number,
        rangeKey: true,
        index: {
            name: "roomId-createdAt-index",
        }
    },
    clientId: {
        type: String,
    },
    connectionId: {
        type: String,
    },
    message: {
        type: String,
    },
    messageId: {
        type: String,
    },
    profileImage: {
        type: String,
    },
    userId: {
        type: String,
    },
    userName: {
        type: String,
    },
    ip: {
        type: String,
    },
});
