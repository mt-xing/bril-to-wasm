import { getProgramFromCmdLine } from "./io.ts";
import { translateProgram } from "./runtime.ts";

const program = await getProgramFromCmdLine();

// run the translation and send to output. idk why this is in its own file
const programTxt = translateProgram(program);
console.log(programTxt);