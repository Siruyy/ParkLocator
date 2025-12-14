import { MigrationInterface, QueryRunner } from "typeorm";

export class FixLevelNames1765615644896 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            WITH ranked_levels AS (
              SELECT id, ROW_NUMBER() OVER (PARTITION BY venue_id ORDER BY created_at) as rn
              FROM levels
            )
            UPDATE levels
            SET 
              name = 'Level ' || ranked_levels.rn,
              level_number = ranked_levels.rn
            FROM ranked_levels
            WHERE levels.id = ranked_levels.id;
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // No easy revert for data fix
    }

}
