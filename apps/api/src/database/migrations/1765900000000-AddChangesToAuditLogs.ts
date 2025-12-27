import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddChangesToAuditLogs1765900000000 implements MigrationInterface {
  name = 'AddChangesToAuditLogs1765900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'audit_logs',
      new TableColumn({
        name: 'changes',
        type: 'jsonb',
        isNullable: true,
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('audit_logs', 'changes');
  }
}
