import * as dynamoose from 'dynamoose';

export interface PushTokenKey {
  pushToken: string;
}

export interface PushToken extends PushTokenKey {
}

export const PushTokenSchema = new dynamoose.Schema({
  pushToken: {
    type: String,
    hashKey: true,
    required: true,
  },
});
