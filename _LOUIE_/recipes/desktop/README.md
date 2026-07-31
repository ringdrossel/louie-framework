Desktop-application packaging and integration recipes — icons, installers, OS shell integration.

Recipes in this section deal with how a desktop app presents itself to the operating system once it is packaged: application and window icons, desktop entries, installer artifacts, and the OS-side caches that keep copies of those assets. They assume a packaged build (AppImage, .deb, .dmg, .msi, …) rather than a dev-server run, and they treat the desktop environment as a stateful integration point that must be refreshed explicitly.
