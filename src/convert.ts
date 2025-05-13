import type { BrilInstruction, Type } from "./types.d.ts";
import { assertUnreachable, freshName } from "./utils.ts";

export function convertBlock(block: BrilInstruction[], context: Map<string, Type>, nestedLoops: string[]): string {
  return block.map(i => convertSingleInstruction(i, context, nestedLoops)).reduce((a, x) => a + x);
}

function getLoopSuffix(index: number, nestedLoops: string[]) {
  if (index >= nestedLoops.length) {
    throw new Error("Invalid loop index " + index + " for loop array " + JSON.stringify(nestedLoops));
  }
  return nestedLoops[nestedLoops.length - 1 - index];
}

export function convertSingleInstruction(instr: BrilInstruction, context: Map<string, Type>, nestedLoops: string[]): string {
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
    case "add": // fall through since they all do the same thing
    case "mul":
    case "sub":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.${instr.op}\nlocal.set $${instr.dest}\n`;
    case "eq":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.${instr.op}\nlocal.set $${instr.dest}\n`;
    case "le":
    case "ge":
    case "lt":
    case "gt":
    case "div":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni64.${instr.op}_s\nlocal.set $${instr.dest}\n`;
    case "call": {
      let ret = "";
      if (instr.args != null) { // push args onto stack
        ret += instr.args.map((arg) => `local.get $${arg}\n`).reduce((acc, it) => acc + it)
      }
      if (instr.dest != null) {
        return ret + `call $${instr.funcs[0]!}\n local.set $${instr.dest}\n`
      }
      else return ret + `call $${instr.funcs[0]!}\n`
    }
    case "not": //not a = a xor 1
      return `i32.const 1\n local.get $${instr.args![0]}\n i32.xor\nlocal.set $${instr.dest}\n`
    case "and": //also fallthrough with or
    case "or":
      return `local.get $${instr.args[0]}\nlocal.get $${instr.args[1]}\ni32.${instr.op}\nlocal.set $${instr.dest}\n`;
    case "id":
      return `local.get $${instr.args[0]}\nlocal.set $${instr.dest}\n`;
    case "ret":
      if (instr.args != null) { //load return value to top of stack
        return `local.get $${instr.args[0]} \n return`
      }
      else return "return\n"


    case "block": {
      const blockName = freshName("block");
      return `(block $${blockName}
        ${convertBlock(instr.children[0], context, nestedLoops)}
      )\n`;
    }
    case "if":
      return `local.get $${instr.args[0]}\n (if
       (then \n ${convertBlock(instr.children[0], context, nestedLoops)} \n) 
       (else \n ${convertBlock(instr.children[1], context, nestedLoops)} \n) \n)\n`;
    case "while": {
      const suffix = freshName("loop");
      nestedLoops.push(suffix);
      const o = `(block $b_${suffix}
        (loop $l_${suffix}
          ${convertBlock(instr.children[0], context, nestedLoops)}
          local.get $${instr.args[0]}
          br_if $l_${suffix}
        )
      )\n`;
      nestedLoops.pop();
      return o;
    }
    case "continue":
      return `br $l_${getLoopSuffix(instr.value, nestedLoops)}\n`;
    case "break":
      return `br $b_${getLoopSuffix(instr.value, nestedLoops)}\n`;

    default:
      assertUnreachable(instr);
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