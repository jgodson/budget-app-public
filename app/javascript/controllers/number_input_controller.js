import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  format() {
    let value = this.element.value.replace(/[^0-9.]/g, '');
    value = parseFloat(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    if (value === 'NaN') {
      this.element.value = 0;
    } else {
      this.element.value = value;
    }
  }
}
