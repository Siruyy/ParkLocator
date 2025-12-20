/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { Test, TestingModule } from '@nestjs/testing';
import { ReportsService } from './reports.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Reservation, ReservationStatus } from '../reservations/entities/reservation.entity';
import { DataSource } from 'typeorm';
import { UserRole } from '../users/entities/user.entity';

describe('ReportsService', () => {
  let service: ReportsService;
  let repositoryMock: any;
  let dataSourceMock: any;

  beforeEach(async () => {
    const queryBuilderMock = {
      select: jest.fn().mockReturnThis(),
      addSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      groupBy: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      getRawOne: jest.fn(),
      getCount: jest.fn(),
      getRawMany: jest.fn(),
    };

    repositoryMock = {
      createQueryBuilder: jest.fn().mockReturnValue(queryBuilderMock),
      findAndCount: jest.fn(),
    };

    dataSourceMock = {};

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        {
          provide: getRepositoryToken(Reservation),
          useValue: repositoryMock,
        },
        {
          provide: DataSource,
          useValue: dataSourceMock,
        },
      ],
    }).compile();

    service = module.get<ReportsService>(ReportsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getFinanceSummary', () => {
    it('should filter by venueId for MANAGER', async () => {
      const user = { role: UserRole.MANAGER, venueId: 'venue-123' };
      const queryBuilder = repositoryMock.createQueryBuilder();
      queryBuilder.getRawOne.mockResolvedValue({ sum: '100' });
      queryBuilder.getCount.mockResolvedValue(5);

      await service.getFinanceSummary(user);

      expect(queryBuilder.andWhere).toHaveBeenCalledWith('r.venueId = :venueId', { venueId: 'venue-123' });
    });

    it('should NOT filter by venueId for SUPER_ADMIN', async () => {
      const user = { role: UserRole.SUPER_ADMIN };
      const queryBuilder = repositoryMock.createQueryBuilder();
      queryBuilder.getRawOne.mockResolvedValue({ sum: '100' });
      queryBuilder.getCount.mockResolvedValue(5);

      await service.getFinanceSummary(user);

      // Check that andWhere was NOT called with venueId
      const calls = queryBuilder.andWhere.mock.calls;
      const venueCall = calls.find(call => call[0].includes('venueId'));
      expect(venueCall).toBeUndefined();
    });
  });

  describe('getTransactions', () => {
    it('should filter by venueId for MANAGER', async () => {
      const user = { role: UserRole.MANAGER, venueId: 'venue-123' };
      repositoryMock.findAndCount.mockResolvedValue([[], 0]);

      await service.getTransactions(1, 10, user);

      expect(repositoryMock.findAndCount).toHaveBeenCalledWith(expect.objectContaining({
        where: { venue: { id: 'venue-123' } }
      }));
    });

    it('should NOT filter by venueId for SUPER_ADMIN', async () => {
      const user = { role: UserRole.SUPER_ADMIN };
      repositoryMock.findAndCount.mockResolvedValue([[], 0]);

      await service.getTransactions(1, 10, user);

      expect(repositoryMock.findAndCount).toHaveBeenCalledWith(expect.objectContaining({
        where: {}
      }));
    });
  });
});
