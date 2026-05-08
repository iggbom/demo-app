-- ── demo database ────────────────────────────────────────────────────────────
-- This file runs in the context of the POSTGRES_DB (demo).

CREATE TABLE IF NOT EXISTS items (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT
);

INSERT INTO items (name, description) VALUES
    ('Widget Alpha',  'A reliable all-purpose widget'),
    ('Widget Beta',   'A next-generation widget with extended features'),
    ('Widget Gamma',  'Compact widget optimised for low-power environments'),
    ('Widget Delta',  'Industrial-grade widget with enhanced durability'),
    ('Widget Epsilon','Experimental widget — handle with care');

-- ── curity database ───────────────────────────────────────────────────────────
CREATE DATABASE curity;

\c curity

-- While Postgres has native support for UUID's, an extension is needed for generating them.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

/* Token Store : table delegations */
CREATE TABLE delegations (
  id                          VARCHAR(40)   PRIMARY KEY,
  tenant_id                   VARCHAR(64)   NULL,
  owner                       VARCHAR(128)  NOT NULL,
  created                     BIGINT        NOT NULL,
  expires                     BIGINT        NOT NULL,
  scope                       VARCHAR(1000) NULL,
  scope_claims                TEXT          NULL,
  client_id                   VARCHAR(128)  NOT NULL,
  redirect_uri                VARCHAR(512)  NULL,
  status                      VARCHAR(16)   NOT NULL,
  claims                      TEXT          NULL,
  authentication_attributes   TEXT          NULL,
  authorization_code_hash     VARCHAR(89)   NULL
);

CREATE INDEX "IDX_DELEGATIONS_CLIENT_ID_STATUS"      ON delegations (client_id ASC, status);
CREATE INDEX IDX_DELEGATIONS_STATUS                  ON delegations (status ASC);
CREATE INDEX IDX_DELEGATIONS_EXPIRES                 ON delegations (expires ASC);
CREATE INDEX IDX_DELEGATIONS_OWNER                   ON delegations (owner ASC);
CREATE INDEX IDX_DELEGATIONS_AUTHORIZATION_CODE_HASH ON delegations (authorization_code_hash ASC);

/* Token Store : table tokens */
CREATE TABLE tokens (
  token_hash     VARCHAR(89)   NOT NULL PRIMARY KEY,
  id             VARCHAR(64)   NULL,
  delegations_id VARCHAR(40)   NOT NULL,
  purpose        VARCHAR(32)   NOT NULL,
  usage          VARCHAR(8)    NOT NULL,
  format         VARCHAR(32)   NOT NULL,
  created        BIGINT        NOT NULL,
  expires        BIGINT        NOT NULL,
  scope          VARCHAR(1000) NULL,
  scope_claims   TEXT          NULL,
  status         VARCHAR(16)   NOT NULL,
  issuer         VARCHAR(200)  NOT NULL,
  subject        VARCHAR(64)   NOT NULL,
  audience       VARCHAR(512)  NULL,
  not_before     BIGINT        NULL,
  claims         TEXT          NULL,
  meta_data      TEXT          NULL
);

CREATE INDEX IDX_TOKENS_ID      ON tokens (id);
CREATE INDEX IDX_TOKENS_STATUS  ON tokens (status ASC);
CREATE INDEX IDX_TOKENS_EXPIRES ON tokens (expires ASC);

CREATE TABLE nonces (
  token           VARCHAR(64) NOT NULL PRIMARY KEY,
  reference_data  TEXT        NOT NULL,
  created         BIGINT      NOT NULL,
  ttl             BIGINT      NOT NULL,
  consumed        BIGINT      NULL,
  status          VARCHAR(16) NOT NULL DEFAULT 'issued'
);

CREATE TABLE accounts (
  account_id  VARCHAR(64)  PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id   VARCHAR(64),
  username    VARCHAR(64)  NOT NULL,
  email       VARCHAR(64),
  phone       VARCHAR(32),
  attributes  JSONB,
  active      SMALLINT     NOT NULL DEFAULT 0,
  created     BIGINT       NOT NULL,
  updated     BIGINT       NOT NULL
);

CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_USERNAME ON accounts (tenant_id, username);
CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_PHONE    ON accounts (tenant_id, phone);
CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_EMAIL    ON accounts (tenant_id, email);
CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_USERNAME_DEFAULT ON accounts(username) WHERE tenant_id IS NULL;
CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_PHONE_DEFAULT    ON accounts(phone)    WHERE tenant_id IS NULL;
CREATE UNIQUE INDEX IDX_ACCOUNTS_TENANT_EMAIL_DEFAULT    ON accounts(email)    WHERE tenant_id IS NULL;
CREATE INDEX IDX_ACCOUNTS_ATTRIBUTES_NAME ON accounts USING GIN ( (attributes->'name') );

CREATE TABLE linked_accounts (
  account_id                  VARCHAR(64) NOT NULL,
  tenant_id                   VARCHAR(64),
  linked_account_id           VARCHAR(64) NOT NULL,
  linked_account_domain_name  VARCHAR(64) NOT NULL,
  linking_account_manager     VARCHAR(128),
  created                     TIMESTAMP   NOT NULL,
  PRIMARY KEY (account_id, linked_account_id, linked_account_domain_name)
);

CREATE UNIQUE INDEX IDX_LINKED_ACCOUNTS_TENANT_ACCOUNT_DOMAIN         ON linked_accounts (tenant_id, linked_account_id, linked_account_domain_name);
CREATE UNIQUE INDEX IDX_LINKED_ACCOUNTS_TENANT_ACCOUNT_DOMAIN_DEFAULT ON linked_accounts (linked_account_id, linked_account_domain_name) WHERE tenant_id IS NULL;

CREATE TABLE credentials (
  id          VARCHAR(36)  PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   VARCHAR(64),
  subject     VARCHAR(64)  NOT NULL,
  password    VARCHAR(128) NOT NULL,
  attributes  JSONB        NOT NULL,
  created     TIMESTAMP    NOT NULL,
  updated     TIMESTAMP    NOT NULL
);

CREATE UNIQUE INDEX IDX_CREDENTIALS_TENANT_SUBJECT         ON credentials (tenant_id, subject);
CREATE UNIQUE INDEX IDX_CREDENTIALS_TENANT_SUBJECT_DEFAULT ON credentials (subject) WHERE tenant_id IS NULL;

CREATE TABLE sessions (
  id            VARCHAR(64) NOT NULL PRIMARY KEY,
  session_data  TEXT        NOT NULL,
  expires       BIGINT      NOT NULL
);

CREATE INDEX IDX_SESSIONS_ID         ON sessions (id ASC);
CREATE INDEX IDX_SESSIONS_ID_EXPIRES ON sessions (id, expires);

CREATE TABLE devices (
  id          VARCHAR(64) PRIMARY KEY NOT NULL,
  device_id   VARCHAR(256),
  tenant_id   VARCHAR(64),
  account_id  VARCHAR(256),
  external_id VARCHAR(32),
  alias       VARCHAR(30),
  form_factor VARCHAR(10),
  device_type VARCHAR(50),
  owner       VARCHAR(256),
  attributes  JSONB,
  expires     BIGINT,
  created     BIGINT      NOT NULL,
  updated     BIGINT      NOT NULL
);

CREATE UNIQUE INDEX IDX_DEVICES_TENANT_ACCOUNT_ID_DEVICE_ID         ON devices (tenant_id, account_id ASC, device_id ASC);
CREATE UNIQUE INDEX IDX_DEVICES_TENANT_ACCOUNT_ID_DEVICE_ID_DEFAULT ON devices (account_id ASC, device_id ASC) WHERE tenant_id IS NULL;
CREATE INDEX IDX_DEVICE_ID ON devices (device_id ASC);

