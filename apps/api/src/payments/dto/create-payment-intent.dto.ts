import { IsNumber, IsString, Min } from 'class-validator';

export class CreatePaymentIntentDto {
  @IsNumber()
  @Min(100) // Minimum amount usually required by gateways (e.g. 100 PHP)
  amount: number;

  @IsString()
  description: string;
}
