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
