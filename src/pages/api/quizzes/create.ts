import type { APIRoute } from 'astro';

export const prerender = false;

interface QuestionInput {
  text?: string;
  options?: unknown;
}

export const POST: APIRoute = async ({ request, locals }) => {
  const { data: { user } } = await locals.supabase.auth.getUser();
  if (!user) return json({ error: 'Não autorizado.' }, 401);

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Corpo inválido.' }, 400);
  }

  const {
    name, title, subtitle, source_tag, service_interest, success_message,
    whatsapp_number, meta_title, meta_description, og_image,
  } = body as Record<string, string | null>;

  if (!name?.trim() || !title?.trim() || !source_tag?.trim()) {
    return json({ error: 'Nome, título e source tag são obrigatórios.' }, 422);
  }

  const questions = normalizeQuestions(body.questions);
  if ('error' in questions) return json({ error: questions.error }, 422);

  const tagClean = source_tag.trim().toLowerCase().replace(/[^a-z0-9-]/g, '-').replace(/-+/g, '-');

  const { data: quiz, error } = await locals.supabase
    .from('quizzes')
    .insert({
      name: name.trim(),
      title: title.trim(),
      subtitle: subtitle?.trim() || null,
      source_tag: tagClean,
      service_interest: service_interest?.trim() || null,
      whatsapp_number: normalizeWhatsapp(whatsapp_number),
      meta_title: meta_title?.trim() || null,
      meta_description: meta_description?.trim() || null,
      og_image: og_image?.trim() || null,
      questions: questions.value,
      success_message: success_message?.trim() || 'Obrigado! Entraremos em contato em breve.',
    })
    .select('id, name')
    .single();

  if (error) {
    const msg = error.message.includes('unique') || error.code === '23505'
      ? 'Já existe um quiz com esse source tag. Use um diferente.'
      : error.message;
    return json({ error: msg }, 500);
  }

  return json({ id: quiz.id, name: quiz.name }, 201);
};

export function normalizeQuestions(raw: unknown): { value: { text: string; options: string[] }[] } | { error: string } {
  if (!Array.isArray(raw) || raw.length === 0) {
    return { error: 'Adicione pelo menos uma pergunta.' };
  }

  const value: { text: string; options: string[] }[] = [];

  for (const [i, item] of raw.entries()) {
    const q = item as QuestionInput;
    const text = typeof q?.text === 'string' ? q.text.trim() : '';
    if (!text) return { error: `A pergunta ${i + 1} está sem enunciado.` };

    const options = Array.isArray(q?.options)
      ? q.options.map((o) => String(o ?? '').trim()).filter(Boolean)
      : [];

    if (options.length < 2) {
      return { error: `A pergunta ${i + 1} precisa de pelo menos 2 opções.` };
    }

    value.push({ text, options });
  }

  return { value };
}

// Só dígitos; vazio vira null para a página cair no número do escritório.
export function normalizeWhatsapp(raw: string | null | undefined): string | null {
  return (raw ?? '').replace(/\D/g, '') || null;
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
