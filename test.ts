import { convertSingleInstruction } from "./convert.ts";
import { getProgramFromCmdLine } from "./io.ts";
import { getLocals } from "./localvars.ts";
import { wrapWithRuntime, writeFunction } from "./runtime.ts";

const program = await getProgramFromCmdLine();

// Hard-code just a main function
const instrs = program.functions[0].instrs;
const context = getLocals(instrs);
const translated = instrs.map(i => convertSingleInstruction(i, context)).reduce((a, x) => a + x);
const programTxt = wrapWithRuntime(writeFunction(translated, context));
console.log(programTxt);