// Admin entry point: `javascript_importmap_tags "admin"` in the admin, admin
// auth and editor layouts. Loads everything public pages get, plus the Lexxy
// rich-text editor and the admin-only Stimulus controllers.
import "application"
import "lexxy"

// Admin controllers live in app/javascript/admin/controllers but keep their
// plain identifiers: stimulus-loading strips the "admin/controllers/" prefix,
// so admin/controllers/ai_chat_controller registers as "ai-chat".
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("admin/controllers", application)
