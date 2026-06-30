Build-time recipes that derive values from the repo or environment and bake them into the app.

Recipes in this section run a step at build time (not runtime) to capture something about the build — the release version, build metadata, commit identity — and expose it to the running application through a generated, gitignored artifact. They assume the app should not depend on git or the build environment being present at runtime.
