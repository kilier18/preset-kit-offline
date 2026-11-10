// make-test-asar.mjs — 造一个最小 asar（含子目录、二进制、unpacked 条目）用于验证安装器的解包逻辑
import fs from "node:fs";
import path from "node:path";

const out = process.argv[2] || "D:/DSH/workspace/default-workspace/pkg-build/repo/test/fake/dsh-root/resources/app.asar";
const outDir = path.dirname(out);
fs.mkdirSync(outDir, { recursive: true });

const files = {
  "package.json": { data: Buffer.from('{"name":"fake-dsh-desktop","main":"lib/main.js"}', "utf8") },
  "a.txt": { data: Buffer.from("hello", "utf8") },
  "sub/b.js": { data: Buffer.from("console.log(1)\n", "utf8") },
  "native.node": { data: Buffer.from("NATIVEBIN", "utf8"), unpacked: true },
  "empty.bin": { data: Buffer.alloc(0) },
};

// 按写入顺序拼数据区
let offset = 0;
const tree = { files: {} };
const blobs = [];
for (const [rel, f] of Object.entries(files)) {
  const parts = rel.split("/");
  let node = tree.files;
  for (let i = 0; i < parts.length - 1; i++) {
    if (!node[parts[i]]) node[parts[i]] = { files: {} };
    node = node[parts[i]].files;
  }
  const name = parts[parts.length - 1];
  if (f.unpacked) {
    node[name] = { size: f.data.length, offset: String(offset), unpacked: true };
    // unpacked 条目在 asar 里通常 size=0、offset 无效，这里仍写数据以便校验越界逻辑
    blobs.push(f.data);
    offset += f.data.length;
  } else {
    node[name] = { size: f.data.length, offset: String(offset) };
    blobs.push(f.data);
    offset += f.data.length;
  }
}

const jsonBuf = Buffer.from(JSON.stringify(tree), "utf8");
const jsonLen = jsonBuf.length;
const head = Buffer.alloc(16);
head.writeUInt32LE(4, 0);
head.writeUInt32LE(8 + jsonLen, 4);
head.writeUInt32LE(4 + jsonLen, 8);
head.writeUInt32LE(jsonLen, 12);

const body = Buffer.concat([head, jsonBuf, ...blobs]);
fs.writeFileSync(out, body);

// unpacked 副本
const unpackedRel = "native.node";
const upPath = path.join(out + ".unpacked", unpackedRel);
fs.mkdirSync(path.dirname(upPath), { recursive: true });
fs.writeFileSync(upPath, files[unpackedRel].data);

console.log(`asar: ${out} (${body.length} B, jsonLen=${jsonLen}, dataBase=${16 + jsonLen})`);
console.log(`unpacked: ${upPath}`);
