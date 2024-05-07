"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicUserDto = void 0;
class BasicUserDto {
    uid;
    id;
    nickname;
    email;
    imgPath;
    provider;
    role;
    constructor(uid, id, nickname, email, imgPath, provider, role) {
        this.uid = uid;
        this.id = id;
        this.nickname = nickname;
        this.email = email;
        this.imgPath = imgPath;
        this.provider = provider;
        this.role = role;
    }
}
exports.BasicUserDto = BasicUserDto;
//# sourceMappingURL=basic-user.dto.js.map