-- Idempotent schema — runs on every startup via spring.sql.init.
-- On Railway there is no init.sql pre-run, so this creates the table the first time.
-- On existing deployments the IF NOT EXISTS clause makes it a no-op.

CREATE TABLE IF NOT EXISTS items (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT
);
