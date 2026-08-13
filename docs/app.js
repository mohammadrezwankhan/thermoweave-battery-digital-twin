const state = { data: null, scenario: 0, frame: 0, playing: false, reduced: false, raf: 0, lastTick: 0 };
const $ = (selector) => document.querySelector(selector);
const palettes = [[0, 86, 136], [88, 216, 255], [183, 255, 88], [255, 179, 67], [255, 92, 76]];

function mix(a, b, t) { return a.map((value, index) => Math.round(value + (b[index] - value) * t)); }
function heatColor(value, minimum, maximum) {
  const normalized = maximum === minimum ? .5 : Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum)));
  const scaled = normalized * (palettes.length - 1);
  const base = Math.min(palettes.length - 2, Math.floor(scaled));
  const color = mix(palettes[base], palettes[base + 1], scaled - base);
  return `rgb(${color.join(',')})`;
}

function currentScenario() { return state.data.scenarios[state.scenario]; }
function frameTemperatures(scenario = currentScenario(), frame = state.frame) { return scenario.temperature_C[frame] || scenario.temperature_C[0]; }

function drawCells(canvas, scenario, frame, hero = false) {
  const context = canvas.getContext('2d');
  const width = canvas.width;
  const height = canvas.height;
  context.clearRect(0, 0, width, height);
  const values = frameTemperatures(scenario, frame);
  const all = scenario.temperature_C.flat();
  const minimum = Math.min(...all);
  const maximum = Math.max(...all);
  const columns = 4;
  const rows = 3;
  const gapX = width / (columns + 1);
  const gapY = height / (rows + 1);
  const radius = Math.min(gapX, gapY) * (hero ? .26 : .29);
  const offset = hero ? 22 : 0;

  context.strokeStyle = 'rgba(88,216,255,.2)';
  context.lineWidth = 2;
  context.setLineDash([7, 10]);
  context.beginPath();
  context.moveTo(gapX * .65, gapY * .65 + offset);
  for (let column = 0; column < columns; column += 1) {
    const y = (column % 2 === 0 ? gapY * 3.35 : gapY * .65) + offset;
    context.lineTo(gapX * (column + 1), y);
  }
  context.stroke();
  context.setLineDash([]);

  values.forEach((value, index) => {
    const row = index % rows;
    const column = Math.floor(index / rows);
    const x = gapX * (column + 1);
    const y = gapY * (row + 1) + offset;
    const color = heatColor(value, minimum, maximum);
    const glow = context.createRadialGradient(x, y, radius * .25, x, y, radius * 1.6);
    glow.addColorStop(0, color.replace('rgb', 'rgba').replace(')', ',.26)'));
    glow.addColorStop(1, 'rgba(7,16,25,0)');
    context.fillStyle = glow;
    context.beginPath(); context.arc(x, y, radius * 1.6, 0, Math.PI * 2); context.fill();
    context.fillStyle = color;
    context.strokeStyle = 'rgba(237,246,247,.72)';
    context.lineWidth = 2;
    context.beginPath(); context.arc(x, y, radius, 0, Math.PI * 2); context.fill(); context.stroke();
    context.fillStyle = 'rgba(7,16,25,.75)';
    context.beginPath(); context.arc(x, y, radius * .36, 0, Math.PI * 2); context.fill();
    if (!hero) {
      context.fillStyle = '#edf6f7';
      context.font = '600 15px system-ui';
      context.textAlign = 'center';
      context.fillText(`${value.toFixed(2)}\u00B0`, x, y + radius + 24);
    }
  });

  const progress = frame / Math.max(1, scenario.time_s.length - 1);
  context.fillStyle = '#58d8ff';
  context.beginPath();
  context.arc(gapX * (.65 + progress * 3.7), gapY * (.65 + (progress % .5) * 5.4) + offset, 5, 0, Math.PI * 2);
  context.fill();
}

function updateMetrics() {
  const scenario = currentScenario();
  $('#metric-peak').textContent = `${(scenario.metrics.peakTemperature_K - 273.15).toFixed(2)} °C`;
  $('#metric-spread').textContent = `${scenario.metrics.peakEdgeGradient_K.toFixed(3)} K`;
  $('#metric-cooling').textContent = `${scenario.metrics.coolingEnergy_J.toFixed(1)} J`;
  $('#metric-residual').textContent = Number(scenario.metrics.energyResidualNormalized).toExponential(1);
  $('#mode-pill').textContent = scenario.boundaryMode;
  $('#scenario-description').textContent = scenario.description;
  $('#scenario-hash').textContent = scenario.scenarioHash.slice(0, 16);
  $('#time-label').textContent = `${scenario.time_s[state.frame].toFixed(0)} s`;
  updateFrameTable(scenario);
}

