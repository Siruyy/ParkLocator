import { MigrationInterface, QueryRunner } from "typeorm";

export class AddDeletedAtToVenues1767085000000 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "venues" ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMP`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "venues" DROP COLUMN "deleted_at"`);
    }

}
