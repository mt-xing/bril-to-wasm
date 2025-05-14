import { getAllFilesInFolder, parseArgs } from "./run_all_utils.ts";
import { pipeStringIntoCmdAndGetOutput } from "./src/io.ts";

async function processFile(fileName: string) {
  const programArgs = ["benches_briloop_wat/" + fileName].concat(await parseArgs(fileName, true));
  const r = await pipeStringIntoCmdAndGetOutput("wasmtime", "", programArgs);
  console.log(r.stdout);
}

const files = await getAllFilesInFolder("./benches_briloop_wat");
for (const file of files) {
  await processFile(file.name);
}