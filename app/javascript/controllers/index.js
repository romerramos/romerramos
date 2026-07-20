// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import Lightbox from "@stimulus-components/lightbox"
import Sortable from "@stimulus-components/sortable"

eagerLoadControllersFrom("controllers", application)
application.register("lightbox", Lightbox)
application.register("sortable", Sortable)
