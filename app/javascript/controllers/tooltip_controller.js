import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!window.bootstrap?.Tooltip) return

    this.tooltip = window.bootstrap.Tooltip.getOrCreateInstance(this.element, {
      container: 'body',
      trigger: 'hover focus' // Explicitly set trigger
    })

    // Hide tooltip on click to prevent it from sticking around during navigation
    this.clickHandler = this.hide.bind(this)
    this.element.addEventListener("click", this.clickHandler)
  }

  disconnect() {
    if (this.clickHandler) {
      this.element.removeEventListener("click", this.clickHandler)
      this.clickHandler = null
    }

    const tooltip = window.bootstrap?.Tooltip?.getInstance(this.element) || this.tooltip
    if (tooltip) tooltip.dispose()

    this.tooltip = null
  }

  hide() {
    const tooltip = window.bootstrap?.Tooltip?.getInstance(this.element)
    if (tooltip) tooltip.hide()
  }
}
