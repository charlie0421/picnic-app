import {EntityRepository, Repository} from 'typeorm';
import {UserEntity} from "../../../entities/user.entity";

@EntityRepository(UserEntity)
export class UsersRepository extends Repository<UserEntity> {
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
