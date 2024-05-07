import { Test, TestingModule } from '@nestjs/testing';
import { UpdateNicknameDto } from './dto/update-nickname.dto';
import { UserSlotCountDto } from './dto/user-slot-count.dto';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User } from '../../../libs/entities/src/entities/user.entity';
import { EmailDto } from './dto/email.dto';
import { UserIdDto } from './dto/user-id.dto';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UserInfoDto } from './dto/user-info.dto';
import { Provider, UserGrade } from './enums';
import { MessageDto } from '../auth/dto/message.dto';
import { Readable } from 'stream';
import { MatchPasswordDto } from './dto/match-password.dto';

const mockUsersService = {
  getSlotCount: (id: number) => {
    return Promise.resolve(new UserSlotCountDto(3));
  },
  findUserInfo: jest.fn(),
  updateNickname: (id: number, nickname: string) => {
    return new Promise<User>((resolve, reject) => {
      resolve(new User());
      reject(new Error());
    });
  },
  getUserIdByEmail: (email: string) => {
    return new Promise<User>((resolve, reject) => {
      resolve(new User());
      reject(new Error());
    });
  },
  isMatchedPassword: (userId: number, newPassword: string) => {
    return new Promise<boolean>((resolve, reject) => {
      resolve(false);
      reject(new Error());
    });
  },
  updatePassword: (id: number, newPassword: string) => {
    return new Promise<User>((resolve, reject) => {
      resolve(new User());
      reject(new Error());
    });
  },
  getNextSlotPrice: jest.fn(),
  doesUserHaveEnoughSstToOpenNewSlot: jest.fn(),
  openSlot: jest.fn(),
  isCorrectPassword: jest.fn(),
  deleteUser: jest.fn(),
  uploadProfileImage: jest.fn(),
  getUserSocialProvider: jest.fn(),
  createResetPasswordToken: jest.fn(),
  emailResetPassword: jest.fn(),
};

