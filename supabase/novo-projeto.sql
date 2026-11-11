-- Estrutura completa do banco (todas as migrations de supabase/migrations em ordem).
-- Cole no SQL Editor de um projeto Supabase NOVO e vazio e execute uma única vez.

-- >>> 20260616201702_create_contacts_table.sql

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

-- >>> 20260616212030_create_materials_and_downloads.sql

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

-- >>> 20260616212119_create_increment_download_count_rpc.sql

CREATE OR REPLACE FUNCTION increment_download_count(material_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE materials
  SET download_count = download_count + 1
  WHERE id = material_id;
END;
$$;
;

-- >>> 20260616213221_storage_policies_and_rpc_grants.sql

-- Políticas de Storage para o bucket 'materials'
-- Admins autenticados podem fazer upload
CREATE POLICY "auth_upload_materials"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'materials');

-- Admins autenticados podem deletar
CREATE POLICY "auth_delete_materials"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'materials');

-- Qualquer pessoa pode gerar signed URL (SELECT necessário para createSignedUrl)
CREATE POLICY "public_read_materials"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'materials');

-- Permite que anon e authenticated chamem o RPC de incremento
GRANT EXECUTE ON FUNCTION increment_download_count(UUID) TO anon, authenticated;
;

-- >>> 20260616214655_create_forms_table.sql

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

-- >>> 20260616232257_create_page_settings.sql

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

