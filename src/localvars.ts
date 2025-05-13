//takes in BrilInstructions array and returns set of strings of locally used variables, call recursively on children

import type { BrilInstruction, Type } from "./types.d.ts";

export function getLocals(brilInstructions: BrilInstruction[]) {
  const localvars = new Map<string, Type>();
  return getLocalCall(brilInstructions, localvars)
}


function getLocalCall(brilInstructions: BrilInstruction[], localvars: Map<string, Type>): Map<string, Type> {

  for (let i = 0; i < brilInstructions.length; i++) {
    const instr = brilInstructions[i];

    if ("dest" in instr) {
      const desty = instr.dest;
      const typy = instr.type;
      localvars.set(desty, typy);
    }

    if ("children" in instr) {
      const kids = instr.children;
      for (let k = 0; k < kids.length; k++) {
        getLocalCall(kids[k], localvars)
      }
    }

  }

  return localvars

}