describe('UsersControllerTest', () => {
  let controller: UsersController;
  let service: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    controller = module.get<UsersController>(UsersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('getSlotCount returns user slot count', async () => {
    const req = {
      user: {
        id: 123,
        email: 'abc@gmail.com',
        nickname: 'ss',
        imgPath: 'https://cdn.com/image.jpg',
      },
    };
    const userSlotCountInfo = await controller.getSlotCount(req);

    expect(userSlotCountInfo.myOpenSlotCount).toBe(3);
  });

  it('findUserInfo returns user information', async () => {
    const req = {
      user: {
        id: 123,
        email: 'test@gmail.com',
        nickname: 'test',
        imgPath: 'https://cdn.com/image.jpg',
      },
    };

    const userInfo = new UserInfoDto(
      req.user.id,
      req.user.imgPath,
      req.user.nickname,
      req.user.email,
      UserGrade.PLAY,
      500,
      30,
      10,
    );

    jest.spyOn(service, 'findUserInfo').mockReturnValue(Promise.resolve(userInfo));

    const response = await controller.findUserInfo(req);

    expect(response.id).toBe(req.user.id);
    expect(response.email).toBe(req.user.email);
    expect(response.nickname).toBe(req.user.nickname);
    expect(response.userImg).toBe(req.user.imgPath);
    expect(response.grade).toBe(UserGrade.PLAY);
    expect(response.pointGst).toBe(500);
    expect(response.pointSst).toBe(30);
    expect(response.pointRight).toBe(10);
  });

  it('isMatchedMyEmail should return correct value', async () => {
    // given
    const req = {
      user: {
        id: 1234,
        email: 'leedo@email.com',
        nickname: 'Sejong',
        imgPath: 'https://cdn.com/thumbnail.jpg',
      },
    };

    // when
    const response = await controller.isMatchedMyEmail(req, 'leedo@email.com');

    // then
    expect(response).toBeInstanceOf(MessageDto);
    expect(response.message).toBe('User email matches');

    try {
      await controller.isMatchedMyEmail(req, 'wrong@email.com');
    } catch (e) {
      expect(e).toBeInstanceOf(BadRequestException);
      expect(e.response.statusCode).toBe(400);
      expect(e.response.message).toBe("User email doesn't match");
      expect(e.response.error).toBe('Bad Request');
    }
  });

  it('isMatchedMyPassword should return correct value', async () => {
    // given
    const req = {
      user: {
        id: 1234,
        email: 'leedo@email.com',
        nickname: 'Sejong',
        imgPath: 'https://cdn.com/thumbnail.jpg',
      },
    };

    const matchPasswordDto1 = new MatchPasswordDto();
    matchPasswordDto1.password = 'correctPassword';

    const matchPasswordDto2 = new MatchPasswordDto();
    matchPasswordDto2.password = 'correctPassword';

    // when
    jest.spyOn(service, 'isMatchedPassword').mockResolvedValueOnce(true).mockResolvedValueOnce(false);

    const response = await controller.isMatchedMyPassword(req, matchPasswordDto1);

    // then
    expect(response).toBeInstanceOf(MessageDto);
    expect(response.message).toBe('User password matches');

    try {
      await controller.isMatchedMyPassword(req, matchPasswordDto2);
    } catch (e) {
      expect(e).toBeInstanceOf(BadRequestException);
      expect(e.response.statusCode).toBe(400);
      expect(e.response.message).toBe("Password doesn't match");
      expect(e.response.error).toBe('Bad Request');
    }
  });

  it('updateNickname returns success code and message', async () => {
    const req = {
      user: {
        id: 123,
        email: 'test@gmail.com',
        nickname: 'test',
        imgPath: 'https://cdn.com/image.jpg',
      },
    };
    const body: UpdateNicknameDto = { nickname: 'test' };

    const response = await controller.updateNickname(req, body);

    expect(response.message).toBe('Successfully updated nickname');
  });

  describe('emailResetPassword group', () => {
    it('emailResetPassword should block user who signed via social', async () => {
      // given
      const body = new EmailDto('email@gmail.com');

      // when
      jest.spyOn(service, 'getUserSocialProvider').mockResolvedValue(Provider.GOOGLE);

      // then
      try {
        await controller.emailResetPassword(body);
        throw new Error();
      } catch (e) {
        expect(e).toBeInstanceOf(BadRequestException);
        expect(e.response.statusCode).toBe(400);
        expect(e.response.message).toBe('The user signed up via google');
        expect(e.response.error).toBe('Bad Request');
      }
    });

    it('emailResetPassword should return correct element', async () => {
      // given
      const body = new EmailDto('success@gmail.com');

      // when
      jest.spyOn(service, 'getUserSocialProvider').mockResolvedValue(undefined);
      jest
        .spyOn(service, 'createResetPasswordToken')
        .mockResolvedValue(
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NTkzODI3MiwiZW1haWwiOiJub2JlbDYwMThAZ21haWwuY29tIiwibmlja25hbWUiOiJyZWFsbHkzMyIsImltZ1BhdGgiOiJodHRwczovL2Nkbi5zdGFycGxheS5jby5rci9pbWcvb25haXItaW1nLWNvbW1lbnQtdW5zZXQucG5nIiwiaXNzIjoic3RhcnBsYXkiLCJ0eXBlIjoiUkVTRVRfUEFTU1dPUkRfVE9LRU4iLCJpYXQiOjE2Mzc5MTQ1MDAsImV4cCI6MTYzNzkxODEwMH0.aiYxcsXElGiDXS0goT_QfHWaKZ_00KFbt2TsWM3Lxdo',
        );
      jest.spyOn(service, 'emailResetPassword').mockResolvedValueOnce('abcd-abad').mockResolvedValueOnce(undefined);

      const response = await controller.emailResetPassword(body);
      const response2 = await controller.emailResetPassword(body);

      // then
      expect(response.message).toBe('Successfully sent email');
      expect(response2.message).toBe('Fail to send email');
    });
  });

  it('test findUserId', async () => {
    // given
    const user = new User();
    user.id = 123;
    user.email = 'leedo@gmail.com';
    user.userId = 'sejong';

    // when
    jest.spyOn(service, 'getUserIdByEmail').mockReturnValueOnce(Promise.resolve(user));

    const body = new EmailDto('leedo@gmail.com');
    const response = await controller.findUserId(body);

    // then
    expect(response.userId).toBe(user.userId);
    expect(response).toStrictEqual(new UserIdDto(user.userId));
  });

  it('test findUserId when there is no matching user', async () => {
    // given
    const user = new User();
    user.id = 123;
    user.email = 'leedo@gmail.com';
    user.userId = 'sejong';

    const notFoundEmail = 'no-user@gmail.com';

    // when
    jest.spyOn(service, 'getUserIdByEmail').mockImplementation(() => {
      throw new NotFoundException(`There is no user where email: ${notFoundEmail}`);
    });

    const body = new EmailDto(notFoundEmail);

    // then
    try {
      await controller.findUserId(body);
    } catch (e) {
      expect(e.message).toBe(`There is no user where email: ${notFoundEmail}`);
      expect(e).toStrictEqual(new NotFoundException(`There is no user where email: ${notFoundEmail}`));
    }
  });

  it('test resetPassword', async () => {
    // given
    const user = new User();
    user.id = 123;
    user.password = 'current-password';

    const req = {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        imgPath: user.imgPath,
      },
    };
    const body = new ResetPasswordDto('new-password');

    const updatedUser = Object.assign({}, user);
    updatedUser.password = '$a2$10$hashed-hashed-hashed';

    // when
    jest.spyOn(service, 'updatePassword').mockReturnValue(Promise.resolve(updatedUser));

    const response = await controller.resetPassword(req, body);

    // then
    expect(response.message).toBe('Successfully changed password');
  });

  it('test updatePassword API', async () => {
    // given
    const user = new User();
    user.id = 123;
    user.password = 'current-password';

    const req = {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        imgPath: user.imgPath,
      },
    };
    const body = new UpdatePasswordDto(user.password, 'new-password');

    const updatedUser = Object.assign({}, user);
    updatedUser.password = '$a2$10$hashed-hashed-hashed';

    // when
    jest.spyOn(service, 'isMatchedPassword').mockReturnValue(Promise.resolve(true));
    jest.spyOn(service, 'updatePassword').mockReturnValueOnce(Promise.resolve(updatedUser));

    const response = await controller.updatePassword(req, body);

    // then
    expect(response.message).toBe('Successfully changed password');
  });

  it(`updatePassword API should throw error when current password doesn't match`, async () => {
    // given
    const user = new User();
    user.id = 123;
    user.password = 'current-password';

    const req = {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        imgPath: user.imgPath,
      },
    };
    const body = new UpdatePasswordDto('not-matched-password', 'new-password');

    // when
    jest.spyOn(service, 'isMatchedPassword').mockReturnValue(Promise.resolve(false));

    // then
    try {
      await controller.updatePassword(req, body);
    } catch (e) {
      expect(e.message).toBe('Current password is not same');
    }
  });

  describe('openNewSlot group', () => {
    it('openNewSlot should throw error when user does not have enough sst', async () => {
      // given
      const req = {
        user: {
          id: 1234,
          email: 'leedo@email.com',
          nickname: 'Sejong',
          imgPath: 'https://cdn.com/thumbnail.jpg',
        },
      };

      const user = new User();
      user.id = 1234;
      user.pointSst = 20;
      user.myOpenSlotCount = 2;

      // when
      jest.spyOn(service, 'getNextSlotPrice').mockResolvedValue(30);
      jest.spyOn(service, 'doesUserHaveEnoughSstToOpenNewSlot').mockResolvedValue(false);

      // then
      try {
        await controller.openNewSlot(req);
      } catch (e) {
        expect(e).toBeInstanceOf(BadRequestException);
        expect(e.response.statusCode).toBe(400);
        expect(e.response.message).toBe(`User doesn't have enough SST to open new slot`);
        expect(e.response.error).toBe('Bad Request');
      }
    });

    it('openNewSlot should return correct elements', async () => {
      // given
      const req = {
        user: {
          id: 1234,
          email: 'leedo@email.com',
          nickname: 'Sejong',
          imgPath: 'https://cdn.com/thumbnail.jpg',
        },
      };

      // when
      jest.spyOn(service, 'getNextSlotPrice').mockResolvedValue(30);
      jest.spyOn(service, 'doesUserHaveEnoughSstToOpenNewSlot').mockResolvedValue(true);
      jest.spyOn(service, 'openSlot').mockResolvedValue(null);

      const response = await controller.openNewSlot(req);

      // then
      expect(response).toBeInstanceOf(MessageDto);
      expect(response.message).toBe('Successfully open new slot');
    });
  });

  describe('deleteUser group', () => {
    const req = {
      user: {
        id: 1234,
        email: 'leedo@email.com',
        nickname: 'Sejong',
        imgPath: 'https://cdn.com/thumbnail.jpg',
      },
    };

    it('deleteUser should throw error when password does not match', async () => {
      // given

      // when
      jest.spyOn(service, 'isCorrectPassword').mockResolvedValue(false);

      // then
      try {
        await controller.deleteUser(req);
      } catch (e) {
        expect(e).toBeInstanceOf(BadRequestException);
        expect(e.response.statusCode).toBe(400);
        expect(e.response.message).toBe('Password is not correct');
        expect(e.response.error).toBe('Bad Request');
      }
    });

    it('deleteUser should return correct element', async () => {
      // given

      // when
      jest.spyOn(service, 'isCorrectPassword').mockResolvedValue(true);
      jest.spyOn(service, 'deleteUser').mockResolvedValue(null);

      const response = await controller.deleteUser(req);

      // then
      expect(response).toBeInstanceOf(MessageDto);
      expect(response.message).toBe('Successfully deleted user');
    });
  });

  it('updateProfileImage should update user profile image', async () => {
    // given
    const req = {
      user: {
        id: 1234,
        email: 'leedo@email.com',
        nickname: 'Sejong',
        imgPath: 'https://cdn.com/thumbnail.jpg',
      },
    };

    const image: Express.Multer.File = {
      fieldname: 'image',
      originalname: 'andrew-donovan-valdivia-BG9i6c7Yp_4-unsplash.jpg',
      encoding: '7bit',
      mimetype: 'image/jpeg',
      buffer: Buffer.from('whatever'),
      size: 4005407,
      stream: Readable.from([]),
      destination: 'somewhere',
      filename: 'foo',
      path: 'bar',
    };

    const user = new User();
    user.id = 1234;
    user.imgPath = 'profile_1637738259.jpg';

    // when
    jest.spyOn(service, 'uploadProfileImage').mockResolvedValue(user);

    const response = await controller.updateProfileImage(image, req);

    // then
    expect(response).toBeInstanceOf(MessageDto);
    expect(response.message).toBe('Successfully saved profile image');
  });
});
