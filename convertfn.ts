import { BrilFunction } from "./types";
import { getLocals } from "./localvars";

/**
 * WASM Syntax: ( func <signature> <locals> <body> )
 * @param func the Bril function to be converted
 */
export function convertFunction(func: BrilFunction): string {
  let output: string = "(func "

  if (func.args != null) {
    func.args.forEach((arg) => {
      switch (arg.type) {
        case "int":
          output = output + `(param $${arg.name} i64) `
          break
        case "bool":
          output = output + `(param $${arg.name} i32) `
          break
      }
    })
  }

  if (func.type != null) {
    switch (func.type) {
      case "int":
        output = output + "(return i64) "
        break
      case "bool":
        output = output + "(return i32) "
        break
    }

  }
  let locals = getLocals(func.instrs)
  locals.forEach((name, t) => {
    switch (t) {
      case "int":
        output = output + `(locals $${name} i64) `
        break
      case "bool":
        output = output + `(locals $${name} i32) `
        break
    }
  })

  func.instrs.forEach((instr) => {
    // convert instruction and append to string
  })

  return output
}
