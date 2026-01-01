/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Delete,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('users/me/vehicles')
@UseGuards(JwtAuthGuard)
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Post()
  create(@Request() req, @Body() createVehicleDto: CreateVehicleDto) {
    console.log('Create Vehicle Request User:', req.user);
    const userId = req.user.userId || req.user.id || req.user.sub;
    if (!userId) {
      console.error('User ID not found in request user object');
      throw new Error('User ID not found');
    }
    return this.vehiclesService.create(userId, createVehicleDto);
  }

  @Post(':id/photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/vehicles',
        filename: (req, file, cb) => {
          const randomName = Array(32)
            .fill(null)
            .map(() => Math.round(Math.random() * 16).toString(16))
            .join('');
          return cb(null, `${randomName}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async uploadPhoto(
    @Request() req,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const photoUrl = `/uploads/vehicles/${file.filename}`;
    const userId = req.user.userId || req.user.id || req.user.sub;
    return this.vehiclesService.update(userId, id, { photoUrl });
  }

  @Get()
  findAll(@Request() req) {
    const userId = req.user.userId || req.user.id || req.user.sub;
    return this.vehiclesService.findAll(userId);
  }

  @Patch(':id')
  update(
    @Request() req,
    @Param('id') id: string,
    @Body() updateVehicleDto: UpdateVehicleDto,
  ) {
    const userId = req.user.userId || req.user.id || req.user.sub;
    return this.vehiclesService.update(userId, id, updateVehicleDto);
  }

  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    const userId = req.user.userId || req.user.id || req.user.sub;
    return this.vehiclesService.remove(userId, id);
  }
}
