import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel/serverless';
import node from '@astrojs/node';

// Na Vercel (variável VERCEL definida no build) usa o adaptador da Vercel;
// em qualquer outro lugar (Hostinger, VPS, local) gera um servidor Node
// autônomo em dist/server/entry.mjs.
const onVercel = Boolean(process.env.VERCEL);

export default defineConfig({
  output: 'hybrid',
  adapter: onVercel ? vercel() : node({ mode: 'standalone' }),
  // Servidor Node escuta em 0.0.0.0 (necessário atrás do proxy da hospedagem).
  server: { host: true },
  // Com www: é o endereço que o domínio serve em produção. Sem isso o canonical
  // e o og:url saíam sem www e apontavam para um host diferente do que o Google indexa.
  site: 'https://www.nemeseteibeladv.com.br',
  compressHTML: true,
  // Serve a pasta assets/ como raiz estática.
  // assets/img/bg1.avif → /img/bg1.avif
  publicDir: 'assets',
  build: {
    assets: '_assets',
  },
});
