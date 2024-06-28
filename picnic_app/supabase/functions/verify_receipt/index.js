"use strict";
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
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
// Setup type definitions for built-in Supabase Runtime APIs
require("https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts");
var supabase_js_1 = require("@supabase/supabase-js");
var supabaseUrl = process.env.SUPABASE_URL;
var supabaseKey = process.env.SUPABASE_SERVICE_KEY;
var supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseKey);
Deno.serve(function (req) { return __awaiter(void 0, void 0, void 0, function () {
    var _a, receipt, platform, response, data;
    return __generator(this, function (_b) {
        switch (_b.label) {
            case 0:
                _a = JSON.parse(event.body), receipt = _a.receipt, platform = _a.platform;
                if (!(platform === 'ios')) return [3 /*break*/, 2];
                return [4 /*yield*/, fetch('https://buy.itunes.apple.com/verifyReceipt', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            'receipt-data': receipt,
                            'password': 'your_shared_secret', // App Store Connect에서 생성한 공유 비밀번호
                        }),
                    })];
            case 1:
                response = _b.sent();
                return [3 /*break*/, 4];
            case 2:
                if (!(platform === 'android')) return [3 /*break*/, 4];
                return [4 /*yield*/, fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/packageName/purchases/products/productId/tokens/token', {
                        method: 'GET',
                        headers: {
                            'Authorization': "Bearer ".concat(process.env.GOOGLE_API_KEY), // Google API Key
                        },
                    })];
            case 3:
                response = _b.sent();
                _b.label = 4;
            case 4: return [4 /*yield*/, response.json()];
            case 5:
                data = _b.sent();
                if (!(response.status === 200 && (platform === 'ios' ? data.status === 0 : true))) return [3 /*break*/, 7];
                // 영수증이 유효함
                return [4 /*yield*/, supabase
                        .from('receipts')
                        .insert([{ receipt_data: receipt, status: 'valid', platform: platform }])];
            case 6:
                // 영수증이 유효함
                _b.sent();
                return [2 /*return*/, {
                        statusCode: 200,
                        body: JSON.stringify({ success: true, data: data }),
                    }];
            case 7: 
            // 영수증이 유효하지 않음
            return [4 /*yield*/, supabase
                    .from('receipts')
                    .insert([{ receipt_data: receipt, status: 'invalid', platform: platform }])];
            case 8:
                // 영수증이 유효하지 않음
                _b.sent();
                return [2 /*return*/, {
                        statusCode: 400,
                        body: JSON.stringify({ success: false, data: data }),
                    }];
        }
    });
}); });
/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/verify_receipt' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
