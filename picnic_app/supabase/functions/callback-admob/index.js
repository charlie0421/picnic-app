"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var supabase_js_2_1 = require("https://esm.sh/@supabase/supabase-js@2");
var postgres = require("https://deno.land/x/postgres@v0.17.0/mod.ts");
var mod_ts_1 = require("https://deno.land/x/dotenv/mod.ts");
(0, mod_ts_1.config)(); // 환경 변수 로드
var databaseUrl = Deno.env.get('SUPABASE_DB_URL');
var pool = new postgres.Pool(databaseUrl, 3, true);
var secretKey = "c0bb7b4bcedf4db314aa7d0bbba4d4a784877bae45d89439ed83549798ccc923";
function base64UrlToBase64(base64Url) {
    return base64Url.replace(/-/g, '+').replace(/_/g, '/').padEnd(base64Url.length + (4 - (base64Url.length % 4)) % 4, '=');
}
function safeAtob(base64) {
    try {
        return Uint8Array.from(atob(base64), function (c) { return c.charCodeAt(0); });
    }
    catch (e) {
        console.error('Failed to decode Base64:', base64);
        throw new Error('Invalid Base64 string');
    }
}
function verifySignature(transaction_id, user_id, reward_amount, signature, secretKey) {
    return __awaiter(this, void 0, void 0, function () {
        var encoder, keyData, data, key, signatureArray, isValid, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 3, , 4]);
                    if (!secretKey) {
                        throw new Error('Secret key is missing');
                    }
                    encoder = new TextEncoder();
                    keyData = encoder.encode(secretKey);
                    data = encoder.encode("".concat(transaction_id).concat(user_id).concat(reward_amount));
                    console.log('Data to be signed:', "".concat(transaction_id).concat(user_id).concat(reward_amount));
                    return [4 /*yield*/, crypto.subtle.importKey('raw', keyData, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify'])];
                case 1:
                    key = _a.sent();
                    signatureArray = safeAtob(base64UrlToBase64(signature));
                    return [4 /*yield*/, crypto.subtle.verify('HMAC', key, signatureArray, data)];
                case 2:
                    isValid = _a.sent();
                    console.log('Signature is valid:', isValid);
                    return [2 /*return*/, isValid];
                case 3:
                    error_1 = _a.sent();
                    console.error('Error during signature verification:', error_1);
                    return [2 /*return*/, false];
                case 4: return [2 /*return*/];
            }
        });
    });
}
Deno.serve(function (req) { return __awaiter(void 0, void 0, void 0, function () {
    var url, params, user_id, reward_amount, custom_data, ad_network, transaction_id, signature, key_id, reward_type, parsedData, isValid, supabaseClient, _a, user_profiles, userError, connection, updateUserQuery, insertHistoryQuery, insertTransactionQuery, e_1, error_2;
    var _b, _c, _d;
    return __generator(this, function (_e) {
        switch (_e.label) {
            case 0:
                _e.trys.push([0, 13, , 14]);
                url = new URL(req.url);
                params = url.searchParams;
                user_id = params.get('user_id');
                reward_amount = parseInt((_b = params.get('reward_amount')) !== null && _b !== void 0 ? _b : '0', 10);
                custom_data = params.get('custom_data');
                ad_network = params.get('ad_network');
                transaction_id = params.get('transaction_id');
                signature = params.get('signature');
                key_id = params.get('key_id');
                reward_type = null;
                if (custom_data) {
                    parsedData = JSON.parse(custom_data);
                    reward_type = parsedData.reward_type;
                }
                console.log('Request parameters:', {
                    user_id: user_id,
                    reward_amount: reward_amount,
                    reward_type: reward_type,
                    ad_network: ad_network,
                    transaction_id: transaction_id,
                    signature: signature,
                    key_id: key_id
                });
                if (!user_id || !reward_amount || !reward_type || !ad_network || !transaction_id || !signature || !key_id) {
                    console.error('Invalid request parameters', {
                        user_id: user_id,
                        reward_amount: reward_amount,
                        reward_type: reward_type,
                        ad_network: ad_network,
                        transaction_id: transaction_id,
                        signature: signature,
                        key_id: key_id
                    });
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'Invalid request' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                console.log('Verifying signature with secret key', secretKey);
                return [4 /*yield*/, verifySignature(transaction_id, user_id, reward_amount, signature, secretKey)];
            case 1:
                isValid = _e.sent();
                isValid = true; // TODO: Remove this line after testing
                if (!isValid) {
                    console.error('Invalid signature', { transaction_id: transaction_id, user_id: user_id, reward_amount: reward_amount, signature: signature });
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'Invalid signature' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                supabaseClient = (0, supabase_js_2_1.createClient)((_c = Deno.env.get('SUPABASE_URL')) !== null && _c !== void 0 ? _c : '', (_d = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) !== null && _d !== void 0 ? _d : '', { global: { headers: { Authorization: "Bearer ".concat(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) } } });
                console.log('Fetching user profile', user_id);
                return [4 /*yield*/, supabaseClient
                        .from('user_profiles')
                        .select('star_candy_bonus')
                        .eq('id', user_id)
                        .single()];
            case 2:
                _a = _e.sent(), user_profiles = _a.data, userError = _a.error;
                if (userError || !user_profiles) {
                    console.error('User not found or other error occurred', userError);
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'User not found or other error occurred' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                return [4 /*yield*/, pool.connect()];
            case 3:
                connection = _e.sent();
                _e.label = 4;
            case 4:
                _e.trys.push([4, 10, , 12]);
                return [4 /*yield*/, connection.queryObject('BEGIN')];
            case 5:
                _e.sent();
                console.log('Updating user rewards');
                updateUserQuery = "UPDATE user_profiles\n                                     SET star_candy_bonus = star_candy_bonus + $1\n                                     WHERE id = $2";
                return [4 /*yield*/, connection.queryObject(updateUserQuery, [reward_amount, user_id])];
            case 6:
                _e.sent();
                console.log('Inserting star_candy history');
                insertHistoryQuery = "INSERT INTO star_candy_bonus_history (type, amount, user_id, transaction_id)\n                                                VALUES ($1, $2, $3, $4)";
                return [4 /*yield*/, connection.queryObject(insertHistoryQuery, ['AD', reward_amount, user_id, transaction_id])];
            case 7:
                _e.sent();
                console.log('Inserting transaction');
                insertTransactionQuery = "INSERT INTO transaction_admob (transaction_id,\n                                                                                   reward_type, reward_amount,\n                                                                                   signature,\n                                                                                   ad_network, key_id)\n                                                    VALUES ($1, $2, $3, $4, $5, $6)";
                return [4 /*yield*/, connection.queryObject(insertTransactionQuery, [transaction_id, reward_type, reward_amount, signature, ad_network, key_id])];
            case 8:
                _e.sent();
                return [4 /*yield*/, connection.queryObject('COMMIT')];
            case 9:
                _e.sent();
                connection.release();
                return [2 /*return*/, new Response(JSON.stringify({ success: true }), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 200,
                    })];
            case 10:
                e_1 = _e.sent();
                return [4 /*yield*/, connection.queryObject('ROLLBACK')];
            case 11:
                _e.sent();
                connection.release();
                console.error('Transaction failed', e_1);
                throw e_1;
            case 12: return [3 /*break*/, 14];
            case 13:
                error_2 = _e.sent();
                console.error('Unhandled error', error_2);
                return [2 /*return*/, new Response(JSON.stringify({ error: error_2.message }), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 500,
                    })];
            case 14: return [2 /*return*/];
        }
    });
}); });
"";
