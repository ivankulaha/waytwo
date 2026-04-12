export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { logger } = await import('./src/lib/logger');

    process.on('uncaughtException', (err) => {
      logger.error('Uncaught exception', {
        message: err.message,
        stack: err.stack,
      });
    });

    process.on('unhandledRejection', (reason) => {
      const message =
        reason instanceof Error ? reason.message : String(reason);
      logger.error('Unhandled rejection', { message });
    });
  }
}
