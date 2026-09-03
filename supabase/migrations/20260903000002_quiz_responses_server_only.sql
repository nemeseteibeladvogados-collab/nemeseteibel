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
