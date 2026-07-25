-- Phase 0 (F0.4): FinTrack's initial schema. See PLAN_MAESTRO_FINTRACK.md §3.2.
-- Working rule: an already-applied migration is NEVER edited; fix it with a new one on top.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    name           VARCHAR(100) NOT NULL,
    base_currency  CHAR(3) NOT NULL DEFAULT 'MXN',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE accounts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name             VARCHAR(100) NOT NULL,
    type             VARCHAR(20) NOT NULL CHECK (type IN ('CASH', 'DEBIT', 'CREDIT', 'SAVINGS')),
    initial_balance  DECIMAL(14, 2) NOT NULL DEFAULT 0,
    archived         BOOLEAN NOT NULL DEFAULT false,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_accounts_user_name UNIQUE (user_id, name)
);

CREATE TABLE categories (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       VARCHAR(60) NOT NULL,
    kind       VARCHAR(10) NOT NULL CHECK (kind IN ('INCOME', 'EXPENSE')),
    color      CHAR(7) NOT NULL,
    icon       VARCHAR(40) NOT NULL,
    archived   BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT uq_categories_user_name_kind UNIQUE (user_id, name, kind)
);

CREATE TABLE transactions (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    account_id           UUID NOT NULL REFERENCES accounts (id) ON DELETE RESTRICT,
    category_id          UUID REFERENCES categories (id) ON DELETE RESTRICT,
    transfer_account_id  UUID REFERENCES accounts (id) ON DELETE RESTRICT,
    type                 VARCHAR(10) NOT NULL CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER')),
    amount               DECIMAL(14, 2) NOT NULL CHECK (amount > 0),
    date                 DATE NOT NULL,
    note                 VARCHAR(255),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_tx_shape CHECK (
        (type = 'TRANSFER' AND category_id IS NULL AND transfer_account_id IS NOT NULL
                          AND transfer_account_id <> account_id)
        OR
        (type IN ('INCOME', 'EXPENSE') AND category_id IS NOT NULL AND transfer_account_id IS NULL)
    )
);

CREATE INDEX idx_tx_user_date ON transactions (user_id, date);
CREATE INDEX idx_tx_account ON transactions (account_id);
CREATE INDEX idx_tx_category ON transactions (category_id);

CREATE TABLE budgets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    category_id   UUID NOT NULL REFERENCES categories (id) ON DELETE RESTRICT,
    year_month    CHAR(7) NOT NULL CHECK (year_month ~ '^\d{4}-\d{2}$'),
    limit_amount  DECIMAL(14, 2) NOT NULL CHECK (limit_amount > 0),
    CONSTRAINT uq_budgets_user_category_month UNIQUE (user_id, category_id, year_month)
);

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens (token_hash);
