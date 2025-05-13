import { BrilInstruction, Type } from "./types.d.ts";
import { assertUnreachable } from "./utils.ts";

export function convertSingleInstruction(instr: BrilInstruction, context: Map<string, Type>): string {
  switch (instr.op) {
    case "nop":
      return "nop\n";
    case "const":
      if (instr.type === "int") {
        return "i64.const " + instr.value + `\nlocal.set $${instr.dest}\n`;
      } else if (instr.type === "bool") {
        return "i32.const " + (instr.value ? "1" : "0") + `\nlocal.set $${instr.dest}\n`;
      }
      throw new Error();
    case "print":
      return instr.args.map((a) => translatePrint(a, context)).reduce((a, x) => a + x);
    case "add":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.add\nlocal.set $${instr.dest}\n`;
    default:
      return '';
  }
}

function translatePrint(arg: string, context: Map<string, Type>): string {
  const t = context.get(arg);
  if (t === undefined) {
    throw new Error("Attempted to print undefined variable " + arg);
  }
  switch (t) {
    case "int":
      return `local.get $${arg}\ncall $int_to_string_and_print\ncall $print_newline\n`;
    case "bool":
      return `local.get $${arg}\ncall $bool_to_string_and_print\ncall $print_newline\n`;
    default:
      assertUnreachable(t);
  }
}