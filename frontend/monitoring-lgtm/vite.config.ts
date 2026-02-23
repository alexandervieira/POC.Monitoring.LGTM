import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
   
  // Configuração de build
  build: {
    outDir: 'build',
    assetsDir: 'assets',
    sourcemap: true,
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash].[ext]',
        manualChunks: {
          vendor: ['react', 'react-dom'],
          ui: ['@headlessui/react', '@heroicons/react'],
        },
      },
    },
  },
  
  // Diretório público
  publicDir: 'public',
  
  // Resolve aliases
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@pages': path.resolve(__dirname, './src/pages'),
    },
  },
  
  // Servidor de desenvolvimento
  server: {
    port: 4000,
    open: true,
    fs: {
      // Permitir servir arquivos de diretórios específicos
      allow: ['..', '.', 'public', 'build'],
    },
    proxy: {
      '/grafana': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/grafana/, ''),
      },
    },
  },
})