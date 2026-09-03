# Nemes & Teibel Advogados - Especificacoes do Projeto

## Visao Geral

Site institucional + landing pages + painel administrativo para o escritorio de advocacia **Nemes & Teibel Advogados**, especializado em Direito Agrario, Fundiario e Ambiental em Mato Grosso.

**URL de producao:** `https://nemeseteibeladv.com.br`

---

## Stack Tecnologica

| Camada       | Tecnologia                         |
| ------------ | ---------------------------------- |
| Framework    | **Astro 4.x** (output `hybrid`)   |
| Linguagem    | TypeScript                         |
| Deploy       | **Vercel** (serverless functions)  |
| Banco/Auth   | **Supabase** (PostgreSQL + Auth)   |
| Storage      | **Supabase Storage** (bucket `materials`) |
| CSS          | CSS puro (sem Tailwind/framework)  |
| Fontes       | Google Fonts (DM Sans + Playfair Display) |

### Dependencias (`package.json`)

```
astro@^4.16.18
@astrojs/vercel@^7.8.2       # adapter para deploy na Vercel
@supabase/supabase-js@^2.108 # client Supabase
@supabase/ssr@^0.12.0        # auth SSR com cookies
ws@^8.21.0                   # WebSocket p/ Supabase realtime
typescript@^5.9.3
```

### Scripts

```bash
npm run dev       # servidor local (astro dev)
npm run build     # build + fix-vercel-runtime
npm run preview   # preview local do build
```

---

## Configuracao do Astro (`astro.config.mjs`)

```js
output: 'hybrid'     // paginas sao estaticas por padrao (SSG)
                      // usar `export const prerender = false` para SSR
adapter: vercel()     // deploy como serverless functions
publicDir: 'assets'   // pasta de arquivos estaticos (assets/img/ -> /img/)
site: 'https://nemeseteibeladv.com.br'
```

**Modo Hybrid explicado:**
- Paginas **sem** `export const prerender = false` -> gera HTML estatico no build (rapido, CDN)
- Paginas **com** `export const prerender = false` -> roda no servidor a cada request (SSR)
- Todas as paginas do `/admin`, `/api` e paginas dinamicas usam `prerender = false`

---

## Estrutura de Pastas

