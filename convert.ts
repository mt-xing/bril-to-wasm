import type { BrilInstruction, Type } from "./types.d.ts";
import { assertUnreachable } from "./utils.ts";

export function convertSingleInstruction(instr: BrilInstruction, context: Map<string, Type>): string {
  // TODO add types
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
    case "mul":
    case "sub":
    case "eq":
    case "le":
    case "ge":
    case "lt":
    case "gt":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.${instr.op}\nlocal.set $${instr.dest}\n`;
    case "div":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.div_s\nlocal.set $${instr.dest}\n`;
    case "call":
      if (instr.dest != null) {
        return `call $${instr.funcs[0]!}\n local.set $${instr.dest}\n`
      }
      else return `call $${instr.funcs[0]!}\n`
    case "not": //not a = a xor 1
      return `i32.const 1\n local.set $${instr.args![0]}\n i32.xor\nlocal.set $${instr.dest}\n`
    case "and":
    case "or":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni32.${instr.op}\nlocal.set $${instr.dest}\n`;


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