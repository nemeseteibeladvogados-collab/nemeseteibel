// Copia dados, arquivos e usuários admin do Supabase antigo para o novo.
//
//   node scripts/migrate-supabase.mjs            -> só compara (não grava nada)
//   node scripts/migrate-supabase.mjs --executar -> copia de fato
//
// Origem:  .env       (projeto atual)
// Destino: .env.novo  (projeto novo; mesmas 3 variáveis do .env)
//
// Antes de rodar, a estrutura precisa existir no projeto novo: cole o conteúdo
// de supabase/novo-projeto.sql no SQL Editor do projeto novo e execute.
// Pode rodar mais de uma vez: usa upsert, não duplica nada.
import { createClient } from '@supabase/supabase-js';
import { readFileSync, existsSync } from 'fs';
import { randomBytes } from 'crypto';

const EXECUTAR = process.argv.includes('--executar');

// Ordem respeita as chaves estrangeiras (pais antes dos filhos).
const TABELAS = [
  { nome: 'contacts', pk: 'id' },
  { nome: 'materials', pk: 'id' },
  { nome: 'forms', pk: 'id' },
  { nome: 'quizzes', pk: 'id' },
  { nome: 'page_settings', pk: 'slug' },
  { nome: 'material_downloads', pk: 'id' },
  { nome: 'quiz_responses', pk: 'id' },
];

function lerEnv(arquivo) {
  if (!existsSync(arquivo)) {
    console.error(`\nArquivo ${arquivo} não encontrado.\n`);
    process.exit(1);
  }
  const env = Object.fromEntries(
    readFileSync(arquivo, 'utf-8')
      .split(/\r?\n/)
      .filter((l) => l && !l.startsWith('#') && l.includes('='))
      .map((l) => {
        const i = l.indexOf('=');
        return [l.slice(0, i).trim(), l.slice(i + 1).trim().replace(/^"|"$/g, '')];
      }),
  );
  for (const k of ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY']) {
    if (!env[k]) {
      console.error(`\n${k} está faltando em ${arquivo}.\n`);
      process.exit(1);
    }
  }
  return env;
}

