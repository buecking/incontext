# InContext

Source for **InContext** — a resource site on the craft of context for AI.

## Layout

The repo separates **content** from **framework**.

### Content

- `index.md` — landing page
- `docs/foundations/` — vocabulary and underlying ideas
- `docs/per-tool/` — references for `CLAUDE.md`, `AGENTS.md`, Cursor rules, etc.
- `docs/patterns/` — recurring shapes that work
- `docs/reference/` — cheat sheets, quick lookups
- `_pages/about.md` — about page
- `assets/images/` — images referenced from content

Each page declares its place in the nav with front matter:

```yaml
---
title: Crafting a CLAUDE.md
parent: Per-tool
nav_order: 1
permalink: /docs/per-tool/claude-md/
---
```

`parent:` matches the `title:` of a section landing page (which has `has_children: true`). `nav_order:` controls the order within that section.

### Framework

- `_config.yml` — site configuration
- `Gemfile` — Jekyll + plugins
- `.github/workflows/deploy.yml` — CI build + deploy
- Theme is [Just the Docs](https://just-the-docs.com/), loaded via `remote_theme` so we don't vendor it.

## Local development

```bash
bundle install
bundle exec jekyll serve --livereload
```

Site at `http://localhost:4000`.

## Deployment

Pushing to `main` triggers `.github/workflows/deploy.yml`, which builds the site and pushes the static output to the `gh-pages` branch. GitHub Pages serves from there.

**One-time setup after creating the repo:**

1. Push this code to `main`.
2. In repo settings → Pages, set source to "Deploy from a branch" → `gh-pages` → `/ (root)`.
3. In `_config.yml`, replace `YOUR-USER` everywhere with your GitHub username, and set `url` to your Pages URL (or custom domain).
4. Push again. The workflow runs and the `gh-pages` branch appears on the first run.

## Adding a page

1. Create the markdown file in the appropriate `docs/<section>/` directory.
2. Add front matter with `title`, `parent` (the section name), `nav_order`, and `permalink`.
3. Optional: add a TOC by including:
   ```markdown
   1. TOC
   {:toc}
   ```
4. Commit and push. The workflow rebuilds and deploys.

## Adding a section

1. Create `docs/<section>/index.md` with `has_children: true` in front matter.
2. Pages in that section reference it by `parent: <Section Title>`.
