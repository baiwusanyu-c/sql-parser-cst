import { AllColumns, BaseNode, Empty, Keyword } from "./Base";
import {
  Expr,
  FuncCall,
  Identifier,
  ListExpr,
  MemberExpr,
  ParenExpr,
  EntityName,
  Variable,
} from "./Expr";
import { Alias } from "./Alias";
import { FrameClause } from "./WindowFrame";
import { Literal, StringLiteral } from "./Literal";
import { MysqlModifier } from "./dialects/Mysql";
import { ColumnDefinition, RelationKind } from "./CreateTable";
import {
  DeleteStmt,
  InsertStmt,
  PostgresqlOperator,
  PostgresqlOperatorExpr,
  UpdateStmt,
} from "./Node";

export type AllSelectNodes =
  | CompoundSelectStmt
  | SelectStmt
  | WithClause
  | CommonTableExpr
  | CteSearchClause
  | CteCycleClause
  | CteCycleClauseValues
  | SelectClause
  | SelectAll
  | SelectDistinct
  | SelectDistinctOn
  | SelectAsStruct
  | SelectAsValue
  | ExceptColumns
  | ReplaceColumns
  | FromClause
  | WhereClause
  | GroupByClause
  | GroupByRollup
  | GroupByCube
  | GroupByGroupingSets
  | GroupByAll
  | HavingClause
  | WindowClause
  | QualifyClause
  | NamedWindow
  | WindowDefinition
  | OrderByClause
  | PartitionByClause
  | LimitClause
  | LimitAll
  | LimitRowsExamined
  | OffsetClause
  | FetchClause
  | DualTable
  | JoinExpr
  | IndexedTable
  | NotIndexedTable
  | LateralDerivedTable
  | PartitionedTable
  | TableWithInheritance
  | TableWithoutInheritance
  | FuncCallWithColumnDefinitions
  | WithOrdinalityExpr
  | RowsFromExpr
  | UnnestWithOffsetExpr
  | UnnestExpr
  | PivotExpr
  | PivotForIn
  | UnpivotExpr
  | UnpivotForIn
  | TablesampleExpr
  | TablesampleMethod
  | TablesamplePercent
  | TablesampleRepeatable
  | ForSystemTimeAsOfExpr
  | JoinOnSpecification
  | JoinUsingSpecification
  | SortSpecification
  | SortDirectionAsc
  | SortDirectionDesc
  | SortDirectionUsingOperator
  | IntoTableClause
  | IntoVariablesClause
  | IntoDumpfileClause
  | IntoOutfileClause
  | OutfileFields
  | OutfileLines
  | OutfileOptionTerminatedBy
  | OutfileOptionEscapedBy
  | OutfileOptionStartingBy
  | OutfileOptionEnclosedBy
  | OutfileOptionCharacterSet
  | ForClause
  | ForClauseTables
  | LockInShareModeClause
  | TableClause;

// SELECT
export interface CompoundSelectStmt extends BaseNode {
  type: "compound_select_stmt";
  left: SubSelect;
  operator:
    | Keyword<"UNION" | "EXCEPT" | "INTERSECT">
    | [Keyword<"UNION" | "EXCEPT" | "INTERSECT">, Keyword<"ALL" | "DISTINCT">];
  right: SubSelect;
}

export type SubSelect = SelectStmt | CompoundSelectStmt | ParenExpr<SubSelect>;

export interface SelectStmt extends BaseNode {
  type: "select_stmt";
  clauses: (
    | WithClause
    | SelectClause
    | FromClause
    | WhereClause
    | GroupByClause
    | HavingClause
    | WindowClause
    | QualifyClause
    | OrderByClause
    | LimitClause
    | OffsetClause
    | FetchClause
    | IntoTableClause
    | IntoVariablesClause
    | IntoDumpfileClause
    | IntoOutfileClause
    | ForClause
    | LockInShareModeClause
    | TableClause
    | ParenExpr<SelectStmt>
  )[];
}

export interface WithClause extends BaseNode {
  type: "with_clause";
  withKw: Keyword<"WITH">;
  recursiveKw?: Keyword<"RECURSIVE">;
  tables: ListExpr<CommonTableExpr>;
}

