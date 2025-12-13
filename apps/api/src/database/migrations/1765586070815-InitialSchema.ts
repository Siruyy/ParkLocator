import { MigrationInterface, QueryRunner } from "typeorm";

export class InitialSchema1765586070815 implements MigrationInterface {

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Enable PostGIS extension
        await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS postgis;`);
        
        // Create a simple version table to verify migrations work
        await queryRunner.query(`
            CREATE TABLE schema_info (
                id SERIAL PRIMARY KEY,
                version VARCHAR(50) NOT NULL,
                applied_at TIMESTAMP DEFAULT NOW()
            );
        `);
        
        await queryRunner.query(`
            INSERT INTO schema_info (version) VALUES ('1.0.0');
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE schema_info;`);
        await queryRunner.query(`DROP EXTENSION IF EXISTS postgis;`);
    }

}
