import { Module, Global } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { redisStore } from 'cache-manager-redis-yet';
import { ConfigModule, ConfigService } from '@nestjs/config';

/**
 * Global Redis Cache Module
 * Provides caching capabilities across the entire application
 */
@Global()
@Module({
  imports: [
    CacheModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      isGlobal: true,
      useFactory: async (configService: ConfigService) => {
        const redisHost = configService.get('REDIS_HOST', 'localhost');
        const redisPort = configService.get('REDIS_PORT', 6379);
        const cacheTTL = configService.get('CACHE_TTL', 60);

        console.log(`[RedisModule] Attempting to connect to Redis at ${redisHost}:${redisPort}`);

        try {
          const store = await redisStore({
            socket: {
              host: redisHost,
              port: parseInt(redisPort.toString(), 10),
            },
          });

          console.log('✅ Redis cache store connected successfully');
          
          return {
            store,
            ttl: cacheTTL * 1000, // Convert to milliseconds
          };
        } catch (error) {
          console.error('❌ Redis cache store connection failed:', error.message);
          console.warn('⚠️  Falling back to in-memory cache');
          console.warn('   Make sure Redis is running: docker-compose up -d redis');
          
          // Fallback to in-memory cache if Redis is unavailable
          return {
            ttl: cacheTTL * 1000,
          };
        }
      },
    }),
  ],
  exports: [CacheModule],
})
export class RedisModule {}
