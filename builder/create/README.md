# create — Jetleaf Project Creator 🛠️

**Short description**

`create` is a small frontend web application (Vite + React + TypeScript) that powers the Jetleaf project generator / package marketplace UI. It provides a visual interface to configure a new Jetleaf project, preview generated output, and browse/create package templates.

---

## 🔎 Overview

- Purpose: Let users configure, preview, and export a new Jetleaf project from the browser. It includes a package marketplace view, project configuration UI, preview pane, and code export functionality.
- Stack: **Vite**, **React (TSX)**, **TypeScript**, **Tailwind-friendly CSS**, and several Radix UI primitives.

---

## ✅ Features

- Project configuration editor with typed model (`src/types`) and UI helpers.
- Package marketplace browsing and package information panels.
- Live project preview and code export (ZIP generation with `jszip` / `file-saver`).
- Reusable UI primitives and accessibility-focused components (Radix + custom components).
- Development-ready Vite workflow with a small build and dev script surface.

---

## 📁 Project Structure (high level)

- `index.html` — Vite entry HTML.
- `package.json` — scripts and dependencies (`dev`, `build`).
- `.env` — environment variables (optional project settings).
- `public/` — static assets served by Vite.
- `src/` — application source code
  - `main.tsx` — app bootstrap
  - `ui/` — higher-level pages and screens
  - `components/` — shared UI primitives (buttons, inputs, select, dialog, scroll-area, etc.)
  - `styles/` — global CSS and tailwind-like utilities
  - `types/` — domain models (`package.ts`, `project_config.ts`, `pubspec.ts`, ...)
  - `utils/` — helpers: `CodeBuilder.tsx`, `Utility.tsx`, hooks and constants
- `vite.config.ts` — Vite configuration
- `LICENSE` — project license
- `.github/workflows/release-on-merge.yml` — automated release workflow

---

## 🔧 Notable files and components

- `src/ui/Header.tsx` — top-level header/navigation
- `src/ui/PackageMarketplace.tsx` — marketplace listing and search
- `src/ui/PackageInformation.tsx` — package details panel
- `src/ui/ProjectConfiguration.tsx` — main form for project settings
- `src/ui/ProjectPreview.tsx` — live preview and generated output preview
- `src/ui/ProjectSummary.tsx` — final summary & export actions
- `src/components/*` — small building blocks used across the UI (e.g., `input.tsx`, `select.tsx`, `dialog.tsx`, `scroll-area.tsx`, and `sonner.tsx` for notifications)
- `src/utils/CodeBuilder.tsx` — central logic for assembling files (pubspec, templates)

---

## 🚀 Development & Local Setup

Prerequisites: Node.js (LTS recommended)

1. Install dependencies

```bash
npm install
```

2. Run development server

```bash
npm run dev
# open http://localhost:5173 (or the Vite-reported address)
```

3. Build for production

```bash
npm run build
# output goes to the Vite build directory (default: dist)
```

Notes:
- The app expects optional config in `.env` (e.g., preview or analytics flags) — check the file if present.
- There is no test runner or lint script in `package.json` by default; add any tooling you prefer.

---

## 💡 Development Tips

- Types live in `src/types` — keep models and props typed for safe editing.
- Use `src/components` for any new UI primitive and `src/ui` for pages/screens.
- Utilities like `CodeBuilder` centralize how project files are created; prefer extending there when adding new export features.
- The repo uses Radix UI primitives and several small libraries (e.g., `jszip`, `file-saver`, `react-syntax-highlighter`) for focused tasks.

---

## 🤝 Contributing

- Fork, create a branch, and open a PR. Keep changes small and self-contained.
- There is a GitHub workflow for releases (`.github/workflows/release-on-merge.yml`). Follow the repo conventions for versioning and releases.

---

## 📄 License & Credits

This project includes a `LICENSE` file in the repository root — please follow the license terms.

Maintainers: Hapnium / Jetleaf team.