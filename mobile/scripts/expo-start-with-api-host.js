const { spawn, spawnSync } = require('node:child_process');
const os = require('node:os');

const API_SUFFIX = '/api/v1';

function getLanIPv4() {
  const nets = os.networkInterfaces();
  const candidates = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] ?? []) {
      if (net.family === 'IPv4' && !net.internal) {
        candidates.push(net.address);
      }
    }
  }
  const score = (addr) => {
    if (addr.startsWith('169.254.')) return 0;
    if (addr.startsWith('192.168.')) return 3;
    if (addr.startsWith('10.')) return 2;
    return 1;
  };
  candidates.sort((a, b) => score(b) - score(a));
  return candidates[0] ?? null;
}

const mode = process.argv[2];
const passthrough = process.argv.slice(3);

let base;
if (mode === 'emulator') {
  const r = spawnSync('adb', ['reverse', 'tcp:3000', 'tcp:3000'], {
    stdio: 'ignore',
    shell: true,
  });
  if (r.error == null && r.status === 0) {
    console.log('[waytwo] adb reverse tcp:3000 tcp:3000 (Android emulator → host API)');
  } else {
    console.log(
      '[waytwo] Android emulator: if API calls fail, run `adb reverse tcp:3000 tcp:3000` or use http://10.0.2.2:3000/api/v1',
    );
  }
  base = `http://127.0.0.1:3000${API_SUFFIX}`;
} else if (mode === 'device') {
  const ip = getLanIPv4();
  if (!ip) {
    console.error(
      '[waytwo] No non-internal IPv4 found. Connect to Wi‑Fi or set EXPO_PUBLIC_API_URL in .env.',
    );
    process.exit(1);
  }
  base = `http://${ip}:3000${API_SUFFIX}`;
} else {
  console.error('Usage: node scripts/expo-start-with-api-host.js <emulator|device> [-- expo args]');
  process.exit(1);
}

const env = { ...process.env, EXPO_PUBLIC_API_URL: base };
console.log(`[waytwo] EXPO_PUBLIC_API_URL=${base}`);

const child = spawn('npx', ['expo', 'start', ...passthrough], {
  env,
  stdio: 'inherit',
  shell: true,
});
child.on('exit', (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 1);
});
