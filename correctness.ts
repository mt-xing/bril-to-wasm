import { getAllFilesInFolder, parseArgs } from "./run_all_utils.ts";
import { pipeStringIntoCmdAndGetOutput } from "./src/io.ts";

async function processFileWasm(fileName: string) {
  const programArgs = ["benches_briloop_wat/" + fileName].concat(await parseArgs(fileName));
  const r = await pipeStringIntoCmdAndGetOutput("wasmtime", "", programArgs);
  return r.stdout;
}

async function processFileBril(filePath: string, fileName: string) {
  const fileText = await Deno.readTextFile(filePath);
  const programArgs = ['-p'].concat(await parseArgs(fileName));
  const r = await pipeStringIntoCmdAndGetOutput("brili", fileText, programArgs);
  return r.stdout;
}

async function processFile(brilFilePath: string, brilFileName: string) {
  console.log("Testing output of file", brilFileName);

  const a = await processFileBril(brilFilePath, brilFileName);

  const baseName = brilFileName.split(".")[0];

  const b = await processFileWasm(baseName + ".wat");

  if (a.replaceAll(/\s/gm, '') !== b.replaceAll(/\s/gm, '')) {
    console.error("FILE WAS DIFFERENT");
    console.error("========================================");
    console.error(a);
    console.error("========================================");
    console.error(b);
    console.error("========================================");
  }
}

const files = await getAllFilesInFolder("./benches_json");
for (const file of files) {
  await processFile(file.path, file.name);
}