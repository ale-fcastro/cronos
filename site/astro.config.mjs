// @ts-check
import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel';

// Páginas estáticas; solo /api/* (prerender = false) corre como función serverless en Vercel.
export default defineConfig({
  site: 'https://cronos-fcastro.vercel.app',
  output: 'static',
  adapter: vercel(),
});
