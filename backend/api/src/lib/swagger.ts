import swaggerJSDoc from 'swagger-jsdoc';

const apis = ['./src/app/api/**/*.ts'];

export const swaggerDefinition: swaggerJSDoc.OAS3Definition = {
  openapi: '3.0.3',
  info: {
    title: 'WayTwo API',
    version: '1.0.0',
    description: 'Versioned HTTP API under /api/v1',
  },
  servers: [{ url: '/', description: 'Current server' }],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Supabase access token (Authorization: Bearer)',
      },
    },
  },
  tags: [
    { name: 'Health', description: 'Health check' },
    { name: 'User', description: 'Current user' },
  ],
};

const options: swaggerJSDoc.Options = {
  definition: swaggerDefinition,
  apis,
};

export function getOpenAPISpec(): object {
  return swaggerJSDoc(options) as object;
}
