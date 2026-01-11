import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { ConfigService } from '@nestjs/config';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class EventsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private logger: Logger = new Logger('EventsGateway');

  constructor(private configService: ConfigService) {}

  async afterInit(server: Server) {
    this.logger.log('WebSocket Gateway initialized');
    
    // Configure Redis Adapter for horizontal scaling
    try {
      const redisHost = this.configService.get('REDIS_HOST', 'localhost');
      const redisPort = this.configService.get('REDIS_PORT', 6379);
      
      const pubClient = createClient({
        socket: {
          host: redisHost,
          port: parseInt(redisPort.toString(), 10),
        },
      });
      
      const subClient = pubClient.duplicate();
      
      await Promise.all([pubClient.connect(), subClient.connect()]);
      
      server.adapter(createAdapter(pubClient, subClient));
      
      this.logger.log('✅ Redis adapter connected for Socket.io (multi-instance ready)');
    } catch (error) {
      this.logger.warn('⚠️  Could not connect Redis adapter for Socket.io');
      this.logger.warn('   WebSockets will work locally but won\'t scale across multiple instances');
      this.logger.warn(`   Error: ${error.message}`);
      this.logger.warn('   Make sure Redis is running: docker-compose up -d redis');
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  handleConnection(client: Socket, ...args: any[]) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  emitVenueUpdate(venueId: string, data: any) {
    this.server.emit(`venue:${venueId}`, data);
  }

  emitLevelUpdate(levelId: string, data: any) {
    this.server.emit(`level:${levelId}`, data);
  }
}
