export interface Prompt {
    id: string;
    name: string;
    template: string;
    version: number;
    model_config: {
        model: string;
        temperature: number;
        system_prompt: string;
        response_format?: string;
    };
    variables: string[];
    is_active: boolean;
}

export interface PromptUsageLog {
    prompt_id: string;
    variables: Record<string, any>;
    response: any;
    execution_time_ms?: number;
    token_count?: number;
    error?: string;
}
