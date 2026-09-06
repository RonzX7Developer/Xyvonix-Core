const $ = s => document.querySelector(s);
const $$ = s => Array.from(document.querySelectorAll(s));
const bridge = window.Axeron || null;

function escapeHtml(s){
  return String(s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
}

function toast(msg){
  const el = $("#toast");
  el.textContent = msg;
  el.classList.add("show");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.remove("show"), 2600);
}

// The AxManager bridge tokenizes the command string on whitespace only —
// it does NOT parse shell-style quotes. Every run() call below sends
// pre-validated, space-free arguments (hostnames / package names) with NO
// surrounding quotes, otherwise the literal quote characters are shipped
// straight through and the receiving shell-side validation rejects them
// (this was the root cause of DNS choices silently reverting to Automatic).
function exec(command){
  return new Promise((resolve, reject) => {
    if (!bridge) return reject(new Error("AxManager bridge unavailable"));
    const cb = `xy_${Date.now()}_${Math.random().toString(16).slice(2)}`;
    let settled = false;
    const timer = setTimeout(() => finish(reject, new Error("AxManager did not respond in time")), 12000);
    function finish(fn, val){
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      delete window[cb];
      fn(val);
    }
    window[cb] = (errno, out, err) => {
      if (Number(errno) === 0) finish(resolve, String(out || "").trim());
      else finish(reject, new Error(String(err || out || `Command failed: ${errno}`).trim()));
    };
    try { bridge.exec(command, "{}", cb); }
    catch (e) { finish(reject, e); }
  });
}
const run = a => exec(`xyvonix ${a}`);

function detectBridge(){
  const badge = $("#bridgeBadge");
  if (bridge) { badge.textContent = "AXERON ONLINE"; badge.classList.add("active"); return true; }
  badge.textContent = "BRIDGE OFFLINE";
  return false;
}

function toggleButton(id, on){
  const node = $(id);
  if (!node) return;
  node.classList.toggle("on", !!on);
  node.dataset.enabled = on ? "1" : "0";
}

async function runToggle(command, id){
  const node = $(id);
  const next = node.dataset.enabled !== "1";
  try {
    await run(`${command} ${next ? "on" : "off"}`);
    toast(next ? "Enabled" : "Disabled");
    await refresh();
  } catch (e) { toast(e.message); }
}

// ---------------- tabs ----------------
$$(".tab").forEach(btn => btn.onclick = () => {
  $$(".tab").forEach(b => b.classList.remove("active"));
  $$(".view").forEach(v => v.classList.remove("active"));
  btn.classList.add("active");
  $(`#${btn.dataset.view}`).classList.add("active");
});

// ---------------- profiles ----------------
$$(".profile-card[data-profile]").forEach(btn => btn.onclick = async () => {
  try {
    await run(`profile ${btn.dataset.profile}`);
    $$(".profile-card").forEach(c => c.classList.remove("active"));
    btn.classList.add("active");
    toast(`${btn.dataset.profile[0].toUpperCase()}${btn.dataset.profile.slice(1)} profile applied`);
    await refresh();
  } catch (e) { toast(e.message); }
});

// ---------------- quick tools ----------------
$("#memoryBtn").onclick = async () => { try { await run("memory"); toast("Memory pass requested"); } catch (e) { toast(e.message); } };
$("#trimBtn").onclick = async () => { try { await run("trim"); toast("Cache trim requested"); } catch (e) { toast(e.message); } };
$("#fstrimBtn").onclick = async () => { try { await run("fstrim"); toast("Storage fstrim requested"); } catch (e) { toast(e.message); } };
$("#optimizeBtn").onclick = async () => {
  try { await run("optimize"); toast("Auto Optimize applied"); await refresh(); }
  catch (e) { toast(e.message); }
};
async function closeBackground(){
  try {
    const n = Number((await run("close-bg")).trim() || "0");
    toast(n > 0 ? `Closed ${n} background app${n === 1 ? "" : "s"}` : "No background apps to close");
  } catch (e) { toast(e.message); }
}
$("#closeBgBtn").onclick = closeBackground;
$("#closeBgBtn2").onclick = closeBackground;
$("#refreshBtn").onclick = () => refresh().then(() => toast("Refreshed"));

