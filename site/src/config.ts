import type {
	Download,
	FAQItem,
	Feature,
	FooterLink,
	SocialLink,
} from "@/types";

const repository = "gencaykut/songbrook";
const github = `https://github.com/${repository}`;

export const site = {
	name: "Songbrook",
	repository,
	url: "https://gencaykut.github.io/songbrook",
	description:
		"A free, open-source YouTube Music player for Mac, iPhone and Android. Search, stream and download songs, and keep your own library.",
	logo: "/favicon.svg",
	keywords: [
		"YouTube Music",
		"music player",
		"open source",
		"macOS",
		"iOS",
		"Android",
	],
	/** Shown until the latest release is read from GitHub. */
	version: "1.0.0",
	releaseDate: "Nov 1, 2026",
	requirements: "macOS 12 · iOS 15 · Android 7",
	social: [
		{ url: github, icon: "RiGithubFill", label: "GitHub" },
	] as SocialLink[],
} as const;

export const links = {
	github,
	releases: `${github}/releases`,
	latestRelease: `${github}/releases/latest`,
	issues: `${github}/issues`,
	upstream: "https://github.com/BryamContreras/BStream-Music",
};

export const downloads: Download[] = [
	{
		kind: "mac",
		platform: "Mac",
		requirements: "macOS 12 or later · Apple silicon and Intel",
		fallbackUrl: `${github}/releases/latest/download/Songbrook.dmg`,
		buttonLabel: "Download for Mac",
		steps: ["Open the disk image.", "Drag Songbrook to Applications."],
		note: "Signed and notarized by Apple, so it opens without warnings.",
	},
	{
		kind: "iphone",
		platform: "iPhone",
		requirements: "iOS 15 or later · not on the App Store",
		fallbackUrl: links.latestRelease,
		buttonLabel: "Download IPA",
		steps: [
			"Download the IPA file.",
			"Install it with Sideloadly, AltStore or SideStore, signing in with your Apple ID.",
		],
		note: "With a free Apple ID the app has to be refreshed every 7 days; AltStore and SideStore do it for you.",
	},
	{
		kind: "android",
		platform: "Android",
		requirements: "Android 7 or later · not on Google Play",
		fallbackUrl: links.latestRelease,
		buttonLabel: "Download APK",
		steps: [
			"Download the APK on your phone.",
			"Open it and allow your browser to install apps when asked.",
		],
		note: "Add Songbrook to Obtainium to get new versions automatically.",
		secondary: {
			label: "Add to Obtainium",
			url: `https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/${github}`,
		},
	},
];

export const features: Feature[] = [
	{
		title: "The YouTube Music catalog",
		description:
			"Search songs, albums, artists and playlists, with radio and suggestions on Home.",
		icon: "FiSearch",
	},
	{
		title: "Downloads and your library",
		description:
			"Save songs for offline listening, with playlists, favorites and synced lyrics.",
		icon: "FiDownload",
	},
	{
		title: "Songs, not music videos",
		description:
			"A music video plays its song version when there is one, and skips its non-music parts otherwise.",
		icon: "FiMusic",
	},
	{
		title: "Songbrook Connect",
		description:
			"Control your Mac from your iPhone, or move playback between them, on the same Wi-Fi.",
		icon: "FiLink",
	},
	{
		title: "Steady volume",
		description:
			"Loud songs are lowered to an even level, as on YouTube Music.",
		icon: "FiVolume2",
	},
	{
		title: "Your history stays with you",
		description:
			"Most played lists, suggestions that learn what you skip, and your top songs kept downloaded on Wi-Fi.",
		icon: "FiShield",
	},
];

/** iPhone screenshots in public/, 603×1311. */
export const screenshots: string[] = [
	"/assets/screenshots/1-home.jpg",
	"/assets/screenshots/2-player.jpg",
	"/assets/screenshots/3-queue.jpg",
	"/assets/screenshots/4-artist.jpg",
];

export const faqs: FAQItem[] = [
	{
		question: "Is Songbrook free?",
		answer:
			"Yes. It is free and open source under the BSD 2-Clause license, with no ads, subscription or account.",
	},
	{
		question: "Why isn't it on the App Store or Google Play?",
		answer:
			"The stores do not accept apps that stream and download from YouTube, so Songbrook is published on GitHub instead.",
	},
	{
		question: "Will my Mac warn me when I open it?",
		answer:
			"No. The Mac app is signed with an Apple Developer ID and notarized by Apple, so it opens like any other app.",
	},
	{
		question: "How do I install it on my iPhone?",
		answer:
			"Use Sideloadly, AltStore or SideStore on your computer with your Apple ID. A free Apple ID allows three such apps and needs a refresh every 7 days, which AltStore and SideStore do automatically.",
	},
	{
		question: "Where does my data go?",
		answer:
			"Songbrook has no servers. Your library and listening history stay on your device; requests go straight to YouTube Music, as from any player.",
	},
	{
		question: "Is Songbrook made by YouTube?",
		answer:
			"No. It is an independent fork of BStream Music by Bryam Contreras and is not affiliated with YouTube or Google.",
	},
];

export const footerSections: { title: string; links: FooterLink[] }[] = [
	{
		title: "Product",
		links: [
			{ label: "Download", href: "#download" },
			{ label: "Screenshots", href: "#screenshots" },
			{ label: "Features", href: "#features" },
			{ label: "FAQ", href: "#faq" },
		],
	},
	{
		title: "Project",
		links: [
			{ label: "Source code", href: github },
			{ label: "Releases", href: links.releases },
			{ label: "Report a problem", href: links.issues },
			{ label: "BStream Music", href: links.upstream },
		],
	},
];
