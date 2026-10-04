#!/usr/bin/env node
// Records the README demo in the real macOS Terminal.app, replaying the beats in
// scripts/demo.tape (everything after `Show`). VHS draws block characters itself,
// edge to edge, so the wordmark comes out as solid letters; Terminal draws them
// from the font and the gaps between cells give the tiled look. This keeps that.
//
//   pnpm demo:record:terminal
//
// Needs Screen Recording and Accessibility permission for the terminal running it.
// Do not touch the keyboard or mouse while it runs: before every keystroke it
// checks that the recording window is frontmost, and stops if it is not, so it
// never types into anything else.

import { execFileSync, spawn } from 'node:child_process';
import { existsSync, readFileSync, rmSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const stage = process.env.SIRUS_DEMO_STAGE ?? join(homedir(), 'sirus-demo');
const out = resolve(repo, process.argv[2] ?? 'media/sirus-demo.mp4');
const columns = Number(process.env.SIRUS_DEMO_COLUMNS ?? 96);
const rows = Number(process.env.SIRUS_DEMO_ROWS ?? 41);
const typingDelay = 0.045;

const osa = (script) => execFileSync('osascript', ['-e', script], { encoding: 'utf8' }).trim();
const sleep = (ms) => new Promise((done) => setTimeout(done, ms));
const quote = (text) => `"${text.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;

/** The beats after `Show`, as [verb, argument] pairs. */
function beats() {
  const lines = readFileSync(join(repo, 'scripts/demo.tape'), 'utf8').split('\n');
  const start = lines.findIndex((line) => line.trim() === 'Show');
  const steps = [];
  for (const raw of lines.slice(start + 1)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const [verb, ...rest] = line.split(' ');
    const arg = rest.join(' ');
    if (verb === 'Type') steps.push(['type', JSON.parse(arg)]);
    else if (verb === 'Sleep') steps.push(['sleep', arg.endsWith('ms') ? Number(arg.slice(0, -2)) : Number(arg.slice(0, -1)) * 1000]);
    else if (['Enter', 'Escape', 'Backspace', 'Ctrl+C'].includes(verb)) steps.push(['key', verb]);
    else throw new Error(`demo.tape: unsupported command after Show: ${line}`);
  }
  return steps;
}

const KEY = { Enter: 'key code 36', Escape: 'key code 53', Backspace: 'key code 51', 'Ctrl+C': 'keystroke "c" using control down' };

/** Fails, rather than typing, unless our window is the one in front. */
function guarded(window, body) {
  osa(`tell application "Terminal"
  activate
  set index of window id ${window} to 1
end tell
delay 0.05
tell application "System Events"
  set frontName to name of (first application process whose frontmost is true)
  if frontName is not "Terminal" then error "Terminal is not frontmost — stopped so nothing is typed elsewhere"
end tell
tell application "Terminal"
  if id of front window is not ${window} then error "the recording window is not in front — stopped"
end tell
tell application "System Events"
  ${body}
end tell`);
}

async function main() {
  if (!existsSync(join(stage, '.bin/sirus'))) execFileSync('bash', [join(repo, 'scripts/demo-stage.sh')], { stdio: 'inherit' });

  const setup = `export PATH=${stage}/.bin:$PATH && cd ${stage}/finsec-gui && clear`;
  const window = osa(`tell application "Terminal"
  set t to do script ${quote(setup)}
  set w to first window whose tabs contains t
  set number of columns of w to ${columns}
  set number of rows of w to ${rows}
  set position of w to {60, 40}
  activate
  set index of w to 1
  return id of w
end tell`);
  await sleep(1500);

  const [left, top, right, bottom] = osa(`tell application "Terminal" to get bounds of window id ${window}`).split(',').map((n) => Number(n.trim()));
  const raw = out.replace(/\.mp4$/, '.raw.mov');
  rmSync(raw, { force: true });
  const capture = spawn('screencapture', ['-v', '-x', `-R${left},${top},${right - left},${bottom - top}`, raw], { stdio: 'ignore' });
  await sleep(1500);

  try {
    for (const [verb, arg] of beats()) {
      if (verb === 'sleep') await sleep(arg);
      else if (verb === 'key') guarded(window, KEY[arg]);
      else guarded(window, `repeat with c in characters of ${quote(arg)}
    keystroke (contents of c)
    delay ${typingDelay}
  end repeat`);
    }
    await sleep(1500);
  } finally {
    capture.kill('SIGINT');
    await new Promise((done) => capture.on('exit', done));
  }

  // Screen capture only writes a frame when something changes; constant 30 fps
  // and faststart so the file plays and seeks normally in a browser.
  execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', raw, '-vf', 'fps=30', '-c:v', 'libx264', '-crf', '24', '-preset', 'slow',
    '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an', out], { stdio: 'inherit' });
  rmSync(raw, { force: true });
  console.log(`recorded ${out}`);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});
