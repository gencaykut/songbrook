// Writes public/altstore.json, the AltStore/SideStore source, from the GitHub
// releases that carry an iOS IPA. Runs before `next build`, so the Pages
// workflow refreshes it on every deploy, including when a release is published.
import { readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repository = "gencaykut/songbrook";
const bundleIdentifier = "io.github.gencaykut.songbrook";
const site = "https://gencaykut.github.io/songbrook";
const tintColor = "1E5AA8";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const infoPlist = join(root, "..", "ios", "Runner", "Info.plist");

const github = async (path) => {
	const headers = { Accept: "application/vnd.github+json" };
	if (process.env.GITHUB_TOKEN) {
		headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
	}
	const response = await fetch(`https://api.github.com${path}`, { headers });
	if (!response.ok) {
		throw new Error(`GitHub ${path}: HTTP ${response.status}`);
	}
	return response.json();
};

// AltStore shows these before installing; they must match the app's Info.plist.
const privacyDescriptions = async () => {
	const plist = await readFile(infoPlist, "utf8");
	const privacy = {};
	for (const [, key, value] of plist.matchAll(
		/<key>(NS\w+UsageDescription)<\/key>\s*<string>([^<]*)<\/string>/g,
	)) {
		privacy[key] = value;
	}
	return privacy;
};

const checksums = async (release) => {
	const asset = release.assets.find((item) => item.name === "SHA256SUMS.txt");
	if (!asset) return {};
	const response = await fetch(asset.browser_download_url);
	if (!response.ok) return {};
	const sums = {};
	for (const line of (await response.text()).split("\n")) {
		const [hash, name] = line.trim().split(/\s+/);
		if (hash && name) sums[name] = hash;
	}
	return sums;
};

const releases = (await github(`/repos/${repository}/releases?per_page=50`))
	.filter((release) => !release.draft && !release.prerelease)
	.filter((release) =>
		release.assets.some((item) => item.name.endsWith(".ipa")),
	);

if (releases.length === 0) {
	throw new Error("No published release has an iOS IPA.");
}

const versions = [];
for (const release of releases) {
	const ipa = release.assets.find((item) => item.name.endsWith(".ipa"));
	const version = release.tag_name.replace(/^v/, "");
	const sha256 = (await checksums(release))[ipa.name];
	versions.push({
		version,
		date: release.published_at,
		localizedDescription: `Songbrook ${version}. Release notes: ${release.html_url}`,
		downloadURL: ipa.browser_download_url,
		size: ipa.size,
		minOSVersion: "15.0",
		...(sha256 ? { sha256 } : {}),
	});
}

const source = {
	name: "Songbrook",
	subtitle: "A free, open-source YouTube Music player.",
	description:
		"The official source for Songbrook. Add it once to install Songbrook and get its updates in AltStore or SideStore.",
	iconURL: `${site}/altstore-icon.png`,
	website: site,
	tintColor,
	featuredApps: [bundleIdentifier],
	apps: [
		{
			name: "Songbrook",
			bundleIdentifier,
			developerName: "Aykut Genç",
			subtitle: "A free, open-source YouTube Music player.",
			localizedDescription:
				"Songbrook searches the YouTube Music catalog, streams and downloads songs, and keeps your own library with playlists, favorites and synced lyrics. Music videos play their song version when there is one, loud songs are lowered to a steady level, and Songbrook Connect lets your iPhone control the Mac version. Free, open source and without ads; not affiliated with YouTube or Google.",
			iconURL: `${site}/altstore-icon.png`,
			tintColor,
			category: "entertainment",
			screenshots: ["1-home", "2-player", "3-queue", "4-artist"].map(
				(name) => `${site}/assets/screenshots/${name}.jpg`,
			),
			versions,
			appPermissions: {
				entitlements: ["com.apple.security.application-groups"],
				privacy: await privacyDescriptions(),
			},
		},
	],
	news: [],
};

await writeFile(
	join(root, "public", "altstore.json"),
	`${JSON.stringify(source, null, "\t")}\n`,
);
console.log(
	`altstore.json: ${versions.length} version(s), latest ${versions[0].version}`,
);
