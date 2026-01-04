import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll(".alert").forEach(alert => {
      if (alert.dataset.persist === "true") return
      
      setTimeout(() => {
        // Bootstrap 5 adds itself to the window object when loaded via UMD/importmap
        const Alert = window.bootstrap.Alert
        const alertInstance = Alert.getOrCreateInstance(alert)
        alertInstance.close()
      }, 10000)
    })
  }
}