```
nemeseteibel/
|-- assets/                   # arquivos estaticos (= publicDir)
|   |-- img/                  # imagens (bg, logos, equipe, etc.)
|   |-- images/               # og-image, favicon
|
|-- src/
|   |-- components/           # componentes Astro reutilizaveis
|   |   |-- Navbar.astro      # menu de navegacao do site
|   |   |-- Footer.astro      # rodape do site
|   |   |-- Hero.astro        # hero section da home
|   |   |-- Services.astro    # secao de servicos
|   |   |-- Team.astro        # secao equipe
|   |   |-- Problems.astro    # secao problemas/dores
|   |   |-- Insights.astro    # secao insights/conteudo
|   |   |-- Ticker.astro      # ticker animado
|   |
|   |-- content/              # colecoes de conteudo (Astro Content Collections)
|   |   |-- config.ts         # schema da colecao blog
|   |   |-- blog/             # artigos em Markdown
|   |       |-- regularizacao-fundiaria.md
|   |       |-- bndes-car-analisado.md
|   |       |-- invasoes-no-campo.md
|   |       |-- sigef-2025-atualizacoes-novo-modelo-incra.md
|   |
|   |-- layouts/
|   |   |-- Layout.astro      # layout principal (navbar + footer + SEO)
|   |   |-- LPLayout.astro    # layout para landing pages (sem navbar, noindex)
|   |
|   |-- lib/
|   |   |-- supabase.ts       # clientes Supabase (server + admin)
|   |
|   |-- middleware.ts          # middleware global (auth + page_settings)
|   |
|   |-- pages/                # rotas (file-based routing do Astro)
|   |   |-- index.astro               # pagina inicial (home)
|   |   |-- due-diligence-rural.astro  # LP: due diligence
|   |   |-- regularizacao-imovel-rural.astro   # LP: regularizacao fundiaria
|   |   |-- regularizacao-ambiental-rural.astro # LP: regularizacao ambiental
|   |   |-- dr-manuela.astro           # perfil Dra. Manuela
|   |   |-- dr-paula.astro             # perfil Dra. Paula
|   |   |-- indisponivel.astro         # pagina de "indisponivel" (redirect)
|   |   |
|   |   |-- blog/
|   |   |   |-- index.astro           # listagem de artigos
|   |   |   |-- [...slug].astro       # artigo individual (rota dinamica)
|   |   |
|   |   |-- materiais/
|   |   |   |-- index.astro           # pagina publica de materiais (captura leads)
|   |   |
|   |   |-- f/
|   |   |   |-- [id].astro            # formulario publico (renderizado por ID)
|   |   |
|   |   |-- q/
|   |   |   |-- [id].astro            # quiz publico multi-etapa (renderizado por ID)
|   |   |
|   |   |-- admin/
|   |   |   |-- login.astro           # tela de login
|   |   |   |-- index.astro           # dashboard
|   |   |   |-- paginas.astro         # gerenciamento de paginas
|   |   |   |-- formularios/index.astro # gerenciamento de formularios
|   |   |   |-- quizzes.astro         # gerenciamento de quizzes
|   |   |   |-- materiais.astro       # gerenciamento de materiais
|   |   |   |-- usuarios.astro        # gerenciamento de admins
|   |   |
|   |   |-- api/                      # endpoints REST (SSR)
|   |       |-- auth/logout.ts
|   |       |-- contacts/submit.ts
|   |       |-- forms/create.ts
|   |       |-- forms/toggle.ts
|   |       |-- forms/[id].ts
|   |       |-- forms/[id]/submit.ts
|       |-- quizzes/create.ts
|       |-- quizzes/toggle.ts
|       |-- quizzes/[id].ts
|       |-- quizzes/[id]/start.ts
|       |-- quizzes/[id]/submit.ts
|   |       |-- materials/upload.ts
|   |       |-- materials/toggle.ts
|   |       |-- materials/download.ts
|   |       |-- materials/[id].ts
|   |       |-- pages/toggle.ts
|   |
|   |-- styles/
|       |-- global.css         # estilos globais
|
|-- supabase/
|   |-- migrations/            # historico de migrations (supabase db push)
|
|-- astro.config.mjs           # configuracao do Astro
|-- package.json
|-- tsconfig.json
```

---

## Variaveis de Ambiente (`.env`)

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...            # chave publica (RLS)
SUPABASE_SERVICE_ROLE_KEY=eyJhbG...     # chave admin (bypassa RLS)
```

- `SUPABASE_ANON_KEY` -> usada em todas as paginas (respeita RLS)
- `SUPABASE_SERVICE_ROLE_KEY` -> usada apenas em `/admin/usuarios` e `/api/materials/toggle` (acesso total)

---

## Clientes Supabase (`src/lib/supabase.ts`)

### `createSupabaseServerClient(request, cookies)`
- Usa `@supabase/ssr` com `createServerClient`
- Gerencia cookies de sessao automaticamente (getAll/setAll)
- Usa a **anon key** (respeita RLS)
- Usado em: middleware, paginas admin, APIs

### `createSupabaseAdminClient()`
- Usa `createClient` com a **service role key**
- Nao persiste sessao (sem cookies)
- Bypassa RLS completamente
- Usado em: gestao de usuarios (`auth.admin.createUser/deleteUser/listUsers`) e toggle de materiais

---

## Middleware (`src/middleware.ts`)

O middleware roda em TODA request SSR e faz duas coisas:

### 1. Autenticacao do Admin
```
Se a URL comeca com /admin (exceto /admin/login):
  -> Verifica se ha usuario autenticado via supabase.auth.getUser()
  -> Se nao ha -> redireciona para /admin/login
  -> Se ha -> salva o user em context.locals.user
