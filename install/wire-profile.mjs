#!/usr/bin/env node
// wire-profile.mjs - idempotently wire dsh-purge into a DSH profile without the plugin installer.
//
//   node wire-profile.mjs --profile desktop
//   node wire-profile.mjs --profile desktop --spec "file:<REPO_DIR>/dist/dsh-preset-kit-1.1.92.tgz"
//
// What it does (each step skipped when already satisfied):
//   1. package.json  dependencies["dsh-purge"] = <spec>
//   2. package.json  dsh.profile.bundles    += "dsh-purge"
//   3. cordis.patch.yml  ensure a top-level `- insert:` array element with id dsh-purge
//   4. optional: report whether allowBuilds has an entry for dsh-purge
//
// ASCII only on purpose: runs under cmd.exe / PowerShell without code page games.
import { readFileSync, writeFileSync, existsSync, copyFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const v = process.argv[i + 1];
  if (!v || v.startsWith("--")) return fallback;
  return v;
}

const PKG = "dsh-purge";
const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const defaultSpec = "file:" + join(repoRoot, "dist", "dsh-preset-kit-1.1.92.tgz");

const profile = arg("profile", "desktop");
const spec = arg("spec", defaultSpec);
const home = process.env.DSH_HOME || join(homedir(), ".dsh");
const dir = join(home, "profiles", profile);
const pkgFile = join(dir, "package.json");
const patchFile = join(dir, "cordis.patch.yml");

if (!existsSync(pkgFile)) {
  console.error(`[!] profile not found: ${pkgFile}`);
  process.exit(2);
}

const changes = [];
const json = JSON.parse(readFileSync(pkgFile, "utf8"));
json.dependencies ??= {};
if (json.dependencies[PKG] !== spec) {
  const before = json.dependencies[PKG];
  json.dependencies[PKG] = spec;
  changes.push(`package.json dependencies.${PKG}: ${before ?? "(absent)"} -> ${spec}`);
}
json.dsh ??= {};
json.dsh.profile ??= {};
json.dsh.profile.bundles ??= [];
if (!json.dsh.profile.bundles.includes(PKG)) {
  json.dsh.profile.bundles.push(PKG);
  changes.push(`package.json dsh.profile.bundles += ${PKG}`);
}
if (changes.length) writeFileSync(pkgFile, JSON.stringify(json, null, 2) + "\n");

// cordis.patch.yml: the real profile file is a top-level YAML ARRAY whose elements
// look like `- insert:` / `  - id: ...`. Appending a bare `insert:` key produces an
// invalid document (the whole profile fails to load), so append a full array element.
if (existsSync(patchFile)) {
  const yml = readFileSync(patchFile, "utf8");
  if (!/^\s*-\s*id:\s*dsh-purge\s*$/m.test(yml)) {
    copyFileSync(patchFile, patchFile + ".wire-bak");
    const block = [
      "- insert:",
      `    - id: ${PKG}`,
      `      name: ${PKG}`,
      "      inject: [ systemPrompt, tools ]",
      "      config:",
      "        enabled: true",
      "        stripMnemon: true",
      "        capabilityProtocol: true",
      "        hooksDenyBypass: true",
      "",
    ].join("\n");
    const next = yml.replace(/\s*$/, "\n") + block;
    writeFileSync(patchFile, next);
    changes.push("cordis.patch.yml: appended top-level `- insert:` element for dsh-purge (backup: .wire-bak)");
  }
} else {
  console.log(`[i] no cordis.patch.yml in ${dir} (web-less profile?); skipped`);
}

const hasBuildKey = existsSync(patchFile) && /allowBuilds:/.test(readFileSync(patchFile, "utf8"));
console.log(`[i] profile = ${dir}`);
console.log(`[i] allowBuilds map present in cordis.patch.yml = ${hasBuildKey}`);
if (!changes.length) console.log("[=] already wired, nothing to do");
else for (const c of changes) console.log("[+] " + c);
console.log("[ok] next: pnpm install (or `pnpm install --ignore-scripts`), then restart DSH desktop");
