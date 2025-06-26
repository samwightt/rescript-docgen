import { defineConfig } from 'vite'
import { resXVitePlugin } from 'rescript-x'

export default defineConfig({
  plugins: [resXVitePlugin()],
  server: {
    port: 9000
  }
})