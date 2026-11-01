"use client";

import { motion } from "framer-motion";
import { withBase } from "@/basePath";
import SocialLinks from "@/components/SocialLinks";
import ThemeToggle from "@/components/ThemeToggle";
import { footerSections, site } from "@/config";
import type { FooterProps } from "@/types";
import { copyright, fade, isExternal } from "./links";

const colHeader = (title: string) => (
	<p className="text-[11px] font-bold uppercase tracking-[0.15em] text-gray-400 dark:text-white/30">
		{title}
	</p>
);

const navLink = (label: string, href: string) => (
	<a
		key={label}
		href={href}
		{...(isExternal(href) ? { rel: "noopener noreferrer" } : {})}
		className="group flex items-center gap-2 text-sm text-body transition-colors hover:text-heading"
	>
		<span className="h-px w-0 bg-brand-500 transition-all duration-300 group-hover:w-3" />
		{label}
	</a>
);

const FooterDesktop = ({ name, logo }: FooterProps) => (
	<div className="hidden md:grid md:grid-cols-[2fr_1fr_1fr_1fr] md:gap-8 lg:gap-12">
		<motion.div {...fade(0)} className="flex flex-col gap-5">
			<a href={withBase("/")} className="flex items-center gap-3">
				<img
					src={withBase(logo)}
					alt={`${name} logo`}
					className="h-10 w-10 rounded-xl border border-gray-200/60 object-cover dark:border-white/10"
				/>
				<span className="text-base font-bold tracking-tight text-gray-900 dark:text-white">
					{name}
				</span>
			</a>
			<p className="max-w-72 text-sm leading-relaxed text-body">
				{site.description}
			</p>
			<p className="mt-auto max-w-72 text-xs text-gray-400 dark:text-white/25">
				{copyright}
			</p>
		</motion.div>

		{footerSections.map((section, index) => (
			<motion.div
				key={section.title}
				{...fade(0.1 + index * 0.05)}
				className="flex flex-col gap-4"
			>
				{colHeader(section.title)}
				<nav className="flex flex-col gap-3">
					{section.links.map(({ label, href }) => navLink(label, href))}
				</nav>
			</motion.div>
		))}

		<motion.div {...fade(0.2)} className="flex flex-col items-end gap-4">
			{colHeader("Follow")}
			<div className="flex flex-wrap justify-end gap-2">
				<SocialLinks items={site.social} />
			</div>
			<ThemeToggle />
		</motion.div>
	</div>
);

export default FooterDesktop;
