"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateVoteDto = void 0;
const mapped_types_1 = require("@nestjs/mapped-types");
const create_vote_dto_1 = require("./create-vote.dto");
class UpdateVoteDto extends (0, mapped_types_1.PartialType)(create_vote_dto_1.CreateVoteDto) {
}
exports.UpdateVoteDto = UpdateVoteDto;
//# sourceMappingURL=update-vote.dto.js.map