function conectar(env) {
  return createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function colunas(env) {
  const r = await fetch(`${env.SUPABASE_URL}/rest/v1/`, {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });
  if (!r.ok) throw new Error(`${env.SUPABASE_URL} respondeu ${r.status}`);
  const spec = await r.json();
  const out = {};
  for (const [tabela, def] of Object.entries(spec.definitions ?? {})) {
    out[tabela] = Object.entries(def.properties ?? {})
      .map(([col, p]) => `${col}:${p.format ?? p.type}`)
      .sort();
  }
  return out;
}

async function lerTudo(sb, tabela, pk) {
  const linhas = [];
  for (let de = 0; ; de += 1000) {
    const { data, error } = await sb.from(tabela).select('*').order(pk).range(de, de + 999);
    if (error) throw new Error(`${tabela}: ${error.message}`);
    linhas.push(...data);
    if (data.length < 1000) return linhas;
  }
}

async function contar(sb, tabela) {
  const { count, error } = await sb.from(tabela).select('*', { count: 'exact', head: true });
  if (error) throw new Error(`${tabela}: ${error.message}`);
  return count;
}

async function listarArquivos(sb, bucket, pasta = '') {
  const arquivos = [];
  const { data, error } = await sb.storage.from(bucket).list(pasta, { limit: 1000 });
  if (error) throw new Error(`storage ${bucket}: ${error.message}`);
  for (const item of data ?? []) {
    const caminho = pasta ? `${pasta}/${item.name}` : item.name;
    if (item.id === null) arquivos.push(...(await listarArquivos(sb, bucket, caminho)));
    else arquivos.push({ caminho, tipo: item.metadata?.mimetype, tamanho: item.metadata?.size ?? 0 });
  }
  return arquivos;
}

const envAntigo = lerEnv('.env');
const envNovo = lerEnv('.env.novo');
if (envAntigo.SUPABASE_URL === envNovo.SUPABASE_URL) {
  console.error('\n.env e .env.novo apontam para o MESMO projeto. Nada a fazer.\n');
  process.exit(1);
}
const antigo = conectar(envAntigo);
const novo = conectar(envNovo);

console.log(`\nOrigem:  ${envAntigo.SUPABASE_URL}`);
console.log(`Destino: ${envNovo.SUPABASE_URL}`);
console.log(EXECUTAR ? 'Modo: EXECUTAR (grava no destino)\n' : 'Modo: comparação (nada é gravado)\n');

// 1. Estrutura
const [colsAntigo, colsNovo] = await Promise.all([colunas(envAntigo), colunas(envNovo)]);
let estruturaOk = true;
for (const { nome } of TABELAS) {
  const a = colsAntigo[nome];
  const n = colsNovo[nome];
  if (!n) {
    console.log(`ESTRUTURA  ${nome}: não existe no destino`);
    estruturaOk = false;
    continue;
  }
  const faltam = a.filter((c) => !n.includes(c));
  const sobram = n.filter((c) => !a.includes(c));
  if (faltam.length || sobram.length) {
    estruturaOk = false;
    console.log(`ESTRUTURA  ${nome}: diferente`);
    if (faltam.length) console.log(`           faltam no destino: ${faltam.join(', ')}`);
    if (sobram.length) console.log(`           só no destino:     ${sobram.join(', ')}`);
  }
}
const extras = Object.keys(colsAntigo).filter((t) => !TABELAS.some((x) => x.nome === t));
if (extras.length) {
  estruturaOk = false;
  console.log(`ESTRUTURA  tabelas na origem que este script não conhece: ${extras.join(', ')}`);
}
if (!estruturaOk) {
  console.log('\nA estrutura do destino não bate com a origem. Execute supabase/novo-projeto.sql');
  console.log('no SQL Editor do projeto novo e rode este script de novo.\n');
  process.exit(1);
}
console.log('ESTRUTURA  ok: mesmas tabelas e colunas nos dois projetos');

// 2. Tabelas
let tudoIgual = true;
for (const { nome, pk } of TABELAS) {
  const linhas = await lerTudo(antigo, nome, pk);
  if (EXECUTAR) {
    for (let i = 0; i < linhas.length; i += 500) {
      const { error } = await novo.from(nome).upsert(linhas.slice(i, i + 500), { onConflict: pk });
      if (error) throw new Error(`gravando ${nome}: ${error.message}`);
    }
  }
  const noDestino = await contar(novo, nome);
  const ok = noDestino >= linhas.length;
  if (!ok) tudoIgual = false;
  console.log(`TABELA     ${nome.padEnd(20)} origem ${String(linhas.length).padStart(5)}   destino ${String(noDestino).padStart(5)}   ${ok ? 'ok' : 'FALTA'}`);
}

// 3. Storage
const { data: buckets, error: bErr } = await antigo.storage.listBuckets();
if (bErr) throw new Error(`listando buckets: ${bErr.message}`);
const { data: bucketsNovo } = await novo.storage.listBuckets();
for (const b of buckets) {
  if (!bucketsNovo?.some((x) => x.id === b.id)) {
    if (EXECUTAR) {
      const { error } = await novo.storage.createBucket(b.id, {
        public: b.public,
        fileSizeLimit: b.file_size_limit ?? undefined,
        allowedMimeTypes: b.allowed_mime_types ?? undefined,
      });
      if (error) throw new Error(`criando bucket ${b.id}: ${error.message}`);
    } else {
      console.log(`STORAGE    bucket ${b.id}: não existe no destino`);
      tudoIgual = false;
      continue;
    }
  }
  const arquivos = await listarArquivos(antigo, b.id);
  if (EXECUTAR) {
    for (const a of arquivos) {
      const { data: blob, error: dErr } = await antigo.storage.from(b.id).download(a.caminho);
      if (dErr) throw new Error(`baixando ${a.caminho}: ${dErr.message}`);
      const { error: uErr } = await novo.storage
        .from(b.id)
        .upload(a.caminho, blob, { contentType: a.tipo, upsert: true });
      if (uErr) throw new Error(`enviando ${a.caminho}: ${uErr.message}`);
    }
  }
  const noDestino = await listarArquivos(novo, b.id);
  const faltando = arquivos.filter(
    (a) => !noDestino.some((n) => n.caminho === a.caminho && n.tamanho === a.tamanho),
  );
  if (faltando.length) tudoIgual = false;
  console.log(`STORAGE    bucket ${b.id.padEnd(13)} origem ${String(arquivos.length).padStart(5)}   destino ${String(noDestino.length).padStart(5)}   ${faltando.length ? 'FALTA' : 'ok'}`);
}

// 4. Usuários admin (a senha não pode ser copiada pela API: cada um recebe uma senha provisória)
const { data: uAntigo, error: uErr } = await antigo.auth.admin.listUsers({ perPage: 1000 });
if (uErr) throw new Error(`listando usuários: ${uErr.message}`);
const { data: uNovo, error: uErr2 } = await novo.auth.admin.listUsers({ perPage: 1000 });
if (uErr2) throw new Error(`listando usuários do destino: ${uErr2.message}`);
for (const u of uAntigo.users) {
  if (uNovo.users.some((x) => x.email === u.email)) {
    console.log(`USUÁRIO    ${u.email}: já existe no destino`);
    continue;
  }
  if (!EXECUTAR) {
    console.log(`USUÁRIO    ${u.email}: não existe no destino`);
    tudoIgual = false;
    continue;
  }
  const senha = randomBytes(12).toString('base64url');
  const { error } = await novo.auth.admin.createUser({
    email: u.email,
    password: senha,
    email_confirm: true,
    user_metadata: u.user_metadata,
  });
  if (error) throw new Error(`criando ${u.email}: ${error.message}`);
  console.log(`USUÁRIO    ${u.email}: criado. Senha provisória: ${senha}`);
  console.log(`           (troque depois com: node scripts/create-admin.mjs ${u.email} <nova-senha>)`);
}

console.log(
  tudoIgual
    ? '\nDestino contém tudo o que existe na origem.\n'
    : EXECUTAR
      ? '\nATENÇÃO: ainda há diferenças (veja as linhas marcadas com FALTA).\n'
      : '\nHá diferenças. Rode com --executar para copiar.\n',
);
process.exit(tudoIgual ? 0 : 1);
