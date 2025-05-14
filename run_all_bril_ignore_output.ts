import { walk, WalkEntry } from "jsr:@std/fs/walk";
import { pipeStringIntoCmdAndGetOutput } from "./src/io.ts";

export async function getAllFilesInFolder(folder: string) {
  const files: WalkEntry[] = [];
  for await (const file of walk(folder)) {
    if (file.isFile) {
      files.push(file);
    }
  }
  return files;
}

export async function parseArgs(fileName: string) {
  const baseName = fileName.split(".")[0];
  const fileText = await Deno.readTextFile("./benches/" + baseName + ".bril");
  const argsParse = /^# ?ARGS: (.+)$/gm.exec(fileText);
  return (argsParse ? (argsParse[1].trim()).split(" ") : []);
}

async function processFile(filePath: string, fileName: string) {
  const fileText = await Deno.readTextFile(filePath);
  const programArgs = ['-p'].concat(await parseArgs(fileName));
  await pipeStringIntoCmdAndGetOutput("brili", fileText, programArgs);
}

const files = await getAllFilesInFolder("./benches_json");
for (const file of files) {
  await processFile(file.path, file.name);
}