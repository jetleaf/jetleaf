/// <reference types="vite/client" />

/**
 * Defines the shape of environment variables exposed via `import.meta.env`.
 *
 * Add any custom VITE_ variables here to get proper TypeScript typings.
 */
interface ImportMetaEnv {
  /** Base API URL for the application, injected via Vite. */
  readonly VITE_BASE_API_URL: string
}

/**
 * Extends the `ImportMeta` interface with typed `env` access.
 */
interface ImportMeta {
  /** Typed access to environment variables. */
  readonly env: ImportMetaEnv
}