// ---------------- DNS ----------------
function restoreDnsUI(mode, host){
  $$(".dns-card").forEach(c => c.classList.remove("active"));
  if (mode === "opportunistic") { $('[data-dns="auto"]')?.classList.add("active"); $("#dnsCurrent").textContent = "Automatic"; return; }
  if (mode === "off") { $('[data-dns="off"]')?.classList.add("active"); $("#dnsCurrent").textContent = "Off"; return; }
  const preset = $(`[data-host="${host}"]`);
  if (preset) { preset.classList.add("active"); $("#dnsCurrent").textContent = preset.querySelector("b").textContent; }
  else if (host) { $("#dnsCurrent").textContent = host; }
  else { $("#dnsCurrent").textContent = "—"; }
}
async function dnsMode(mode, host = ""){
  try {
    await run(mode === "hostname" ? `dns hostname ${host}` : `dns ${mode}`);
    toast("Private DNS updated");
    await refresh();
  } catch (e) { toast(e.message); }
}
$$(".dns-card[data-dns]").forEach(b => b.onclick = () => dnsMode(b.dataset.dns));
$$(".dns-card[data-host]").forEach(b => b.onclick = () => dnsMode("hostname", b.dataset.host));
$("#setCustomDns").onclick = () => {
  const host = $("#customDns").value.trim();
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(host)) { toast("Invalid hostname"); return; }
  dnsMode("hostname", host);
};

// ---------------- toggles ----------------
$("#networkToggle").onclick = () => runToggle("network", "#networkToggle");
$("#wifiLatencyToggle").onclick = () => runToggle("wifi-latency", "#wifiLatencyToggle");
$("#renderToggle").onclick = () => runToggle("render", "#renderToggle");
$("#blurToggle").onclick = () => runToggle("blur", "#blurToggle");
$("#refreshToggle").onclick = () => runToggle("refresh", "#refreshToggle");
$("#autoGameToggle").onclick = () => runToggle("auto-game", "#autoGameToggle").then(pollGameStatus);

// ---------------- background app manager (ignore list) ----------------
async function renderIgnoreList(){
  try {
    const raw = await run("ignore-list");
    const pkgs = raw.split(/\r?\n/).map(x => x.trim()).filter(Boolean);
    $("#ignoreList").innerHTML = pkgs.length
      ? pkgs.map(pkg => `<div class="game-row"><div class="game-name"><b>${escapeHtml(pkg)}</b><small>always kept running</small></div><button class="mini" data-unignore="${escapeHtml(pkg)}"><i data-icon="close"></i></button></div>`).join("")
      : '<div class="hint">No apps pinned — Xyvonix Core will still skip the current app and your tracked games.</div>';
    mountIcons($("#ignoreList"));
    $$("[data-unignore]").forEach(b => b.onclick = async () => {
      try { await run(`ignore-remove ${b.dataset.unignore}`); await renderIgnoreList(); toast("Removed from keep-alive list"); }
      catch (e) { toast(e.message); }
    });
  } catch (e) { toast(e.message); }
}
$("#addIgnore").onclick = async () => {
  const pkg = $("#ignorePkg").value.trim();
  if (!/^[A-Za-z0-9_][A-Za-z0-9_.]*$/.test(pkg)) { toast("Invalid package name"); return; }
  try { await run(`ignore-add ${pkg}`); $("#ignorePkg").value = ""; await renderIgnoreList(); toast("Added to keep-alive list"); }
  catch (e) { toast(e.message); }
};

