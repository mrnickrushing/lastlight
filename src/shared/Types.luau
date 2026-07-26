--!strict

export type EnvironmentName = "local" | "test" | "staging" | "production"
export type LogLevel = "debug" | "info" | "warn" | "error"
export type LogFields = { [string]: any }

export type Logger = {
    debug: (self: Logger, event: string, fields: LogFields?) -> (),
    info: (self: Logger, event: string, fields: LogFields?) -> (),
    warn: (self: Logger, event: string, fields: LogFields?) -> (),
    error: (self: Logger, event: string, fields: LogFields?) -> (),
}

export type FeatureFlagReader = {
    isEnabled: (self: FeatureFlagReader, flag: string) -> boolean,
}

export type ServiceContext = {
    environment: EnvironmentName,
    logger: Logger,
    featureFlags: FeatureFlagReader,
}

export type Service = {
    Name: string,
    Init: ((self: any, context: ServiceContext) -> ())?,
    Start: ((self: any) -> ())?,
}

return {}
