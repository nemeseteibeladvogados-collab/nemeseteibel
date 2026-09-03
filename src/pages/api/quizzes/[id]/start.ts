import type { APIRoute } from 'astro';
import { createSupabaseAdminClient } from '../../../../lib/supabase';

export const prerender = false;

// Registra o início do quiz para compor o funil (início -> conclusão).
export const POST: APIRoute = async ({ params, locals }) => {
  const { id } = params;
  if (!id) return json({ error: 'id é obrigatório.' }, 422);

  // Busca com a anon key: respeita a RLS que só expõe quizzes ativos.
  const { data: quiz, error: quizErr } = await locals.supabase
    .from('quizzes')
    .select('id')
    .eq('id', id)
    .eq('is_active', true)
    .single();

  if (quizErr || !quiz) return json({ error: 'Quiz não encontrado ou inativo.' }, 404);

  // Service role: as respostas não ficam legíveis nem graváveis pela anon key,
  // e só assim é possível ler de volta o id da linha criada.
  const { data: response, error } = await createSupabaseAdminClient()
    .from('quiz_responses')
    .insert({ quiz_id: quiz.id, status: 'started' })
    .select('id')
    .single();

  if (error) return json({ error: error.message }, 500);

  return json({ response_id: response.id }, 201);
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
