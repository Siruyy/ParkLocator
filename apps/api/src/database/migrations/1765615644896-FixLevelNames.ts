import { MigrationInterface, QueryRunner } from 'typeorm';

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

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  public async down(_queryRunner: QueryRunner): Promise<void> {
    // No easy revert for data fix
  }
}
