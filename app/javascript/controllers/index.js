// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import Lightbox from "@stimulus-components/lightbox"

eagerLoadControllersFrom("controllers", application)
application.register("lightbox", Lightbox)
