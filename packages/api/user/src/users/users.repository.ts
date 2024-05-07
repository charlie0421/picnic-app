import {EntityRepository, Repository} from 'typeorm';
import {PrameUserEntity} from "../../../entities/prame-user.entity";

@EntityRepository(PrameUserEntity)
export class UsersRepository extends Repository<PrameUserEntity> {
    async findById(id: number) {
        return this.findOne({
            where: {id},
        });
    }

    async findByEmail(email: string) {
        return this.findOne({
            where: {email},
        });
    }
}
