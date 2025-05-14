import { getAllFilesInFolder, parseArgs } from "./run_all_utils.ts";
import { pipeStringIntoCmdAndGetOutput } from "./src/io.ts";

async function processFile(filePath: string, fileName: string) {
  const fileText = await Deno.readTextFile(filePath);
  const programArgs = ['-p'].concat(await parseArgs(fileName));
  const r = await pipeStringIntoCmdAndGetOutput("brili", fileText, programArgs);
  console.log(r.stdout);
}

const files = await getAllFilesInFolder("./benches_json");
for (const file of files) {
  await processFile(file.path, file.name);
}