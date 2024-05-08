import {Injectable, Logger} from '@nestjs/common';
import {Celeb} from '../../../entities/celeb.entity';
import {Repository} from 'typeorm';
import {InjectRepository} from '@nestjs/typeorm';
import {paginate} from 'nestjs-typeorm-paginate';
import {UserEntity} from "../../../entities/user.entity";
import {CelebBanner} from "../../../entities/celeb_banner.entity";

@Injectable()
export class CelebService {
    private readonly logger = new Logger(CelebService.name);

    constructor(
        @InjectRepository(Celeb) private celebRepository: Repository<Celeb>,
        @InjectRepository(UserEntity) private userRepository: Repository<UserEntity>,
        @InjectRepository(CelebBanner) private celebBannerRepository: Repository<CelebBanner>,
    ) {
    }

    async findAll() {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user');

        return paginate<Celeb>(queryBuilder, {limit: 100, page: 1});
    }

    async findMine(id: number) {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user').where('user.id = :userId', {userId: id})
            .select(['celeb']);

        return paginate<Celeb>(queryBuilder, {limit: 100, page: 1});
    }

    async search(q: string) {
        const queryBuilder = this.celebRepository.createQueryBuilder('celeb')
            .leftJoinAndSelect('celeb.users', 'user')
            .where('celeb.nameKo like :q', {q: `%${q}%`});

        return paginate<Celeb>(queryBuilder, {limit: 100, page: 1});
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
        return paginate<CelebBanner>(this.celebBannerRepository, { limit: 100, page: 1}, { where: { celeb: { id: celebId } } });
    }
}
