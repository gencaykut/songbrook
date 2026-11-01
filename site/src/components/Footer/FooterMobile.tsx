"use client";

import { motion } from "framer-motion";
import { withBase } from "@/basePath";
import SocialLinks from "@/components/SocialLinks";
import ThemeToggle from "@/components/ThemeToggle";
import { footerSections, site } from "@/config";
import type { FooterProps } from "@/types";
import { copyright, fade, isExternal } from "./links";

const FooterMobile = ({ name, logo }: FooterProps) => (
	<motion.div {...fade(0)} className="flex flex-col gap-6 md:hidden">
		<div className="flex items-center justify-between">
			<a href={withBase("/")} className="flex items-center gap-2.5">
				<img
					src={withBase(logo)}
					alt={`${name} logo`}
					className="h-9 w-9 rounded-xl border border-gray-200/60 object-cover dark:border-white/10"
				/>
				<span className="font-bold tracking-tight text-gray-900 dark:text-white">
					{name}
				</span>
			</a>
			<ThemeToggle />
		</div>

		<nav className="flex gap-10">
			{footerSections.map((section) => (
				<div key={section.title} className="flex flex-col gap-3">
					{section.links.map(({ label, href }) => (
						<a
							key={label}
							href={href}
							{...(isExternal(href) ? { rel: "noopener noreferrer" } : {})}
							className="text-sm text-body transition-colors hover:text-heading"
						>
							{label}
						</a>
					))}
				</div>
			))}
		</nav>

		<div className="flex items-center justify-between gap-4">
			<div className="flex gap-2">
				<SocialLinks items={site.social} />
			</div>
			<p className="text-right text-xs text-gray-400 dark:text-white/25">
				{copyright}
			</p>
		</div>
	</motion.div>
);

export default FooterMobile;
