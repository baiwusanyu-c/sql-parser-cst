import { BaseNode, Keyword } from "./Base";
import {
  Identifier,
  ListExpr,
  EntityName,
  Expr,
  ParenExpr,
  FuncCall,
} from "./Expr";
import { FunctionSignature } from "./Function";
import { BooleanLiteral, StringLiteral } from "./Literal";

export type AllDclNodes =
  | AllDclStatements
  | Privilege
  | AllPrivileges
  | GrantResource
  | WithGrantOptionClause
  | GrantedByClause
  | GranteeGroup
  | GranteePublic;

export type AllDclStatements =
  | GrantPrivilegeStmt
  | GrantRoleStmt
  | RevokePrivilegeStmt;

// GRANT privilege ON resource TO roles
export interface GrantPrivilegeStmt extends BaseNode {
  type: "grant_privilege_stmt";
  grantKw: Keyword<"GRANT">;
  privileges: ListExpr<Privilege> | ListExpr<Identifier> | AllPrivileges;
  onKw: Keyword<"ON">;
  resource: GrantResource;
  toKw: Keyword<"TO">;
  roles: ListExpr<Grantee> | ListExpr<StringLiteral>;
  withGrantOptionKw?: [Keyword<"WITH">, Keyword<"GRANT">, Keyword<"OPTION">];
  grantedBy?: GrantedByClause;
}

// GRANT role TO role
export interface GrantRoleStmt extends BaseNode {
  type: "grant_role_stmt";
  grantKw: Keyword<"GRANT">;
  grantedRoles: ListExpr<Identifier>;
  toKw: Keyword<"TO">;
  granteeRoles: ListExpr<Grantee>;
  option?: WithGrantOptionClause;
  grantedBy?: GrantedByClause;
}

export interface Privilege extends BaseNode {
  type: "privilege";
  privilegeKw:
    | Keyword<
        | "SELECT"
        | "INSERT"
        | "UPDATE"
        | "DELETE"
        | "TRUNCATE"
        | "REFERENCES"
        | "TRIGGER"
        | "MAINTAIN"
        | "USAGE"
        | "CREATE"
        | "CONNECT"
        | "TEMPORARY"
        | "TEMP"
        | "SET"
        | "EXECUTE"
      >
    | [Keyword<"ALTER">, Keyword<"SYSTEM">];
  columns?: ParenExpr<ListExpr<Identifier>>;
}

export interface AllPrivileges extends BaseNode {
  type: "all_privileges";
  allKw: Keyword<"ALL">;
  privilegesKw?: Keyword<"PRIVILEGES">;
  columns?: ParenExpr<ListExpr<Identifier>>;
}

export type GrantResource =
  | GrantResourceTable
  | GrantResourceAllTablesInSchema
  | GrantResourceSequence
  | GrantResourceAllSequencesInSchema
  | GrantResourceDatabase
  | GrantResourceDomain
  | GrantResourceForeignDataWrapper
  | GrantResourceForeignServer
  | GrantResourceFunction
  | GrantResourceAllFunctionsInSchema
  | GrantResourceLanguage
  | GrantResourceLargeObject
  | GrantResourcePostgresqlOption
  | GrantResourceSchema
  | GrantResourceTablespace
  | GrantResourceType
  | GrantResourceView;

export interface GrantResourceTable extends BaseNode {
  type: "grant_resource_table";
  tableKw?: Keyword<"TABLE"> | [Keyword<"EXTERNAL">, Keyword<"TABLE">];
  tables: ListExpr<EntityName>;
}

export interface GrantResourceAllTablesInSchema extends BaseNode {
  type: "grant_resource_all_tables_in_schema";
  allTablesInSchemaKw: [
    Keyword<"ALL">,
    Keyword<"TABLES">,
    Keyword<"IN">,
    Keyword<"SCHEMA">
  ];
  schemas: ListExpr<Identifier>;
}

export interface GrantResourceSequence extends BaseNode {
  type: "grant_resource_sequence";
  sequenceKw: Keyword<"SEQUENCE">;
  sequences: ListExpr<EntityName>;
}

export interface GrantResourceAllSequencesInSchema extends BaseNode {
  type: "grant_resource_all_sequences_in_schema";
  allSequencesInSchemaKw: [
    Keyword<"ALL">,
    Keyword<"SEQUENCES">,
    Keyword<"IN">,
    Keyword<"SCHEMA">
  ];
  schemas: ListExpr<Identifier>;
}

