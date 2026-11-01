import type { IconType } from "react-icons";
import {
	FiDownload,
	FiLink,
	FiMusic,
	FiSearch,
	FiShield,
	FiVolume2,
} from "react-icons/fi";
import { RiGithubFill } from "react-icons/ri";

const iconMap: Record<string, IconType> = {
	FiDownload,
	FiLink,
	FiMusic,
	FiSearch,
	FiShield,
	FiVolume2,
	RiGithubFill,
};

export const getIcon = (name: string): IconType | null => iconMap[name] ?? null;
