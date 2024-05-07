"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersRepository = void 0;
const user_entity_1 = require("../../../libs/entities/src/entities/user.entity");
const typeorm_1 = require("typeorm");
let UsersRepository = class UsersRepository extends typeorm_1.Repository {
    async findById(id) {
        return this.findOne({
            where: { id },
        });
    }
    async findByUserId(userId) {
        return this.findOne({
            where: { userId: userId },
        });
    }
    async findByEmailAndProvider(email, provider) {
        return this.findOne({
            where: { email: email, provider: provider },
        });
    }
    async findByProviderIdAndProvider(providerId, provider) {
        return this.findOne({
            where: { providerId: providerId, provider },
        });
    }
    async findByEmail(email) {
        return this.findOne({
            where: { email },
        });
    }
};
UsersRepository = __decorate([
    (0, typeorm_1.EntityRepository)(user_entity_1.User)
], UsersRepository);
exports.UsersRepository = UsersRepository;
//# sourceMappingURL=users.repository.js.map