// ---------------- games ----------------
async function renderGames(){
  try {
    const raw = await run("games-list");
    const pkgs = raw.split(/\r?\n/).map(x => x.trim()).filter(Boolean);
    $("#gameList").innerHTML = pkgs.length
      ? pkgs.map(pkg => `<div class="game-row"><div class="game-name"><b>${escapeHtml(pkg)}</b><small>installed package</small></div><button class="mini" data-boost="${escapeHtml(pkg)}">Boost</button><button class="mini" data-art="${escapeHtml(pkg)}">ART</button><button class="mini" data-remove="${escapeHtml(pkg)}"><i data-icon="close"></i></button></div>`).join("")
      : '<div class="hint">No packages tracked yet — tap Discover or add one manually.</div>';
    mountIcons($("#gameList"));
    $$("[data-boost]").forEach(b => b.onclick = () => {
      try { bridge?.optimizeApp?.(b.dataset.boost); toast("Boost requested via AxManager"); }
      catch { toast("AxManager optimizeApp unavailable"); }
    });
    $$("[data-art]").forEach(b => b.onclick = async () => {
      try { await run(`game-compile ${b.dataset.art} speed-profile`); toast("ART compilation requested"); }
      catch (e) { toast(e.message); }
    });
    $$("[data-remove]").forEach(b => b.onclick = async () => {
      try { await run(`game-remove ${b.dataset.remove}`); await renderGames(); toast("Removed from list"); }
      catch (e) { toast(e.message); }
    });
  } catch (e) { toast(e.message); }
}
$("#discoverBtn").onclick = async () => {
  try { await run("games-discover"); await renderGames(); toast("Game list refreshed"); }
  catch (e) { toast(e.message); }
};
$("#addGame").onclick = async () => {
  const pkg = $("#gamePkg").value.trim();
  if (!/^[A-Za-z0-9_][A-Za-z0-9_.]*$/.test(pkg)) { toast("Invalid package name"); return; }
  try { await run(`game-add ${pkg}`); $("#gamePkg").value = ""; await renderGames(); toast("Game added"); }
  catch (e) { toast(e.message); }
};
$("#gameProfileBtn").onclick = async () => {
  try { await run("profile performance"); await run("network on"); toast("Gaming profile applied"); await refresh(); }
  catch (e) { toast(e.message); }
};

// ---------------- game auto-detection ----------------
async function pollGameStatus(){
  try {
    const s = JSON.parse(await run("game-status"));
    $("#foregroundPkg").textContent = s.foreground || "No foreground app detected";
    const badge = $("#gameActiveBadge");
    badge.textContent = s.gameModeActive ? "ACTIVE" : (s.inGameList ? "DETECTED" : "IDLE");
    badge.classList.toggle("active", !!s.gameModeActive);
    toggleButton("#autoGameToggle", s.autoGameMode === 1 || s.autoGameMode === "1");
    return s;
  } catch (e) { /* stay quiet on background poll errors */ }
}

// ---------------- reset ----------------
$("#resetBtn").onclick = async () => {
  try { await run("reset"); toast("Xyvonix Core reset to defaults"); await refresh(); }
  catch (e) { toast(e.message); }
};

// ---------------- status / telemetry ----------------
const latencyHistory = [];
function drawLatencyGraph(){
  const canvas = $("#latencyGraph");
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.clientWidth * 2;
  const h = canvas.height = canvas.clientHeight * 2;
  ctx.clearRect(0, 0, w, h);
  if (latencyHistory.length < 2) return;
  const max = Math.max(...latencyHistory, 10);
  ctx.beginPath();
  ctx.lineWidth = 4;
  ctx.strokeStyle = "#6ef4a0";
  latencyHistory.forEach((v, i) => {
    const x = (i / (latencyHistory.length - 1)) * w;
    const y = h - (v / max) * (h * 0.82) - 6;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  });
  ctx.stroke();
}
async function measureLivePing(){
  const t0 = performance.now();
  try {
    await fetch("https://cloudflare.com/cdn-cgi/trace", { cache: "no-store", mode: "no-cors" });
    const ms = Math.round(performance.now() - t0);
    $("#latencyText").textContent = `${ms} ms`;
    latencyHistory.push(ms);
    if (latencyHistory.length > 24) latencyHistory.shift();
    drawLatencyGraph();
  } catch { /* offline: leave last known value on screen */ }
}

