// Public entry point, loaded by every layout. Configure the import map in
// config/importmap.rb. Admin-only code (the Lexxy editor, Active Storage
// uploads and admin Stimulus controllers) lives in the "admin" entry point
// (app/javascript/admin/index.js), which only admin and editor layouts load.
import "@hotwired/turbo-rails"
import "controllers"