export interface CommonTableExpr extends BaseNode {
  type: "common_table_expr";
  table: Identifier;
  columns?: ParenExpr<ListExpr<Identifier>>;
  asKw: Keyword<"AS">;
  materializedKw?:
    | Keyword<"MATERIALIZED">
    | [Keyword<"NOT">, Keyword<"MATERIALIZED">];
  // PostgreSQL supports UPDATE, DELETE, and INSERT in WITH clause
  expr: ParenExpr<SubSelect | DeleteStmt | InsertStmt | UpdateStmt>;
  search?: CteSearchClause;
  cycle?: CteCycleClause;
}

// PostgreSQL
export interface CteSearchClause extends BaseNode {
  type: "cte_search_clause";
  searchKw: [
    Keyword<"SEARCH">,
    Keyword<"BREADTH" | "DEPTH">,
    Keyword<"FIRST">,
    Keyword<"BY">
  ];
  columns: ListExpr<Identifier>;
  setKw: Keyword<"SET">;
  resultColumn: Identifier;
}

// PostgreSQL
export interface CteCycleClause extends BaseNode {
  type: "cte_cycle_clause";
  cycleKw: Keyword<"CYCLE">;
  columns: ListExpr<Identifier>;
  setKw: Keyword<"SET">;
  resultColumn: Identifier;
  values?: CteCycleClauseValues;
  usingKw: Keyword<"USING">;
  pathColumn: Identifier;
}

// PostgreSQL
export interface CteCycleClauseValues extends BaseNode {
  type: "cte_cycle_clause_values";
  toKw: Keyword<"TO">;
  markValue: Literal;
  defaultKw?: Keyword<"DEFAULT">;
  defaultValue: Literal;
}

export interface SelectClause extends BaseNode {
  type: "select_clause";
  selectKw: Keyword<"SELECT">;
  modifiers: (
    | SelectAll
    | SelectDistinct
    | SelectDistinctOn
    | SelectAsStruct
    | SelectAsValue
    | MysqlModifier
  )[];
  // PostgreSQL supports empty SELECT clause
  columns?: ListExpr<
    AllColumns | ExceptColumns | ReplaceColumns | Expr | Alias<Expr> | Empty
  >;
}

export interface SelectAll extends BaseNode {
  type: "select_all";
  allKw: Keyword<"ALL">;
}

export interface SelectDistinct extends BaseNode {
  type: "select_distinct";
  distinctKw: Keyword<"DISTINCT" | "DISTINCTROW">;
}

// PostgreSQL
export interface SelectDistinctOn extends BaseNode {
  type: "select_distinct_on";
  distinctOnKw: [Keyword<"DISTINCT">, Keyword<"ON">];
  columns: ParenExpr<ListExpr<Expr>>;
}

// BigQuery
export interface SelectAsStruct extends BaseNode {
  type: "select_as_struct";
  asStructKw: [Keyword<"AS">, Keyword<"STRUCT">];
}

// BigQuery
export interface SelectAsValue extends BaseNode {
  type: "select_as_value";
  asValueKw: [Keyword<"AS">, Keyword<"VALUE">];
}

// BigQuery
export interface ExceptColumns extends BaseNode {
  type: "except_columns";
  expr: MemberExpr | AllColumns;
  exceptKw: Keyword<"EXCEPT">;
  columns: ParenExpr<ListExpr<Identifier>>;
}

// BigQuery
export interface ReplaceColumns extends BaseNode {
  type: "replace_columns";
  expr: MemberExpr | AllColumns;
  replaceKw: Keyword<"REPLACE">;
  columns: ParenExpr<ListExpr<Alias<Expr>>>;
}

export interface FromClause extends BaseNode {
  type: "from_clause";
  fromKw: Keyword<"FROM" | "USING">; // The USING keyword is used in MySQL/MariaDB DELETE statement
  expr: TableExpr | DualTable;
}

export interface WhereClause extends BaseNode {
  type: "where_clause";
  whereKw: Keyword<"WHERE">;
  expr: Expr;
}

export interface GroupByClause extends BaseNode {
  type: "group_by_clause";
  groupByKw: [Keyword<"GROUP">, Keyword<"BY">];
  distinctKw?: Keyword<"ALL" | "DISTINCT">; // PostgreSQL
  columns: ListExpr<GroupingElement>;
  withRollupKw?: [Keyword<"WITH">, Keyword<"ROLLUP">]; // MySQL, MariaDB
}

