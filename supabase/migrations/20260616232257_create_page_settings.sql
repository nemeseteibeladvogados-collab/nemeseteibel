
-- Tabela para controlar ativação/desativação de páginas públicas
CREATE TABLE IF NOT EXISTS page_settings (
  slug TEXT PRIMARY KEY,
  is_active BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: qualquer um pode ler (middleware precisa), apenas autenticados alteram
ALTER TABLE page_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anyone_can_read_page_settings"
  ON page_settings FOR SELECT
  USING (true);

CREATE POLICY "authenticated_can_update_page_settings"
  ON page_settings FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "authenticated_can_insert_page_settings"
  ON page_settings FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Seed com as páginas controláveis
INSERT INTO page_settings (slug, is_active) VALUES
  ('/due-diligence-rural', true),
  ('/regularizacao-imovel-rural', true),
  ('/regularizacao-ambiental-rural', true),
  ('/dr-manuela', true),
  ('/dr-paula', true),
  ('/materiais', true)
ON CONFLICT (slug) DO NOTHING;
;
