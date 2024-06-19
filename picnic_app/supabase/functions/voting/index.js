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
var databaseUrl = Deno.env.get('SUPABASE_DB_URL');
var pool = new postgres.Pool(databaseUrl, 3, true);
Deno.serve(function (req) { return __awaiter(void 0, void 0, void 0, function () {
    var supabaseClient, _a, vote_id, vote_item_id, amount, user_id, _b, user_profiles, userError, connection, insertVoteQuery, vote_pick, vote_pick_id, existingVoteRows, existingVoteTotal, updateVoteQuery, updateUserQuery, insertHistoryQuery, e_1, error_1;
    var _c, _d;
    return __generator(this, function (_e) {
        switch (_e.label) {
            case 0:
                _e.trys.push([0, 15, , 16]);
                supabaseClient = (0, supabase_js_2_1.createClient)((_c = Deno.env.get('SUPABASE_URL')) !== null && _c !== void 0 ? _c : '', (_d = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) !== null && _d !== void 0 ? _d : '', { global: { headers: { Authorization: req.headers.get('Authorization') } } });
                return [4 /*yield*/, req.json()];
            case 1:
                _a = _e.sent(), vote_id = _a.vote_id, vote_item_id = _a.vote_item_id, amount = _a.amount, user_id = _a.user_id;
                console.log('Request data:', { vote_id: vote_id, vote_item_id: vote_item_id, amount: amount, user_id: user_id });
                return [4 /*yield*/, supabaseClient
                        .from('user_profiles')
                        .select('star_candy')
                        .eq('id', user_id)
                        .single()];
            case 2:
                _b = _e.sent(), user_profiles = _b.data, userError = _b.error;
                if (userError || !user_profiles) {
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'User not found or other error occurred' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                if (amount < 0 || user_profiles.star_candy < amount) {
                    return [2 /*return*/, new Response(JSON.stringify({ error: 'Invalid amount or insufficient star_candy' }), {
                            headers: { 'Content-Type': 'application/json' },
                            status: 400,
                        })];
                }
                return [4 /*yield*/, pool.connect()];
            case 3:
                connection = _e.sent();
                _e.label = 4;
            case 4:
                _e.trys.push([4, 12, , 14]);
                return [4 /*yield*/, connection.queryObject('BEGIN')];
            case 5:
                _e.sent();
                insertVoteQuery = "INSERT INTO vote_pick (vote_id, vote_item_id, amount, user_id)\n                                             VALUES ($1, $2, $3, $4) RETURNING id";
                return [4 /*yield*/, connection.queryObject(insertVoteQuery, [vote_id, vote_item_id, amount, user_id])];
            case 6:
                vote_pick = _e.sent();
                console.log(vote_pick);
                vote_pick_id = void 0;
                if (vote_pick.rows.length > 0) {
                    vote_pick_id = vote_pick.rows[0].id;
                }
                else {
                    // Handle the case where no rows were inserted
                    console.error('No rows were inserted');
                }
                return [4 /*yield*/, connection.queryObject("SELECT vote_total\n                 FROM vote_item\n                 WHERE id = $1", [vote_item_id])];
            case 7:
                existingVoteRows = (_e.sent()).rows;
                existingVoteTotal = existingVoteRows.length > 0 ? existingVoteRows[0].vote_total : 0;
                // 투표수 업데이트
                console.log('Updating vote total');
                updateVoteQuery = "UPDATE vote_item\n                                             SET vote_total = vote_total + $1\n                                             WHERE id = $2";
                return [4 /*yield*/, connection.queryObject(updateVoteQuery, [amount, vote_item_id])];
            case 8:
                _e.sent();
                // 사용자 포인트 차감
                console.log('Updating user rewards');
                updateUserQuery = "UPDATE user_profiles\n                                             SET star_candy = star_candy - $1\n                                             WHERE id = $2";
                return [4 /*yield*/, connection.queryObject(updateUserQuery, [amount, user_id])];
            case 9:
                _e.sent();
                // 히스토리 저장
                console.log('Inserting star_candy history');
                insertHistoryQuery = "INSERT INTO star_candy_history (type, user_id, amount, vote_pick_id)\n                                                VALUES ($1, $2, $3, $4)";
                return [4 /*yield*/, connection.queryObject(insertHistoryQuery, ['VOTE', user_id, amount, vote_pick_id])];
            case 10:
                _e.sent();
                return [4 /*yield*/, connection.queryObject('COMMIT')];
            case 11:
                _e.sent();
                connection.release();
                return [2 /*return*/, new Response(JSON.stringify({
                        existingVoteTotal: existingVoteTotal,
                        addedVoteTotal: amount,
                        updatedVoteTotal: existingVoteTotal + amount,
                        updatedAt: new Date().toISOString(),
                    }), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 200,
                    })];
            case 12:
                e_1 = _e.sent();
                return [4 /*yield*/, connection.queryObject('ROLLBACK')];
            case 13:
                _e.sent();
                connection.release();
                throw e_1;
            case 14: return [3 /*break*/, 16];
            case 15:
                error_1 = _e.sent();
                console.error('Unhandled error', error_1);
                return [2 /*return*/, new Response(JSON.stringify({ error: error_1.message }), {
                        headers: { 'Content-Type': 'application/json' },
                        status: 500,
                    })];
            case 16: return [2 /*return*/];
        }
    });
}); });
