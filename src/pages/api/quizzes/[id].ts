import type { APIRoute } from 'astro';
import { normalizeQuestions, normalizeWhatsapp } from './create';

export const prerender = false;

export const GET: APIRoute = async ({ params, locals }) => {
  const { id } = params;
  if (!id) return json({ error: 'id é obrigatório.' }, 422);

  const { data: quiz, error } = await locals.supabase
    .from('quizzes')
    .select('id, title, subtitle, questions, success_message, whatsapp_number')
    .eq('id', id)
    .eq('is_active', true)
    .single();

  if (error || !quiz) return json({ error: 'Quiz não encontrado.' }, 404);

  return json(quiz, 200);
};

export const PATCH: APIRoute = async ({ params, request, locals }) => {
  const { data: { user } } = await locals.supabase.auth.getUser();
  if (!user) return json({ error: 'Não autorizado.' }, 401);

  const { id } = params;
  if (!id) return json({ error: 'id é obrigatório.' }, 422);

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Corpo inválido.' }, 400);
  }

  const patch: Record<string, unknown> = {};

  if (body.questions !== undefined) {
    const questions = normalizeQuestions(body.questions);
    if ('error' in questions) return json({ error: questions.error }, 422);
    patch.questions = questions.value;
  }

  for (const field of ['name', 'title'] as const) {
    if (body[field] !== undefined) {
      const val = String(body[field] ?? '').trim();
      if (!val) return json({ error: `O campo ${field} não pode ficar vazio.` }, 422);
      patch[field] = val;
    }
  }

  for (const field of ['subtitle', 'service_interest', 'meta_title', 'meta_description', 'og_image'] as const) {
    if (body[field] !== undefined) {
      patch[field] = String(body[field] ?? '').trim() || null;
    }
  }

  if (body.whatsapp_number !== undefined) {
    patch.whatsapp_number = normalizeWhatsapp(body.whatsapp_number as string | null);
  }

  if (body.success_message !== undefined) {
    patch.success_message = String(body.success_message ?? '').trim()
      || 'Obrigado! Entraremos em contato em breve.';
  }

  if (Object.keys(patch).length === 0) {
    return json({ error: 'Nada para atualizar.' }, 422);
  }

  const { error } = await locals.supabase.from('quizzes').update(patch).eq('id', id);
  if (error) return json({ error: error.message }, 500);

  return json({ ok: true }, 200);
};

export const DELETE: APIRoute = async ({ params, locals }) => {
  const { data: { user } } = await locals.supabase.auth.getUser();
  if (!user) return json({ error: 'Não autorizado.' }, 401);

  const { id } = params;
  if (!id) return json({ error: 'id é obrigatório.' }, 422);

  const { error } = await locals.supabase.from('quizzes').delete().eq('id', id);
  if (error) return json({ error: error.message }, 500);

  return json({ ok: true }, 200);
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
