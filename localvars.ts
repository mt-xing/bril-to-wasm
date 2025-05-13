//takes in BrilInstructions array and returns set of strings of locally used variables, call recursively on children

import { BrilInstruction } from "./types";


export function getLocals(brilInstructions : BrilInstruction[]){
  let localvars = new Set<string>;
  getLocalCall(brilInstructions, localvars)
}


function getLocalCall(brilInstructions : BrilInstruction[], localvars: Set<string>) : Set<string>{

  for (let i=0; i < brilInstructions.length; i++) {
    let instr = brilInstructions[i];

    if ("dest" in instr) {
      localvars.add(instr.dest);
    }
    if ("args" in instr) {
      if (instr.args != undefined) {
        let args = instr.args;
        for (let j = 0; j < args.length; j++) {
          localvars.add(instr.args[j]);
        }
      }
    }
    
    if ("children" in instr) {
      let kids = instr.children;
      for (let k = 0; k < kids.length; k++){
        getLocalCall(kids[k], localvars)
      }
    }

  }

  return localvars

}