```

### 2. Controle de Paginas (page_settings)
```
Para qualquer URL que NAO seja /admin, /api, / ou /indisponivel:
  -> Consulta a tabela page_settings pelo slug
  -> Se a pagina esta marcada como inativa (is_active = false)
  -> Redireciona para /indisponivel
```

Isso permite que o admin desative qualquer landing page, artigo ou pagina de perfil pelo painel sem precisar alterar codigo.

---

## Layouts

### `Layout.astro` - Layout Principal
- Usado pela pagina home e paginas institucionais
- Inclui: Navbar, Footer, meta tags SEO, Open Graph
- Pagina indexada pelos buscadores

### `LPLayout.astro` - Layout de Landing Page
- Usado pelas landing pages de trafego pago
- **Sem navbar** (foco na conversao, sem distracao)
- `noindex, nofollow` (nao aparece no Google)
- Inclui botao flutuante de WhatsApp

---

## Paginas Publicas

### Pagina Inicial (`/`)
- SSG (estatica)
- Componentes: Hero, Services, Problems, Team, Insights, Ticker, Footer
- Layout: `Layout.astro`

### Landing Pages (SSR)
| Rota                            | Servico                      |
| ------------------------------- | ---------------------------- |
| `/due-diligence-rural`          | Due Diligence Rural          |
| `/regularizacao-imovel-rural`   | Regularizacao Fundiaria      |
| `/regularizacao-ambiental-rural`| Regularizacao Ambiental (CAR/PRA) |

- Layout: `LPLayout.astro` (sem navbar, com WhatsApp)
- Formulario de contato envia para `/api/contacts/submit`
- Podem ser ativadas/desativadas pelo admin

### Perfis Profissionais (SSR)
| Rota            | Profissional        |
| --------------- | ------------------- |
| `/dr-manuela`   | Dra. Manuela Nemes  |
| `/dr-paula`     | Dra. Paula Teibel   |

### Blog
| Rota               | Funcao                               |
| ------------------- | ------------------------------------ |
| `/blog`             | Listagem de todos os artigos         |
| `/blog/[slug]`      | Artigo individual (content collection)|

- Artigos escritos em Markdown em `src/content/blog/`
- Schema: title, date, pubDate, readTime, tag, author, excerpt, img, imgAlt

### Materiais (`/materiais`)
- Pagina publica que lista materiais ativos para download
- Visitante preenche nome + email/telefone para baixar
- Cada download gera um lead na tabela `contacts` + registro em `material_downloads`

### Formulario Publico (`/f/[id]`)
- Renderiza formulario dinamico criado pelo admin
- Suporta modo embed (`?embed=1`) para usar como iframe
- Envia dados para `/api/forms/[id]/submit`

### Quiz Publico (`/q/[id]`)
- Renderiza quiz multi-etapa criado pelo admin (uma pergunta por vez + barra de progresso)
- Ultima etapa e o formulario de lead (nome + email/whatsapp), seguido da tela de sucesso
- Suporta modo embed (`?embed=1`) para usar como iframe
- Marca o inicio do funil em `/api/quizzes/[id]/start` e conclui em `/api/quizzes/[id]/submit`

### Pagina Indisponivel (`/indisponivel`)
- Exibida quando uma pagina foi desativada pelo admin
- Mostra mensagem amigavel com link para voltar ao site

---

## Painel Administrativo (`/admin`)

Todas as paginas do admin sao SSR (`prerender = false`) e protegidas pelo middleware (requer login).

### Login (`/admin/login`)
- Formulario com e-mail e senha
- Autentica via `supabase.auth.signInWithPassword`
- Redireciona para `/admin` apos sucesso
- Exibe mensagem de erro se credenciais invalidas

### Dashboard (`/admin`)
- **Cards de estatisticas:**
  - Total de contatos recebidos
  - Novos contatos (ultimos 7 dias)
  - Contatos aguardando atendimento (status "novo")
  - Materiais ativos
  - Downloads totais
- **Tabela de leads:** nome, email, telefone, servico, mensagem, status, data
- **Status possiveis:** Novo, Em contato, Convertido, Descartado

### Paginas (`/admin/paginas`)
- Lista todas as paginas do site, organizadas por tipo
- **Tipos:** Institucional, Landing Page, Perfil, Blog, Artigo, Materiais
- **Funcionalidades:**
  - Toggle ativar/desativar paginas (via `/api/pages/toggle`)
  - Filtros por tipo
  - Alternancia entre visualizacao em grid (cards) ou lista
  - Copiar link da pagina
  - Abrir pagina em nova aba
- Paginas desativadas redirecionam para `/indisponivel`

### Formularios (`/admin/formularios`)
- **Criar formulario:** nome interno, source tag (auto-gerado), titulo publico, subtitulo, servico de interesse, mensagem de sucesso
- **Listar formularios** com contagem de submissoes
- **Acoes por formulario:**
  - Copiar link publico (`/f/{id}`)
  - Copiar codigo iframe (para embed externo)
  - Ativar/desativar
  - Excluir

### Quizzes (`/admin/quizzes`)
- **Criar quiz:** nome interno, source tag (auto-gerado), titulo publico, subtitulo, servico de interesse, mensagem de sucesso
- **Builder de perguntas:** adicionar/remover perguntas, uma opcao por linha (minimo 2 opcoes por pergunta)
- **Listar quizzes** com numero de perguntas e funil (inicio -> conclusao + taxa)
- **Acoes por quiz:**
  - Copiar link publico (`/q/{id}`)
  - Copiar codigo iframe (para embed externo)
  - Editar perguntas e textos
  - Ativar/desativar
  - Excluir

### Materiais (`/admin/materiais`)
- **Upload de material:** arrasta/solta ou seleciona arquivo (PDF, JPG, PNG, WebP, max 50MB)
- Campos: titulo, categoria, descricao
- **Acoes por material:**
  - Copiar link publico
  - Ativar/desativar
  - Excluir (remove arquivo do storage + registros)
- **Tabela de downloads recentes:** nome do lead, contato, material baixado, origem, data

### Usuarios (`/admin/usuarios`)
- **Criar administrador:** email + senha (min 6 caracteres)
- **Listar administradores:** email, data de cadastro
- **Remover administrador** (nao permite remover a si mesmo)
- Usa `supabaseAdmin.auth.admin` (service role key)

---

## API REST (`/api`)

Todos os endpoints sao SSR (`prerender = false`).

### Autenticacao

| Metodo | Rota               | Auth | Descricao                |
| ------ | ------------------- | ---- | ------------------------ |
| POST   | `/api/auth/logout`  | Sim  | Encerra sessao e redireciona para login |

### Contatos

| Metodo | Rota                  | Auth | Descricao                          |
| ------ | ---------------------- | ---- | ---------------------------------- |
| POST   | `/api/contacts/submit` | Nao  | Salva lead na tabela `contacts`   |

**Campos:** name*, email*, phone, message*, service_interest, source
**Validacao:** nome, email e mensagem obrigatorios; email validado por regex

### Formularios

| Metodo | Rota                       | Auth | Descricao                           |
| ------ | --------------------------- | ---- | ----------------------------------- |
| POST   | `/api/forms/create`         | Sim  | Cria novo formulario                |
| POST   | `/api/forms/toggle`         | Sim  | Ativa/desativa formulario           |
| GET    | `/api/forms/[id]`           | Nao  | Retorna dados publicos do formulario|
| DELETE | `/api/forms/[id]`           | Sim  | Exclui formulario                   |
| POST   | `/api/forms/[id]/submit`    | Nao  | Submete lead pelo formulario publico|

**Submit do formulario publico:** valida nome (min 2 chars), exige email ou telefone, verifica se formulario existe e esta ativo, salva como contato com source_tag do formulario.

### Quizzes

| Metodo | Rota                         | Auth | Descricao                            |
| ------ | ---------------------------- | ---- | ------------------------------------ |
| POST   | `/api/quizzes/create`        | Sim  | Cria novo quiz (com perguntas)       |
| POST   | `/api/quizzes/toggle`        | Sim  | Ativa/desativa quiz                  |
| GET    | `/api/quizzes/[id]`          | Nao  | Retorna dados publicos do quiz       |
| PATCH  | `/api/quizzes/[id]`          | Sim  | Atualiza perguntas e textos do quiz  |
| DELETE | `/api/quizzes/[id]`          | Sim  | Exclui quiz (e suas respostas)       |
| POST   | `/api/quizzes/[id]/start`    | Nao  | Registra inicio do quiz (funil)      |
| POST   | `/api/quizzes/[id]/submit`   | Nao  | Conclui o quiz e submete o lead      |

**Submit do quiz publico:** mesma validacao do formulario, exige todas as perguntas respondidas, salva o lead em `contacts` (source_tag do quiz, respostas resumidas em `message`) e conclui a linha em `quiz_responses` com as respostas estruturadas.

### Materiais

| Metodo | Rota                       | Auth | Descricao                           |
| ------ | --------------------------- | ---- | ----------------------------------- |
| POST   | `/api/materials/upload`     | Sim  | Upload de arquivo + metadados       |
| POST   | `/api/materials/toggle`     | Sim  | Alterna ativo/inativo               |
| POST   | `/api/materials/download`   | Nao  | Registra lead + retorna signed URL  |
| DELETE | `/api/materials/[id]`       | Sim  | Exclui material + arquivo storage   |

**Download flow:**
1. Visitante preenche nome + email/telefone
2. API verifica se material existe e esta ativo
3. Salva/atualiza lead na tabela `contacts` (upsert por email)
4. Registra download em `material_downloads`
5. Incrementa contador via RPC `increment_download_count`
6. Gera signed URL (60s de validade) do Supabase Storage
7. Retorna URL para o frontend iniciar o download

### Paginas

| Metodo | Rota                  | Auth | Descricao                       |
| ------ | ---------------------- | ---- | ------------------------------- |
| POST   | `/api/pages/toggle`    | Sim  | Ativa/desativa pagina (upsert em `page_settings`) |

---

## Tabelas Supabase (inferidas do codigo)

### `contacts`
| Coluna           | Tipo     | Descricao                               |
| ---------------- | -------- | --------------------------------------- |
| id               | uuid     | PK                                      |
| name             | text     | Nome do lead                            |
| email            | text     | Email (unique, usado para upsert)       |
| phone            | text?    | Telefone/WhatsApp                       |
| message          | text     | Mensagem ou contexto                    |
| service_interest | text?    | Servico de interesse                    |
| source           | text?    | Origem (ex: "site", "blog-regularizacao") |
| status           | text     | "novo", "em_contato", "convertido", "descartado" |
| created_at       | timestamp| Data de criacao                         |

### `forms`
| Coluna           | Tipo     | Descricao                               |
| ---------------- | -------- | --------------------------------------- |
| id               | uuid     | PK                                      |
| name             | text     | Nome interno (visivel so no admin)      |
| title            | text     | Titulo publico                          |
| subtitle         | text?    | Subtitulo                               |
| source_tag       | text     | Tag unica para identificar leads (unique) |
| service_interest | text?    | Servico vinculado                       |
| success_message  | text     | Mensagem de sucesso apos envio          |
| is_active        | boolean  | Se o formulario esta ativo              |
| created_at       | timestamp| Data de criacao                         |

### `quizzes`
| Coluna           | Tipo     | Descricao                               |
| ---------------- | -------- | --------------------------------------- |
| id               | uuid     | PK                                      |
| name             | text     | Nome interno (visivel so no admin)      |
| title            | text     | Titulo publico (etapa final)            |
| subtitle         | text?    | Subtitulo                               |
| source_tag       | text     | Tag unica para identificar leads (unique) |
| service_interest | text?    | Servico vinculado                       |
| questions        | jsonb    | `[{ "text": "...", "options": [...] }]` |
| success_message  | text     | Mensagem de sucesso apos envio          |
| is_active        | boolean  | Se o quiz esta ativo                    |
| created_at       | timestamp| Data de criacao                         |

### `quiz_responses`
| Coluna       | Tipo      | Descricao                                    |
| ------------ | --------- | -------------------------------------------- |
| id           | uuid      | PK                                           |
| quiz_id      | uuid      | FK -> quizzes (on delete cascade)            |
| contact_id   | uuid?     | FK -> contacts                               |
| answers      | jsonb     | `[{ "question": "...", "answer": "..." }]`   |
| status       | text      | "started" ou "completed" (funil)             |
| started_at   | timestamp | Inicio do quiz                               |
| completed_at | timestamp?| Conclusao do quiz                            |

### `materials`
| Coluna           | Tipo     | Descricao                               |
| ---------------- | -------- | --------------------------------------- |
| id               | uuid     | PK                                      |
| title            | text     | Titulo do material                      |
| description      | text?    | Descricao                               |
| category         | text?    | Categoria                               |
| file_path        | text     | Caminho no Supabase Storage             |
| file_name        | text     | Nome original do arquivo                |
| file_size        | integer? | Tamanho em bytes                        |
| is_active        | boolean  | Se esta disponivel para download        |
| download_count   | integer  | Contador de downloads                   |
| created_at       | timestamp| Data de criacao                         |

### `material_downloads`
| Coluna      | Tipo      | Descricao                                |
| ----------- | --------- | ---------------------------------------- |
| id          | uuid      | PK                                       |
| material_id | uuid      | FK -> materials                          |
| contact_id  | uuid?     | FK -> contacts                           |
| name        | text      | Nome de quem baixou                      |
| email       | text?     | Email                                    |
| phone       | text?     | Telefone                                 |
| source      | text?     | Origem                                   |
| created_at  | timestamp | Data do download                         |

### `page_settings`
| Coluna     | Tipo      | Descricao                                 |
| ---------- | --------- | ----------------------------------------- |
| slug       | text      | PK / unique (ex: "/due-diligence-rural")  |
| is_active  | boolean   | Se a pagina esta ativa                    |
| updated_at | timestamp | Ultima atualizacao                        |

### Supabase Auth (users)
- Gerenciado pelo Supabase Auth (nao e uma tabela customizada)
- Admins criados via `auth.admin.createUser`
- Login via `auth.signInWithPassword`

### Funcoes RPC
- `increment_download_count(material_id)` - incrementa o `download_count` de um material (SECURITY DEFINER, funciona com anon key)

### Policies RLS (inferidas)
- `contacts`: insercao publica (anon), leitura apenas para admins autenticados
- `materials`: leitura publica de materiais ativos, escrita para admins
- `material_downloads`: insercao publica, leitura para admins
- `forms`: leitura publica de formularios ativos, CRUD para admins
- `quizzes`: leitura publica de quizzes ativos, CRUD para admins
- `quiz_responses`: insercao publica e update das linhas iniciadas, leitura para admins
- `page_settings`: leitura publica, escrita para admins

---

## Blog (Content Collections)

### Schema de artigo (`src/content/config.ts`)
```typescript
{
  title:    string,    // titulo do artigo
  date:     string,    // data formatada ("12 de maio de 2025")
  pubDate:  Date,      // data ISO para ordenacao
  readTime: string,    // tempo de leitura ("8 min")
  tag:      string,    // categoria ("Regularizacao Fundiaria")
  author:   string,    // nome do autor
  excerpt:  string,    // resumo para listagem
  img:      string,    // caminho da imagem de capa
  imgAlt:   string,    // alt text da imagem
}
```

### Artigos existentes
1. `regularizacao-fundiaria.md`
2. `bndes-car-analisado.md`
3. `invasoes-no-campo.md`
4. `sigef-2025-atualizacoes-novo-modelo-incra.md`

### Para adicionar um novo artigo
1. Criar arquivo `.md` em `src/content/blog/`
2. Preencher o frontmatter com todos os campos do schema
3. Escrever o conteudo em Markdown abaixo do frontmatter
4. O artigo aparece automaticamente em `/blog` e `/blog/[slug]`
5. Tambem aparece no admin em `/admin/paginas` como tipo "Artigo"

---

## Fluxo de Captura de Leads

### 1. Via Landing Page
```
Visitante -> preenche formulario na LP -> POST /api/contacts/submit
-> salva na tabela contacts (status: "novo", source: "site")
-> admin ve no dashboard
```

### 2. Via Formulario Dinamico
```
Admin cria formulario no painel -> gera link /f/{id}
Visitante acessa link ou iframe -> preenche nome + email/telefone
-> POST /api/forms/{id}/submit -> salva em contacts (source: source_tag do form)
```

### 3. Via Quiz Dinamico
```
Admin cria quiz no painel -> gera link /q/{id}
Visitante responde as perguntas -> POST /api/quizzes/{id}/start (funil: inicio)
-> preenche nome + email/telefone na ultima etapa
-> POST /api/quizzes/{id}/submit -> salva em contacts (source: source_tag do quiz)
-> conclui a linha em quiz_responses com as respostas (funil: conclusao)
```

### 4. Via Download de Material
```
Admin faz upload de material -> publica na pagina /materiais
Visitante preenche dados para baixar -> POST /api/materials/download
-> salva/atualiza lead em contacts
-> registra em material_downloads
-> incrementa download_count
-> retorna signed URL para download
```

---

## Design System (CSS)

### Paleta de Cores
| Variavel   | Hex       | Uso                          |
| ---------- | --------- | ---------------------------- |
| dark       | `#3A3426` | Backgrounds escuros, textos  |
| gold       | `#B8972A` | Destaques, acentos           |
| cream      | `#F5F0E8` | Backgrounds claros           |
| bg         | `#F0EDE6` | Background geral             |
| text       | `#3D3828` | Texto principal              |
| muted      | `#9A9285` | Texto secundario             |
| brown      | `#8C7355` | Texto terciario              |
| green      | `#3DBE4F` | Sucesso, status ativo, CTAs  |
| blue       | `#4A8CF7` | Links, badges                |
| red/error  | `#C0392B` | Erros, botao excluir         |

