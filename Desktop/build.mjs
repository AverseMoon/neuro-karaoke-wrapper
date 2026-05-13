import esbuild from "esbuild";

await esbuild.build({
    entryPoints: ["src/injected.js"],
    bundle: true,
    format: "iife",
    platform: "browser",
    outfile: "dist/bundle.js",
    minify: true,
    loader: {
        ".txt": "text",
        ".html": "text",
        ".css": "text",
    }
});