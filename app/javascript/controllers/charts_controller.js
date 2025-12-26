import { Controller } from "@hotwired/stimulus"
import "chart.js"

// Connects to data-controller="charts"
export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object,
    centerLabel: String,
    centerText: String,
    centerColor: String
  }

  connect() {
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    this.renderChart()
    this.themeChangeListener = (event) => {
      if (this.chart) {
        const theme = document.documentElement.getAttribute('data-bs-theme');
        const textColor = theme === 'dark' ? '#adb5bd' : '#666666';
        const gridColor = theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)';
        
        this.chart.options.color = textColor;
        
        if (this.chart.options.scales) {
          ['x', 'y'].forEach(axis => {
            if (this.chart.options.scales[axis]) {
              if (this.chart.options.scales[axis].ticks) {
                this.chart.options.scales[axis].ticks.color = textColor;
              }
              if (this.chart.options.scales[axis].grid) {
                this.chart.options.scales[axis].grid.color = gridColor;
              }
            }
          });
        }
        
        this.chart.update(); 
      }
    }
    window.addEventListener('theme-changed', this.themeChangeListener)
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
    window.removeEventListener('theme-changed', this.themeChangeListener)
  }

  renderChart() {
    const ctx = this.element.getContext('2d')

    // Default options
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        tooltip: {
          callbacks: {
            label: function(context) {
              let label = context.dataset.label || '';
              if (label) { label += ': '; }
              let value = context.raw;
              label += new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
              return label;
            }
          }
        }
      }
    }

    const options = { ...defaultOptions, ...this.optionsValue }
    
    // Ensure default plugins logic isn't overwritten by shallow merge
    if (!options.plugins) { options.plugins = {}; }
    
    // Restore default tooltip callback if not explicitly overridden
    if (!options.plugins.tooltip) { options.plugins.tooltip = {}; }
    if (!options.plugins.tooltip.callbacks) { options.plugins.tooltip.callbacks = {}; }
    if (!options.plugins.tooltip.callbacks.label) {
      options.plugins.tooltip.callbacks.label = defaultOptions.plugins.tooltip.callbacks.label;
    }

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

        // Draw Center Text if available
        if (this.hasCenterTextValue) {
          const { width, height, top, bottom, left, right } = chart.chartArea;
          const centerX = (left + right) / 2;
          const centerY = (top + bottom) / 2;

          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';

          // Draw Label
          if (this.hasCenterLabelValue) {
            ctx.font = "normal 14px 'Arial Unicode MS', 'Inter', sans-serif";
            ctx.fillStyle = theme === 'dark' ? '#adb5bd' : '#6c757d'; // muted
            ctx.fillText(this.centerLabelValue, centerX, centerY - 15);
          }

          // Draw Value
          ctx.font = "bold 20px 'Arial Unicode MS', 'Inter', sans-serif";
          ctx.fillStyle = this.centerColorValue;
          ctx.fillText(this.centerTextValue, centerX, centerY + 10);
        }
      }
    };

    const theme = document.documentElement.getAttribute('data-bs-theme');
    const textColor = theme === 'dark' ? '#adb5bd' : '#666666';
    const gridColor = theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)';

    if (!options.color) { options.color = textColor; }
    
    if (this.typeValue !== 'pie' && this.typeValue !== 'doughnut') {
      if (!options.scales) { options.scales = {}; }
      ['x', 'y'].forEach(axis => {
        if (!options.scales[axis]) { options.scales[axis] = {}; }
        if (!options.scales[axis].ticks) { options.scales[axis].ticks = {}; }
        if (!options.scales[axis].ticks.color) { options.scales[axis].ticks.color = textColor; }
        
        if (!options.scales[axis].grid) { options.scales[axis].grid = {}; }
        if (!options.scales[axis].grid.color) { options.scales[axis].grid.color = gridColor; }
      });
    }

    this.chart = new window.Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: options,
      plugins: [backgroundPlugin]
    })
  }
}
