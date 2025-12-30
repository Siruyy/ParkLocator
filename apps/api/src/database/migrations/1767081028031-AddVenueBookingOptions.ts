import { MigrationInterface, QueryRunner } from "typeorm";

export class AddVenueBookingOptions1767081028031 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "supports_real_time_booking" boolean NOT NULL DEFAULT true`);
        await queryRunner.query(`ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "supports_future_booking" boolean NOT NULL DEFAULT false`);
        await queryRunner.query(`ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "require_vehicle_details" boolean NOT NULL DEFAULT true`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "venues" DROP COLUMN "require_vehicle_details"`);
        await queryRunner.query(`ALTER TABLE "venues" DROP COLUMN "supports_future_booking"`);
        await queryRunner.query(`ALTER TABLE "venues" DROP COLUMN "supports_real_time_booking"`);
    }

}
