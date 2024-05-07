import type { ArgumentMetadata, PipeTransform } from '@nestjs/common';
import { Injectable } from '@nestjs/common';

@Injectable()
export class ParseArrayPipe implements PipeTransform {
  transform(value: unknown, metadata: ArgumentMetadata) {
    if (!value) {
      return value;
    }

    return Array.isArray(value) ? value : [value];
  }
}
