// takes in BrilInstructions array and returns set of strings of locally used variables, call recursively on children

import type { BrilFunction, BrilInstruction, Type } from "./types.d.ts";

export function getLocals(func: BrilFunction) {
  const localvars = new Map<string, Type>();
  const params = new Set<string>();
  if (func.args != null) {
    for (const arg of func.args) {
      params.add(arg.name)
    }
  }
  return getLocalCall(func.instrs, localvars, params)
}


function getLocalCall(brilInstructions: BrilInstruction[], localvars: Map<string, Type>, params: Set<string>): Map<string, Type> {

  for (let i = 0; i < brilInstructions.length; i++) {
    const instr = brilInstructions[i];

    if ("dest" in instr) {
      const desty = instr.dest;
      const typy = instr.type;
      if (!params.has(desty)) {
        localvars.set(desty, typy);
      }
    }

    if ("children" in instr) {
      const kids = instr.children;
      for (let k = 0; k < kids.length; k++) {
        getLocalCall(kids[k], localvars, params)
      }
    }

  }

  return localvars

}