type GroupingElement =
  | Expr
  | GroupByRollup
  | GroupByCube
  | GroupByGroupingSets
  | GroupByAll;

// BigQuery, PostgreSQL
export interface GroupByRollup extends BaseNode {
  type: "group_by_rollup";
  rollupKw: Keyword<"ROLLUP">;
  columns: ParenExpr<ListExpr<Expr>>;
}

// BigQuery, PostgreSQL
export interface GroupByCube extends BaseNode {
  type: "group_by_cube";
  cubeKw: Keyword<"CUBE">;
  columns: ParenExpr<ListExpr<Expr>>;
}

// BigQuery
export interface GroupByAll extends BaseNode {
  type: "group_by_all";
  allKw: Keyword<"ALL">;
}

// PostgreSQL
export interface GroupByGroupingSets extends BaseNode {
  type: "group_by_grouping_sets";
  groupingSetsKw: Keyword<"GROUPING SETS">;
  columns: ParenExpr<ListExpr<GroupingElement>>;
}

export interface HavingClause extends BaseNode {
  type: "having_clause";
  havingKw: Keyword<"HAVING">;
  expr: Expr;
}

export interface WindowClause extends BaseNode {
  type: "window_clause";
  windowKw: Keyword<"WINDOW">;
  namedWindows: ListExpr<NamedWindow>;
}

export interface NamedWindow extends BaseNode {
  type: "named_window";
  name: Identifier;
  asKw: Keyword<"AS">;
  window: ParenExpr<WindowDefinition>;
}

export interface WindowDefinition extends BaseNode {
  type: "window_definition";
  baseWindowName?: Identifier;
  partitionBy?: PartitionByClause;
  orderBy?: OrderByClause;
  frame?: FrameClause;
}

export interface OrderByClause extends BaseNode {
  type: "order_by_clause";
  orderByKw: [Keyword<"ORDER">, Keyword<"BY">];
  specifications: ListExpr<SortSpecification | Identifier>;
  withRollupKw?: [Keyword<"WITH">, Keyword<"ROLLUP">]; // MySQL
}

export interface PartitionByClause extends BaseNode {
  type: "partition_by_clause";
  partitionByKw: [Keyword<"PARTITION">, Keyword<"BY">];
  specifications: ListExpr<Expr>;
}

export interface LimitClause extends BaseNode {
  type: "limit_clause";
  limitKw: Keyword<"LIMIT">;
  count?: Expr | LimitAll;
  offsetKw?: Keyword<"OFFSET">;
  offset?: Expr;
  rowsExamined?: LimitRowsExamined;
}

// PostgreSQL
export interface LimitAll extends BaseNode {
  type: "limit_all";
  allKw: Keyword<"ALL">;
}

// MariaDB
export interface LimitRowsExamined extends BaseNode {
  type: "limit_rows_examined";
  rowsExaminedKw: [Keyword<"ROWS">, Keyword<"EXAMINED">];
  count: Expr;
}

// MariaDB, PostgreSQL
export interface OffsetClause extends BaseNode {
  type: "offset_clause";
  offsetKw: Keyword<"OFFSET">;
  offset: Expr;
  rowsKw?: Keyword<"ROWS" | "ROW">;
}

// MariaDB, PostgreSQL
export interface FetchClause extends BaseNode {
  type: "fetch_clause";
  fetchKw: [Keyword<"FETCH">, Keyword<"FIRST" | "NEXT">];
  count?: Expr;
  rowsKw: Keyword<"ROWS" | "ROW">;
  withTiesKw: Keyword<"ONLY"> | [Keyword<"WITH">, Keyword<"TIES">];
}

// MySQL, MariaDB
export interface DualTable extends BaseNode {
  type: "dual_table";
  dualKw: Keyword<"DUAL">;
}

type TableExpr =
  | JoinExpr
  | PivotExpr
  | UnpivotExpr
  | TablesampleExpr
  | ForSystemTimeAsOfExpr
  | TableFactor;

