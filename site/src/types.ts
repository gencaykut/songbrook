export type DownloadKind = "mac" | "iphone" | "android";

export interface Download {
	kind: DownloadKind;
	platform: string;
	requirements: string;
	/** Used until the latest release's file is known. */
	fallbackUrl: string;
	buttonLabel: string;
	steps: string[];
	note: string;
	secondary?: { label: string; url: string }[];
}

export interface Feature {
	title: string;
	description: string;
	icon: string;
}

export interface FAQItem {
	question: string;
	answer: string;
}

export interface SocialLink {
	url: string;
	icon: string;
	label: string;
}

export interface FooterLink {
	label: string;
	href: string;
}

export type ThemeMode = "light" | "dark" | "system";

export interface AppHeroProps {
	title: string;
	description: string;
	logo: string;
}

export interface FeaturesProps {
	items: Feature[];
}

export interface FeatureCardProps {
	feature: Feature;
	index: number;
}

export interface DownloadsProps {
	items: Download[];
}

export interface FAQProps {
	items: FAQItem[];
}

export interface FAQCardProps {
	item: FAQItem;
	index: number;
}

export interface SocialLinksProps {
	items: SocialLink[];
}

export interface FooterProps {
	name: string;
	logo: string;
}

export interface GalleryProps {
	images: string[];
	onOpen: (index: number) => void;
}

export interface ScreenshotsProps {
	images: string[];
}
