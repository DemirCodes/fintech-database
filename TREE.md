fintech-database/
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Makefile
│
├── migrations/
│   ├── V1__create_schemas.sql
│   ├── V2__create_tables.sql
│   ├── V3__add_constraints.sql
│   ├── V4__add_indexes.sql
│   ├── V5__create_functions.sql
│   ├── V6__create_procedures.sql
│   ├── V7__create_triggers.sql
│   ├── V8__create_views.sql
│   ├── V9__create_partitions.sql
│   └── V10__seed_currencies.sql
│
├── rollback/
│   ├── U1__drop_views.sql
│   ├── U2__drop_procedures.sql
│   ├── U3__drop_functions.sql
│   ├── U4__drop_triggers.sql
│   ├── U5__drop_partitions.sql
│   ├── U6__drop_indexes.sql
│   ├── U7__drop_constraints.sql
│   ├── U8__drop_tables.sql
│   └── U9__drop_schemas.sql
│
├── database/
│   ├── schemas/
│   │   ├── core.sql
│   │   ├── payment.sql
│   │   ├── wallet.sql
│   │   ├── billing.sql
│   │   ├── reconciliation.sql
│   │   └── audit.sql
│   │
│   ├── tables/
│   │   ├── core/
│   │   │   ├── tenants.sql
│   │   │   ├── tenant_balances.sql
│   │   │   ├── users.sql
│   │   │   └── user_sessions.sql
│   │   ├── customer/
│   │   │   ├── customers.sql
│   │   │   ├── customer_addresses.sql
│   │   │   ├── customer_wallets.sql
│   │   │   └── payment_methods.sql
│   │   ├── payment/
│   │   │   ├── transactions.sql
│   │   │   ├── transaction_details.sql
│   │   │   ├── wallet_ledger.sql
│   │   │   ├── transfers.sql
│   │   │   └── refunds.sql
│   │   ├── billing/
│   │   │   ├── commission_rates.sql
│   │   │   ├── commissions.sql
│   │   │   ├── installment_plans.sql
│   │   │   └── installment_payments.sql
│   │   ├── chargeback/
│   │   │   ├── chargebacks.sql
│   │   │   └── chargeback_status_history.sql
│   │   ├── reconciliation/
│   │   │   ├── reconciliation_batches.sql
│   │   │   └── reconciliation_items.sql
│   │   └── audit/
│   │       ├── audit_logs.sql
│   │       ├── outbox.sql
│   │       └── event_logs.sql
│   │
│   ├── views/
│   │   ├── vw_customer_balances.sql
│   │   ├── vw_tenant_revenue.sql
│   │   ├── vw_daily_transactions.sql
│   │   ├── vw_pending_chargebacks.sql
│   │   └── vw_reconciliation_summary.sql
│   │
│   ├── functions/
│   │   ├── fn_get_wallet_balance.sql
│   │   ├── fn_calculate_commission.sql
│   │   ├── fn_convert_currency.sql
│   │   ├── fn_validate_idempotency.sql
│   │   └── fn_reconcile_ledger.sql
│   │
│   ├── procedures/
│   │   ├── sp_create_transaction.sql
│   │   ├── sp_transfer_money.sql
│   │   ├── sp_process_refund.sql
│   │   ├── sp_create_installment.sql
│   │   ├── sp_close_reconciliation_batch.sql
│   │   └── sp_generate_daily_summary.sql
│   │
│   ├── triggers/
│   │   ├── trg_audit_log.sql
│   │   ├── trg_update_wallet_balance.sql
│   │   ├── trg_check_balance_constraint.sql
│   │   ├── trg_outbox_publisher.sql
│   │   ├── trg_validate_status_transition.sql
│   │   └── trg_update_updated_at.sql
│   │
│   └── partitions/
│       ├── transactions_partitions.sql
│       ├── wallet_ledger_partitions.sql
│       ├── audit_logs_partitions.sql
│       └── outbox_partitions.sql
│
├── seed/
│   ├── production/
│   │   └── (boş — production'a elle seed atılmaz)
│   ├── staging/
│   │   ├── currencies.sql
│   │   ├── commission_rates.sql
│   │   └── minimal_tenants.sql
│   └── development/
│       ├── currencies.sql
│       ├── commission_rates.sql
│       ├── tenants.sql
│       ├── users.sql
│       ├── customers.sql
│       ├── payment_methods.sql
│       ├── wallets.sql
│       ├── transactions.sql
│       ├── ledger.sql
│       ├── installment_plans.sql
│       └── outbox_events.sql
│
├── scripts/
│   ├── setup/
│   │   ├── init_database.sh
│   │   ├── create_roles.sh
│   │   └── configure_extensions.sh
│   ├── migration/
│   │   ├── migrate.sh
│   │   ├── rollback.sh
│   │   └── validate.sh
│   ├── seed/
│   │   ├── seed_dev.sh
│   │   └── seed_staging.sh
│   ├── backup/
│   │   ├── full_backup.sh
│   │   └── restore_backup.sh
│   └── maintenance/
│       ├── vacuum_analyze.sh
│       ├── archive_partitions.sh
│       └── health_check.sh
│
├── monitoring/
│   ├── queries/
│   │   ├── slow_queries.sql
│   │   ├── table_sizes.sql
│   │   ├── index_usage.sql
│   │   ├── lock_monitor.sql
│   │   ├── connection_stats.sql
│   │   └── replication_status.sql
│   └── alerts/
│       ├── alert_balance_mismatch.sql
│       ├── alert_deadlock.sql
│       └── alert_partition_growth.sql
│
├── tests/
│   ├── unit/
│   │   ├── test_functions.sql
│   │   ├── test_triggers.sql
│   │   └── test_constraints.sql
│   ├── integration/
│   │   ├── test_transaction_flow.sql
│   │   ├── test_transfer_flow.sql
│   │   └── test_reconciliation_flow.sql
│   ├── concurrency/
│   │   ├── test_race_condition.sql
│   │   ├── test_deadlock.sql
│   │   └── test_isolation_levels.sql
│   └── performance/
│       ├── benchmark_reads.sql
│       ├── benchmark_writes.sql
│       └── benchmark_partitioned.sql
│
├── config/
│   ├── postgresql/
│   │   ├── postgresql.conf
│   │   ├── pg_hba.conf
│   │   └── pg_ident.conf
│   ├── flyway/
│   │   ├── flyway.conf
│   │   └── flyway-dev.conf
│   └── docker/
│       ├── Dockerfile.postgres
│       └── Dockerfile.flyway
│
└── docs/
    ├── architecture/
    │   ├── overview.md
    │   ├── multi-tenancy.md
    │   └── high-availability.md
    ├── schema/
    │   ├── er-diagram.md
    │   ├── table-catalog.md
    │   └── column-reference.md
    ├── strategy/
    │   ├── indexing.md
    │   ├── partitioning.md
    │   └── backup-recovery.md
    ├── operations/
    │   ├── runbook.md
    │   ├── disaster-recovery.md
    │   └── capacity-planning.md
    └── testing/
        ├── test-plan.md
        └── performance-baseline.md