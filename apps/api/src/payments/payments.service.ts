/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';

@Injectable()
export class PaymentsService {
  private readonly paymongoUrl = 'https://api.paymongo.com/v1';
  private readonly secretKey: string;

  constructor(private configService: ConfigService) {
    this.secretKey =
      this.configService.get<string>('PAYMONGO_SECRET_KEY') || '';
  }

  private get headers() {
    const token = Buffer.from(this.secretKey).toString('base64');
    return {
      Authorization: `Basic ${token}`,
      'Content-Type': 'application/json',
    };
  }

  async createPaymentIntent(createPaymentIntentDto: CreatePaymentIntentDto) {
    try {
      // PayMongo expects amount in centavos (e.g., 100 PHP = 10000 centavos)
      const amountInCentavos = createPaymentIntentDto.amount * 100;

      const response = await axios.post(
        `${this.paymongoUrl}/payment_intents`,
        {
          data: {
            attributes: {
              amount: amountInCentavos,
              payment_method_allowed: ['card', 'paymaya', 'gcash', 'grab_pay'],
              currency: 'PHP',
              description: createPaymentIntentDto.description,
              capture_type: 'automatic',
            },
          },
        },
        {
          headers: this.headers,
        },
      );

      return response.data.data;
    } catch (error) {
      console.error('PayMongo Error:', error.response?.data || error.message);
      throw new InternalServerErrorException('Failed to create payment intent');
    }
  }

  async getPaymentIntent(id: string) {
    try {
      const response = await axios.get(
        `${this.paymongoUrl}/payment_intents/${id}`,
        {
          headers: this.headers,
        },
      );
      return response.data.data;
    } catch (error) {
      console.error('PayMongo Error:', error.response?.data || error.message);
      throw new InternalServerErrorException('Failed to fetch payment intent');
    }
  }
}
