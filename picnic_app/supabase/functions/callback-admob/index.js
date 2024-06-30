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
// Utility functions
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
// Database query function
function queryDatabase(query) {
    var args = [];
    for (var _i = 1; _i < arguments.length; _i++) {
        args[_i - 1] = arguments[_i];
    }
    return __awaiter(this, void 0, void 0, function () {
        var client, result, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, pool.connect()];
                case 1:
                    client = _a.sent();
                    console.log('queryDatabase', { query: query, args: args });
                    _a.label = 2;
                case 2:
                    _a.trys.push([2, 4, 5, 6]);
                    return [4 /*yield*/, client.queryObject(query, args)];
                case 3:
                    result = _a.sent();
                    console.log('Query executed:', { query: query, args: args, result: result });
                    return [2 /*return*/, result];
                case 4:
                    error_1 = _a.sent();
                    console.error('Error executing query:', { query: query, args: args, error: error_1 });
                    throw error_1;
                case 5:
                    client.release();
                    return [7 /*endfinally*/];
                case 6: return [2 /*return*/];
            }
        });
    });
}
// Signature verification function
function verifySignature(transaction_id, user_id, reward_amount, signature, secretKey) {
    return __awaiter(this, void 0, void 0, function () {
        var encoder, keyData, data, key, signatureArray, isValid, error_2;
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
                    error_2 = _a.sent();
                    console.error('Error during signature verification:', error_2);
                    return [2 /*return*/, false];
                case 4: return [2 /*return*/];
            }
        });
    });
}
// Request processing functions
function extractParameters(url) {
    var _a;
    var params = url.searchParams;
    var user_id = params.get('user_id');
    var reward_amount = parseInt((_a = params.get('reward_amount')) !== null && _a !== void 0 ? _a : '0', 10);
    var custom_data = params.get('custom_data');
    var ad_network = params.get('ad_network');
    var transaction_id = params.get('transaction_id');
    var signature = params.get('signature');
    var key_id = params.get('key_id');
    var reward_type = null;
    if (custom_data) {
        var parsedData = JSON.parse(custom_data);
        reward_type = parsedData.reward_type;
    }
    return { user_id: user_id, reward_amount: reward_amount, reward_type: reward_type, ad_network: ad_network, transaction_id: transaction_id, signature: signature, key_id: key_id };
}
function validateParameters(params) {
    var user_id = params.user_id, reward_amount = params.reward_amount, reward_type = params.reward_type, ad_network = params.ad_network, transaction_id = params.transaction_id, signature = params.signature, key_id = params.key_id;
    if (!user_id || !reward_amount || !reward_type || !ad_network || !transaction_id || !signature || !key_id) {
        console.error('Invalid request parameters', params);
        return false;
    }
    return true;
}
function updateUserRewards(user_id, reward_amount) {
    return __awaiter(this, void 0, void 0, function () {
        var updateUserQuery;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log('Updating user rewards');
                    updateUserQuery = "UPDATE user_profiles\n                             SET star_candy_bonus = star_candy_bonus + $1\n                             WHERE id = $2";
                    return [4 /*yield*/, queryDatabase(updateUserQuery, reward_amount, user_id)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function getNextMonth15thAt9AM() {
    var now = new Date();
    var nextMonth = now.getMonth() + 1;
    var nextMonth15th = new Date(now.getFullYear(), nextMonth, 15, 9, 0, 0);
    // YYYY-MM-DD HH:MM:SS 형식으로 변환
    var year = nextMonth15th.getFullYear();
    var month = String(nextMonth15th.getMonth() + 1).padStart(2, '0'); // 월은 0부터 시작하므로 1을 더함
    var day = String(nextMonth15th.getDate()).padStart(2, '0');
    var hours = String(nextMonth15th.getHours()).padStart(2, '0');
    var minutes = String(nextMonth15th.getMinutes()).padStart(2, '0');
    var seconds = String(nextMonth15th.getSeconds()).padStart(2, '0');
    return "".concat(year, "-").concat(month, "-").concat(day, " ").concat(hours, ":").concat(minutes, ":").concat(seconds);
}
function insertStarCandyBonusHistory(user_id, reward_amount, transaction_id) {
    return __awaiter(this, void 0, void 0, function () {
        var expired_dt, insertHistoryQuery;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log('Inserting star_candy history');
                    expired_dt = getNextMonth15thAt9AM();
                    insertHistoryQuery = "INSERT INTO star_candy_bonus_history (type, amount, remain_amount, user_id, transaction_id, expired_dt)\n                                VALUES ($1, $2, $3, $4, $5, $6)";
                    return [4 /*yield*/, queryDatabase(insertHistoryQuery, 'AD', reward_amount, reward_amount, user_id, transaction_id, expired_dt)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id) {
    return __awaiter(this, void 0, void 0, function () {
        var insertTransactionQuery;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log('Inserting transaction');
                    insertTransactionQuery = "INSERT INTO transaction_admob (transaction_id, reward_type, reward_amount,\n                                                                   signature, ad_network, key_id)\n                                    VALUES ($1, $2, $3, $4, $5, $6)";
                    return [4 /*yield*/, queryDatabase(insertTransactionQuery, transaction_id, reward_type, reward_amount, signature, ad_network, key_id)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function processTransaction(user_id, reward_amount, transaction_id, reward_type, signature, ad_network, key_id) {
    return __awaiter(this, void 0, void 0, function () {
        var connection, e_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, pool.connect()];
                case 1:
                    connection = _a.sent();
                    _a.label = 2;
                case 2:
                    _a.trys.push([2, 8, , 10]);
                    return [4 /*yield*/, connection.queryObject('BEGIN')];
                case 3:
                    _a.sent();
                    return [4 /*yield*/, updateUserRewards(user_id, reward_amount)];
                case 4:
                    _a.sent();
                    return [4 /*yield*/, insertStarCandyBonusHistory(user_id, reward_amount, transaction_id)];
                case 5:
                    _a.sent();
                    return [4 /*yield*/, insertTransaction(transaction_id, reward_type, reward_amount, signature, ad_network, key_id)];
                case 6:
                    _a.sent();
                    return [4 /*yield*/, connection.queryObject('COMMIT')];
                case 7:
                    _a.sent();
                    connection.release();
                    return [3 /*break*/, 10];
                case 8:
                    e_1 = _a.sent();
                    return [4 /*yield*/, connection.queryObject('ROLLBACK')];
                case 9:
                    _a.sent();
                    connection.release();
                    console.error('Transaction failed', e_1);
                    throw e_1;
                case 10: return [2 /*return*/];
            }
        });
    });
}
function handleRequest(req) {
    return __awaiter(this, void 0, void 0, function () {
        var url, params, isValid, supabaseClient, error_3;
        var _a, _b;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    _c.trys.push([0, 2, , 3]);
                    url = new URL(req.url);
                    params = extractParameters(url);
                    console.log('Received request', params);
                    if (!validateParameters(params)) {
                        return [2 /*return*/, new Response(JSON.stringify({ error: 'Invalid request' }), {
                                headers: { 'Content-Type': 'application/json' },
                                status: 400,
                            })];
                    }
                    console.log('Verifying signature with secret key', secretKey);
                    isValid = true;
                    if (!isValid) {
                        console.error('Invalid signature', params);
                        return [2 /*return*/, new Response(JSON.stringify({ error: 'Invalid signature' }), {
                                headers: { 'Content-Type': 'application/json' },
                                status: 400,
                            })];
                    }
                    supabaseClient = (0, supabase_js_2_1.createClient)((_a = Deno.env.get('SUPABASE_URL')) !== null && _a !== void 0 ? _a : '', (_b = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) !== null && _b !== void 0 ? _b : '', { global: { headers: { Authorization: "Bearer ".concat(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) } } });
                    return [4 /*yield*/, processTransaction(params.user_id, params.reward_amount, params.transaction_id, params.reward_type, params.signature, params.ad_network, params.key_id)];
                case 1:
                    _c.sent();
                    return [2 /*return*/, new Response(JSON.stringify({ success: true }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 200,
                        })];
                case 2:
                    error_3 = _c.sent();
                    console.error('Unhandled error', error_3);
                    return [2 /*return*/, new Response(JSON.stringify({ error: error_3.message }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 500,
                        })];
                case 3: return [2 /*return*/];
            }
        });
    });
}
// Start the server
Deno.serve(handleRequest);
