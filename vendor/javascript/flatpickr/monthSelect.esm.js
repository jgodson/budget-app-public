import "flatpickr/monthSelect";

const plugin = (typeof window !== "undefined" && window.monthSelectPlugin)
  || (typeof globalThis !== "undefined" && globalThis.monthSelectPlugin);

export default plugin;
