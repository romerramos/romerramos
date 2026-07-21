# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@avo-hq/marksmith", to: "@avo-hq--marksmith.js" # @0.4.8
pin "@stimulus-components/lightbox", to: "@stimulus-components--lightbox.js" # @4.0.0
pin "@stimulus-components/sortable", to: "@stimulus-components--sortable.js" # @5.0.3
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.13
pin "lightgallery" # @2.9.0
pin "sortablejs" # @1.15.7
