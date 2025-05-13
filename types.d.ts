export type Type = "int" | "bool";

export type ArithmeticInstruction = {
  op: "add" | "mul" | "sub" | "div";
  dest: string;
  type: "int";
  args: [string, string];
};

export type ComparisonInstruction = {
  op: "eq" | "lt" | "gt" | "le" | "get";
  dest: string;
  type: "bool";
  args: [string, string];
};

export type UnaryLogicInstruction = {
  op: "not";
  dest: string;
  type: "bool";
  args: [string];
};

export type BinaryLogicInstruction = {
  op: "and" | "or";
  dest: string;
  type: "bool";
  args: [string, string];
};

export type ControlInstruction = ({
  op: "call";
  funcs: [string];
} & ({} | {
  dest: string;
  type: Type;
})) | {
  op: "ret";
  args?: [] | [string];
} | {
  op: "block"
  // TODO
} | {
  op: "while"
  // TODO
} | {
  op: "if"
  // TODO
};

export type MiscInstructions = {
  op: "id";
  args: [string];
  type: Type;
  dest: string;
} | {
  op: "print";
  args: string[];
} | {
  op: "nop";
} | ({
  op: "const";
  dest: string;
} & ({
  type: "int";
  value: number;
} | {
  type: "bool";
  value: boolean;
}))

export type BrilInstruction =
  | ArithmeticInstruction
  | ComparisonInstruction
  | UnaryLogicInstruction
  | BinaryLogicInstruction
  | ControlInstruction
  | MiscInstructions
;

export type BrilFunction = {
  name: string;
  args?: {name: string; type: Type}[];
  type?: Type;
  instrs: BrilInstruction[];
};

export type BrilProgram = {
  functions: BrilFunction[]
};