CREATE TABLE audit (
  id                    VARCHAR(64)  PRIMARY KEY,
  instant               TIMESTAMP    NOT NULL,
  event_instant         VARCHAR(64)  NOT NULL,
  server                VARCHAR(255) NOT NULL,
  message               TEXT         NOT NULL,
  event_type            VARCHAR(48)  NOT NULL,
  subject               VARCHAR(128),
  client                VARCHAR(128),
  resource              VARCHAR(128),
  authenticated_subject VARCHAR(128),
  authenticated_client  VARCHAR(128),
  acr                   VARCHAR(128),
  endpoint              VARCHAR(255),
  session               VARCHAR(128)
);

CREATE TABLE dynamically_registered_clients (
  client_id           VARCHAR(64)  NOT NULL PRIMARY KEY,
  client_secret       VARCHAR(128),
  instance_of_client  VARCHAR(64)  NULL,
  created             TIMESTAMP    NOT NULL,
  updated             TIMESTAMP    NOT NULL,
  initial_client      VARCHAR(64)  NULL,
  authenticated_user  VARCHAR(64)  NULL,
  attributes          JSONB        NOT NULL DEFAULT '{}',
  status              VARCHAR(12)  NOT NULL DEFAULT 'active',
  scope               TEXT         NULL,
  redirect_uris       TEXT         NULL,
  grant_types         VARCHAR(500) NULL
);

CREATE INDEX IDX_DRC_INSTANCE_OF_CLIENT ON dynamically_registered_clients(instance_of_client);
CREATE INDEX IDX_DRC_ATTRIBUTES         ON dynamically_registered_clients USING GIN (attributes);
CREATE INDEX IDX_DRC_CREATED            ON dynamically_registered_clients(created);
CREATE INDEX IDX_DRC_STATUS             ON dynamically_registered_clients(status);
CREATE INDEX IDX_DRC_AUTHENTICATED_USER ON dynamically_registered_clients(authenticated_user);

CREATE TABLE database_clients (
  client_id                VARCHAR(64)  NOT NULL,
  profile_id               VARCHAR(64)  NOT NULL,
  client_name              VARCHAR(128) NULL,
  created                  TIMESTAMP    NOT NULL,
  updated                  TIMESTAMP    NOT NULL,
  owner                    VARCHAR(128) NOT NULL,
  status                   VARCHAR(16)  NOT NULL DEFAULT 'active',
  client_metadata          JSONB        NOT NULL DEFAULT '{}',
  configuration_references JSONB        NOT NULL DEFAULT '{}',
  attributes               JSONB        NOT NULL DEFAULT '{}',
  PRIMARY KEY (client_id, profile_id)
);

CREATE INDEX IDX_DATABASE_CLIENTS_PROFILE_ID     ON database_clients (profile_id ASC);
CREATE INDEX IDX_DATABASE_CLIENTS_CLIENT_NAME    ON database_clients (client_name ASC);
CREATE INDEX IDX_DATABASE_CLIENTS_OWNER          ON database_clients (owner ASC);
CREATE INDEX IDX_DATABASE_CLIENTS_METADATA_TAGS  ON database_clients USING GIN ((client_metadata -> 'tags') jsonb_path_ops);
CREATE INDEX IDX_DATABASE_CLIENTS_METADATA_TAGS_NULL ON database_clients (client_metadata) WHERE client_metadata->'tags' IS NULL;

