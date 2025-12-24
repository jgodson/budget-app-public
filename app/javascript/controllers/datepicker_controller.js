import { Controller } from "@hotwired/stimulus"
import "flatpickr"

export default class extends Controller {
  static values = {
    type: String // 'day', 'month', 'year'
  }

  connect() {
    this.initializeFlatpickr();
    
    // Listen for theme changes
    this.themeChangeHandler = this.handleThemeChange.bind(this);
    window.addEventListener('theme-changed', this.themeChangeHandler);
  }

  disconnect() {
    if (this.fp) {
      this.fp.destroy();
    }
    window.removeEventListener('theme-changed', this.themeChangeHandler);
  }

  initializeFlatpickr() {
    const config = this.getConfig();
    this.fp = flatpickr(this.element, config);
  }

  getConfig() {
    const type = this.typeValue || this.inferTypeFromClass();
    
    switch (type) {
      case 'month':
        return { dateFormat: "m" };
      case 'year':
        return { dateFormat: "Y" };
      case 'day':
      default:
        return { dateFormat: "Y-m-d" };
    }
  }

  inferTypeFromClass() {
    if (this.element.classList.contains('datepicker-month')) return 'month';
    if (this.element.classList.contains('datepicker-year')) return 'year';
    return 'day';
  }

  handleThemeChange(event) {
    // Flatpickr theme is handled via CSS file enabling/disabling in theme_controller
    // But if we needed to redraw or re-init, we could do it here.
    // For now, the global CSS switch is sufficient as per legacy code.
  }
}
