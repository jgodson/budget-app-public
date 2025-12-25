import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart-switcher"
export default class extends Controller {
  static targets = ["view", "btn", "title"]

  connect() {
    // Initialize Bootstrap tooltips
    this.btnTargets.forEach(btn => {
      new bootstrap.Tooltip(btn)
    })
  }

  switch(event) {
    const clickedBtn = event.currentTarget
    const viewName = clickedBtn.dataset.viewName
    const titleText = clickedBtn.dataset.title

    // Update Title
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = titleText
    }

    // Update Buttons State
    this.btnTargets.forEach(btn => {
      btn.classList.remove("active", "btn-secondary")
      btn.classList.add("btn-outline-secondary")
    })
    clickedBtn.classList.remove("btn-outline-secondary")
    clickedBtn.classList.add("active", "btn-secondary")

    // Update Views Visibility
    this.viewTargets.forEach(view => {
      if (view.dataset.viewName === viewName) {
        view.classList.remove("d-none")
      } else {
        view.classList.add("d-none")
      }
    })
  }
}
