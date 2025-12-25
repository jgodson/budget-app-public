import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart-toggle"
export default class extends Controller {
  static targets = ["primary", "secondary", "icon"]

  toggle() {
    this.primaryTarget.classList.toggle("d-none")
    this.secondaryTarget.classList.toggle("d-none")
    
    // Toggle Icon
    if (this.hasIconTarget) {
      if (this.primaryTarget.classList.contains("d-none")) {
        this.iconTarget.classList.remove("bi-pie-chart-fill")
        this.iconTarget.classList.add("bi-bar-chart-fill")
        this.element.title = "View Overview"
      } else {
        this.iconTarget.classList.remove("bi-bar-chart-fill")
        this.iconTarget.classList.add("bi-pie-chart-fill")
        this.element.title = "View Details"
      }
    }
  }
}
