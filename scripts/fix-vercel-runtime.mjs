import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'fs';
import { join } from 'path';

const OUTPUT = join(process.cwd(), '.vercel', 'output', 'functions');

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      walk(full);
    } else if (entry === '.vc-config.json') {
      const raw = readFileSync(full, 'utf-8');
      if (raw.includes('nodejs18.x')) {
        writeFileSync(full, raw.replace(/nodejs18\.x/g, 'nodejs20.x'));
        console.log(`[fix-runtime] ${full} → nodejs20.x`);
      }
    }
  }
}

// Só existe em build da Vercel; fora dela (adaptador Node) não há o que corrigir.
if (process.env.VERCEL && existsSync(OUTPUT)) walk(OUTPUT);
