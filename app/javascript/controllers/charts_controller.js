import { Controller } from "@hotwired/stimulus"
// Connects to data-controller="charts"
export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    this.renderChart()
  }

  renderChart() {
    if (typeof Chart === 'undefined') {
      console.error("Chart.js is not loaded")
      return
    }

    const ctx = this.element.getContext('2d')

    // Default options
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
    }

    const options = { ...defaultOptions, ...this.optionsValue }

    new Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: options
    })
  }
}