async function refresh(){
  try {
    const s = JSON.parse(await run("status"));
    $("#mProfile").textContent = s.profile || "—";
    $("#mDevice").textContent = s.model || "—";
    $("#mRam").textContent = s.ramMB ? `${(s.ramMB / 1024).toFixed(1)} GB` : "—";
    $("#mHz").textContent = s.refreshHz ? `${s.refreshHz} Hz` : "—";

    $$(".profile-card").forEach(c => c.classList.toggle("active", c.dataset.profile === s.profile));
    restoreDnsUI(s.dnsMode, s.dnsHost);

    toggleButton("#networkToggle", s.network === 1 || s.network === "1");
    toggleButton("#wifiLatencyToggle", s.wifiLatency === 1 || s.wifiLatency === "1");
    toggleButton("#renderToggle", s.render === 1 || s.render === "1");
    toggleButton("#blurToggle", s.blur === 1 || s.blur === "1");
    toggleButton("#refreshToggle", !!(s.highRefresh && s.highRefresh !== "0"));
    toggleButton("#autoGameToggle", s.autoGame === 1 || s.autoGame === "1");

    $("#dModel").textContent = [s.brand, s.model].filter(Boolean).join(" ") || "—";
    $("#dAndroid").textContent = s.android ? `Android ${s.android} (API ${s.sdk})` : "—";
    $("#dHyper").textContent = s.hyperos || "—";
    $("#dSoc").textContent = s.soc || "—";
    $("#dRam").textContent = s.ramMB ? `${(s.ramMB / 1024).toFixed(1)} GB` : "—";
    $("#dBattery").textContent = s.battery ? `${s.battery}%${s.batteryTemp ? " • " + s.batteryTemp + "\u00b0C" : ""}` : "—";
    $("#dKernel").textContent = s.kernel || "—";
    $("#dGov").textContent = s.cpuGovernor || "—";
    $("#dThermal").textContent = s.thermal || "Nominal";
    $("#dStorage").textContent = s.freeStorage || "—";
    $("#compatBadge").textContent = s.model ? "DETECTED" : "LIMITED";
    $("#compatBadge").classList.toggle("active", !!s.model);
  } catch (e) {
    toast(e.message);
  }
}

// ---------------- speed test ----------------
$("#speedBtn").onclick = async () => {
  const state = $("#testState"), ring = $("#speedRing"), val = $("#speedValue");
  state.textContent = "TESTING";
  const t0 = performance.now();
  try {
    const res = await fetch("https://speed.cloudflare.com/__down?bytes=5000000", { cache: "no-store" });
    const buf = await res.arrayBuffer();
    const seconds = (performance.now() - t0) / 1000;
    const mbps = (buf.byteLength * 8 / 1e6) / seconds;
    val.textContent = mbps.toFixed(1);
    ring.style.setProperty("--deg", `${Math.min(mbps / 150, 1) * 360}deg`);
    $("#testDownload").textContent = mbps.toFixed(1);
    $("#testLatency").textContent = Math.round(seconds * 200);
    $("#testDns").textContent = $("#dnsCurrent").textContent;
    state.textContent = "DONE";
  } catch {
    state.textContent = "FAILED";
    toast("Network test failed — check your connection");
  }
};

// ---------------- boot ----------------
mountIcons();
if (detectBridge()) {
  refresh();
  renderGames();
  renderIgnoreList();
  pollGameStatus();
  setInterval(pollGameStatus, 5000);
} else {
  toast("Waiting for AxManager bridge…");
}
setInterval(measureLivePing, 3000);
measureLivePing();
