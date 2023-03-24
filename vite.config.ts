import { defineConfig, loadEnv } from "vite";
import elmPlugin from "vite-plugin-elm";
import { certificateFor } from "devcert";

export default defineConfig(async ({ mode }) => {
	Object.assign(process.env, loadEnv(mode, process.cwd(), ""));

	return {
		plugins: [elmPlugin()],
		base: "/",
		server: {
			host: true,
			port: 3000,
			https: await certificateFor("localhost"),
		},
	};
});
