import type { Metadata, Viewport } from "next";
import { withBase } from "@/basePath";
import BackToTop from "@/components/BackToTop";
import Footer from "@/components/Footer";
import { site } from "@/config";
import "./globals.css";

export const metadata: Metadata = {
	metadataBase: new URL(site.url),
	title: {
		default: site.name,
		template: `%s — ${site.name}`,
	},
	description: site.description,
	keywords: [...site.keywords],
	openGraph: {
		type: "website",
		url: site.url,
		siteName: site.name,
		title: site.name,
		description: site.description,
	},
	icons: {
		icon: { url: withBase("/favicon.svg"), type: "image/svg+xml" },
		apple: withBase("/favicon.svg"),
	},
};

export const viewport: Viewport = {
	width: "device-width",
	initialScale: 1,
	themeColor: [
		{ media: "(prefers-color-scheme: light)", color: "#f9fafb" },
		{ media: "(prefers-color-scheme: dark)", color: "#060606" },
	],
};

const themeScript = `(function(){
  var t=localStorage.getItem('theme')||'system';
  var r=document.documentElement;
  r.classList.remove('light','dark');
  if(t==='system'){
    r.classList.add(window.matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');
  }else{
    r.classList.add(t);
  }
  if(!localStorage.getItem('theme'))localStorage.setItem('theme','system');
})();`;

export default function RootLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<html lang="en" suppressHydrationWarning>
			<head>
				<script dangerouslySetInnerHTML={{ __html: themeScript }} />
			</head>
			<body className="bg-gray-50 text-gray-900 dark:bg-[#060606] dark:text-white">
				<div className="mx-auto max-w-375">
					{children}
					<Footer name={site.name} logo={site.logo} />
				</div>
				<BackToTop />
			</body>
		</html>
	);
}
