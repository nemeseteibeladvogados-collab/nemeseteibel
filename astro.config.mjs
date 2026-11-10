import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel/serverless';

export default defineConfig({
  output: 'hybrid',
  adapter: vercel(),
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
