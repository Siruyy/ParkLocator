import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateVenuesLevelsSpots1765600000000 implements MigrationInterface {
  name = 'CreateVenuesLevelsSpots1765600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create spot_status enum
    await queryRunner.query(
      `CREATE TYPE "public"."spots_status_enum" AS ENUM('available', 'occupied', 'reserved', 'maintenance')`,
    );

    // Create venues table with PostGIS geography column
    await queryRunner.query(`
      CREATE TABLE "venues" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "address" character varying NOT NULL,
        "location" geography(Point, 4326) NOT NULL,
        "is_active" boolean NOT NULL DEFAULT true,
        "image_url" character varying,
        "description" text,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_67dd0e2caae46e3d84e5f4dab03" PRIMARY KEY ("id")
      )
    `);

    // Create spatial index on location
    await queryRunner.query(
      `CREATE INDEX "IDX_venues_location" ON "venues" USING GIST ("location")`,
    );

    // Create levels table
    await queryRunner.query(`
      CREATE TABLE "levels" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "level_number" integer NOT NULL,
        "name" character varying NOT NULL,
        "total_capacity" integer NOT NULL,
        "available_spots" integer NOT NULL DEFAULT 0,
        "is_active" boolean NOT NULL DEFAULT true,
        "venue_id" uuid NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_05f8dd8b4f4b2b7b3e8f6c1e1e1" PRIMARY KEY ("id"),
        CONSTRAINT "FK_levels_venue" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE CASCADE ON UPDATE NO ACTION
      )
    `);

    // Create index on venue_id for levels
    await queryRunner.query(
      `CREATE INDEX "IDX_levels_venue_id" ON "levels" ("venue_id")`,
    );

    // Create spots table
    await queryRunner.query(`
      CREATE TABLE "spots" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "spot_number" character varying NOT NULL,
        "status" "public"."spots_status_enum" NOT NULL DEFAULT 'available',
        "is_active" boolean NOT NULL DEFAULT true,
        "level_id" uuid NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_08a1e1a5a3b5b1b5b5b5b5b5b5b" PRIMARY KEY ("id"),
        CONSTRAINT "FK_spots_level" FOREIGN KEY ("level_id") REFERENCES "levels"("id") ON DELETE CASCADE ON UPDATE NO ACTION
      )
    `);

    // Create index on level_id for spots
    await queryRunner.query(
      `CREATE INDEX "IDX_spots_level_id" ON "spots" ("level_id")`,
    );

    // Create index on spot status for quick availability queries
    await queryRunner.query(
      `CREATE INDEX "IDX_spots_status" ON "spots" ("status")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "public"."IDX_spots_status"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_spots_level_id"`);
    await queryRunner.query(`DROP TABLE "spots"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_levels_venue_id"`);
    await queryRunner.query(`DROP TABLE "levels"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_venues_location"`);
    await queryRunner.query(`DROP TABLE "venues"`);
    await queryRunner.query(`DROP TYPE "public"."spots_status_enum"`);
  }
}
