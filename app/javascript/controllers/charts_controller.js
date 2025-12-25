import { Controller } from "@hotwired/stimulus"
import "chart.js"

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
    const ctx = this.element.getContext('2d')

    // Default options
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
    }

    const options = { ...defaultOptions, ...this.optionsValue }

    const backgroundPlugin = {
      id: 'customCanvasBackgroundColor',
      beforeDraw: (chart, args, options) => {
        const {ctx} = chart;
        ctx.save();
        ctx.globalCompositeOperation = 'destination-over';
        
        const theme = document.documentElement.getAttribute('data-bs-theme');
        // Use pure white for light mode, match dark theme for dark mode
        ctx.fillStyle = theme === 'dark' ? '#1e1e1e' : '#ffffff';
        
        ctx.fillRect(0, 0, chart.width, chart.height);
        ctx.restore();
      }
    };

    new window.Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: options,
      plugins: [backgroundPlugin]
    })
  }
}
