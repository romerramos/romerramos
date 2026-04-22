// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import { MarksmithController } from "@avo-hq/marksmith"
import { application } from "controllers/application"
application.register("marksmith", MarksmithController)
