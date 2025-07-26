/*
 * How to use:
 * - Go to your Credit Card account on Wealthsimple.
 * - Click on "View all" to go to the transactions page.
 * - Scroll to the bottom of the page and click "Load more" to load all transactions (depending on how many transactions you need to import, you may have to click this multiple times).
 * - Right-click and select Inspect to open Developer Tools. (You may need to enable them in your browser settings)
 * - Go to the Console tab.
 * - Paste the script above and press Enter.
 * - This will trigger a download of a transactions.csv file with the relevant data.
 * - You can add the script as a bookmarklet for easier access in the future.
*/ 

(function() {
  const rows = [];

  const buttons = document.querySelectorAll("button");

  buttons.forEach(button => {
    let date = null;
    let el = button;
    while (el && !date) {
      el = el.previousElementSibling || el.parentElement;
      if (el && el.tagName === "H2" && /\d{4}|Today|Yesterday/i.test(el.textContent)) {
        date = el.textContent.trim();
      }
    }

    const ps = button.querySelectorAll("p");
    const description = ps[0]?.textContent.trim();

    let amount = null;
    ps.forEach(p => {
      if (/\$\d/.test(p.textContent)) {
        amount = p.textContent.trim();
      }
    });

    if (date && description && amount) {
      rows.push([date, description, amount]);
    }
  });

  const uniqueRows = Array.from(new Set(rows.map(e => e.join("|")))).map(r => r.split("|"));

  function csvEscape(value) {
    if (typeof value !== 'string') return value;
    if (value.includes(',') || value.includes('"') || value.includes('\n')) {
      return `"${value.replace(/"/g, '""')}"`; // Escape double quotes by doubling them
    }
    return value;
  }

  const csvHeader = ["Date", "Description", "Amount"];
  const csvRows = [csvHeader, ...uniqueRows];

  const csvContent = "data:text/csv;charset=utf-8,"
    + csvRows.map(row => row.map(csvEscape).join(",")).join("\n");

  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", "transactions.csv");
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
})();


