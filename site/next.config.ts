import type { NextConfig } from "next";

// GitHub Pages serves the project under /songbrook; the Pages workflow passes
// the path it was given by actions/configure-pages.
const basePath = process.env.PAGES_BASE_PATH ?? "";

const config: NextConfig = {
	output: "export",
	basePath,
	env: { NEXT_PUBLIC_BASE_PATH: basePath },
	images: { unoptimized: true },
	trailingSlash: true,
	reactStrictMode: true,
	compiler: {
		removeConsole: { exclude: ["error"] },
	},
};

export default config;