CREATE TABLE buckets (
  id         VARCHAR(64)  NOT NULL DEFAULT uuid_generate_v4(),
  subject    VARCHAR(128) NOT NULL,
  purpose    VARCHAR(64)  NOT NULL,
  tenant_id  VARCHAR(64),
  attributes JSONB        NOT NULL,
  created    TIMESTAMP    NOT NULL,
  updated    TIMESTAMP    NOT NULL,
  expires    TIMESTAMP    NULL,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IDX_BUCKETS_TENANT_SUBJECT_PURPOSE         ON buckets (tenant_id, subject, purpose);
CREATE UNIQUE INDEX IDX_BUCKETS_TENANT_SUBJECT_PURPOSE_DEFAULT ON buckets (subject, purpose) WHERE tenant_id IS NULL;
CREATE INDEX IDX_BUCKETS_ATTRIBUTES ON buckets USING GIN (attributes);
CREATE INDEX "IDX_BUCKETS_EXPIRES"  ON buckets (expires);

CREATE TABLE IF NOT EXISTS database_service_providers (
  id                        VARCHAR(64)  NOT NULL,
  profile_id                VARCHAR(64)  NOT NULL,
  service_provider_name     VARCHAR(128) NULL,
  created                   TIMESTAMP    NOT NULL,
  updated                   TIMESTAMP    NOT NULL,
  owner                     VARCHAR(128) NOT NULL,
  enabled                   VARCHAR(16)  NOT NULL DEFAULT 'enabled',
  service_provider_metadata JSONB        NOT NULL DEFAULT '{}',
  configuration_references  JSONB        NOT NULL DEFAULT '{}',
  attributes                JSONB        NOT NULL DEFAULT '{}',
  PRIMARY KEY (id, profile_id)
);

CREATE INDEX IF NOT EXISTS IDX_DBSP_PROFILE_ID            ON database_service_providers (profile_id);
CREATE INDEX IF NOT EXISTS IDX_DBSP_SERVICE_PROVIDER_NAME ON database_service_providers (service_provider_name);
CREATE INDEX IF NOT EXISTS IDX_DBSP_OWNER                 ON database_service_providers (owner);

CREATE TABLE entities (
  id           VARCHAR(64)  NOT NULL PRIMARY KEY,
  tenant_id    VARCHAR(64)  NULL,
  context_id   VARCHAR(64)  NOT NULL,
  type         VARCHAR(64)  NOT NULL,
  value        VARCHAR(512) NOT NULL,
  display_name VARCHAR(255) NULL,
  versions     JSONB        NOT NULL,
  attributes   JSONB        NULL,
  external_id  VARCHAR(64)  NULL,
  created      TIMESTAMP    NOT NULL,
  updated      TIMESTAMP    NOT NULL,
  deleted      TIMESTAMP    NULL,
  version      VARCHAR(64)  NOT NULL DEFAULT '1',
  CONSTRAINT "FK_ENTITIES_CONTEXT_ID" FOREIGN KEY (context_id) REFERENCES entities (id)
);

CREATE UNIQUE INDEX "IDX_ENTITIES_BUSINESS_KEY"         ON entities (tenant_id, context_id, type, value);
CREATE UNIQUE INDEX "IDX_ENTITIES_BUSINESS_KEY_DEFAULT" ON entities (context_id, type, value) WHERE tenant_id IS NULL;
CREATE INDEX "IDX_ENTITIES_TENANT_TYPE_VALUE"           ON entities (tenant_id, type, value);
CREATE INDEX "IDX_ENTITIES_TENANT_TYPE_VALUE_DEFAULT"   ON entities (type, value) WHERE tenant_id IS NULL;
CREATE INDEX "IDX_ENTITIES_EXTERNAL_ID"                 ON entities (external_id);
CREATE INDEX "IDX_ENTITIES_CONTEXT_ID"                  ON entities (context_id);

INSERT INTO entities (id, tenant_id, context_id, type, value, display_name, versions, attributes, created, updated, version)
VALUES ('__GLOBAL__', '__ROOT__', '__GLOBAL__', '__SYSTEM__', '__GLOBAL__', 'Global context (e.g. for context entities)', '{}', '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '1');

CREATE TABLE entity_relations (
  id               VARCHAR(64) NOT NULL PRIMARY KEY,
  source_entity_id VARCHAR(64) NOT NULL,
  target_entity_id VARCHAR(64) NOT NULL,
  type             VARCHAR(64) NOT NULL,
  tenant_id        VARCHAR(64) NULL,
  created          TIMESTAMP   NOT NULL,
  attributes       JSONB       NULL,
  CONSTRAINT "FK_ENTITY_RELATIONS_SOURCE_ENTITY_ID" FOREIGN KEY (source_entity_id) REFERENCES entities (id),
  CONSTRAINT "FK_ENTITY_RELATIONS_TARGET_ENTITY_ID" FOREIGN KEY (target_entity_id) REFERENCES entities (id)
);

CREATE UNIQUE INDEX "IDX_ENTITY_RELATIONS_BUSINESS_KEY"         ON entity_relations (source_entity_id, type, target_entity_id);
CREATE UNIQUE INDEX "IDX_ENTITY_RELATIONS_REVERSE_BUSINESS_KEY" ON entity_relations (target_entity_id, type, source_entity_id);

CREATE TABLE account_resource_relations (
  id               VARCHAR(64) NOT NULL PRIMARY KEY,
  account_id       VARCHAR(64) NOT NULL,
  tenant_id        VARCHAR(64) NULL,
  entity_id        VARCHAR(64) NOT NULL,
  type             VARCHAR(64) NOT NULL,
  relation_version INTEGER     NOT NULL,
  status           VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
  not_before       TIMESTAMP   NULL,
  expires          TIMESTAMP   NULL,
  attributes       JSONB       NULL,
  created          TIMESTAMP   NOT NULL,
  updated          TIMESTAMP   NOT NULL,
  version          VARCHAR(64) NOT NULL DEFAULT '1',
  CONSTRAINT "FK_ACCOUNT_RESOURCE_RELATIONS_ENTITIES_ENTITY_ID" FOREIGN KEY (entity_id) REFERENCES entities (id)
);

CREATE UNIQUE INDEX "IDX_ACCOUNT_RESOURCE_RELATIONS_BUSINESS_KEY"         ON account_resource_relations (tenant_id, account_id, entity_id, type, relation_version);
CREATE UNIQUE INDEX "IDX_ACCOUNT_RESOURCE_RELATIONS_BUSINESS_KEY_DEFAULT" ON account_resource_relations (account_id, entity_id, type, relation_version) WHERE tenant_id IS NULL;
CREATE INDEX "IDX_ACCOUNT_RESOURCE_RELATIONS_ENTITY_ID_TYPE"              ON account_resource_relations(entity_id, type);

CREATE TABLE database_client_resource_relations (
  id                 VARCHAR(64) NOT NULL PRIMARY KEY,
  database_client_id VARCHAR(64) NOT NULL,
  tenant_id          VARCHAR(64) NULL,
  entity_id          VARCHAR(64) NOT NULL,
  type               VARCHAR(64) NOT NULL,
  relation_version   INTEGER     NOT NULL,
  status             VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
  not_before         TIMESTAMP   NULL,
  expires            TIMESTAMP   NULL,
  attributes         JSONB       NULL,
  created            TIMESTAMP   NOT NULL,
  updated            TIMESTAMP   NOT NULL,
  version            VARCHAR(64) NOT NULL DEFAULT '1',
  CONSTRAINT "FK_DATABASE_CLIENT_RESOURCE_RELATIONS_ENTITIES_ID" FOREIGN KEY (entity_id) REFERENCES entities (id)
);

CREATE UNIQUE INDEX "IDX_DATABASE_CLIENT_RESOURCE_RELATIONS_BUSINESS_KEY"         ON database_client_resource_relations (tenant_id, database_client_id, entity_id, type, relation_version);
CREATE UNIQUE INDEX "IDX_DATABASE_CLIENT_RESOURCE_RELATIONS_BUSINESS_KEY_DEFAULT" ON database_client_resource_relations (database_client_id, entity_id, type, relation_version) WHERE tenant_id IS NULL;
CREATE INDEX "IDX_DATABASE_CLIENT_RESOURCE_RELATIONS_ENTITY_ID_TYPE"              ON database_client_resource_relations(entity_id, type);
