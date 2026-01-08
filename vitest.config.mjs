import imba from "imba/plugin";
import { defineConfig } from "vite";

export default defineConfig({
	plugins: [imba()],
	define: {
		"import.meta.vitest": "undefined",
	},
	test: {
		globals: true,
		include: ["tests/**/*.{test,spec}.{imba,js,mjs,ts}"],
		environment: "node",
		setupFiles: ["./tests/setup.imba"],
		testTimeout: 10000,
		hookTimeout: 10000,
		// Use threads pool to avoid process.send conflicts with Formidable
		pool: "threads",
		poolOptions: {
			threads: {
				singleThread: true,
			},
		},
		// Ensure proper module resolution
		server: {
			deps: {
				inline: [/imba/, /@formidablejs/],
			},
		},
	},
});
