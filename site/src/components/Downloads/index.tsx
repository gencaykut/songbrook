"use client";

import { motion } from "framer-motion";
import { FaAndroid, FaApple } from "react-icons/fa";
import { links } from "@/config";
import { megabytes, useLatestRelease } from "@/latestRelease";
import type { DownloadKind, DownloadsProps } from "@/types";

const icons: Record<DownloadKind, typeof FaApple> = {
	mac: FaApple,
	iphone: FaApple,
	android: FaAndroid,
};

const Downloads = ({ items }: DownloadsProps) => {
	const release = useLatestRelease();

	return (
		<div>
			<motion.div
				initial={{ opacity: 0, y: 20 }}
				whileInView={{ opacity: 1, y: 0 }}
				viewport={{ once: true }}
				transition={{ duration: 0.4 }}
				className="mb-12 flex flex-col items-center text-center"
			>
				<span className="section-label mb-4">Download</span>
				<h2 className="section-heading max-w-2xl">
					Pick your device, <span className="accent">it's free.</span>
				</h2>
			</motion.div>

			<div className="grid grid-cols-1 gap-5 md:grid-cols-3">
				{items.map((item, index) => {
					const Icon = icons[item.kind];
					const file = release?.files[item.kind];
					return (
						<motion.article
							key={item.kind}
							initial={{ opacity: 0, y: 24 }}
							whileInView={{ opacity: 1, y: 0 }}
							viewport={{ once: true }}
							transition={{ duration: 0.4, delay: index * 0.1 }}
							className="card-base flex flex-col p-6"
						>
							<div className="mb-4 flex items-center gap-3">
								<span className="flex h-11 w-11 items-center justify-center rounded-xl border border-brand-100 bg-brand-50 dark:border-brand-500/20 dark:bg-brand-500/10">
									<Icon className="h-5 w-5 text-brand-600 dark:text-brand-400" />
								</span>
								<div>
									<h3 className="text-lg font-bold text-gray-900 dark:text-white">
										{item.platform}
									</h3>
									<p className="text-xs text-muted">{item.requirements}</p>
								</div>
							</div>
							<ol className="mb-4 list-decimal space-y-1 pl-5 text-sm leading-relaxed text-body">
								{item.steps.map((step) => (
									<li key={step}>{step}</li>
								))}
							</ol>
							<p className="mb-6 text-sm leading-relaxed text-body">
								{item.note}
							</p>
							<div className="mt-auto flex flex-wrap gap-2">
								<a
									href={file?.url ?? item.fallbackUrl}
									className="rounded-xl bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white transition-all duration-200 hover:bg-brand-700 active:scale-[0.98] dark:bg-brand-500 dark:hover:bg-brand-400"
								>
									{item.buttonLabel}
								</a>
								{item.secondary?.map((extra) => (
									<a
										key={extra.label}
										href={extra.url}
										className="button-base px-5 py-2.5 text-sm font-semibold text-heading transition-colors hover:bg-gray-50 dark:hover:bg-white/10"
									>
										{extra.label}
									</a>
								))}
							</div>
							<p className="mt-3 min-h-4 text-xs text-muted">
								{file ? `${file.name} · ${megabytes(file.size)}` : ""}
							</p>
						</motion.article>
					);
				})}
			</div>

			<p className="mt-6 text-center text-sm text-body">
				Checksums, older versions and release notes are on{" "}
				<a
					href={release?.notesUrl ?? links.releases}
					className="accent underline underline-offset-4"
				>
					GitHub Releases
				</a>
				.
			</p>
		</div>
	);
};

export default Downloads;
