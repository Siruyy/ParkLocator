import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UseGuards,
  Request,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ReservationsService } from './reservations.service';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('reservations')
@UseGuards(JwtAuthGuard)
export class ReservationsController {
  constructor(private readonly reservationsService: ReservationsService) {}

  @Post()
  async create(
    @Request() req,
    @Body() createReservationDto: CreateReservationDto,
  ) {
    const reservation = await this.reservationsService.create(
      req.user.userId,
      createReservationDto,
    );

    return {
      success: true,
      data: this.transformReservation(reservation),
      message: 'Reservation created successfully',
    };
  }

  @Get('admin/all')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async findAllAdmin(@Request() req) {
    const reservations = await this.reservationsService.findAllForAdmin(req.user);

    return {
      success: true,
      data: reservations.map((r) => this.transformReservation(r)),
      meta: { count: reservations.length },
    };
  }

  @Get()
  async findAll(@Request() req) {
    const reservations = await this.reservationsService.findAllByUser(
      req.user.userId,
    );

    return {
      success: true,
      data: reservations.map((r) => this.transformReservation(r)),
      meta: { count: reservations.length },
    };
  }

  @Get('active')
  async findActive(@Request() req) {
    const reservations = await this.reservationsService.findActiveByUser(
      req.user.userId,
    );

    return {
      success: true,
      data: reservations.map((r) => this.transformReservation(r)),
      meta: { count: reservations.length },
    };
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const reservation = await this.reservationsService.findOne(id);

    return {
      success: true,
      data: this.transformReservation(reservation),
    };
  }

  @Delete(':id')
  async cancel(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    const reservation = await this.reservationsService.cancel(id, req.user.userId);

    return {
      success: true,
      data: this.transformReservation(reservation),
      message: 'Reservation cancelled successfully',
    };
  }

  @Post('check-in/:qrCode')
  async checkIn(@Param('qrCode') qrCode: string) {
    const reservation = await this.reservationsService.checkIn(qrCode);

    return {
      success: true,
      data: this.transformReservation(reservation),
      message: 'Check-in successful',
    };
  }

  @Post('check-out/:qrCode')
  async checkOut(@Param('qrCode') qrCode: string) {
    const reservation = await this.reservationsService.checkOut(qrCode);

    return {
      success: true,
      data: this.transformReservation(reservation),
      message: 'Check-out successful',
    };
  }

  private transformReservation(reservation: any) {
    return {
      id: reservation.id,
      status: reservation.status,
      amount: parseFloat(reservation.amount),
      durationHours: reservation.durationHours,
      arrivalWindowMinutes: reservation.arrivalWindowMinutes,
      startAt: reservation.startAt?.toISOString(),
      endAt: reservation.endAt?.toISOString(),
      expiresAt: reservation.expiresAt?.toISOString(),
      checkedInAt: reservation.checkedInAt?.toISOString(),
      checkedOutAt: reservation.checkedOutAt?.toISOString(),
      qrCode: reservation.qrCode,
      createdAt: reservation.createdAt?.toISOString(),
      updatedAt: reservation.updatedAt?.toISOString(),
      venue: reservation.venue
        ? {
            id: reservation.venue.id,
            name: reservation.venue.name,
            address: reservation.venue.address,
          }
        : null,
      level: reservation.level
        ? {
            id: reservation.level.id,
            name: reservation.level.name,
            levelNumber: reservation.level.levelNumber,
          }
        : null,
      spot: reservation.spot
        ? {
            id: reservation.spot.id,
            spotNumber: reservation.spot.spotNumber,
          }
        : null,
    };
  }
}
