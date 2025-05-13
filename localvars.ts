//takes in BrilInstructions array and returns set of strings of locally used variables, call recursively on children

import { BrilInstruction } from "./types";
import { Type } from "./types";

export function getLocals(brilInstructions: BrilInstruction[]): Map<string, Type> {
  let localvars = getLocalCall(brilInstructions, new Map<string, Type>())
  return localvars
}


function getLocalCall(brilInstructions: BrilInstruction[], localvars: Map<string, Type>): Map<string, Type> {

  for (let i = 0; i < brilInstructions.length; i++) {
    let instr = brilInstructions[i];

    if ("dest" in instr) {
      let desty = instr.dest;
      let typy = instr.type;
      localvars.set(desty, typy);
    }

    if ("children" in instr) {
      let kids = instr.children;
      for (let k = 0; k < kids.length; k++) {
        getLocalCall(kids[k], localvars)
      }
    }

  }

  return localvars

}