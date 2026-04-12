const TAG = '[waytwo]';

type LogFn = (message: string, extra?: Record<string, unknown>) => void;

function fmt(message: string, extra?: Record<string, unknown>): string {
  if (!extra) return `${TAG} ${message}`;
  return `${TAG} ${message} ${JSON.stringify(extra)}`;
}

// debug / info — dev only; warn / error — always (visible in device system logs too)
const noop: LogFn = () => {};

export const log = {
  debug: __DEV__ ? ((m, e) => console.debug(fmt(m, e))) satisfies LogFn : noop,
  info: __DEV__ ? ((m, e) => console.info(fmt(m, e))) satisfies LogFn : noop,
  warn: ((m, e) => console.warn(fmt(m, e))) satisfies LogFn,
  error: ((m, e) => console.error(fmt(m, e))) satisfies LogFn,
};
