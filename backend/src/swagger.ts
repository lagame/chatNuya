import { Express } from 'express';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

export function setupSwagger(app: Express): void {
  const options: swaggerJsdoc.Options = {
    definition: {
      openapi: '3.0.3',
      info: {
        title: 'NUYA API',
        version: '1.0.0',
        description: 'Backend API documentation for NUYA chat application',
      },
      servers: [
        { url: '/', description: 'Current host' },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
        schemas: {
          User: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              username: { type: 'string', example: 'lagame' },
              email: { type: 'string', example: 'lagame@example.com' },
              birthDate: { type: 'string', nullable: true, example: '1979-03-20' },
              gender: { type: 'string', nullable: true, example: 'Male' },
              avatarUrl: { type: 'string', nullable: true, example: '/uploads/avatar-123.png' },
              language: { type: 'string', nullable: true, example: 'pt-BR' },
            },
          },
          AuthResponse: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: { $ref: '#/components/schemas/User' },
            },
          },
          ErrorResponse: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
      paths: {
        '/health': {
          get: {
            tags: ['System'],
            summary: 'Health check',
            responses: {
              '200': { description: 'Server is healthy' },
            },
          },
        },
        '/register': {
          post: {
            tags: ['Auth'],
            summary: 'Register a new user',
            requestBody: {
              required: true,
              content: {
                'multipart/form-data': {
                  schema: {
                    type: 'object',
                    required: ['username', 'email', 'password'],
                    properties: {
                      username: { type: 'string' },
                      email: { type: 'string' },
                      password: { type: 'string' },
                      birthDate: { type: 'string', nullable: true },
                      gender: { type: 'string', nullable: true },
                      language: { type: 'string', nullable: true },
                      avatar: { type: 'string', format: 'binary' },
                    },
                  },
                },
              },
            },
            responses: {
              '201': {
                description: 'User registered successfully',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/AuthResponse' },
                  },
                },
              },
              '400': {
                description: 'Validation error',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/ErrorResponse' },
                  },
                },
              },
            },
          },
        },
        '/login': {
          post: {
            tags: ['Auth'],
            summary: 'Login with username/email and password',
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['identifier', 'password'],
                    properties: {
                      identifier: { type: 'string' },
                      password: { type: 'string' },
                    },
                  },
                },
              },
            },
            responses: {
              '200': {
                description: 'Login success',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/AuthResponse' },
                  },
                },
              },
              '401': {
                description: 'Invalid credentials',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/ErrorResponse' },
                  },
                },
              },
            },
          },
        },
        '/users': {
          get: {
            tags: ['Users'],
            summary: 'Get all users',
            security: [{ bearerAuth: [] }],
            responses: {
              '200': {
                description: 'User list',
                content: {
                  'application/json': {
                    schema: {
                      type: 'array',
                      items: { $ref: '#/components/schemas/User' },
                    },
                  },
                },
              },
            },
          },
        },
        '/users/{id}': {
          get: {
            tags: ['Users'],
            summary: 'Get user by id (self only)',
            security: [{ bearerAuth: [] }],
            parameters: [
              {
                name: 'id',
                in: 'path',
                required: true,
                schema: { type: 'integer' },
              },
            ],
            responses: {
              '200': {
                description: 'User found',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/User' },
                  },
                },
              },
              '403': { description: 'Forbidden' },
            },
          },
        },
        '/users/{id}/language': {
          put: {
            tags: ['Users'],
            summary: 'Update user language (self only)',
            security: [{ bearerAuth: [] }],
            parameters: [
              {
                name: 'id',
                in: 'path',
                required: true,
                schema: { type: 'integer' },
              },
            ],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['language'],
                    properties: {
                      language: { type: 'string', example: 'pt-BR' },
                    },
                  },
                },
              },
            },
            responses: {
              '200': {
                description: 'Updated user',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/User' },
                  },
                },
              },
            },
          },
        },
        '/contacts/{userId}': {
          get: {
            tags: ['Contacts'],
            summary: 'Get contacts for a user (self only)',
            security: [{ bearerAuth: [] }],
            parameters: [
              {
                name: 'userId',
                in: 'path',
                required: true,
                schema: { type: 'integer' },
              },
            ],
            responses: {
              '200': {
                description: 'Contact list',
                content: {
                  'application/json': {
                    schema: {
                      type: 'array',
                      items: { $ref: '#/components/schemas/User' },
                    },
                  },
                },
              },
            },
          },
        },
        '/contacts': {
          post: {
            tags: ['Contacts'],
            summary: 'Add contact by username/email (self only)',
            security: [{ bearerAuth: [] }],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['userId', 'query'],
                    properties: {
                      userId: { type: 'integer' },
                      query: { type: 'string' },
                    },
                  },
                },
              },
            },
            responses: {
              '200': {
                description: 'Added contact',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/User' },
                  },
                },
              },
            },
          },
        },
      },
    },
    apis: [],
  };

  const spec = swaggerJsdoc(options);

  app.get('/docs.json', (_req, res) => {
    res.json(spec);
  });

  app.use('/docs', swaggerUi.serve, swaggerUi.setup(spec));
}
