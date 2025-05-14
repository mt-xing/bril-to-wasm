import { walk, WalkEntry } from "jsr:@std/fs/walk";

export async function getAllFilesInFolder(folder: string) {
  const files: WalkEntry[] = [];
  for await (const file of walk(folder)) {
    if (file.isFile) {
      files.push(file);
    }
  }
  return files;
}

function convertBoolStrings(x: string) {
  if (x === "true") {
    return "1";
  } else if (x === "false") {
    return "0";
  }
  return x;
}

export async function parseArgs(fileName: string, convertBool: boolean) {
  const baseName = fileName.split(".")[0];
  const fileText = await Deno.readTextFile("./benches/" + baseName + ".bril");
  const argsParse = /^# ?ARGS: (.+)$/gm.exec(fileText);
  const x = (argsParse ? (argsParse[1].trim()).split(" ") : []);
  return convertBool ? x.map(convertBoolStrings) : x;
}
