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

export async function parseArgs(fileName: string) {
  const baseName = fileName.split(".")[0];
  const fileText = await Deno.readTextFile("./benches/" + baseName + ".bril");
  const argsParse = /^# ?ARGS: (.+)$/gm.exec(fileText);
  return (argsParse ? (argsParse[1].trim()).split(" ") : []);
}
