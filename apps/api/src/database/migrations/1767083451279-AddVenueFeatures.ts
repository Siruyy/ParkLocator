import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddVenueFeatures1767083451279 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "has_covered_parking" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "has_cctv" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "venues" DROP COLUMN "has_cctv"`);
    await queryRunner.query(
      `ALTER TABLE "venues" DROP COLUMN "has_covered_parking"`,
    );
  }
}