### Tipografia
- **Titulos:** Playfair Display (serif, 600/700)
- **Corpo:** DM Sans (sans-serif, 400/500/600/700)

### Componentes Visuais Recorrentes
- **Cards** com `border-radius: 14px` e `box-shadow` suave
- **Botoes pill** com `border-radius: 50px`
- **Status badges** coloridos (verde=ativo, cinza=inativo)
- **Tabelas responsivas** (mobile vira cards com `data-label`)
- **Toast notifications** (canto inferior direito)
- **Modais** com overlay + backdrop blur
- **Mobile drawer** (menu hamburguer para telas < 768px)

---

## Deploy e Build

### Build
```bash
npm run build
# Executa: astro build && node scripts/fix-vercel-runtime.mjs
```

### Vercel
- Adapter: `@astrojs/vercel/serverless`
- Paginas SSG -> servidas como arquivos estaticos via CDN
- Paginas SSR -> executadas como serverless functions
- Variaveis de ambiente configuradas no dashboard da Vercel

---

## Como Realizar Tarefas Comuns

### Adicionar nova Landing Page
1. Criar `src/pages/nome-da-lp.astro`
2. Usar `LPLayout.astro` como layout
3. Adicionar `export const prerender = false;` no frontmatter
4. Registrar na lista de paginas em `src/pages/admin/paginas.astro` (array `allItems`)
5. O middleware ja cuidara do controle de ativacao via `page_settings`

### Adicionar novo componente
1. Criar em `src/components/NomeComponente.astro`
2. Importar e usar na pagina desejada

### Adicionar novo endpoint de API
1. Criar arquivo `.ts` em `src/pages/api/`
2. Exportar funcoes nomeadas (GET, POST, DELETE, etc.) do tipo `APIRoute`
3. Adicionar `export const prerender = false;`
4. Usar `locals.supabase` para acessar o banco
5. Verificar auth com `locals.supabase.auth.getUser()` se necessario

### Criar novo admin
1. Acessar `/admin/usuarios`
2. Preencher email e senha
3. Clicar em "Cadastrar"
