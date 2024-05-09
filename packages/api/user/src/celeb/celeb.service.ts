import {Injectable, Logger} from '@nestjs/common';
import {CelebEntity} from '../../../entities/celeb.entity';
import {Repository} from 'typeorm';
import {InjectRepository} from '@nestjs/typeorm';
import {paginate} from 'nestjs-typeorm-paginate';
import {UserEntity} from "../../../entities/user.entity";
import {BannerEntity} from "../../../entities/banner.entity";

@Injectable()
export class CelebService {
    private readonly logger = new Logger(CelebService.name);

    constructor(
        @InjectRepository(CelebEntity) private celebRepository: Repository<CelebEntity>,
        @InjectRepository(UserEntity) private userRepository: Repository<UserEntity>,
        @InjectRepository(BannerEntity) private celebBannerRepository: Repository<BannerEntity>,
    ) {
    }

    async findAll() {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user');

        return paginate<CelebEntity>(queryBuilder, {limit: 100, page: 1});
    }

    async findMine(id: number) {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user').where('user.id = :userId', {userId: id})
            .select(['celeb']);

        return paginate<CelebEntity>(queryBuilder, {limit: 100, page: 1});
    }

    async search(q: string) {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user')
            .where('celeb.nameKo like :q', {q: `%${q}%`});

        return paginate<CelebEntity>(queryBuilder, {limit: 100, page: 1});
    }

    async addBookmark(celebId: number, userId: number) {
        const celeb = await this.celebRepository.findOne({where: {id: celebId}, relations: ['users']});
        if (!celeb) {
            throw new Error('celeb not found');
        }

        const user = await this.userRepository.findOne({where: {id: userId}});
        if (!user) {
            throw new Error('user not found');
        }

        celeb.users.push(user);
        await this.celebRepository.save(celeb);
        return this.findAll();
    }

    async deleteBookmark(celebId: number, userId: number) {
        const celeb = await this.celebRepository.findOne({where: {id: celebId}, relations: ['users']});
        if (!celeb) {
            throw new Error('celeb not found');
        }

        const user = await this.userRepository.findOne({where: {id: userId}});
        if (!user) {
            throw new Error('user not found');
        }

        celeb.users = celeb.users.filter(u => u.id !== user.id);
        await this.celebRepository.save(celeb);
        return this.findAll();
    }

    async getBanners(celebId: number) {
        return paginate<BannerEntity>(this.celebBannerRepository, { limit: 100, page: 1}, { where: { celeb: { id: celebId } } });
    }
}
