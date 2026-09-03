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
