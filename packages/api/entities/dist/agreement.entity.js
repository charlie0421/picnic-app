"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Agreement = void 0;
const typeorm_1 = require("typeorm");
const base_entitiy_1 = require("./base.entitiy");
let Agreement = class Agreement extends base_entitiy_1.BaseEntitiy {
};
exports.Agreement = Agreement;
__decorate([
    (0, typeorm_1.Column)({ name: 'type', type: 'varchar', length: 255 }),
    __metadata("design:type", String)
], Agreement.prototype, "type", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'title', type: 'varchar', length: 255 }),
    __metadata("design:type", String)
], Agreement.prototype, "title", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'content', type: 'text' }),
    __metadata("design:type", String)
], Agreement.prototype, "content", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'version', type: 'varchar', length: 255 }),
    __metadata("design:type", String)
], Agreement.prototype, "version", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'effective_date', type: 'datetime' }),
    __metadata("design:type", Date)
], Agreement.prototype, "effectiveDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_required', type: 'boolean' }),
    __metadata("design:type", Boolean)
], Agreement.prototype, "isRequired", void 0);
exports.Agreement = Agreement = __decorate([
    (0, typeorm_1.Entity)('agreement')
], Agreement);
//# sourceMappingURL=agreement.entity.js.map