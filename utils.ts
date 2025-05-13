export function assertUnreachable(x: never): never {
  throw new Error(`Unreachable code reached: ${x}`);
}

export function freshName(base?: string): string {
  const randomSuffix = `${Math.random()}`.substring(2);
  return `${base ?? 'generated'}_${randomSuffix}`;
}