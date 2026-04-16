import { logger } from '@/lib/logger';

export async function register() {
  const runtime = process.env.NEXT_RUNTIME ?? 'unknown';
  logger.info('Instrumentation register invoked', { runtime });

  if (process.env.NEXT_RUNTIME === 'nodejs') {
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

    const keyVaultEnabled = Boolean(process.env.AZURE_KEYVAULT_URL?.trim());
    logger.info('Startup secret source resolved', { keyVaultEnabled });

    if (keyVaultEnabled) {
      logger.info('Key Vault bootstrap starting');
      const { preloadAll, startRefreshLoop } = await import('@/lib/secrets');
      await preloadAll();
      logger.info('Key Vault preload finished');
      startRefreshLoop();
      logger.info('Key Vault refresh loop initialized');
    } else {
      logger.info('Key Vault disabled; using environment-provided secrets');
    }
  }
}
