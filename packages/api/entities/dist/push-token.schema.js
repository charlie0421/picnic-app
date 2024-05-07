"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PushTokenSchema = void 0;
const dynamoose = require("dynamoose");
exports.PushTokenSchema = new dynamoose.Schema({
    pushToken: {
        type: String,
        hashKey: true,
        required: true,
    },
});
//# sourceMappingURL=push-token.schema.js.map