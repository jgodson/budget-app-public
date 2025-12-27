import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["yearly", "month"]

  connect() {
    this.updateState()
  }

  toggleYearly() {
    if (this.yearlyTarget.checked) {
      this.monthTargets.forEach(checkbox => {
        checkbox.checked = false
      })
    }
    // If I uncheck yearly manually, what happens? 
    // Usually one state must be valid. 
    // If I uncheck yearly, and no months are checked, it implies yearly?
    // I'll leave it simple: check yearly -> uncheck months.
    // Uncheck yearly -> do nothing (user will check a month).
  }

  toggleMonth() {
    const anyChecked = this.monthTargets.some(checkbox => checkbox.checked)
    if (anyChecked) {
      this.yearlyTarget.checked = false
    } else {
      // If all months unchecked, re-check yearly?
      this.yearlyTarget.checked = true
    }
  }

  updateState() {
    // Ensure consistent state on load
    const anyChecked = this.monthTargets.some(checkbox => checkbox.checked)
    if (anyChecked) {
      this.yearlyTarget.checked = false
    } else {
      this.yearlyTarget.checked = true
    }
  }
}
