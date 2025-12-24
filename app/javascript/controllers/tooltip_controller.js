import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

export default class extends Controller {
  connect() {
    this.tooltip = new Tooltip(this.element, {
      container: 'body',
      trigger: 'hover focus' // Explicitly set trigger
    })
  }

  disconnect() {
    if (this.tooltip) {
      this.tooltip.dispose()
    }
  }
}
