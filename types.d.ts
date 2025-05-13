export type Type = string | {[key: string]: Type};
export type BrilInstruction = {
  op: string;
  dest?: string;
  type?: Type;
  args?: string[];
  funcs?: string[];
  labels?: string[];
  value?: number | boolean;
} | { label: string };
export type BrilFunction = {
  name: string;
  args?: {name: string; type: Type}[];
  type?: Type;
  instrs: BrilInstruction[];
};
export type BrilProgram = {
  functions: BrilFunction[]
};
