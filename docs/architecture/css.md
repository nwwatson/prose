# CSS Components

BEM component styles, theme tokens and the reusable component classes.

## BEM CSS Components
Frontend component styles use BEM (Block Element Modifier) methodology in `app/assets/tailwind/components/`. Each component gets its own file (e.g., `_post-card.css`) imported via the `_index.css` manifest. Component CSS is **unlayered**, so it beats Tailwind's layered utilities: toggling the `hidden` class can't show an element whose component rule applies `hidden`, or hide one whose rule sets `display`. Toggle the `hidden` attribute (as `markdown_preview` does) or a BEM modifier instead. Theme variables (fonts, colors) are defined in the `@theme` block of `application.css` — Tailwind v4's `@theme` directive cannot be extracted to a separate file. `SiteHelper` methods inject runtime overrides for admin-configurable fonts and colors.

Greys in components come from the semantic tokens in `@theme`, remapped in the `.dark` block of `application.css`, so use the token rather than a `text-gray-* dark:text-gray-*` pair: `muted` (500/400, meta and hints), `muted-strong` (600/400, subtitles, excerpts, descriptions), `faint` (400/500, idle icons and small asides), `rule` (200/700, card borders and dividers), `rule-strong` (300/700, masthead, footer and page headers) and `surface` (white/800, raised cards). The admin dark theme overrides only `cream`, `charcoal` and `ink-blue`, not these. Greys outside those six pairs stay as literal utilities.

Reuse before adding a rule: `.page-heading` and `.section-heading` for headings; `.btn` with `--primary`, `--secondary`, `--danger` or `--inverse` (high-contrast call to action), plus `--small`/`--large` (a block such as `.paywall__cta` only positions the button); `.narrow-page` (`--centered`, `__heading`, `__message`) for single-task pages like unsubscribe and email preferences. Where two blocks need the same declarations, group their selectors in one rule (`.post-nav, .related-posts`; the ruled-off post sections including `.share-buttons` in `_post-detail.css`).

