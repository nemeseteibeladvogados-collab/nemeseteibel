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
