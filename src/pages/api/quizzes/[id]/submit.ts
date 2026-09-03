import type { APIRoute } from 'astro';
import { createSupabaseAdminClient } from '../../../../lib/supabase';

export const prerender = false;

interface QuizQuestion {
  text: string;
  options: string[];
}

export const POST: APIRoute = async ({ params, request, locals }) => {
  const { id } = params;
  if (!id) return json({ error: 'id é obrigatório.' }, 422);

  let body: Record<string, any>;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Corpo inválido.' }, 400);
  }

  const { name, email, phone, response_id } = body as Record<string, string | undefined>;

  if (!name?.trim() || name.trim().length < 2) {
    return json({ error: 'Nome é obrigatório (mínimo 2 caracteres).' }, 422);
  }

  const hasEmail = !!email?.trim();
  const hasPhone = !!phone?.trim();

  if (!hasEmail && !hasPhone) {
    return json({ error: 'Informe e-mail ou WhatsApp.' }, 422);
  }

  if (hasEmail) {
    const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRe.test(email!.trim())) {
      return json({ error: 'E-mail inválido.' }, 422);
    }
  }

  if (hasPhone) {
    const digits = phone!.replace(/\D/g, '');
    if (digits.length < 10) {
      return json({ error: 'WhatsApp inválido (mínimo 10 dígitos).' }, 422);
    }
  }

  // Busca com a anon key: respeita a RLS que só expõe quizzes ativos.
  const { data: quiz, error: quizErr } = await locals.supabase
    .from('quizzes')
    .select('id, name, source_tag, service_interest, questions')
    .eq('id', id)
    .eq('is_active', true)
    .single();

  if (quizErr || !quiz) return json({ error: 'Quiz não encontrado ou inativo.' }, 404);

  const questions: QuizQuestion[] = Array.isArray(quiz.questions) ? quiz.questions : [];
  const answers = pairAnswers(questions, body.answers);

  if (answers.length < questions.length) {
    return json({ error: 'Responda todas as perguntas antes de enviar.' }, 422);
  }

  // Service role: a anon key não pode ler de volta o registro gravado
  // (não há policy de SELECT pública em contacts nem em quiz_responses),
  // e sem a leitura não dá para vincular o lead à resposta do quiz.
  const admin = createSupabaseAdminClient();

  const summary = answers.map((a, i) => `${i + 1}. ${a.question} → ${a.answer}`).join('\n');

  const contactData = {
    name: name.trim(),
    phone: hasPhone ? formatPhone(phone!) : null,
    message: `Quiz: ${quiz.name}\n${summary}`,
    service_interest: quiz.service_interest ?? null,
    source: quiz.source_tag,
  };

  const { data: contact, error: contactErr } = hasEmail
    ? await admin
        .from('contacts')
        .upsert({ ...contactData, email: email!.trim().toLowerCase() }, { onConflict: 'email' })
        .select('id')
        .single()
    : await admin
        .from('contacts')
        .insert({ ...contactData, email: `phone_${Date.now()}@noemail.local` })
        .select('id')
        .single();

  // O lead é o entregável: se ele não gravou, o visitante precisa saber.
  if (contactErr || !contact) {
    return json({ error: 'Não foi possível registrar seus dados. Tente novamente.' }, 500);
  }

  const completion = {
    answers,
    contact_id: contact.id,
    status: 'completed',
    completed_at: new Date().toISOString(),
  };

  if (response_id) {
    const { data: updated } = await admin
      .from('quiz_responses')
      .update(completion)
      .eq('id', response_id)
      .eq('quiz_id', quiz.id)
      .select('id')
      .maybeSingle();

    // Se a linha de início não existe ou não pertence a este quiz, grava uma nova.
    if (!updated) {
      await admin.from('quiz_responses').insert({ quiz_id: quiz.id, ...completion });
    }
  } else {
    await admin.from('quiz_responses').insert({ quiz_id: quiz.id, ...completion });
  }

  return json({ ok: true }, 200);
};

function pairAnswers(questions: QuizQuestion[], raw: unknown): { question: string; answer: string }[] {
  if (!Array.isArray(raw)) return [];

  const paired: { question: string; answer: string }[] = [];

  questions.forEach((q, i) => {
    const item = raw[i];
    const answer = typeof item === 'string'
      ? item.trim()
      : String((item as { answer?: unknown })?.answer ?? '').trim();

    if (answer) paired.push({ question: q.text, answer });
  });

  return paired;
}

function formatPhone(phone: string) {
  return phone.replace(/\D/g, '').replace(/^(\d{2})(\d{4,5})(\d{4})$/, '($1) $2-$3');
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
