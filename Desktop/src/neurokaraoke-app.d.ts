export {};

export interface NeuroKaraokeApp {
    args: {
        devtools: boolean;
        enable_os_decorations: boolean;
        disable_custom_controls: boolean;
        use_test_site: boolean;
        theme?: "neuro" | "twins" | "evil";
        disable_url_checking: boolean;
    };
}