function updateFrameTable(scenario) {
  const body = $('#frame-data-body');
  const values = frameTemperatures(scenario, state.frame);
  body.innerHTML = '';
  values.forEach((value, index) => {
    const row = document.createElement('tr');
    const cellRow = (index % 3) + 1;
    const cellColumn = Math.floor(index / 3) + 1;
    [index + 1, cellRow, cellColumn, `${value.toFixed(2)} \u00B0C`].forEach((entry, column) => {
      const element = document.createElement(column === 0 ? 'th' : 'td');
      if (column === 0) element.scope = 'row';
      element.textContent = entry;
      row.append(element);
    });
    body.append(row);
  });
}

function render() {
  const scenario = currentScenario();
  drawCells($('#hero-canvas'), scenario, state.frame, true);
  drawCells($('#lab-canvas'), scenario, state.frame, false);
  $('#time-slider').value = state.frame;
  updateMetrics();
}

function populateModes() {
  const preferred = ['scalar', 'vector', 'zonal', 'coolant'];
  const labels = { scalar: 'one shared interface', vector: 'per-cell prescribed field', zonal: 'grouped actuators', coolant: 'flow-coupled propagation' };
  const grid = $('#mode-grid');
  grid.innerHTML = '';
  preferred.forEach((mode) => {
    const scenario = state.data.scenarios.find((item) => item.boundaryMode === mode);
    const article = document.createElement('article');
    article.className = 'mode-card';
    const temperatures = scenario ? scenario.temperature_C.at(-1) : Array(12).fill(0);
    const min = Math.min(...temperatures);
    const max = Math.max(...temperatures);
    const bars = temperatures.slice(0, 12).map((value) => `<i style="--level:${max === min ? .55 : (value - min) / (max - min)}"></i>`).join('');
    article.innerHTML = `<div class="mode-icon" aria-hidden="true">${bars}</div><h3>${mode}</h3><p>${labels[mode]}</p><strong>${scenario ? `${scenario.metrics.peakEdgeGradient_K.toFixed(3)} K peak edge spread` : 'adapter available'}</strong>`;
    grid.append(article);
  });
}

function tick(timestamp) {
  if (!state.playing) return;
  if (timestamp - state.lastTick > 120) {
    const scenario = currentScenario();
    state.frame = (state.frame + 1) % scenario.time_s.length;
    state.lastTick = timestamp;
    render();
    if (state.reduced) stop();
  }
  state.raf = requestAnimationFrame(tick);
}

function play() {
  state.playing = true;
  $('#play-button').textContent = 'Pause';
  state.raf = requestAnimationFrame(tick);
}
function stop() {
  state.playing = false;
  $('#play-button').textContent = 'Play';
  cancelAnimationFrame(state.raf);
}

function selectScenario(index) {
  stop();
  state.scenario = index;
  state.frame = 0;
  const scenario = currentScenario();
  $('#time-slider').max = scenario.time_s.length - 1;
  render();
}

function validatePayload(payload) {
  if (!payload || payload.schemaVersion !== 'thermoweave.web/v1' || !Array.isArray(payload.scenarios)) {
    throw new Error('Result data does not satisfy thermoweave.web/v1');
  }
  payload.scenarios.forEach((scenario) => {
    const frames = scenario.time_s?.length;
    const validHash = typeof scenario.scenarioHash === 'string' && /^[0-9a-f]{64}$/i.test(scenario.scenarioHash);
    const validFrames = Number.isInteger(frames) && frames > 0 && scenario.temperature_C?.length === frames;
    const validCells = validFrames && scenario.temperature_C.every((frame) => Array.isArray(frame) && frame.length === 12 && frame.every(Number.isFinite));
    if (scenario.sourceSchema !== 'thermoweave.result/v1' || !validHash || !validCells) {
      throw new Error(`Scenario '${scenario.id || 'unknown'}' failed schema, hash, or shape validation`);
    }
  });
  return payload;
}

async function init() {
  const response = await fetch('assets/thermoweave-demo.json');
  if (!response.ok) throw new Error(`Result data unavailable (${response.status})`);
  state.data = validatePayload(await response.json());
  const select = $('#scenario-select');
  state.data.scenarios.forEach((scenario, index) => {
    const option = document.createElement('option');
    option.value = index;
    option.textContent = `${scenario.id} \u00B7 ${scenario.boundaryMode}`;
    select.append(option);
  });
  state.reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  $('#motion-toggle').checked = state.reduced;
  populateModes();
  selectScenario(0);

  select.addEventListener('change', (event) => selectScenario(Number(event.target.value)));
  $('#play-button').addEventListener('click', () => state.playing ? stop() : play());
  $('#step-button').addEventListener('click', () => { stop(); state.frame = (state.frame + 1) % currentScenario().time_s.length; render(); });
  $('#time-slider').addEventListener('input', (event) => { stop(); state.frame = Number(event.target.value); render(); });
  $('#motion-toggle').addEventListener('change', (event) => { state.reduced = event.target.checked; if (state.reduced) stop(); });
}

init().catch((error) => {
  $('#scenario-description').textContent = `${error.message}. Run generateArtifacts in MATLAB to regenerate the traceable site data.`;
});
