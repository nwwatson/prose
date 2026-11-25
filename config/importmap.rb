# Pin npm packages by running ./bin/importmap
#
# Two entry points: "application" (every page) and "admin" (admin, admin auth
# and editor layouts, via `javascript_importmap_tags "admin"`). A pin's
# `preload:` decides which entry points emit a <link rel="modulepreload"> for
# it: `true` for every entry point, "admin" for the admin one only, `false`
# for none (still importable on demand). Every pin stays in the import map
# itself, so admin modules are never fetched on public pages unless imported.

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
# turbo.min.js bundles its own Action Cable consumer; nothing imports this pin.
pin "@rails/actioncable", to: "actioncable.esm.js", preload: false
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/lib", under: "lib"

# Admin entry point (admin/index.js), admin controllers and admin-only helpers.
pin_all_from "app/javascript/admin", under: "admin", preload: "admin"
pin "lexxy", to: "lexxy.js", preload: "admin"
# Imported on demand by Lexxy when a file is attached.
pin "@rails/activestorage", to: "activestorage.esm.js", preload: "admin"

pin "highlight.js", to: "https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.11.1/es/highlight.min.js", preload: false
