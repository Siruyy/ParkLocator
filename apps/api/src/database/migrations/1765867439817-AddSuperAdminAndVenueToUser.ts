import { MigrationInterface, QueryRunner } from "typeorm";

export class AddSuperAdminAndVenueToUser1765867439817 implements MigrationInterface {
    name = 'AddSuperAdminAndVenueToUser1765867439817'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_RESERVATIONS_START_AT"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_RESERVATIONS_END_AT"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_RESERVATIONS_SPOT_DATES"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "venue_id" uuid`);
        await queryRunner.query(`ALTER TYPE "public"."users_role_enum" RENAME TO "users_role_enum_old"`);
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum" AS ENUM('super_admin', 'driver', 'manager', 'attendant')`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" TYPE "public"."users_role_enum" USING "role"::"text"::"public"."users_role_enum"`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'driver'`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum_old"`);
        await queryRunner.query(`CREATE INDEX "IDX_52347cfdddee5b6890d5768110" ON "reservations" ("start_at") `);
        await queryRunner.query(`CREATE INDEX "IDX_7e3da5e02e390920db8fb25d88" ON "reservations" ("end_at") `);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "FK_b90530780af37dc60c96431bc45" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "FK_b90530780af37dc60c96431bc45"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_7e3da5e02e390920db8fb25d88"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_52347cfdddee5b6890d5768110"`);
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum_old" AS ENUM('driver', 'manager', 'attendant')`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" TYPE "public"."users_role_enum_old" USING "role"::"text"::"public"."users_role_enum_old"`);
        await queryRunner.query(`ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'driver'`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
        await queryRunner.query(`ALTER TYPE "public"."users_role_enum_old" RENAME TO "users_role_enum"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "venue_id"`);
        await queryRunner.query(`CREATE INDEX "IDX_RESERVATIONS_SPOT_DATES" ON "reservations" ("spot_id", "start_at", "end_at") `);
        await queryRunner.query(`CREATE INDEX "IDX_RESERVATIONS_END_AT" ON "reservations" ("end_at") `);
        await queryRunner.query(`CREATE INDEX "IDX_RESERVATIONS_START_AT" ON "reservations" ("start_at") `);
    }

}
