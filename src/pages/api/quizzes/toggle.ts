import type { APIRoute } from 'astro';

export const prerender = false;

export const POST: APIRoute = async ({ request, locals }) => {
  const { data: { user } } = await locals.supabase.auth.getUser();
  if (!user) return json({ error: 'Não autorizado.' }, 401);

  let body: { id?: string; is_active?: boolean };
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Corpo inválido.' }, 400);
  }

  const { id, is_active } = body;
  if (!id || typeof is_active !== 'boolean') {
    return json({ error: 'id e is_active são obrigatórios.' }, 422);
  }

  const { error } = await locals.supabase
    .from('quizzes')
    .update({ is_active })
    .eq('id', id);

  if (error) return json({ error: error.message }, 500);

  return json({ ok: true }, 200);
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
