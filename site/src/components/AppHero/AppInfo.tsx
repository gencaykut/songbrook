"use client";

import { site } from "@/config";
import type { LatestRelease } from "@/latestRelease";

const Badge = ({ label, value }: { label: string; value: string }) => (
	<span className="info-badge text-xs">
		<span className="font-medium text-gray-500 dark:text-white/40">
			{label}
		</span>
		<span className="font-semibold text-heading">{value}</span>
	</span>
);

const AppInfo = ({ release }: { release: LatestRelease | null }) => (
	<div className="flex flex-wrap justify-center gap-2">
		<Badge label="Version" value={release?.version || site.version} />
		<Badge label="Requires" value={site.requirements} />
		<Badge label="Updated" value={release?.date || site.releaseDate} />
	</div>
);

export default AppInfo;
