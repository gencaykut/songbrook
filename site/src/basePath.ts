/** Prefixes a file in public/ with the site's base path, for plain <img> and <a>. */
export const withBase = (path: string) =>
	`${process.env.NEXT_PUBLIC_BASE_PATH ?? ""}${path}`;
