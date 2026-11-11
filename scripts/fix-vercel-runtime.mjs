import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'fs';
import { join } from 'path';

// O @astrojs/vercel 7 grava um runtime antigo (nodejs18.x) nas funções.
// A Vercel descontinuou o 18 e o 20, então trocamos pelo 22.
const RUNTIME = 'nodejs22.x';
const OUTPUT = join(process.cwd(), '.vercel', 'output', 'functions');

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      walk(full);
    } else if (entry === '.vc-config.json') {
      const raw = readFileSync(full, 'utf-8');
      const fixed = raw.replace(/nodejs\d+\.x/g, RUNTIME);
      if (fixed !== raw) {
        writeFileSync(full, fixed);
        console.log(`[fix-runtime] ${full} → ${RUNTIME}`);
      }
    }
  }
}

// Só existe em build da Vercel; fora dela (adaptador Node) não há o que corrigir.
if (process.env.VERCEL && existsSync(OUTPUT)) walk(OUTPUT);
