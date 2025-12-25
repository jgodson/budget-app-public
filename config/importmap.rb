# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap/dist/js/bootstrap.bundle.min.js", preload: true
pin "flatpickr", to: "flatpickr/dist/flatpickr.min.js", preload: true
pin "chart.js", to: "chart.js/dist/chart.umd.js"
pin "@kurkle/color", to: "@kurkle/color/dist/color.esm.js"
