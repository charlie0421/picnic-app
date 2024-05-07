"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TokenType = exports.EmailType = exports.UserGrade = exports.Provider = void 0;
var Provider;
(function (Provider) {
    Provider["GOOGLE"] = "google";
    Provider["KAKAOTALK"] = "kakaotalk";
    Provider["FACEBOOK"] = "facebook";
    Provider["APPLE"] = "apple";
})(Provider || (exports.Provider = Provider = {}));
var UserGrade;
(function (UserGrade) {
    UserGrade["PLAY"] = "PLAY";
    UserGrade["PLUS"] = "PLUS";
    UserGrade["PRIME"] = "PRIME";
    UserGrade["PRIME_S"] = "PRIME_S";
})(UserGrade || (exports.UserGrade = UserGrade = {}));
var EmailType;
(function (EmailType) {
    EmailType["FIND_PASSWORD"] = "FIND_PASSWORD";
})(EmailType || (exports.EmailType = EmailType = {}));
var TokenType;
(function (TokenType) {
    TokenType["ACCESS_TOKEN"] = "ACCESS_TOKEN";
    TokenType["REFRESH_TOKEN"] = "REFRESH_TOKEN";
    TokenType["RESET_PASSWORD_TOKEN"] = "RESET_PASSWORD_TOKEN";
})(TokenType || (exports.TokenType = TokenType = {}));
//# sourceMappingURL=enums.js.map