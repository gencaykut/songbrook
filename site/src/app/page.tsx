import AppHero from "@/components/AppHero";
import Downloads from "@/components/Downloads";
import FAQ from "@/components/FAQ";
import Features from "@/components/Features";
import Screenshots from "@/components/Screenshots";
import { downloads, faqs, features, screenshots, site } from "@/config";

export default function HomePage() {
	return (
		<main className="container mx-auto px-3 md:px-6">
			<AppHero
				title={site.name}
				description={site.description}
				logo={site.logo}
			/>
			{screenshots.length > 0 && (
				<section id="screenshots" className="mb-16 scroll-mt-8 md:mb-24">
					<Screenshots images={screenshots} />
				</section>
			)}
			<section id="download" className="mb-16 scroll-mt-8 md:mb-24">
				<Downloads items={downloads} />
			</section>
			<section id="features" className="mb-16 scroll-mt-8 md:mb-24">
				<Features items={features} />
			</section>
			<section id="faq" className="mb-16 scroll-mt-8 md:mb-24">
				<FAQ items={faqs} />
			</section>
		</main>
	);
}
