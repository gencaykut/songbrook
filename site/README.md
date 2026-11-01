# Songbrook download page

The page published at <https://gencaykut.github.io/songbrook/> by
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml). It is a
Next.js static export adapted from
[bohd4nx/app-landing](https://github.com/bohd4nx/app-landing) (MIT, see
[LICENSE](LICENSE)); store buttons, ratings, reviews, pricing and the legal
pages were removed.

Content lives in `src/config.ts`. The download buttons read the latest GitHub
release in the browser, so a new release needs no change here; only the
fallback version and date in `site` do.

```bash
pnpm install
pnpm dev          # http://localhost:3000
pnpm exec biome check --write .
pnpm build        # static export → out/
```

The template pins pnpm 12 in `package.json`; with an older pnpm, run
`npx pnpm@12.4.1 <command>`. Screenshots in `public/assets/screenshots/` are
from the iOS simulator in English (603×1311 JPEG).
