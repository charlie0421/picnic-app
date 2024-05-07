import { Exclude, Expose } from 'class-transformer';

@Exclude()
export class UserSlotCountDto {
  @Expose()
  readonly myOpenSlotCount: number;

  constructor(myOpenSlotCount: number) {
    this.myOpenSlotCount = myOpenSlotCount;
  }
}