export interface JoinExpr extends BaseNode {
  type: "join_expr";
  left: TableExpr;
  operator: JoinOp | ",";
  right: TableFactor;
  specification?: JoinOnSpecification | JoinUsingSpecification;
}

type JoinOp =
  | Keyword<
      | "NATURAL"
      | "LEFT"
      | "RIGHT"
      | "FULL"
      | "OUTER"
      | "INNER"
      | "CROSS"
      | "JOIN"
    >[]
  | Keyword<"JOIN" | "STRAIGHT_JOIN">;

export type TableFactor =
  | RelationExpr
  | TableFuncCall
  | WithOrdinalityExpr
  | ParenExpr<SubSelect | TableExpr>
  | UnnestWithOffsetExpr
  | UnnestExpr
  | LateralDerivedTable
  | PartitionedTable
  | RowsFromExpr
  | Alias<TableFactor>;

export type RelationExpr =
  | EntityName
  | TableWithInheritance
  | TableWithoutInheritance
  | IndexedTable
  | NotIndexedTable;

export type TableFuncCall = FuncCall | FuncCallWithColumnDefinitions;

// SQLite only
export interface IndexedTable extends BaseNode {
  type: "indexed_table";
  table: EntityName | Alias<EntityName>;
  indexedByKw: [Keyword<"INDEXED">, Keyword<"BY">];
  index: Identifier;
}
export interface NotIndexedTable extends BaseNode {
  type: "not_indexed_table";
  table: EntityName | Alias<EntityName>;
  notIndexedKw: [Keyword<"NOT">, Keyword<"INDEXED">];
}

// MySQL, MariaDB, PostgreSQL
export interface LateralDerivedTable extends BaseNode {
  type: "lateral_derived_table";
  lateralKw: Keyword<"LATERAL">;
  expr:
    | ParenExpr<SubSelect>
    | TableFuncCall
    | WithOrdinalityExpr
    | RowsFromExpr;
}

// MySQL, MariaDB
export interface PartitionedTable extends BaseNode {
  type: "partitioned_table";
  table: EntityName | Alias<EntityName>;
  partitionKw: Keyword<"PARTITION">;
  partitions: ParenExpr<ListExpr<Identifier>>;
}

// PostgreSQL syntax: table_name *
export interface TableWithInheritance extends BaseNode {
  type: "table_with_inheritance";
  table: EntityName;
}

// PostgreSQL syntax: ONLY table_name
export interface TableWithoutInheritance extends BaseNode {
  type: "table_without_inheritance";
  onlyKw: Keyword<"ONLY">;
  table: EntityName;
}

// PostgreSQL
export interface RowsFromExpr extends BaseNode {
  type: "rows_from_expr";
  rowsFromKw: [Keyword<"ROWS">, Keyword<"FROM">];
  expr: ParenExpr<ListExpr<TableFuncCall>>;
}

// PostgreSQL
export interface WithOrdinalityExpr extends BaseNode {
  type: "with_ordinality_expr";
  expr: TableFuncCall | RowsFromExpr;
  withOrdinalityKw: [Keyword<"WITH">, Keyword<"ORDINALITY">];
}

// PostgreSQL
export interface FuncCallWithColumnDefinitions extends BaseNode {
  type: "func_call_with_column_definitions";
  funcCall: Alias<FuncCall> | FuncCall;
  asKw?: Keyword<"AS">;
  columns: ParenExpr<ListExpr<ColumnDefinition>>;
}

