import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    this.setTheme(savedTheme);
    this.syncCheckbox(savedTheme);
  }

  toggle(event) {
    // If it's a checkbox change event, use the checked state
    // Otherwise toggle based on current attribute
    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
    let newTheme;
    
    if (event.target.type === 'checkbox') {
      newTheme = event.target.checked ? 'dark' : 'light';
    } else {
      event.preventDefault();
      newTheme = currentTheme === 'light' ? 'dark' : 'light';
    }
    
    this.setTheme(newTheme);
    this.syncCheckbox(newTheme);
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    localStorage.setItem('theme', theme);
    
    window.dispatchEvent(new CustomEvent('theme-changed', { detail: { theme } }));
    
    const darkThemeStyle = document.getElementById('flatpickr-dark-theme');
    if (darkThemeStyle) {
      darkThemeStyle.disabled = (theme !== 'dark');
    }
  }

  syncCheckbox(theme) {
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = (theme === 'dark');
    }
  }
}
