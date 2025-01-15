export class OpenAIError extends Error {
    constructor(
        message: string,
        public readonly code: string = 'OPENAI_ERROR',
        public readonly status: number = 500,
        public readonly shouldRetry: boolean = false,
    ) {
        super(message);
        this.name = 'OpenAIError';
    }
}
