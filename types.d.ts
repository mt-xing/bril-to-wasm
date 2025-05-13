export type Type = "int" | "bool"; // TODO add floats

export type ArithmeticInstruction = {
  op: "add" | "mul" | "sub" | "div";
  dest: string;
  type: "int";
  args: [string, string];
};

export type ComparisonInstruction = {
  op: "eq" | "lt" | "gt" | "le" | "ge"; // i think there was a typo here, said get not ge
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
  args?: [string];
} & (Record<string, never> | {
  dest: string;
  type: Type;
})) | {
  op: "ret";
  args?: [] | [string];
} | {
  op: "block"
  children: [BrilInstruction[]];
} | {
  op: "while"
  args: [string];
  children: [BrilInstruction[]];
} | {
  op: "if"
  args: [string];
  children: [BrilInstruction[], BrilInstruction[]];
} | {
  op: "continue" | "break";
  value: number;
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
  args?: { name: string; type: Type }[];
  type?: Type;
  instrs: BrilInstruction[];
};

export type BrilProgram = {
  functions: BrilFunction[]
};
