const TAG = '[waytwo-api]';

type Extra = Record<string, unknown>;

function fmt(level: string, message: string, extra?: Extra): string {
  const base = `${TAG} ${level} ${message}`;
  return extra ? `${base} ${JSON.stringify(extra)}` : base;
}

export const logger = {
  debug: (message: string, extra?: Extra) => console.debug(fmt('DEBUG', message, extra)),
  info: (message: string, extra?: Extra) => console.info(fmt('INFO', message, extra)),
  warn: (message: string, extra?: Extra) => console.warn(fmt('WARN', message, extra)),
  error: (message: string, extra?: Extra) => console.error(fmt('ERROR', message, extra)),
};
