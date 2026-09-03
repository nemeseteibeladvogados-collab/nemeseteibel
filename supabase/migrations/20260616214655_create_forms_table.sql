
CREATE TABLE IF NOT EXISTS forms (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT        NOT NULL,
  title            TEXT        NOT NULL,
  subtitle         TEXT,
  success_message  TEXT        NOT NULL DEFAULT 'Obrigado! Entraremos em contato em breve.',
  service_interest TEXT,
  source_tag       TEXT        NOT NULL,
  is_active        BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_select_active_forms"
  ON forms FOR SELECT TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "auth_all_forms"
  ON forms FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

CREATE TRIGGER set_forms_updated_at
  BEFORE UPDATE ON forms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_forms_active ON forms(is_active, created_at DESC);
CREATE UNIQUE INDEX idx_forms_source_tag ON forms(source_tag);
;
