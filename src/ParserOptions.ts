export const validDialectNames = {
  sqlite: true,
  mysql: true,
  bigquery: true,
};

export type DialectName = keyof typeof validDialectNames;

export type ParamType = "?" | "?nr" | ":name" | "$name" | "@name";

export type ParserOptions = {
  dialect: DialectName;
  includeComments?: boolean;
  includeNewlines?: boolean;
  includeSpaces?: boolean;
  includeRange?: boolean;
  paramTypes?: ParamType[];
  /** SQL file name, used when reporting syntax errors */
  filename?: string;
};
