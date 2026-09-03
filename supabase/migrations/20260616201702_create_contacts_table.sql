
-- ============================================================
-- Tabela: contacts (leads do site)
-- ============================================================
CREATE TABLE IF NOT EXISTS contacts (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT        NOT NULL,
  email            TEXT        NOT NULL,
  phone            TEXT,
  message          TEXT        NOT NULL,
  service_interest TEXT,       -- ex: regularizacao, due-diligence, inventario, etc.
  status           TEXT        NOT NULL DEFAULT 'novo'
                               CHECK (status IN ('novo','em_contato','convertido','descartado')),
  source           TEXT,       -- ex: homepage, blog, whatsapp, instagram
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Row-Level Security
-- ============================================================
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Qualquer visitante pode enviar um contato (formulário público)
CREATE POLICY "public_insert_contacts"
  ON contacts FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Apenas admins autenticados podem ler
CREATE POLICY "auth_select_contacts"
  ON contacts FOR SELECT
  TO authenticated
  USING (true);

-- Apenas admins autenticados podem atualizar (ex: mudar status)
CREATE POLICY "auth_update_contacts"
  ON contacts FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- Trigger: atualiza updated_at automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_contacts_updated_at
  BEFORE UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Índices para as queries do painel admin
-- ============================================================
CREATE INDEX idx_contacts_created_at  ON contacts(created_at DESC);
CREATE INDEX idx_contacts_status      ON contacts(status);
CREATE INDEX idx_contacts_email       ON contacts(email);
;
