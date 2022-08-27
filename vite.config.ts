import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import { certificateFor } from "devcert";

export default defineConfig(async () => {
  return {
    plugins: [elmPlugin()],
    server: {
      host: true,
      port: 1234,
      https: await certificateFor("localhost"),
    },
  };
});
