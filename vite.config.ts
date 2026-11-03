import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  base: '/dialycollection/',
  plugins: [
    react(),
    VitePWA({
      registerType: 'prompt',
      includeAssets: ['favicon.svg'],
      manifest: {
        name: 'Daily Collection Manager',
        short_name: 'Collections',
        description: 'Admin loan and daily collection management',
        theme_color: '#172f91',
        background_color: '#f4f6fb',
        display: 'standalone',
        start_url: '/dialycollection/',
        scope: '/dialycollection/',
        icons: [
          { src: 'pwa-192.svg', sizes: '192x192', type: 'image/svg+xml', purpose: 'any' },
          { src: 'pwa-512.svg', sizes: '512x512', type: 'image/svg+xml', purpose: 'any' }
        ]
      },
      workbox: { navigateFallback: '/dialycollection/index.html', globPatterns: ['**/*.{js,css,html,svg,png,ico}'] }
    })
  ]
})