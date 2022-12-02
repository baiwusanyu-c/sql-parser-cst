import { BaseNode, Keyword } from "./Base";
import { Table } from "./Expr";

// CREATE SCHEMA
export interface CreateSchemaStmt extends BaseNode {
  type: "create_schema_stmt";
  createSchemaKw: [Keyword<"CREATE">, Keyword<"SCHEMA" | "DATABASE">];
  ifNotExistsKw?: [Keyword<"IF">, Keyword<"NOT">, Keyword<"EXISTS">];
  name: Table;
}

// DROP SCHEMA
export interface DropSchemaStmt extends BaseNode {
  type: "drop_schema_stmt";
  dropSchemaKw: [Keyword<"DROP">, Keyword<"SCHEMA" | "DATABASE">];
  ifExistsKw?: [Keyword<"IF">, Keyword<"EXISTS">];
  name: Table;
  behaviorKw?: Keyword<"CASCADE" | "RESTRICT">;
}
