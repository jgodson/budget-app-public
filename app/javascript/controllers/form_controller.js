import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    // Find all inputs with data-type="number" inside this form
    const numberInputs = this.element.querySelectorAll('input[data-type="number"]');
    numberInputs.forEach(input => {
      input.value = input.value.replace(/,/g, '');
    });
  }
}
