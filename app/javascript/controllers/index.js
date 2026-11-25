// Register the public Stimulus controllers (controllers/**/*_controller).
// Admin-only controllers are registered by the "admin" entry point instead.
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
