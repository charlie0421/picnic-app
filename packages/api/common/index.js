import * as baseError from './base-error'
import * as decorators from './decorators';
import * as enums from './enums';
import { ErrorInterceptor } from './error-interceptor';
import { HttpExceptionFilter } from './http-exception.filter';
import { ParseArrayPipe } from './parse-array.pipe';
import { swaggerConfig } from './swagger.config';
import * as types from './types';

// export const decorators = decoratorsModule;
module.exports = {
  ...baseError,
  decorators,
  enums,
  ErrorInterceptor,
  HttpExceptionFilter,
  ParseArrayPipe,
  swaggerConfig,
  ...types,
};
