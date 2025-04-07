// 验证传入的配置项是否是支持的语言
// 一、与starRocks语法相似度排序（由高到低）
// MySQL/MariaDB（最接近）
// PostgreSQL
// BigQuery
// SQLite（差异最大）
export const validDialectNames = {
  sqlite: true,
  mysql: true,
  mariadb: true,
  bigquery: true,
  postgresql: true,
  starrocks: true,
};

export type DialectName = keyof typeof validDialectNames;

export type ParamType =
  | "?"
  | "?nr"
  | "$nr"
  | ":name"
  | "$name"
  | "@name"
  | "@`name`";

// 解析器可选配置定义
export type ParserOptions = {
  dialect: DialectName;
  includeComments?: boolean;
  includeNewlines?: boolean;
  includeSpaces?: boolean;
  includeRange?: boolean;
  paramTypes?: ParamType[];
  acceptUnsupportedGrammar?: boolean;
  /** SQL file name, used when reporting syntax errors */
  filename?: string;
};
