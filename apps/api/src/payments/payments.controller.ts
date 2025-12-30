import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('intent')
  createPaymentIntent(@Body() createPaymentIntentDto: CreatePaymentIntentDto) {
    return this.paymentsService.createPaymentIntent(createPaymentIntentDto);
  }

  @Get('intent/:id')
  getPaymentIntent(@Param('id') id: string) {
    return this.paymentsService.getPaymentIntent(id);
  }
}
