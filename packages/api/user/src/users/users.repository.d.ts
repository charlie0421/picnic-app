import { User } from '../../../libs/entities/src/entities/user.entity';
import { Repository } from 'typeorm';
import { Provider } from './enums';
export declare class UsersRepository extends Repository<User> {
    findById(id: number): Promise<User>;
    findByUserId(userId: string): Promise<User>;
    findByEmailAndProvider(email: string, provider: Provider): Promise<User>;
    findByProviderIdAndProvider(providerId: string, provider: Provider): Promise<User>;
    findByEmail(email: string): Promise<User>;
}
