
-- ============================================================
-- Tabela: materials (biblioteca de materiais)
-- ============================================================
CREATE TABLE IF NOT EXISTS materials (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title          TEXT        NOT NULL,
  description    TEXT,
  file_path      TEXT        NOT NULL,
  file_name      TEXT        NOT NULL,
  file_size      INTEGER,
  category       TEXT,
  is_active      BOOLEAN     NOT NULL DEFAULT true,
  download_count INTEGER     NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE materials ENABLE ROW LEVEL SECURITY;

-- Visitantes podem ler materiais ativos
CREATE POLICY "public_select_active_materials"
  ON materials FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Admins autenticados podem gerenciar todos
CREATE POLICY "auth_all_materials"
  ON materials FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE TRIGGER set_materials_updated_at
  BEFORE UPDATE ON materials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_materials_active     ON materials(is_active, created_at DESC);
CREATE INDEX idx_materials_category   ON materials(category);

-- ============================================================
-- Tabela: material_downloads (rastreamento de downloads)
-- ============================================================
CREATE TABLE IF NOT EXISTS material_downloads (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID        NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  contact_id  UUID        REFERENCES contacts(id) ON DELETE SET NULL,
  name        TEXT        NOT NULL,
  email       TEXT,
  phone       TEXT,
  source      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE material_downloads ENABLE ROW LEVEL SECURITY;

-- Qualquer visitante pode registrar um download (lead capture)
CREATE POLICY "public_insert_downloads"
  ON material_downloads FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Apenas admins podem ver os downloads
CREATE POLICY "auth_select_downloads"
  ON material_downloads FOR SELECT
  TO authenticated
  USING (true);

CREATE INDEX idx_downloads_material   ON material_downloads(material_id, created_at DESC);
CREATE INDEX idx_downloads_contact    ON material_downloads(contact_id);

-- ============================================================
-- Storage: bucket 'materials' (privado)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'materials',
  'materials',
  false,
  52428800,  -- 50 MB
  ARRAY['application/pdf','image/jpeg','image/png','image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Service role tem acesso total via API (não precisa de policy pois usamos chave service_role)
-- Signed URLs são geradas server-side, sem acesso público direto
;
