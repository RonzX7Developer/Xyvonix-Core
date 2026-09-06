// Xyvonix Core v3.0 — inline SVG icon set (no emoji anywhere in the WebUI).
// Every icon uses stroke="currentColor"/fill="currentColor" so it inherits
// the surrounding element's color (including the active/on states already
// defined in style.css) without needing per-icon overrides.
const ICONS = {
  bolt: '<path d="M13 2 4 14h6l-1 8 9-12h-6z" fill="currentColor"/>',
  diamond: '<rect x="6.5" y="6.5" width="11" height="11" rx="2.2" transform="rotate(45 12 12)" fill="none" stroke="currentColor" stroke-width="1.8"/>',
  battery: '<rect x="3" y="7" width="16" height="10" rx="2.4" fill="none" stroke="currentColor" stroke-width="1.8"/><rect x="19.4" y="10" width="1.8" height="4" rx="0.9" fill="currentColor"/><rect x="5.2" y="9.2" width="7" height="5.6" rx="1.1" fill="currentColor"/>',
  chip: '<rect x="6" y="6" width="12" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><rect x="9.3" y="9.3" width="5.4" height="5.4" rx="1" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M9 3v3M12 3v3M15 3v3M9 18v3M12 18v3M15 18v3M3 9h3M3 12h3M3 15h3M18 9h3M18 12h3M18 15h3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
  refresh: '<path d="M4.5 12a7.5 7.5 0 0 1 13-5.1M19.5 12a7.5 7.5 0 0 1-13 5.1" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M17.2 3.6v4.3h-4.3M6.8 20.4v-4.3h4.3" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
  storage: '<ellipse cx="12" cy="6.2" rx="7" ry="2.8" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M5 6.2v11.6c0 1.55 3.13 2.8 7 2.8s7-1.25 7-2.8V6.2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M5 12c0 1.55 3.13 2.8 7 2.8s7-1.25 7-2.8" fill="none" stroke="currentColor" stroke-width="1.8"/>',
  rocket: '<path d="M12 2.5c2.8 1.8 4.6 5.4 4.6 9 0 2.1-.7 4-1.8 5.3l-1.1-2.7-1.7 1.9-1.7-1.9-1.1 2.7c-1.1-1.3-1.8-3.2-1.8-5.3 0-3.6 1.8-7.2 4.6-9z" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><circle cx="12" cy="10.3" r="1.35" fill="currentColor"/><path d="M8.2 16.9 6 21.2M15.8 16.9 18 21.2" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>',
  shield: '<path d="M12 3 5.5 5.8v5.1c0 4.6 2.9 8.2 6.5 9.3 3.6-1.1 6.5-4.7 6.5-9.3V5.8L12 3z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><path d="M9 12.2l2.1 2.1 3.9-4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
  gamepad: '<rect x="2.8" y="8" width="18.4" height="9.4" rx="4.6" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 10.6v4M6 12.6h4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="16.2" cy="11.1" r="1.05" fill="currentColor"/><circle cx="18.2" cy="13.4" r="1.05" fill="currentColor"/>',
  home: '<path d="M4 11.2 12 4l8 7.2" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 10v9.3h12V10" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><path d="M9.8 19.3v-5.1h4.4v5.1" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
  wifi: '<path d="M4.5 9a11 11 0 0 1 15 0" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M7.6 12.6a6.5 6.5 0 0 1 8.8 0" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M10.4 16.1a2.6 2.6 0 0 1 3.2 0" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="18.6" r="1.05" fill="currentColor"/>',
  sliders: '<line x1="4" y1="6.3" x2="20" y2="6.3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="9.2" cy="6.3" r="2.1" fill="currentColor"/><line x1="4" y1="12" x2="20" y2="12" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="15.1" cy="12" r="2.1" fill="currentColor"/><line x1="4" y1="17.7" x2="20" y2="17.7" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="11.4" cy="17.7" r="2.1" fill="currentColor"/>',
  info: '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.8"/><line x1="12" y1="11" x2="12" y2="16.3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="7.6" r="1.15" fill="currentColor"/>',
  check: '<path d="M4 12.3 9 17.3 20 6.3" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
  close: '<path d="M5.5 5.5l13 13M18.5 5.5l-13 13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
  apps_off: '<rect x="3.4" y="3.4" width="6.6" height="6.6" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.7"/><rect x="14" y="3.4" width="6.6" height="6.6" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.7"/><rect x="3.4" y="14" width="6.6" height="6.6" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M14.3 14.3l6 6M20.3 14.3l-6 6" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/>',
  target: '<circle cx="12" cy="12" r="8.3" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12" r="3.4" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M12 1.7v3.4M12 18.9v3.4M1.7 12h3.4M18.9 12h3.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
  thermo: '<path d="M12 3.2a2 2 0 0 0-2 2v9.3a4.1 4.1 0 1 0 4 0V5.2a2 2 0 0 0-2-2z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><circle cx="12" cy="17.6" r="1.9" fill="currentColor"/>',
};

function svgIcon(name){
  const body = ICONS[name] || '';
  return `<svg viewBox="0 0 24 24" width="1em" height="1em" aria-hidden="true">${body}</svg>`;
}

// Replace every <i data-icon="name"></i> placeholder in the current DOM with
// its inline SVG. Safe to call multiple times (e.g. after re-rendering a
// list) since it only ever touches elements still carrying data-icon.
function mountIcons(root){
  (root || document).querySelectorAll('[data-icon]').forEach(el=>{
    const name = el.getAttribute('data-icon');
    el.innerHTML = svgIcon(name);
    el.removeAttribute('data-icon');
    el.classList.add('icon');
  });
}

// icons.js is loaded (blocking) after all markup above it, so the static
// icons already exist in the DOM by the time this line runs — no need to
// wait for DOMContentLoaded. app.js calls mountIcons() again after it
// injects new HTML (game rows, ignore-list rows, etc.).
mountIcons();
