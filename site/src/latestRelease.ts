"use client";

import { useEffect, useState } from "react";
import { site } from "@/config";
import type { DownloadKind } from "@/types";

export interface ReleaseFile {
	name: string;
	url: string;
	size: number;
}

export interface LatestRelease {
	version: string;
	date: string;
	notesUrl: string;
	files: Partial<Record<DownloadKind, ReleaseFile>>;
}

interface GitHubAsset {
	name: string;
	size: number;
	browser_download_url: string;
}

const pickers: Record<DownloadKind, (names: string[]) => string | undefined> = {
	mac: (names) =>
		names.find((name) => name === "Songbrook.dmg") ??
		names.find((name) => name.endsWith(".dmg")),
	iphone: (names) => names.find((name) => name.endsWith(".ipa")),
	android: (names) => names.find((name) => name.endsWith(".apk")),
};

let request: Promise<LatestRelease | null> | undefined;

// One request per page load; the static links in the config are used until it
// answers, or for good if GitHub's API is unreachable or rate-limited.
const fetchLatestRelease = () => {
	request ??= fetch(
		`https://api.github.com/repos/${site.repository}/releases/latest`,
	)
		.then(async (response) => {
			if (!response.ok) return null;
			const release = await response.json();
			const assets: GitHubAsset[] = release.assets ?? [];
			const names = assets.map((asset) => asset.name);
			const files: LatestRelease["files"] = {};
			for (const kind of Object.keys(pickers) as DownloadKind[]) {
				const asset = assets.find(
					(candidate) => candidate.name === pickers[kind](names),
				);
				if (asset) {
					files[kind] = {
						name: asset.name,
						url: asset.browser_download_url,
						size: asset.size,
					};
				}
			}
			return {
				version: String(release.tag_name ?? "").replace(/^v/, ""),
				date: release.published_at
					? new Date(release.published_at).toLocaleDateString("en-US", {
							year: "numeric",
							month: "short",
							day: "numeric",
						})
					: "",
				notesUrl: release.html_url,
				files,
			};
		})
		.catch(() => null);
	return request;
};

export const useLatestRelease = () => {
	const [release, setRelease] = useState<LatestRelease | null>(null);
	useEffect(() => {
		let active = true;
		fetchLatestRelease().then((result) => {
			if (active) setRelease(result);
		});
		return () => {
			active = false;
		};
	}, []);
	return release;
};

export const megabytes = (bytes: number) =>
	`${Math.round(bytes / 1_048_576)} MB`;