// BigQuery
export interface UnnestWithOffsetExpr extends BaseNode {
  type: "unnest_with_offset_expr";
  unnest:
    | UnnestExpr
    | MemberExpr
    | Identifier
    | Alias<UnnestExpr | MemberExpr | Identifier>;
  withOffsetKw: [Keyword<"WITH">, Keyword<"OFFSET">];
}
// BigQuery
export interface UnnestExpr extends BaseNode {
  type: "unnest_expr";
  unnestKw: Keyword<"UNNEST">;
  expr: ParenExpr<Expr>;
}
// BigQuery
export interface PivotExpr extends BaseNode {
  type: "pivot_expr";
  left: TableExpr;
  pivotKw: Keyword<"PIVOT">;
  args: ParenExpr<PivotForIn>;
}
// BigQuery
export interface PivotForIn extends BaseNode {
  type: "pivot_for_in";
  aggregations: ListExpr<FuncCall | Alias<FuncCall>>;
  forKw: Keyword<"FOR">;
  inputColumn: Identifier;
  inKw: Keyword<"IN">;
  pivotColumns: ParenExpr<ListExpr<Expr | Alias<Expr>>>;
}
// BigQuery
export interface UnpivotExpr extends BaseNode {
  type: "unpivot_expr";
  left: TableExpr;
  unpivotKw: Keyword<"UNPIVOT">;
  nullHandlingKw?: [Keyword<"INCLUDE" | "EXCLUDE">, Keyword<"NULLS">];
  args: ParenExpr<UnpivotForIn>;
}
// BigQuery
export interface UnpivotForIn extends BaseNode {
  type: "unpivot_for_in";
  valuesColumn:
    | Identifier // for single-column unpivot
    | ParenExpr<ListExpr<Identifier>>; // for multi-column unpivot
  forKw: Keyword<"FOR">;
  nameColumn: Identifier;
  inKw: Keyword<"IN">;
  unpivotColumns:
    | ParenExpr<ListExpr<Identifier | Alias<Expr>>> // for single-column unpivot
    // for multi-column unpivot
    | ParenExpr<
        ListExpr<
          | ParenExpr<ListExpr<Identifier>>
          | Alias<ParenExpr<ListExpr<Identifier>>>
        >
      >;
}
// BigQuery & PostgreSQL
export interface TablesampleExpr extends BaseNode {
  type: "tablesample_expr";
  left: TableExpr;
  tablesampleKw: Keyword<"TABLESAMPLE">;
  method: TablesampleMethod | Identifier;
  args: ParenExpr<ListExpr<TablesamplePercent | Expr>>;
  repeatable?: TablesampleRepeatable;
}
// BigQuery & PostgreSQL
export interface TablesampleMethod extends BaseNode {
  type: "tablesample_method";
  methodKw: Keyword<"SYSTEM" | "BERNOULLI">;
}
// BigQuery
export interface TablesamplePercent extends BaseNode {
  type: "tablesample_percent";
  percent: Expr;
  percentKw: Keyword<"PERCENT">;
}
// PostgreSQL
export interface TablesampleRepeatable extends BaseNode {
  type: "tablesample_repeatable";
  repeatableKw: Keyword<"REPEATABLE">;
  seed: ParenExpr<Expr>;
}

// BigQuery
export interface ForSystemTimeAsOfExpr extends BaseNode {
  type: "for_system_time_as_of_expr";
  left: TableExpr;
  forSystemTimeAsOfKw: [
    Keyword<"FOR">,
    Keyword<"SYSTEM_TIME">,
    Keyword<"AS">,
    Keyword<"OF">
  ];
  expr: Expr;
}

export interface JoinOnSpecification extends BaseNode {
  type: "join_on_specification";
  onKw: Keyword<"ON">;
  expr: Expr;
}

export interface JoinUsingSpecification extends BaseNode {
  type: "join_using_specification";
  usingKw: Keyword<"USING">;
  expr: ParenExpr<ListExpr<Identifier>>;
}

export interface SortSpecification extends BaseNode {
  type: "sort_specification";
  expr: Expr;
  direction?: SortDirectionAsc | SortDirectionDesc | SortDirectionUsingOperator;
  nullHandlingKw?: [Keyword<"NULLS">, Keyword<"FIRST" | "LAST">]; // SQLite, PostgreSQL
}

export interface SortDirectionAsc extends BaseNode {
  type: "sort_direction_asc";
  ascKw: Keyword<"ASC">;
}

export interface SortDirectionDesc extends BaseNode {
  type: "sort_direction_desc";
  descKw: Keyword<"DESC">;
}

export interface SortDirectionUsingOperator extends BaseNode {
  type: "sort_direction_using_operator";
  usingKw: Keyword<"USING">;
  operator: PostgresqlOperator | PostgresqlOperatorExpr;
}

// BigQuery
export interface QualifyClause extends BaseNode {
  type: "qualify_clause";
  qualifyKw: Keyword<"QUALIFY">;
  expr: Expr;
}

