import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    this.setTheme(savedTheme);
  }

  toggle(event) {
    event.preventDefault();
    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    this.setTheme(newTheme);
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    localStorage.setItem('theme', theme);
    
    // Dispatch a custom event for other controllers to react to
    window.dispatchEvent(new CustomEvent('theme-changed', { detail: { theme } }));
    
    // Handle Flatpickr theme toggling specifically as it was in the legacy code
    // Ideally this should be in the datepicker controller listening to the event, 
    // but for the global stylesheet toggle, we can keep it here or move it.
    // The legacy code did:
    const darkThemeStyle = document.getElementById('flatpickr-dark-theme');
    if (darkThemeStyle) {
      if (theme === 'dark') {
        darkThemeStyle.removeAttribute('disabled');
      } else {
        darkThemeStyle.setAttribute('disabled', 'disabled');
      }
    }
  }
}
