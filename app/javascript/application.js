// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@popperjs/core"
import "bootstrap"
import "flatpickr";
import "controllers"

function setTheme(theme) {
  document.documentElement.setAttribute('data-bs-theme', theme);
  initalizeDatepickers(theme);
  localStorage.setItem('theme', theme);
}

function toggleTheme() {
  const currentTheme = document.documentElement.getAttribute('data-bs-theme');
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  setTheme(newTheme);
}

function initalizeDatepickers(theme) {
  flatpickr(".datepicker-day", {
    dateFormat: "Y-m-d", // Default format for full date
  });

  flatpickr(".datepicker-month", {
    dateFormat: "m", // Year and month format
  });

  flatpickr(".datepicker-year", {
    dateFormat: "Y",
  });

  if (theme) {
    const darkThemeStyle = document.getElementById('flatpickr-dark-theme');
    if (theme === 'dark') {
      darkThemeStyle.removeAttribute('disabled');
    } else {
      darkThemeStyle.setAttribute('disabled', 'disabled');
    }
  }
}

function formatNumberInput(input) {
  let value = input.value.replace(/[^0-9.]/g, '');
  value = parseFloat(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  if (value === 'NaN') {
    input.value = 0;
  } else {
    console.log(value);
    input.value = value;
  }
}

function processNumberInputs(event) {
  const numberInputs = event.srcElement.querySelectorAll('input[data-type="number"]');
  console.log(numberInputs);
  numberInputs.forEach(input => {
    input.value = input.value.replace(/,/g, '');
  });
}

document.addEventListener("turbo:load", () => {
  initalizeDatepickers();
});

document.addEventListener('DOMContentLoaded', () => {
  const savedTheme = localStorage.getItem('theme') || 'light';
  setTheme(savedTheme);
  initalizeDatepickers(savedTheme);
});

const BudgetApp = {
  toggleTheme,
  formatNumberInput,
  processNumberInputs,
};

window.BudgetApp = BudgetApp;