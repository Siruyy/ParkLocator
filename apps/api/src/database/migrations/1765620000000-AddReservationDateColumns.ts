import {
  MigrationInterface,
  QueryRunner,
  TableColumn,
  TableIndex,
} from 'typeorm';

export class AddReservationDateColumns1765620000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add start_at column
    await queryRunner.addColumn(
      'reservations',
      new TableColumn({
        name: 'start_at',
        type: 'timestamp',
        isNullable: true, // Initially nullable for existing rows
      }),
    );

    // Add end_at column
    await queryRunner.addColumn(
      'reservations',
      new TableColumn({
        name: 'end_at',
        type: 'timestamp',
        isNullable: true, // Initially nullable for existing rows
      }),
    );

    // Populate existing rows with default values (created_at as start, +duration as end)
    await queryRunner.query(`
      UPDATE reservations
      SET start_at = created_at,
          end_at = created_at + (duration_hours * INTERVAL '1 hour')
      WHERE start_at IS NULL
    `);

    // Now make columns non-nullable
    await queryRunner.changeColumn(
      'reservations',
      'start_at',
      new TableColumn({
        name: 'start_at',
        type: 'timestamp',
        isNullable: false,
      }),
    );

    await queryRunner.changeColumn(
      'reservations',
      'end_at',
      new TableColumn({
        name: 'end_at',
        type: 'timestamp',
        isNullable: false,
      }),
    );

    // Add indexes for efficient overlap queries
    await queryRunner.createIndex(
      'reservations',
      new TableIndex({
        name: 'IDX_RESERVATIONS_START_AT',
        columnNames: ['start_at'],
      }),
    );

    await queryRunner.createIndex(
      'reservations',
      new TableIndex({
        name: 'IDX_RESERVATIONS_END_AT',
        columnNames: ['end_at'],
      }),
    );

    // Composite index for overlap queries
    await queryRunner.createIndex(
      'reservations',
      new TableIndex({
        name: 'IDX_RESERVATIONS_SPOT_DATES',
        columnNames: ['spot_id', 'start_at', 'end_at'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('reservations', 'IDX_RESERVATIONS_SPOT_DATES');
    await queryRunner.dropIndex('reservations', 'IDX_RESERVATIONS_END_AT');
    await queryRunner.dropIndex('reservations', 'IDX_RESERVATIONS_START_AT');
    await queryRunner.dropColumn('reservations', 'end_at');
    await queryRunner.dropColumn('reservations', 'start_at');
  }
}
