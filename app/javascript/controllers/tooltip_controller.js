import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.tooltip = new window.bootstrap.Tooltip(this.element, {
      container: 'body',
      trigger: 'hover focus' // Explicitly set trigger
    })
    
    // Hide tooltip on click to prevent it from sticking around during navigation
    this.element.addEventListener("click", this.hide.bind(this))
  }

  disconnect() {
    if (this.tooltip) {
      this.tooltip.dispose()
    }
  }

  hide() {
    if (this.tooltip) {
      this.tooltip.hide()
    }
  }
}