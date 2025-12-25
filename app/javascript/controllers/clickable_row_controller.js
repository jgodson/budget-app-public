import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  click(event) {
    // If the click originated from a link, button, or form control, do nothing.
    // Also ignore if the clicked element (or its parent) has 'data-clickable-row-target="ignore"'
    if (event.target.closest("a") || 
        event.target.closest("button") || 
        event.target.closest("input") || 
        event.target.closest("select") || 
        event.target.closest(".no-row-click")) {
      return
    }

    // Use Turbo for navigation if available, otherwise fallback to window.location
    if (window.Turbo) {
        window.Turbo.visit(this.urlValue)
    } else {
        window.location.href = this.urlValue
    }
  }
}
