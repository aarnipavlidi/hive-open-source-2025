ALTER TABLE guidances
    RENAME COLUMN reason TO context;

ALTER TABLE guidances
    DROP COLUMN IF EXISTS status;

ALTER TABLE guidances
    ADD COLUMN IF NOT EXISTS city TEXT NOT NULL DEFAULT 'Helsinki';
