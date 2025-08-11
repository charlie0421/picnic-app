export class OpenAIError extends Error {
  code;
  status;
  shouldRetry;
  constructor(message, code = 'OPENAI_ERROR', status = 500, shouldRetry = false){
    super(message);
    this.code = code;
    this.status = status;
    this.shouldRetry = shouldRetry;
    this.name = 'OpenAIError';
  }
}
