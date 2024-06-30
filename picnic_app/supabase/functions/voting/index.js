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
var mod_ts_1 = require("https://deno.land/x/postgres@v0.17.0/mod.ts");
var databaseUrl = Deno.env.get('SUPABASE_DB_URL');
var pool = new mod_ts_1.Pool(databaseUrl, 3, true);
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
function getUserProfiles(supabaseClient, user_id) {
    return __awaiter(this, void 0, void 0, function () {
        var _a, user_profiles, error, error_2;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _b.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, supabaseClient
                            .from('user_profiles')
                            .select('id, star_candy, star_candy_bonus')
                            .eq('id', user_id)
                            .single()];
                case 1:
                    _a = _b.sent(), user_profiles = _a.data, error = _a.error;
                    if (error) {
                        throw error;
                    }
                    return [2 /*return*/, { user_profiles: user_profiles, error: null }];
                case 2:
                    error_2 = _b.sent();
                    return [2 /*return*/, { user_profiles: null, error: error_2 }];
                case 3: return [2 /*return*/];
            }
        });
    });
}
function deductStarCandy(user_id, amount, vote_pick_id) {
    return __awaiter(this, void 0, void 0, function () {
        var rows, _a, id, star_candy;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0: return [4 /*yield*/, queryDatabase("\n        SELECT id, star_candy\n        FROM user_profiles\n        WHERE id = $1\n    ", user_id)];
                case 1:
                    rows = (_b.sent()).rows;
                    if (rows.length === 0) {
                        throw new Error('User not found');
                    }
                    _a = rows[0], id = _a.id, star_candy = _a.star_candy;
                    // Insert new record into star_candy_history for direct star_candy deduction
                    return [4 /*yield*/, queryDatabase("\n        INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)\n        VALUES ('VOTE', $1, $2, $3)\n    ", user_id, amount, vote_pick_id)];
                case 2:
                    // Insert new record into star_candy_history for direct star_candy deduction
                    _b.sent();
                    // Update user_profiles to deduct star_candy
                    return [4 /*yield*/, queryDatabase("\n        UPDATE user_profiles\n        SET star_candy = GREATEST(star_candy - $1, 0)\n        WHERE id = $2\n    ", amount, id)];
                case 3:
                    // Update user_profiles to deduct star_candy
                    _b.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function deductStarCandyBonus(user_id, amount, bonusId, vote_pick_id) {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, queryDatabase("\n        UPDATE star_candy_bonus_history\n        SET remain_amount = GREATEST(remain_amount - $1, 0),\n            updated_at    = NOW()\n        WHERE id = $2\n    ", amount, bonusId)];
                case 1:
                    _a.sent();
                    return [4 /*yield*/, queryDatabase("\n        INSERT INTO star_candy_bonus_history (user_id, amount, remain_amount, parent_id, vote_pick_id)\n        VALUES ($1, $2, $3, $4, $5)\n    ", user_id, amount, amount, bonusId, vote_pick_id)];
                case 2:
                    _a.sent();
                    // Update user_profiles to deduct star_candy_bonus
                    return [4 /*yield*/, queryDatabase("\n        UPDATE user_profiles\n        SET star_candy_bonus = GREATEST(star_candy_bonus - $1, 0)\n        WHERE id = $2\n    ", amount, user_id)];
                case 3:
                    // Update user_profiles to deduct star_candy_bonus
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function canVote(user_id, vote_amount, vote_pick_id) {
    return __awaiter(this, void 0, void 0, function () {
        var rows, _a, id, star_candy, star_candy_bonus, totalStarCandy, remainingAmount, bonusRows, _i, bonusRows_1, bonusRow, bonusId, bonusAmount, error_3;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _b.trys.push([0, 11, , 12]);
                    return [4 /*yield*/, queryDatabase("\n            SELECT id, star_candy, star_candy_bonus\n            FROM user_profiles\n            WHERE id = $1\n        ", user_id)];
                case 1:
                    rows = (_b.sent()).rows;
                    if (rows.length === 0) {
                        throw new Error('User not found');
                    }
                    _a = rows[0], id = _a.id, star_candy = _a.star_candy, star_candy_bonus = _a.star_candy_bonus;
                    totalStarCandy = star_candy + star_candy_bonus;
                    if (totalStarCandy < vote_amount || vote_amount <= 0) {
                        return [2 /*return*/, false];
                    }
                    remainingAmount = vote_amount;
                    if (!(star_candy_bonus > 0)) return [3 /*break*/, 8];
                    return [4 /*yield*/, queryDatabase("\n                SELECT id, remain_amount\n                FROM star_candy_bonus_history\n                WHERE user_id = $1\n                  AND expired_dt > NOW()\n                  AND remain_amount > 0\n                ORDER BY created_at ASC\n            ", user_id)];
                case 2:
                    bonusRows = (_b.sent()).rows;
                    _i = 0, bonusRows_1 = bonusRows;
                    _b.label = 3;
                case 3:
                    if (!(_i < bonusRows_1.length)) return [3 /*break*/, 8];
                    bonusRow = bonusRows_1[_i];
                    bonusId = bonusRow.id, bonusAmount = bonusRow.remain_amount;
                    if (remainingAmount <= 0)
                        return [3 /*break*/, 8];
                    if (!(bonusAmount >= remainingAmount)) return [3 /*break*/, 5];
                    return [4 /*yield*/, deductStarCandyBonus(user_id, remainingAmount, bonusId, vote_pick_id)];
                case 4:
                    _b.sent();
                    remainingAmount = 0;
                    return [3 /*break*/, 7];
                case 5: return [4 /*yield*/, deductStarCandyBonus(user_id, bonusAmount, bonusId, vote_pick_id)];
                case 6:
                    _b.sent();
                    remainingAmount -= bonusAmount;
                    _b.label = 7;
                case 7:
                    _i++;
                    return [3 /*break*/, 3];
                case 8:
                    if (!(remainingAmount > 0)) return [3 /*break*/, 10];
                    return [4 /*yield*/, deductStarCandy(user_id, remainingAmount, vote_pick_id)];
                case 9:
                    _b.sent();
                    _b.label = 10;
                case 10: return [2 /*return*/, true];
                case 11:
                    error_3 = _b.sent();
                    console.error('Error in canVote function:', error_3);
                    throw error_3;
                case 12: return [2 /*return*/];
            }
        });
    });
}
function performTransaction(connection, vote_id, vote_item_id, amount, user_id) {
    return __awaiter(this, void 0, void 0, function () {
        var votePickResult, vote_pick_id, canVoteResult, voteTotalResult, existingVoteTotal, error_4;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, connection.queryObject('BEGIN')];
                case 1:
                    _a.sent();
                    _a.label = 2;
                case 2:
                    _a.trys.push([2, 8, , 10]);
                    return [4 /*yield*/, queryDatabase("\n            INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id)\n            VALUES ($1, $2, $3, $4) RETURNING id\n        ", vote_id, vote_item_id, amount, user_id)];
                case 3:
                    votePickResult = _a.sent();
                    vote_pick_id = votePickResult.rows[0].id;
                    return [4 /*yield*/, canVote(user_id, amount, vote_pick_id)];
                case 4:
                    canVoteResult = _a.sent();
                    if (!canVoteResult) {
                        throw new Error('Insufficient star_candy and star_candy_bonus to vote');
                    }
                    // Update vote_item table with the new vote total
                    return [4 /*yield*/, queryDatabase("\n            UPDATE vote_item\n            SET vote_total = vote_total + $1\n            WHERE id = $2\n        ", amount, vote_item_id)];
                case 5:
                    // Update vote_item table with the new vote total
                    _a.sent();
                    return [4 /*yield*/, queryDatabase("\n            SELECT vote_total\n            FROM vote_item\n            WHERE id = $1\n        ", vote_item_id)];
                case 6:
                    voteTotalResult = _a.sent();
                    existingVoteTotal = voteTotalResult.rows.length > 0 ? voteTotalResult.rows[0].vote_total : 0;
                    // Commit the transaction
                    return [4 /*yield*/, connection.queryObject('COMMIT')];
                case 7:
                    // Commit the transaction
                    _a.sent();
                    connection.release();
                    return [2 /*return*/, {
                            existingVoteTotal: existingVoteTotal,
                            addedVoteTotal: amount,
                            updatedVoteTotal: existingVoteTotal + amount,
                            updatedAt: new Date().toISOString(),
                        }];
                case 8:
                    error_4 = _a.sent();
                    // Rollback transaction on error
                    return [4 /*yield*/, connection.queryObject('ROLLBACK')];
                case 9:
                    // Rollback transaction on error
                    _a.sent();
                    connection.release();
                    console.error('Error in performTransaction function:', error_4);
                    throw error_4;
                case 10: return [2 /*return*/];
            }
        });
    });
}
// Deno server setup
Deno.serve(function (req) { return __awaiter(void 0, void 0, void 0, function () {
    var supabaseClient, _a, vote_id, vote_item_id, amount, user_id, _b, user_profiles, userError, connection, transactionResult, e_1, error_5;
    var _c, _d, _e;
    return __generator(this, function (_f) {
        switch (_f.label) {
            case 0:
                supabaseClient = (0, supabase_js_2_1.createClient)((_c = Deno.env.get('SUPABASE_URL')) !== null && _c !== void 0 ? _c : '', (_d = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) !== null && _d !== void 0 ? _d : '', { global: { headers: { Authorization: (_e = req.headers.get('Authorization')) !== null && _e !== void 0 ? _e : '' } } });
                _f.label = 1;
            case 1:
                _f.trys.push([1, 10, , 11]);
                return [4 /*yield*/, req.json()];
            case 2:
                _a = _f.sent(), vote_id = _a.vote_id, vote_item_id = _a.vote_item_id, amount = _a.amount, user_id = _a.user_id;
                console.log('Request data:', { vote_id: vote_id, vote_item_id: vote_item_id, amount: amount, user_id: user_id });
                return [4 /*yield*/, getUserProfiles(supabaseClient, user_id)];
            case 3:
                _b = _f.sent(), user_profiles = _b.user_profiles, userError = _b.error;
                if (userError || !user_profiles) {
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'User not found or other error occurred' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                return [4 /*yield*/, pool.connect()];
            case 4:
                connection = _f.sent();
                _f.label = 5;
            case 5:
                _f.trys.push([5, 7, , 9]);
                return [4 /*yield*/, performTransaction(connection, vote_id, vote_item_id, amount, user_id)];
            case 6:
                transactionResult = _f.sent();
                return [2 /*return*/, new Response(JSON.stringify(transactionResult), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 200,
                    })];
            case 7:
                e_1 = _f.sent();
                return [4 /*yield*/, connection.queryObject('ROLLBACK')];
            case 8:
                _f.sent();
                connection.release();
                console.error('Error occurred during transaction:', e_1);
                throw e_1;
            case 9: return [3 /*break*/, 11];
            case 10:
                error_5 = _f.sent();
                console.error('Unexpected error occurred:', error_5);
                return [2 /*return*/, new Response(JSON.stringify({ error: 'Unexpected error occurred' }), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 500,
                    })];
            case 11: return [2 /*return*/];
        }
    });
}); });