-- >>> 20260903000000_create_quizzes_tables.sql
-- ============================================================
-- Tabela: quizzes (quiz multi-etapa de captação de leads)
-- ============================================================
CREATE TABLE IF NOT EXISTS quizzes (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT        NOT NULL,
  title            TEXT        NOT NULL,
  subtitle         TEXT,
  success_message  TEXT        NOT NULL DEFAULT 'Obrigado! Entraremos em contato em breve.',
  service_interest TEXT,
  source_tag       TEXT        NOT NULL,
  questions        JSONB       NOT NULL DEFAULT '[]'::jsonb,
  is_active        BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN quizzes.questions IS
  'Array de perguntas: [{ "text": "Pergunta?", "options": ["A", "B"] }]';

ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_select_active_quizzes"
  ON quizzes FOR SELECT TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "auth_all_quizzes"
  ON quizzes FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

CREATE TRIGGER set_quizzes_updated_at
  BEFORE UPDATE ON quizzes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_quizzes_active ON quizzes(is_active, created_at DESC);
CREATE UNIQUE INDEX idx_quizzes_source_tag ON quizzes(source_tag);

-- ============================================================
-- Tabela: quiz_responses (funil início -> conclusão + respostas)
-- ============================================================
CREATE TABLE IF NOT EXISTS quiz_responses (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id      UUID        NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  contact_id   UUID        REFERENCES contacts(id) ON DELETE SET NULL,
  answers      JSONB       NOT NULL DEFAULT '[]'::jsonb,
  status       TEXT        NOT NULL DEFAULT 'started'
                           CHECK (status IN ('started','completed')),
  started_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

COMMENT ON COLUMN quiz_responses.answers IS
  'Array de respostas: [{ "question": "Pergunta?", "answer": "Opção escolhida" }]';

ALTER TABLE quiz_responses ENABLE ROW LEVEL SECURITY;

-- Qualquer visitante pode iniciar um quiz
CREATE POLICY "public_insert_quiz_responses"
  ON quiz_responses FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ...e concluir a própria linha iniciada (nunca alterar uma já concluída)
CREATE POLICY "public_update_started_quiz_responses"
  ON quiz_responses FOR UPDATE
  TO anon, authenticated
  USING (status = 'started')
  WITH CHECK (true);

-- Apenas admins autenticados leem as respostas
CREATE POLICY "auth_select_quiz_responses"
  ON quiz_responses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "auth_delete_quiz_responses"
  ON quiz_responses FOR DELETE
  TO authenticated
  USING (true);

CREATE INDEX idx_quiz_responses_quiz    ON quiz_responses(quiz_id, started_at DESC);
CREATE INDEX idx_quiz_responses_funnel  ON quiz_responses(quiz_id, status);
CREATE INDEX idx_quiz_responses_contact ON quiz_responses(contact_id);

-- >>> 20260903000001_contacts_email_unique.sql
-- ============================================================
-- Correção: contacts.email não tinha índice UNIQUE.
--
-- `/api/forms/[id]/submit`, `/api/materials/download` e o novo
-- `/api/quizzes/[id]/submit` usam upsert com onConflict: 'email'.
-- Sem o índice UNIQUE o Postgres devolve 42P10 ("no unique or
-- exclusion constraint matching the ON CONFLICT specification") e,
-- como os endpoints não checam o erro, todo lead que informava
-- e-mail era silenciosamente descartado.
--
-- O índice não-único idx_contacts_email continua servindo às buscas
-- do painel; este substitui a necessidade dele para o upsert.
-- ============================================================
CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_email_unique ON contacts(email);

-- >>> 20260903000002_quiz_responses_server_only.sql
-- ============================================================
-- quiz_responses passa a ser escrita apenas pelo servidor.
--
-- As policies públicas de INSERT/UPDATE não bastavam: a anon key
-- não tem SELECT na tabela, então todo insert com RETURNING
-- (`.insert().select()`, usado para devolver o response_id ao
-- navegador) falhava com 42501 — o Postgres reporta a ausência de
-- SELECT como violação de RLS na linha inserida.
--
-- Em vez de abrir SELECT público sobre as respostas dos leads,
-- `/api/quizzes/[id]/start` e `/submit` passam a usar a service
-- role. Com isso a anon key não precisa de acesso nenhum aqui:
-- ninguém consegue ler nem inserir respostas direto na API pública.
-- ============================================================
DROP POLICY IF EXISTS "public_insert_quiz_responses"         ON quiz_responses;
DROP POLICY IF EXISTS "public_update_started_quiz_responses" ON quiz_responses;

-- >>> 20260903000003_quizzes_whatsapp_number.sql
-- ============================================================
-- Botão "enviar respostas no WhatsApp" na tela de sucesso do quiz.
--
-- Opcional e por quiz: em branco, a página usa o número do
-- escritório (556541410010, o mesmo do resto do site). Preenchido,
-- permite rotear o quiz direto para a sócia responsável pelo tema.
--
-- Formato esperado: só dígitos, com DDI + DDD (ex: 556541410010).
-- ============================================================
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS whatsapp_number TEXT;

COMMENT ON COLUMN quizzes.whatsapp_number IS
  'Número de destino do botão de WhatsApp (só dígitos, DDI+DDD). NULL = número padrão do escritório.';

-- >>> 20260903000004_quizzes_share_metadata.sql
-- ============================================================
-- Metadados de compartilhamento do quiz (WhatsApp, Instagram,
-- Facebook, LinkedIn — tudo que lê Open Graph).
--
-- Sem estes campos, o preview usaria `title`, que é o texto da
-- ETAPA FINAL ("Pronto! Para onde enviamos seu diagnóstico?") —
-- sem sentido nenhum para quem ainda nem abriu o link.
--
-- Todos opcionais: em branco, a página cai nos textos do quiz e
-- na imagem padrão /images/og-quiz.jpg.
-- ============================================================
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS meta_title       TEXT;
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS meta_description TEXT;
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS og_image         TEXT;

COMMENT ON COLUMN quizzes.meta_title IS
  'Título do preview ao compartilhar o link. NULL = usa title.';
COMMENT ON COLUMN quizzes.meta_description IS
  'Descrição do preview ao compartilhar o link. NULL = usa subtitle.';
COMMENT ON COLUMN quizzes.og_image IS
  'Imagem do preview: caminho do site (/images/og-quiz.jpg) ou URL absoluta. NULL = imagem padrão.';
