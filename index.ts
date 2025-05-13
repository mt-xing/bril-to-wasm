import { getProgramFromCmdLine } from "./src/io.ts";
import { translateProgram } from "./src/runtime.ts";

const program = await getProgramFromCmdLine();

// run the translation and send to output. idk why this is in its own file
const programTxt = translateProgram(program);
console.log(programTxt);