export interface GrantResourceDatabase extends BaseNode {
  type: "grant_resource_database";
  databaseKw: Keyword<"DATABASE">;
  databases: ListExpr<Identifier>;
}

export interface GrantResourceDomain extends BaseNode {
  type: "grant_resource_domain";
  domainKw: Keyword<"DOMAIN">;
  domains: ListExpr<EntityName>;
}

export interface GrantResourceForeignDataWrapper extends BaseNode {
  type: "grant_resource_foreign_data_wrapper";
  foreignDataWrapperKw: [
    Keyword<"FOREIGN">,
    Keyword<"DATA">,
    Keyword<"WRAPPER">
  ];
  dataWrappers: ListExpr<Identifier>;
}

export interface GrantResourceForeignServer extends BaseNode {
  type: "grant_resource_foreign_server";
  foreignServerKw: [Keyword<"FOREIGN">, Keyword<"SERVER">];
  servers: ListExpr<Identifier>;
}

export interface GrantResourceFunction extends BaseNode {
  type: "grant_resource_function";
  functionKw: Keyword<"FUNCTION" | "PROCEDURE" | "ROUTINE">;
  functions: ListExpr<FunctionSignature>;
}

export interface GrantResourceAllFunctionsInSchema extends BaseNode {
  type: "grant_resource_all_functions_in_schema";
  allFunctionsInSchemaKw: [
    Keyword<"ALL">,
    Keyword<"FUNCTIONS" | "PROCEDURES" | "ROUTINES">,
    Keyword<"IN">,
    Keyword<"SCHEMA">
  ];
  schemas: ListExpr<Identifier>;
}

export interface GrantResourceLanguage extends BaseNode {
  type: "grant_resource_language";
  languageKw: Keyword<"LANGUAGE">;
  languages: ListExpr<Identifier>;
}

export interface GrantResourceLargeObject extends BaseNode {
  type: "grant_resource_large_object";
  largeObjectKw: [Keyword<"LARGE">, Keyword<"OBJECT">];
  oids: ListExpr<Expr>;
}

export interface GrantResourcePostgresqlOption extends BaseNode {
  type: "grant_resource_postgresql_option";
  parameterKw: Keyword<"PARAMETER">;
  options: ListExpr<Identifier>;
}

export interface GrantResourceSchema extends BaseNode {
  type: "grant_resource_schema";
  schemaKw: Keyword<"SCHEMA">;
  schemas: ListExpr<EntityName>;
}

export interface GrantResourceTablespace extends BaseNode {
  type: "grant_resource_tablespace";
  tablespaceKw: Keyword<"TABLESPACE">;
  tablespaces: ListExpr<Identifier>;
}

export interface GrantResourceType extends BaseNode {
  type: "grant_resource_type";
  typeKw: Keyword<"TYPE">;
  types: ListExpr<EntityName>;
}

// BigQuery
export interface GrantResourceView extends BaseNode {
  type: "grant_resource_view";
  viewKw: Keyword<"VIEW">;
  views: ListExpr<EntityName>;
}

export interface WithGrantOptionClause extends BaseNode {
  type: "with_grant_option_clause";
  withKw: Keyword<"WITH">;
  nameKw: Keyword<"GRANT" | "ADMIN" | "INHERIT" | "SET">;
  value: Keyword<"OPTION"> | BooleanLiteral;
}

export interface GrantedByClause extends BaseNode {
  type: "granted_by_clause";
  grantedByKw: [Keyword<"GRANTED">, Keyword<"BY">];
  role: Grantee;
}

// REVOKE privilege ON resource FROM roles
export interface RevokePrivilegeStmt extends BaseNode {
  type: "revoke_privilege_stmt";
  revokeKw: Keyword<"REVOKE">;
  grantOptionForKw?: [Keyword<"GRANT">, Keyword<"OPTION">, Keyword<"FOR">];
  privileges: ListExpr<Privilege> | ListExpr<Identifier> | AllPrivileges;
  onKw: Keyword<"ON">;
  resource: GrantResource;
  fromKw: Keyword<"FROM">;
  roles: ListExpr<Grantee> | ListExpr<StringLiteral>;
  grantedBy?: GrantedByClause;
  behaviorKw?: Keyword<"CASCADE" | "RESTRICT">;
}

type Grantee = Identifier | FuncCall | GranteeGroup | GranteePublic;

export interface GranteeGroup extends BaseNode {
  type: "grantee_group";
  groupKw: Keyword<"GROUP">;
  name: Identifier;
}

export interface GranteePublic extends BaseNode {
  type: "grantee_public";
  publicKw: Keyword<"PUBLIC">;
}
