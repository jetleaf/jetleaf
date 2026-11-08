/**
 * A centralized place for shared constants and configuration values.
 * Use this class to store base URLs, cache keys, TTLs, and other constants.
 */
export default class Constants {
    /** Base URL for the backend API */
    static readonly BASE_API: string = import.meta.env.VITE_BASE_API_URL;

    /** LocalStorage key for caching the package marketplace data */
    static readonly PACKAGES_CACHE_KEY: string = 'packageMarketplaceCache';

    /** LocalStorage key for caching the jetleaf package data */
    static readonly MAIN_CACHE_KEY: string = 'jetleaf_version_cache';

    /** LocalStorage key for caching the jetleaf devtool package data */
    static readonly DEV_TOOL_CACHE_KEY: string = 'jetleaf_dev_tool_cache';

    /** Time-to-live for cached data (in milliseconds). Default: 1 day */
    static readonly CACHE_TTL: number = 1000 * 60 * 60 * 24; // 24 hours

    /** Time-to-live for cached data (in milliseconds). Default: 1 hour */
    static readonly CACHE_ONE_HOUR_TTL: number = 1000 * 60 * 60;

    /** Default server port used for local development or web module */
    static readonly SERVER_PORT: number = 8080;

    /** Default server host used for local development or web module */
    static readonly SERVER_HOST: string = "localhost";

    /** Environment variable name for server port (used in `.env` or configs) */
    static readonly SERVER_PORT_NAME: string = "SERVER_PORT";

    /** Environment variable name for server host (used in `.env` or configs) */
    static readonly SERVER_HOST_NAME: string = "SERVER_HOST";
}