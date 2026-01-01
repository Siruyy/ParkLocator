import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateReservationsTable1765614924644 implements MigrationInterface {
  name = 'CreateReservationsTable1765614924644';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "spots" DROP CONSTRAINT "FK_spots_level"`,
    );
    await queryRunner.query(
      `ALTER TABLE "levels" DROP CONSTRAINT "FK_levels_venue"`,
    );
    await queryRunner.query(`DROP INDEX "public"."IDX_spots_level_id"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_spots_status"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_levels_venue_id"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_venues_location"`);
    await queryRunner.query(
      `CREATE TYPE "public"."reservations_status_enum" AS ENUM('pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'expired', 'no_show')`,
    );
    await queryRunner.query(
      `CREATE TABLE "reservations" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "user_id" uuid NOT NULL, "venue_id" uuid NOT NULL, "level_id" uuid NOT NULL, "spot_id" uuid NOT NULL, "status" "public"."reservations_status_enum" NOT NULL DEFAULT 'pending', "amount" numeric(10,2) NOT NULL, "duration_hours" integer NOT NULL DEFAULT '1', "arrival_window_minutes" integer NOT NULL DEFAULT '60', "expires_at" TIMESTAMP NOT NULL, "checked_in_at" TIMESTAMP, "checked_out_at" TIMESTAMP, "qr_code" character varying, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_dccb4d5810c0a81fb41f38d0067" UNIQUE ("qr_code"), CONSTRAINT "PK_da95cef71b617ac35dc5bcda243" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_4af5055a871c46d011345a255a" ON "reservations" ("user_id") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_f486dcef5c26fd22cc63ba1c07" ON "reservations" ("venue_id") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_4ff1235a5578fc5c759a00ea4d" ON "reservations" ("level_id") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_a147f41ed0d946484c5183c3ef" ON "reservations" ("spot_id") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_c42f5dcdd13d6e63ee44b4cb23" ON "reservations" ("status") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_98b848a943fd38687f0caa171a" ON "reservations" ("expires_at") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_be677afd59218cba25e6e38789" ON "venues" USING GiST ("location") `,
    );
    await queryRunner.query(
      `ALTER TABLE "spots" ADD CONSTRAINT "FK_37ad9469fd0730ad2bcb16be96f" FOREIGN KEY ("level_id") REFERENCES "levels"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "levels" ADD CONSTRAINT "FK_fc8363f4a7dc30ef13e265a9a3b" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" ADD CONSTRAINT "FK_4af5055a871c46d011345a255a6" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" ADD CONSTRAINT "FK_f486dcef5c26fd22cc63ba1c071" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" ADD CONSTRAINT "FK_4ff1235a5578fc5c759a00ea4d6" FOREIGN KEY ("level_id") REFERENCES "levels"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" ADD CONSTRAINT "FK_a147f41ed0d946484c5183c3efc" FOREIGN KEY ("spot_id") REFERENCES "spots"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "reservations" DROP CONSTRAINT "FK_a147f41ed0d946484c5183c3efc"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" DROP CONSTRAINT "FK_4ff1235a5578fc5c759a00ea4d6"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" DROP CONSTRAINT "FK_f486dcef5c26fd22cc63ba1c071"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" DROP CONSTRAINT "FK_4af5055a871c46d011345a255a6"`,
    );
    await queryRunner.query(
      `ALTER TABLE "levels" DROP CONSTRAINT "FK_fc8363f4a7dc30ef13e265a9a3b"`,
    );
    await queryRunner.query(
      `ALTER TABLE "spots" DROP CONSTRAINT "FK_37ad9469fd0730ad2bcb16be96f"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_be677afd59218cba25e6e38789"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_98b848a943fd38687f0caa171a"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_c42f5dcdd13d6e63ee44b4cb23"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_a147f41ed0d946484c5183c3ef"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_4ff1235a5578fc5c759a00ea4d"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_f486dcef5c26fd22cc63ba1c07"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."IDX_4af5055a871c46d011345a255a"`,
    );
    await queryRunner.query(`DROP TABLE "reservations"`);
    await queryRunner.query(`DROP TYPE "public"."reservations_status_enum"`);
    await queryRunner.query(
      `CREATE INDEX "IDX_venues_location" ON "venues" USING GiST ("location") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_levels_venue_id" ON "levels" ("venue_id") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_spots_status" ON "spots" ("status") `,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_spots_level_id" ON "spots" ("level_id") `,
    );
    await queryRunner.query(
      `ALTER TABLE "levels" ADD CONSTRAINT "FK_levels_venue" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "spots" ADD CONSTRAINT "FK_spots_level" FOREIGN KEY ("level_id") REFERENCES "levels"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }
}
