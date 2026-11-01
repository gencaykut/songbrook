export const isExternal = (href: string) => href.startsWith("http");

export const fade = (delay = 0) => ({
	initial: { opacity: 0, y: 16 },
	whileInView: { opacity: 1, y: 0 },
	viewport: { once: true },
	transition: { duration: 0.5, delay },
});

export const copyright =
	"© 2026 Aykut Genç · BSD 2-Clause. Not affiliated with YouTube or Google.";