// PostgreSQL
export interface IntoTableClause extends BaseNode {
  type: "into_table_clause";
  intoKw: Keyword<"INTO">;
  kind?: RelationKind;
  tableKw?: Keyword<"TABLE">;
  name: EntityName;
}

// MySQL, MariaDB
export interface IntoVariablesClause extends BaseNode {
  type: "into_variables_clause";
  intoKw: Keyword<"INTO">;
  variables: ListExpr<Variable>;
}

// MySQL, MariaDB
export interface IntoDumpfileClause extends BaseNode {
  type: "into_dumpfile_clause";
  intoDumpfileKw: [Keyword<"INTO">, Keyword<"DUMPFILE">];
  filename: StringLiteral;
}

// MySQL, MariaDB
export interface IntoOutfileClause extends BaseNode {
  type: "into_outfile_clause";
  intoOutfileKw: [Keyword<"INTO">, Keyword<"OUTFILE">];
  filename: StringLiteral;
  charset?: OutfileOptionCharacterSet;
  fields?: OutfileFields;
  lines?: OutfileLines;
}

// MySQL, MariaDB
export interface OutfileFields extends BaseNode {
  type: "outfile_fields";
  fieldsKw: Keyword<"FIELDS" | "COLUMNS">;
  options: (
    | OutfileOptionTerminatedBy
    | OutfileOptionEnclosedBy
    | OutfileOptionEscapedBy
  )[];
}

// MySQL, MariaDB
export interface OutfileLines extends BaseNode {
  type: "outfile_lines";
  linesKw: Keyword<"LINES">;
  options: (OutfileOptionStartingBy | OutfileOptionTerminatedBy)[];
}

// MySQL, MariaDB
export interface OutfileOptionTerminatedBy extends BaseNode {
  type: "outfile_option_terminated_by";
  terminatedByKw: [Keyword<"TERMINATED">, Keyword<"BY">];
  value: StringLiteral;
}

// MySQL, MariaDB
export interface OutfileOptionEscapedBy extends BaseNode {
  type: "outfile_option_escaped_by";
  escapedByKw: [Keyword<"ESCAPED">, Keyword<"BY">];
  value: StringLiteral;
}

// MySQL, MariaDB
export interface OutfileOptionStartingBy extends BaseNode {
  type: "outfile_option_starting_by";
  startingByKw: [Keyword<"STARTING">, Keyword<"BY">];
  value: StringLiteral;
}

// MySQL, MariaDB
export interface OutfileOptionEnclosedBy extends BaseNode {
  type: "outfile_option_enclosed_by";
  optionallyKw?: Keyword<"OPTIONALLY">;
  enclosedByKw: [Keyword<"ENCLOSED">, Keyword<"BY">];
  value: StringLiteral;
}

// MySQL, MariaDB
export interface OutfileOptionCharacterSet extends BaseNode {
  type: "outfile_option_character_set";
  characterSetKw: [Keyword<"CHARACTER">, Keyword<"SET">];
  value: Identifier;
}

// MySQL, MariaDB, PostgreSQL
// Referred to as the Locking Clause in PostgreSQL documentation
export interface ForClause extends BaseNode {
  type: "for_clause";
  forKw: Keyword<"FOR">;
  lockStrengthKw:
    | Keyword<"UPDATE">
    | [Keyword<"NO">, Keyword<"KEY">, Keyword<"UPDATE">]
    | Keyword<"SHARE">
    | [Keyword<"KEY">, Keyword<"SHARE">];
  tables?: ForClauseTables;
  waitingKw?: Keyword<"NOWAIT"> | [Keyword<"SKIP">, Keyword<"LOCKED">];
}

// MySQL, PostgreSQL
export interface ForClauseTables extends BaseNode {
  type: "for_clause_tables";
  ofKw: Keyword<"OF">;
  tables: ListExpr<Identifier>;
}

// MySQL, MariaDB
export interface LockInShareModeClause extends BaseNode {
  type: "lock_in_share_mode_clause";
  lockInShareModeKw: [
    Keyword<"LOCK">,
    Keyword<"IN">,
    Keyword<"SHARE">,
    Keyword<"MODE">
  ];
}

// MySQL, MariaDB, PostgreSQL
export interface TableClause extends BaseNode {
  type: "table_clause";
  tableKw: Keyword<"TABLE">;
  table: RelationExpr;
}
