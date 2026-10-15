import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

const target = process.env.LAB_API_URL || "http://localhost:9001";
const proxy = Object.fromEntries(
  ["/api", "/tickets", "/ticket-events"].map((path) => [path, { target }]),
);

export default defineConfig({
  plugins: [vue()],
  server: { host: "127.0.0.1", port: 5173, strictPort: true, proxy },
  preview: { host: "127.0.0.1", port: 4173, strictPort: true, proxy },
});
