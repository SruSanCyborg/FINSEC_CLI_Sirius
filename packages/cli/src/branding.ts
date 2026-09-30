/**
 * Product identity, in one place.
 *
 * Kept separate from the renderers so the name, attribution, and tagline are
 * changed once rather than hunted through banner strings — which is exactly the
 * problem the finsec-lint → sirius rename created the first time.
 */

import { createRequire } from 'node:module';

export const PRODUCT = 'sirius';

/** Read from package.json so `sirius --version` always matches the published package. */
export const VERSION: string = createRequire(import.meta.url)('../package.json').version;

/** Shown as "powered by …" beneath the wordmark. */
export const AUTHOR = 'Srusan';

export const TAGLINE = 'Compliance linting for money-handling code';

/**
 * Sirius is the brightest star in the night sky, and blue-white. The wordmark's
 * gradient and star accent come from that, which is what keeps the identity
 * from being a generic ASCII banner.
 */
export const STAR = '✦';
