{
  /** Identity function */
  const identity = (x) => x;

  /** Extracts second item from array */
  const second = ([_, x]) => x;

  /** Last item in array */
  const last = (arr) => arr[arr.length-1];

  /** True when value is object */
  const isObject = (value) => typeof value === "object";

  /** Prefer undefined over null */
  const nullToUndefined = (value) => value === null ? undefined : value;

  /** Creates new array with first item replaced by value */
  const setFirst = ([oldFirst, ...rest], value) => {
    return [value, ...rest];
  };

  /** Creates new array with last item replaced by value */
  const setLast = (array, value) => {
    const rest = array.slice(0, -1);
    return [...rest, value];
  };

  /** Attaches optional comments to AST node, or to array of AST nodes (the first and last) */
  const withComments = (node, { leading, trailing }) => {
    if (node instanceof Array) {
      // Add surrounding comments to first and last item in array (which might be the same one)
      node = setFirst(node, withComments(node[0], { leading }));
      node = setLast(node, withComments(last(node), { trailing }));
      return node;
    }
    if (leading && leading.length) {
      if (node.leadingComments) {
        throw new Error("withComments(): Node already has leadingComments");
      }
      node = {...node, leadingComments: leading};
    }
    if (trailing && trailing.length) {
      if (node.trailingComments) {
        throw new Error("withComments(): Node already has trailingComments");
      }
      node = {...node, trailingComments: trailing};
    }
    return node;
  };

  // Shorthands for attaching just trailing or leading comments
  const leading = (node, leading) => withComments(node, { leading });
  const trailing = (node, trailing) => withComments(node, { trailing });

  function createBinaryExprChain(head, tail) {
    return tail.reduce((left, [c1, op, c2, right]) => createBinaryExpr(left, c1, op, c2, right), head);
  }

  function createBinaryExpr(left, c1, op, c2, right) {
    return {
      type: 'binary_expr',
      operator: op,
      left: withComments(left, {trailing: c1}),
      right: withComments(right, {leading: c2}),
    };
  }

  function createUnaryExpr(op, c, right) {
    return {
      type: "unary_expr",
      operator: op,
      expr: withComments(right, { leading: c }),
    };
  }

  const createKeyword = (text) => ({ type: "keyword", text });

  const createKeywordList = (items) => {
    if (!items) {
      return undefined;
    }
    if (!(items instanceof Array)) {
      return [items];
    }
    const keywords = [];
    for (const it of items) {
      if (it instanceof Array) {
        keywords[keywords.length - 1] = withComments(keywords[keywords.length - 1], {trailing: it});
      } else {
        keywords.push(it);
      }
    }
    return keywords;
  }

  const readCommaSepList = (head, tail) => {
    const items = [head];
    for (const [c1, comma, c2, expr] of tail) {
      const lastIdx = items.length - 1;
      items[lastIdx] = withComments(items[lastIdx], { trailing: c1 });
      items.push(withComments(expr, { leading: c2 }));
    }
    return items;
  };

  const readSpaceSepList = (head, tail) => {
    const items = [head];
    for (const [c, expr] of tail) {
      items.push(withComments(expr, { leading: c }));
    }
    return items;
  };

  const createIdentifier = (text) => ({ type: "identifier", text });

  const createAlias = (expr, _alias) => {
    if (!_alias) {
      return expr;
    }
    const [c, partialAlias] = _alias;
    return {
      type: "alias",
      expr: withComments(expr, { trailing: c }),
      ...partialAlias,
    };
  }

  const createParenExpr = (c1, expr, c2) => {
    return {
      type: "paren_expr",
      expr: withComments(expr, { leading: c1, trailing: c2 }),
    };
  }
}

start
  = multiple_stmt

multiple_stmt
  = head:statement tail:(__ SEMICOLON __ statement)* {
    return readCommaSepList(head, tail);
  }

statement
  = union_stmt
  / drop_stmt
  / create_table_stmt
  / create_index_stmt
  / create_db_stmt
  / create_view_stmt
  / truncate_stmt
  / rename_stmt
  / call_stmt
  / use_stmt
  / alter_table_stmt
  / set_stmt
  / lock_stmt
  / unlock_stmt
  / show_stmt
  / desc_stmt
  / update_stmt
  / replace_insert_stmt
  / insert_no_columns_stmt
  / insert_into_set
  / delete_stmt
  / proc_stmt
  / empty_stmt

empty_stmt
  = c:__ {
    return withComments({ type: "empty_statement" }, { trailing: c });
  }

union_stmt
  = head:select_stmt tail:(__ KW_UNION __ KW_ALL? __ select_stmt)* (__ ob:order_by_clause)? (__ l:limit_clause)? {
    return head; // TODO
  }

column_order_list
  = head:column_order_item tail:(__ COMMA __ column_order_item)* {
    return "[Not implemented]";
  }

column_order_item
  = c:expr o:(KW_ASC / KW_DESC)? {
    return "[Not implemented]";
  }
  / column_order

column_order
  = c:column_ref __ o:(KW_ASC / KW_DESC)? {
    return "[Not implemented]";
  }
create_db_definition
  = head:create_option_character_set tail:(__ create_option_character_set)* {
    return "[Not implemented]";
  }

create_db_stmt
  = a:KW_CREATE __
    k:(KW_DATABASE / KW_SCHEME) __
    ife:if_not_exists? __
    t:ident_name __
    c:create_db_definition? {
      return "[Not implemented]";
    }

view_with
  = KW_WITH __ c:("CASCADED"i / "LOCAL"i) __ "CHECK"i __ "OPTION" {
    return "[Not implemented]";
  }
  / KW_WITH __ "CHECK"i __ "OPTION" {
    return "[Not implemented]";
  }

create_view_stmt
  = a:KW_CREATE __
  or:(KW_OR __ KW_REPLACE)? __
  al:("ALGORITHM"i __ "=" __ ("UNDEFINED"i / "MERGE"i / "TEMPTABLE"i))? __
  df:("DEFINER"i __ "=" __ ident)? __
  ss:("SQL"i __ "SECURITY"i __ ("DEFINER"i / "INVOKER"i))? __
  KW_VIEW __ v:table_name __ c:(LPAREN __ column_list __ RPAREN)? __
  KW_AS __ s:select_stmt_nake __
  w:view_with? {
    return "[Not implemented]";
  }

create_index_stmt
  = a:KW_CREATE __
  kw:(KW_UNIQUE / KW_FULLTEXT / KW_SPATIAL)? __
  t:KW_INDEX __
  n:ident __
  um:index_type? __
  on:KW_ON __
  ta:table_name __
  LPAREN __ cols:column_order_list __ RPAREN __
  io:index_options? __
  al:alter_algorithm? __
  lo:alter_lock? __ {
    return "[Not implemented]";
  }

create_table_stmt
  = a:KW_CREATE __
    tp:KW_TEMPORARY? __
    KW_TABLE __
    ife:if_not_exists? __
    t:table_name __
    lt:create_like_table {
      return "[Not implemented]";
    }
  / createKw:KW_CREATE
    tmpKw:(c:__ kw:KW_TEMPORARY { return leading(kw, c); })?
    tableKw:(c:__ kw:KW_TABLE { return leading(kw, c); })
    ifKw:(c:__ kw:if_not_exists { return leading(kw, c); })?
    table:(c1:__ t:table_name c2:__ { return withComments(t, { leading: c1, trailing: c2 }); })
    columns:create_table_definition
    __ table_options?
    __ (KW_IGNORE / KW_REPLACE)?
    __ KW_AS?
    __ union_stmt? {
      return {
        type: "create_table_statement",
        createKw,
        temporaryKw: nullToUndefined(tmpKw),
        tableKw,
        ifNotExistsKw: nullToUndefined(ifKw),
        table,
        columns,
      };
    }

if_not_exists
  = kws:(KW_IF __ KW_NOT __ KW_EXISTS) { return createKeywordList(kws); }

create_like_table_simple
  = KW_LIKE __ t: table_ref_list {
    return "[Not implemented]";
  }

create_like_table
  = create_like_table_simple
  / LPAREN __ e:create_like_table  __ RPAREN {
    return "[Not implemented]";
  }

create_table_definition
  = LPAREN c1:__ head:create_definition tail:(__ COMMA __ create_definition)* c2:__ RPAREN {
    return withComments(readCommaSepList(head, tail), { leading: c1, trailing: c2 });
  }

create_definition
  = create_constraint_definition
  / create_column_definition
  / create_index_definition
  / create_fulltext_spatial_index_definition

column_definition_opt
  = kws:(KW_NOT __ KW_NULL) {
    return { type: "column_option_nullable", kw: createKeywordList(kws), value: false };
  }
  / kw:KW_NULL {
    return { type: "column_option_nullable", kw, value: true };
  }
  / kw:KW_DEFAULT c:__ e:(literal / paren_expr) {
    return { type: "column_option_default", kw, expr: withComments(e, {leading: c}) };
  }
  / kw:KW_AUTO_INCREMENT {
    return { type: "column_option_auto_increment", kw };
  }
  / kws:(KW_UNIQUE __ KW_KEY / KW_UNIQUE / KW_PRIMARY __ KW_KEY / KW_KEY) {
    return { type: "column_option_key", kw: createKeywordList(kws) };
  }
  / column_option_comment
  / ca:collate_expr {
    return "[Not implemented]";
  }
  / cf:column_format {
    return "[Not implemented]";
  }
  / s:storage {
    return "[Not implemented]";
  }
  / re:reference_definition {
    return "[Not implemented]";
  }
  / ck:check_constraint_definition {
    return "[Not implemented]";
  }
  / t:create_option_character_set_kw __ s:"="? __ v:ident_name {
    return "[Not implemented]";
  }

column_definition_opt_list
  = head:column_definition_opt tail:(__ column_definition_opt)* {
    return readSpaceSepList(head, tail);
  }

create_column_definition
  = name:column_ref c1:__
    type:data_type
    options:(c:__ list:column_definition_opt_list { return leading(list, c); })? {
      return {
        type: "column_definition",
        name: withComments(name, {trailing: c1}),
        dataType: type,
        options: options || [],
      };
    }

column_option_comment
  = kw:KW_COMMENT c:__ str:literal_string {
    return {
      type: "column_option_comment",
      kw,
      value: withComments(str, { leading: c }),
    };
  }

collate_expr
  = KW_COLLATE __ s:"="? __ ca:ident_name {
    return "[Not implemented]";
  }
column_format
  = k:KW_COLUMN_FORMAT __ f:(KW_FIXED / KW_DYNAMIC / KW_DEFAULT) {
    return "[Not implemented]";
  }
storage
  = k:KW_STORAGE __ s:(KW_DISK / KW_MEMORY) {
    return "[Not implemented]";
  }
drop_index_opt
  = head:(alter_algorithm / alter_lock) tail:(__ (alter_algorithm / alter_lock))* {
    return "[Not implemented]";
  }
if_exists
  = KW_IF __ KW_EXISTS {
    return "[Not implemented]";
  }

drop_stmt
  = a:KW_DROP __
    r:KW_TABLE __
    ife: if_exists? __
    t:table_ref_list {
      return "[Not implemented]";
    }
  / a:KW_DROP __
    r:KW_INDEX __
    i:column_ref __
    KW_ON __
    t:table_name __
    op:drop_index_opt? __ {
      return "[Not implemented]";
    }

truncate_stmt
  = a:KW_TRUNCATE  __
    kw:KW_TABLE? __
    t:table_ref_list {
      return "[Not implemented]";
    }

use_stmt
  = KW_USE  __
    d:ident {
      return "[Not implemented]";
    }

alter_table_stmt
  = KW_ALTER  __
    KW_TABLE __
    t:table_name __
    e:alter_action_list {
      return "[Not implemented]";
    }

alter_action_list
  = head:alter_action tail:(__ COMMA __ alter_action)* {
      return "[Not implemented]";
    }

alter_action
  = alter_add_constraint
  / alter_drop_constraint
  / alter_drop_key
  / alter_enable_constraint
  / alter_disable_constraint
  / alter_add_column
  / alter_drop_column
  / alter_add_index_or_key
  / alter_add_fulletxt_sparital_index
  / alter_rename_column
  / alter_rename_table
  / alter_algorithm
  / alter_lock
  / alter_change_column
  / t:table_option {
    return "[Not implemented]";
  }

alter_add_column
  = KW_ADD __
    kc:KW_COLUMN? __
    cd:create_column_definition {
      return "[Not implemented]";
    }

alter_drop_column
  = KW_DROP __
    kc:KW_COLUMN? __
    c:column_ref {
      return "[Not implemented]";
    }

alter_add_index_or_key
  = KW_ADD __
    id:create_index_definition {
      return "[Not implemented]";
    }

alter_rename_table
  = KW_RENAME __
  kw:(KW_TO / KW_AS)? __
  tn:ident {
    return "[Not implemented]";
  }

alter_rename_column
  = KW_RENAME __ KW_COLUMN __ c:column_ref __
  kw:(KW_TO / KW_AS)? __
  tn:column_ref {
    return "[Not implemented]";
  }

alter_algorithm
  = "ALGORITHM"i __ s:"="? __ val:("DEFAULT"i / "INSTANT"i / "INPLACE"i / "COPY"i) {
    return "[Not implemented]";
  }

alter_lock
  = "LOCK"i __ s:"="? __ val:("DEFAULT"i / "NONE"i / "SHARED"i / "EXCLUSIVE"i) {
    return "[Not implemented]";
  }

alter_change_column
  = 'CHANGE'i __ kc:KW_COLUMN? __ od:column_ref __ cd:create_column_definition __ fa:(('FIRST'i / 'AFTER'i) __ column_ref)? {
    return "[Not implemented]";
  }

alter_add_constraint
  = KW_ADD __ c:create_constraint_definition {
    return "[Not implemented]";
  }

alter_drop_key
  = KW_DROP __ 'PRIMARY'i __ KW_KEY {
    return "[Not implemented]";
  }
  / KW_DROP __ 'FOREIGN'i __ KW_KEY __ c:ident_name {
    return "[Not implemented]";
  }

alter_drop_constraint
  = KW_DROP __ kc:'CHECK'i __ c:ident_name {
    return "[Not implemented]";
  }

alter_enable_constraint
  = KW_WITH __ 'CHECK'i __ 'CHECK'i __ KW_CONSTRAINT __ c:ident_name {
    return "[Not implemented]";
  }

alter_disable_constraint
  = 'NOCHECK'i __ KW_CONSTRAINT __ c:ident_name {
    return "[Not implemented]";
  }


create_index_definition
  = kc:(KW_INDEX / KW_KEY) __
    c:column? __
    t:index_type? __
    de:cte_columns_definition __
    id:index_options? __ {
      return "[Not implemented]";
    }

create_fulltext_spatial_index_definition
  = p: (KW_FULLTEXT / KW_SPATIAL) __
    kc:(KW_INDEX / KW_KEY)? __
    c:column? __
    de: cte_columns_definition __
    id: index_options? {
      return "[Not implemented]";
    }

create_constraint_definition
  = create_constraint_primary
  / create_constraint_unique
  / create_constraint_foreign
  / create_constraint_check

constraint_name
  = kc:KW_CONSTRAINT __
  c:ident? {
    return "[Not implemented]";
  }

create_constraint_primary
  = kc:constraint_name? __
  p:(KW_PRIMARY __ KW_KEY) __
  t:index_type? __
  de:cte_columns_definition __
  id:index_options? {
    return "[Not implemented]";
  }

create_constraint_unique
  = kc:constraint_name? __
  u:KW_UNIQUE __
  p:(KW_INDEX / KW_KEY)? __
  i:column? __
  t:index_type? __
  de:cte_columns_definition __
  id:index_options? {
    return "[Not implemented]";
  }

create_constraint_check
  = kc:constraint_name? __ u:KW_CHECK __ nfr:(KW_NOT __ KW_FOR __ KW_REPLICATION __)? LPAREN __ c:expr __ RPAREN {
    return "[Not implemented]";
  }

create_constraint_foreign
  = kc:constraint_name? __
  p:(KW_FOREIGN KW_KEY) __
  i:column? __
  de:cte_columns_definition __
  id:reference_definition? {
    return "[Not implemented]";
  }

check_constraint_definition
  = kc:constraint_name? __ u:KW_CHECK __ LPAREN __ c:expr __ RPAREN __ ne:(KW_NOT? __ KW_ENFORCED)?  {
    return "[Not implemented]";
  }

reference_definition
  = kc:KW_REFERENCES __
  t:table_ref_list __
  de:cte_columns_definition __
  m:(KW_MATCH __ KW_FULL / KW_MATCH __ KW_PARTIAL / KW_MATCH __ KW_SIMPLE)? __
  od:on_reference? __
  ou:on_reference? {
    return "[Not implemented]";
  }
  / oa:on_reference {
    return "[Not implemented]";
  }

on_reference
  = on_kw:KW_ON __ kw:(KW_DELETE / KW_UPDATE) __ ro:reference_option {
    return "[Not implemented]";
  }
reference_option
  = kc:(KW_RESTRICT / KW_CASCADE / KW_SET __ KW_NULL / KW_NO __ KW_ACTION / KW_SET __ KW_DEFAULT / KW_CURRENT_TIMESTAMP) {
    return "[Not implemented]";
  }

table_options
  = head:table_option tail:(__ COMMA? __ table_option)* {
    return "[Not implemented]";
  }

create_option_character_set_kw
  = KW_CHARACTER __ KW_SET {
    return "[Not implemented]";
  }
create_option_character_set
  = kw:KW_DEFAULT? __ t:(create_option_character_set_kw / KW_CHARSET / KW_COLLATE) __ s:("=")? __ v:ident_name {
    return "[Not implemented]";
  }

table_option
  = kw:(KW_AUTO_INCREMENT / KW_AVG_ROW_LENGTH / KW_KEY_BLOCK_SIZE / KW_MAX_ROWS / KW_MIN_ROWS / KW_STATS_SAMPLE_PAGES) __ s:("=")? __ v:literal_numeric {
    return "[Not implemented]";
  }
  / create_option_character_set
  / kw:(KW_COMMENT / KW_CONNECTION) __ s:("=")? __ c:literal_string {
    return "[Not implemented]";
  }
  / kw:KW_COMPRESSION __ s:("=")? __ v:("'"('ZLIB'i / 'LZ4'i / 'NONE'i)"'") {
    return "[Not implemented]";
  }
  / kw:KW_ENGINE __ s:("=")? __ c:ident_name {
    return "[Not implemented]";
  }
  / kw:KW_ROW_FORMAT __ s:("=")? __ c:(KW_DEFAULT / KW_DYNAMIC / KW_FIXED / KW_COMPRESSED / KW_REDUNDANT / KW_COMPACT) {
    return "[Not implemented]";
  }


alter_add_fulletxt_sparital_index
  = KW_ADD __
    fsid:create_fulltext_spatial_index_definition {
      return "[Not implemented]";
    }

rename_stmt
  = KW_RENAME  __
    KW_TABLE __
    t:table_to_list {
      return "[Not implemented]";
    }

set_stmt
  = KW_SET __
  kw: (KW_GLOBAL / KW_SESSION / KW_LOCAL / KW_PERSIST / KW_PERSIST_ONLY)? __
  a: assign_stmt {
    return "[Not implemented]";
  }

unlock_stmt
  = KW_UNLOCK __ KW_TABLES {
    return "[Not implemented]";
  }

lock_type
  = "READ"i __ s:("LOCAL"i)? {
    return "[Not implemented]";
  }
  / p:("LOW_PRIORITY"i)? __ "WRITE"i {
    return "[Not implemented]";
  }

lock_table
  = t:table_base __ lt:lock_type {
    return "[Not implemented]";
  }

lock_table_list
  = head:lock_table tail:(__ COMMA __ lock_table)* {
    return "[Not implemented]";
  }

lock_stmt
  = KW_LOCK __ KW_TABLES __ ltl:lock_table_list {
    return "[Not implemented]";
  }

call_stmt
  = KW_CALL __
  e: proc_func_call {
    return "[Not implemented]";
  }

show_stmt
  = KW_SHOW __ t:('BINARY'i / 'MASTER'i) __ 'LOGS'i {
    return "[Not implemented]";
  }
  / KW_SHOW __ 'BINLOG'i __ 'EVENTS'i __ ins:in_op_right? __ from: from_clause? __ limit: limit_clause? {
    return "[Not implemented]";
  }
  / KW_SHOW __ k:(('CHARACTER'i __ 'SET'i) / 'COLLATION'i) __ e:(like_op_right / where_clause)? {
    return "[Not implemented]";
  }
  / KW_SHOW __ KW_CREATE __ KW_VIEW __ t:table_name {
    return "[Not implemented]";
  }
  / show_grant_stmt

show_grant_stmt
  = KW_SHOW __ 'GRANTS'i __ f:show_grant_for? {
    return "[Not implemented]";
  }

show_grant_for
  = 'FOR'i __ n:ident __ h:("@" __ ident)? __ u:show_grant_for_using? {
    return "[Not implemented]";
  }

show_grant_for_using
  = KW_USING __ l:show_grant_for_using_list {
    return "[Not implemented]";
  }

show_grant_for_using_list
  = head:ident tail:(__ COMMA __ ident)* {
    return "[Not implemented]";
  }

desc_stmt
  = (KW_DESC / KW_DESCRIBE) __ t:ident {
    return "[Not implemented]";
  }

select_stmt
  = select_stmt_nake
  / s:('(' __ select_stmt __ ')') {
      return "[Not implemented]";
    }

with_clause
  = withKw:KW_WITH
    recursiveKw:(c:__ kw:KW_RECURSIVE { return leading(kw, c) })?
    c:__ head:common_table_expression tail:(__ COMMA __ common_table_expression)* {
      return {
        type: "with_clause",
        withKw,
        recursiveKw: nullToUndefined(recursiveKw),
        tables: leading(readCommaSepList(head, tail), c),
      };
    }

common_table_expression
  = table:ident
    columns:(c:__ cols:cte_columns_definition { return {cols, c}; })?
    c1:__ asKw:KW_AS
    opt:(c:__ op:cte_option { return leading(op, c); })?
    c2:__ LPAREN c3:__ select:union_stmt c4:__ RPAREN {
      return {
        type: "common_table_expression",
        table: columns ? trailing(table, columns.c) : table,
        columns: columns ? columns.cols : [],
        asKw: leading(asKw, c1),
        optionKw: nullToUndefined(opt),
        expr: leading(createParenExpr(c3, select, c4), c2),
      };
    }

cte_option
  = kws:(KW_NOT __ KW_MATERIALIZED) { return createKeywordList(kws); }
  / KW_MATERIALIZED

cte_columns_definition
  = LPAREN c1:__ head:ident tail:(__ COMMA __ ident)* c2:__ RPAREN {
      return withComments(readCommaSepList(head, tail), { leading: c1, trailing: c2 });
    }

for_update
  = fu:('FOR'i __ KW_UPDATE) {
    return "[Not implemented]";
  }

lock_in_share_mode
  = m:('LOCK'i __ 'IN'i __ 'SHARE'i __ 'MODE'i) {
    return "[Not implemented]";
  }

lock_option
  = w:('WAIT'i __ literal_numeric) { return "[Not implemented]"; }
  / nw:'NOWAIT'i
  / sl:('SKIP'i __ 'LOCKED'i) { return "[Not implemented]"; }

locking_read
  = t:(for_update / lock_in_share_mode) __ lo:lock_option? {
    return "[Not implemented]";
  }

select_stmt_nake
  = cte:(cls:with_clause c:__ { return trailing(cls, c); })?
    select:(c:__ cls:select_clause { return leading(cls, c); })
    otherClauses:(c:__ cls:other_clause { return leading(cls, c); })* {
      return {
        type: "select_statement",
        clauses: [cte, select, ...otherClauses].filter(identity),
      };
  }

// Other clauses of SELECT statement (besides WITH & SELECT)
other_clause
  = from_clause
  / where_clause
  / group_by_clause
  / having_clause
  / order_by_clause
  / limit_clause
  / locking_read
  / window_clause
  / into_clause

select_clause
  = selectKw:KW_SELECT
    options:(c:__ kw:select_option { return leading(kw, c) })*
    columns:(c:__ cls:select_columns { return leading(cls, c) }) {
      return {
        type: "select_clause",
        selectKw,
        options,
        columns,
      };
    }

select_option
  = KW_ALL
  / KW_DISTINCT

select_option$mysql
  = KW_ALL
  / KW_DISTINCT
  / KW_DISTINCTROW
  / KW_HIGH_PRIORITY
  / KW_STRAIGHT_JOIN
  / KW_SQL_CALC_FOUND_ROWS
  / KW_SQL_CACHE
  / KW_SQL_NO_CACHE
  / KW_SQL_BIG_RESULT
  / KW_SQL_SMALL_RESULT
  / KW_SQL_BUFFER_RESULT

select_columns
  = head:column_list_item tail:(__ COMMA __ column_list_item)* {
      return readCommaSepList(head, tail);
    }

fulltext_search_mode
  = KW_IN __ 'NATURAL'i __ 'LANGUAGE'i __ 'MODE'i __ 'WITH'i __ 'QUERY'i __ 'EXPANSION'i  {
    return "[Not implemented]";
  }
  / KW_IN __ 'NATURAL'i __ 'LANGUAGE'i __ 'MODE'i {
    return "[Not implemented]";
  }
  / KW_IN __ 'BOOLEAN'i __ 'MODE'i {
    return "[Not implemented]";
  }
  / KW_WITH __ 'QUERY'i __ 'EXPANSION'i {
    return "[Not implemented]";
  }

fulltext_search
  = 'MATCH'i __ LPAREN __ c:column_ref_list __ RPAREN __ 'AGAINST' __ LPAREN __ e:expr __ mo:fulltext_search_mode? __ RPAREN __ as:alias_clause? {
    return "[Not implemented]";
  }

column_list_item
  = fs:fulltext_search {
    return "[Not implemented]";
  }
  / STAR {
    return {
      type: "column_ref",
      column: { type: "all_columns" },
    };
  }
  / table:ident c1:__ DOT c2:__ STAR {
    return  {
      type: "column_ref",
      table: trailing(table, c1),
      column: leading({ type: "all_columns" }, c2),
    };
  }
  / a:assign_stmt {
    return "[Not implemented]";
  }
  / expr:expr alias:(__ alias_clause)? {
    return createAlias(expr, alias);
  }

alias_clause
  = kw:KW_AS c:__ id:alias_ident {
    return {
      asKw: kw,
      alias: withComments(id, { leading: c }),
    };
  }
  / id:alias_ident {
    return { alias: id };
  }

into_clause
  = KW_INTO __ v:var_decl_list {
    return "[Not implemented]";
  }
  / KW_INTO __ k:('OUTFILE'i / 'DUMPFILE'i)? __ f:(literal_string / ident) {
    return "[Not implemented]";
  }

from_clause
  = kw:KW_FROM c:__ tables:table_ref_list {
    return {
      type: "from_clause",
      fromKw: withComments(kw, { trailing: c }),
      tables,
    };
  }

table_to_list
  = head:table_to_item tail:(__ COMMA __ table_to_item)* {
    return "[Not implemented]";
  }

table_to_item
  = head:table_name __ KW_TO __ tail: (table_name) {
    return "[Not implemented]";
  }

index_type
  = KW_USING __
  t:("BTREE"i / "HASH"i) {
    return "[Not implemented]";
  }

index_options
  = head:index_option tail:(__ index_option)* {
    return "[Not implemented]";
  }

index_option
  = k:KW_KEY_BLOCK_SIZE __ e:("=")? __ kbs:literal_numeric {
    return "[Not implemented]";
  }
  / index_type
  / "WITH"i __ "PARSER"i __ pn:ident_name {
    return "[Not implemented]";
  }
  / k:("VISIBLE"i / "INVISIBLE"i) {
    return "[Not implemented]";
  }
  / column_option_comment

table_ref_list
  = head:table_base tail:_table_join* {
    return [head, ...tail];
  }

_table_join
  = c:__ join:table_join {
    return withComments(join, { leading: c });
  }

table_join
  = COMMA c:__ table:table_base {
    return {
      type: "join",
      operator: ",",
      table: withComments(table, { leading: c }),
    };
  }
  / op:join_op c1:__ t:table_base spec:(c:__ j:join_specification { return leading(j, c) })? {
    return {
      type: "join",
      operator: op,
      table: withComments(t, { leading: c1 }),
      specification: spec || undefined,
    };
  }

//NOTE that, the table assigned to `var` shouldn't write in `table_join`
table_base
  = KW_DUAL {
    return "[Not implemented]";
  }
  / t:table_name alias:(__ alias_clause)? {
    return createAlias(t, alias);
  }
  / LPAREN c1:__ t:table_name c2:__ RPAREN alias:(__ alias_clause)? {
    return createAlias(createParenExpr(c1, t, c2), alias);
  }
  / stmt:value_clause __ alias:alias_clause? {
    return "[Not implemented]";
  }
  / LPAREN __ stmt:value_clause __ RPAREN __ alias:alias_clause? {
    return "[Not implemented]";
  }
  / LPAREN c1:__ stmt:union_stmt c2:__ RPAREN alias:(__ alias_clause)? {
    return createAlias(createParenExpr(c1, stmt, c2), alias);
  }

join_op
  = kws:(KW_LEFT __ KW_OUTER __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_LEFT __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_RIGHT __ KW_OUTER __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_RIGHT __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_FULL __ KW_OUTER __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_FULL __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_INNER __ KW_JOIN) { return createKeywordList(kws); }
  / kw:KW_JOIN { return createKeywordList([kw]); }

join_op$mysql
  = kws:(KW_LEFT __ KW_OUTER __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_LEFT __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_RIGHT __ KW_OUTER __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_RIGHT __ KW_JOIN) { return createKeywordList(kws); }
  / kws:(KW_INNER __ KW_JOIN) { return createKeywordList(kws); }
  / kw:KW_JOIN { return createKeywordList([kw]); }

table_name
  = db:ident c1:__ DOT c2:__ t:ident {
    return {
      type: "table_ref",
      db: withComments(db, { trailing: c1 }),
      table: withComments(t, { leading: c2 }),
    };
  }
  / t:ident {
    return {
      type: "table_ref",
      table: t,
    };
  }
  / v:var_decl {
    return "[Not implemented]";
  }

join_specification
  = using_clause / on_clause

using_clause
  = kw:KW_USING c1:__ LPAREN c2:__ head:plain_column_ref tail:(__ COMMA __ plain_column_ref)* c3:__ RPAREN {
    const columnList = { type: "expr_list", children: readCommaSepList(head, tail) };
    return {
      type: "join_specification",
      kw,
      expr: withComments(createParenExpr(c2, columnList, c3), { leading: c1 }),
    };
  }

plain_column_ref
  = col:column {
    return { type: "column_ref", column: col };
  }

on_clause
  = kw:KW_ON c:__ expr:expr {
    return {
      type: "join_specification",
      kw,
      expr: withComments(expr, {leading: c}),
    };
  }

where_clause
  = kw:KW_WHERE c:__ expr:expr {
    return {
      type: "where_clause",
      whereKw: kw,
      expr: withComments(expr, {leading: c}),
    };
  }

group_by_clause
  = kws:(KW_GROUP __ KW_BY __) list:expr_list {
    return {
      type: "group_by_clause",
      groupByKw: createKeywordList(kws),
      columns: list.children,
    };
  }

column_ref_list
  = head:column_ref tail:(__ COMMA __ column_ref)* {
      return "[Not implemented]";
    }

having_clause
  = kw:KW_HAVING c:__ expr:expr {
    return {
      type: "having_clause",
      havingKw: kw,
      expr: withComments(expr, {leading: c}),
    };
  }

partition_by_clause
  = KW_PARTITION __ KW_BY __ bc:select_columns { return "[Not implemented]"; }

order_by_clause
  = kws:(KW_ORDER __ KW_BY __) l:order_by_list {
    return {
      type: "order_by_clause",
      orderByKw: createKeywordList(kws),
      specifications: l,
    };
  }

order_by_list
  = head:order_by_element tail:(__ COMMA __ order_by_element)* {
    return readCommaSepList(head, tail);
  }

order_by_element
  = e:expr c:__ orderKw:(KW_DESC / KW_ASC) {
    return {
      type: "sort_specification",
      expr: withComments(e, { trailing: c }),
      orderKw,
    };
  }
  / e:expr {
    return {
      type: "sort_specification",
      expr: e,
    };
  }

number_or_param
  = literal_numeric
  / param
  / '?' {
    return "[Not implemented]";
  }

limit_clause
  = KW_LIMIT __ i1:(number_or_param) __ tail:((COMMA / KW_OFFSET) __ number_or_param)? {
    return "[Not implemented]";
  }

update_stmt
  = KW_UPDATE    __
    t:table_ref_list __
    KW_SET       __
    l:set_list   __
    w:where_clause? __
    or:order_by_clause? __
    lc:limit_clause? {
      return "[Not implemented]";
    }

delete_stmt
  = KW_DELETE    __
    t: table_ref_list? __
    f:from_clause __
    w:where_clause? __
    or:order_by_clause? __
    l:limit_clause? {
      return "[Not implemented]";
    }

set_list
  = head:set_item tail:(__ COMMA __ set_item)* {
      return "[Not implemented]";
    }

/**
 * here only use `additive_expr` to support 'col1 = col1+2'
 * if you want to use lower operator, please use '()' like below
 * 'col1 = (col2 > 3)'
 */
set_item
  = tbl:(ident __ DOT)? __ c:column __ '=' __ v:additive_expr {
    return "[Not implemented]";
  }

insert_value_clause
  = value_clause
  / select_stmt_nake

insert_partition
  = KW_PARTITION __ LPAREN __ head:ident_name tail:(__ COMMA __ ident_name)* __ RPAREN {
    return "[Not implemented]";
  }
  / KW_PARTITION __ v: value_item {
    return "[Not implemented]";
  }

replace_insert_stmt
  = ri:replace_insert       __
    ig:KW_IGNORE?  __
    it:KW_INTO? __
    t:table_name  __
    p:insert_partition? __ LPAREN __ c:column_list  __ RPAREN __
    v:insert_value_clause __
    odp:on_duplicate_update_stmt? {
      return "[Not implemented]";
    }

insert_no_columns_stmt
  = ri:replace_insert __
    ig:KW_IGNORE?  __
    it:KW_INTO?   __
    t:table_name  __
    p:insert_partition? __
    v:insert_value_clause __
    odp: on_duplicate_update_stmt? {
      return "[Not implemented]";
    }

insert_into_set
  = ri:replace_insert __
    KW_INTO __
    t:table_name  __
    p:insert_partition? __
    KW_SET       __
    l:set_list   __
    odp:on_duplicate_update_stmt? {
      return "[Not implemented]";
    }

on_duplicate_update_stmt
  = KW_ON __ 'DUPLICATE'i __ KW_KEY __ KW_UPDATE __ s:set_list {
    return "[Not implemented]";
  }

replace_insert
  = KW_INSERT   { return "[Not implemented]"; }
  / KW_REPLACE  { return "[Not implemented]"; }

value_clause
  = KW_VALUES __ l:value_list  { return "[Not implemented]"; }

value_list
  = head:value_item tail:(__ COMMA __ value_item)* {
    return "[Not implemented]";
  }

value_item
  = 'ROW'i? __ LPAREN __ l:expr_list  __ RPAREN {
    return "[Not implemented]";
  }

expr_list
  = head:expr tail:(__ COMMA __ expr)* {
    return { type: "expr_list", children: readCommaSepList(head, tail) };
  }

interval_expr
  = KW_INTERVAL                    __
    e:expr                       __
    u: interval_unit {
      return "[Not implemented]";
    }

case_expr
  = KW_CASE                         __
    condition_list:case_when_then+  __
    otherwise:case_else?            __
    KW_END __ KW_CASE? {
      return "[Not implemented]";
    }
  / KW_CASE                         __
    expr:expr                      __
    condition_list:case_when_then+  __
    otherwise:case_else?            __
    KW_END __ KW_CASE? {
      return "[Not implemented]";
    }

case_when_then
  = KW_WHEN __ condition:expr __ KW_THEN __ result:expr {
    return "[Not implemented]";
  }

case_else = KW_ELSE __ result:expr {
    return "[Not implemented]";
  }

/**
 * Operator precedence, as implemented currently (though incorrect)
 * ---------------------------------------------------------------------------------------------------
 * | -, ~, !                                                  | negation, bit inversion              |
 * | *, /, DIV, MOD                                           | multiplication, division             |
 * | +, -                                                     | addition, subtraction, concatenation |
 * | =, <, >, <=, >=, <>, !=, <=>, IS, LIKE, BETWEEN, IN      | comparion                            |
 * | NOT                                                      | logical negation                     |
 * | AND, &&                                                  | conjunction                          |
 * | XOR                                                      | exclusive or                         |
 * | OR, ||                                                   | disjunction                          |
 * ---------------------------------------------------------------------------------------------------
 */

expr
  = or_expr
  / union_stmt

or_expr
  = head:xor_expr tail:(__ or_op __ xor_expr)* {
    return createBinaryExprChain(head, tail);
  }

or_op = kw:KW_OR / "||"

xor_expr
  = head:and_expr tail:(__ KW_XOR __ and_expr)* {
    return createBinaryExprChain(head, tail);
  }

and_expr
  = head:not_expr tail:(__ and_op __ not_expr)* {
    return createBinaryExprChain(head, tail);
  }

and_op = kw:KW_AND / "&&"

//here we should use `NOT` instead of `comparision_expr` to support chain-expr
not_expr
  = comparison_expr
  / exists_expr
  / kw:KW_NOT c:__ expr:not_expr {
    return createUnaryExpr(kw, c, expr);
  }

comparison_expr
  = head:additive_expr tail:(__ comparison_op_right)? {
    if (!tail) {
      return head;
    }
    const [c, right] = tail;
    if (right.kind === "arithmetic") {
      // overwrite the first comment (which never matches) in tail,
      // because the comment inside this rule matches first.
      right.tail[0][0] = c;
      return createBinaryExprChain(head, right.tail);
    }
    else if (right.kind === "between") {
      return {
        type: "between_expr",
        left: withComments(head, { trailing: c }),
        betweenKw: right.betweenKw,
        begin: right.begin,
        andKw: right.andKw,
        end: right.end,
      };
    }
    else {
      return createBinaryExpr(head, c, right.op, right.c, right.right);
    }
  }
  / literal_string
  / column_ref

exists_expr
  = op:exists_op __ LPAREN __ stmt:union_stmt __ RPAREN {
    return "[Not implemented]";
  }

exists_op
  = nk:(KW_NOT __ KW_EXISTS) { return "[Not implemented]"; }
  / KW_EXISTS

comparison_op_right
  = arithmetic_op_right
  / in_op_right
  / is_op_right
  / like_op_right
  / regexp_op_right
  / between_op_right

arithmetic_op_right
  = tail:(__ arithmetic_comparison_operator __ additive_expr)+ {
    return { kind: "arithmetic", tail };
  }

arithmetic_comparison_operator
  = "<=>" / ">=" / ">" / "<=" / "<>" / "<" / "=" / "!="

in_op_right
  = op:in_op c1:__ LPAREN  c2:__ list:expr_list c3:__ RPAREN {
    return {
      kind: "in",
      op,
      c: c1,
      right: createParenExpr(c2, list, c3),
    };
  }
  / op:in_op c:__ right:(var_decl / column_ref / literal_string) {
    return { kind: "in", op, c, right };
  }

in_op
  = kws:(KW_NOT __ KW_IN) { return createKeywordList(kws); }
  / kw:KW_IN

is_op_right
  = kw:KW_IS c:__ right:additive_expr {
    return { kind: "is", op: kw, c, right };
  }
  / kws:(KW_IS __ KW_NOT) c:__ right:additive_expr {
    return { kind: "is", op: createKeywordList(kws), c, right };
  }

like_op_right
  = op:like_op c:__ right:(literal / comparison_expr) {
    return { kind: "like", op, c, right };
  }

like_op
  = kws:(KW_NOT __ KW_LIKE) { return createKeywordList(kws); }
  / kw:KW_LIKE

regexp_op_right
  = op:regexp_op c:__ b:'BINARY'i? __ right:(literal_string / column_ref) {
    return { kind: "regexp", op, c, right }; // TODO
  }

regexp_op
  = kws:(KW_NOT __ (KW_REGEXP / KW_RLIKE)) {
    return createKeywordList(kws);
  }
  / KW_REGEXP
  / KW_RLIKE

between_op_right
  = betweenKw:between_op c1:__  begin:additive_expr c2:__ andKw:KW_AND c3:__ end:additive_expr {
    return {
      kind: "between",
      betweenKw,
      begin: withComments(begin, { leading: c1 }),
      andKw: withComments(andKw, { leading: c2 }),
      end: withComments(end, { leading: c3 }),
    };
  }

between_op
  = kws:(KW_NOT __ KW_BETWEEN) { return createKeywordList(kws); }
  / kw:KW_BETWEEN { return createKeywordList([kw]); }

additive_expr
  = head: multiplicative_expr
    tail:(__ additive_operator  __ multiplicative_expr)* {
      return createBinaryExprChain(head, tail);
    }

additive_operator
  = "+" / "-"

multiplicative_expr
  = head:negation_expr
    tail:(__ multiplicative_operator  __ negation_expr)* {
      return createBinaryExprChain(head, tail);
    }

multiplicative_operator
  = "*" / "/" / "%" / '&' / '>>' / '<<' / '^' / '|' / op:KW_DIV / op:KW_MOD

negation_expr
  = primary
  / op:negation_operator c:__ right:negation_expr {
    return createUnaryExpr(op, c, right);
  }

negation_operator = "-" / "~" / "!"

primary
  = cast_expr
  / literal
  / fulltext_search
  / aggr_func
  / func_call
  / case_expr
  / interval_expr
  / column_ref
  / param
  / paren_expr
  / var_decl
  / __ prepared_symbol:'?' {
    return "[Not implemented]";
  }

paren_expr
  = LPAREN c1:__ expr:expr c2:__ RPAREN {
    return createParenExpr(c1, expr, c2);
  }

column_ref
  = tbl:(ident __ DOT __)? col:column __ a:(("->>" / "->") __ (literal_string / literal_numeric))+ __ ca:collate_expr? {
    return "[Not implemented]";
  }
  / tbl:ident c1:__ DOT c2:__ col:qualified_column {
    return {
      type: "column_ref",
      table: withComments(tbl, {trailing: c1}),
      column: withComments(col, {leading: c2}),
    };
  }
  / col:column {
    return {
      type: "column_ref",
      column: col,
    };
  }

column_list
  = head:column tail:(__ COMMA __ column)* {
    return "[Not implemented]";
  }

alias_ident
  = ident
  / s:literal_single_quoted_string { return createIdentifier(s.text); }
  / s:literal_double_quoted_string { return createIdentifier(s.text); }

ident
  = name:ident_name !{ return __RESERVED_KEYWORDS__[name.toUpperCase()] === true; } {
    return createIdentifier(name);
  }
  / quoted_ident

quoted_ident
  = name:backticks_quoted_ident { return createIdentifier(name); }
quoted_ident$mysql
  = name:backticks_quoted_ident { return createIdentifier(name); }
quoted_ident$sqlite
  = name:bracket_quoted_ident { return createIdentifier(name); }
  / name:backticks_quoted_ident { return createIdentifier(name); }
  / str:literal_double_quoted_string { return createIdentifier(str.text); }

backticks_quoted_ident
  = q:"`" chars:([^`] / "``")+ "`" { return text(); }

bracket_quoted_ident
  = q:"[" chars:([^\]] / "]]")+ "]" { return text(); }

// Keywords can be used as column names when they are prefixed by table name, like tbl.update
qualified_column
  = name:ident_name {
    return createIdentifier(name);
  }
  / quoted_ident

column
  = ident

ident_name
  = ident_start ident_part* { return text(); }
  / [0-9]+ ident_start ident_part* { return text(); }

ident_start = [A-Za-z_]

ident_part  = [A-Za-z0-9_]

param
  = l:(':' ident_name) {
      return "[Not implemented]";
    }

aggr_func
  = aggr_fun_count
  / aggr_fun_smma

aggr_fun_smma
  = name:KW_SUM_MAX_MIN_AVG  __ LPAREN __ e:additive_expr __ RPAREN __ bc:over_partition? {
      return "[Not implemented]";
    }

KW_SUM_MAX_MIN_AVG
  = KW_SUM / KW_MAX / KW_MIN / KW_AVG

on_update_current_timestamp
  = KW_ON __ KW_UPDATE __ kw:KW_CURRENT_TIMESTAMP __ LPAREN __ l:expr_list? __ RPAREN{
    return "[Not implemented]";
  }
  / KW_ON __ KW_UPDATE __ kw:KW_CURRENT_TIMESTAMP {
    return "[Not implemented]";
  }

over_partition
  = 'OVER'i __ aws:as_window_specification {
    return "[Not implemented]";
  }
  / on_update_current_timestamp

window_clause
  = 'WINDOW'i __ l:named_window_expr_list {
    return "[Not implemented]";
  }

named_window_expr_list
  = head:named_window_expr tail:(__ COMMA __ named_window_expr)* {
    return "[Not implemented]";
  }

named_window_expr
  = nw:ident_name __ KW_AS __ anw:as_window_specification {
    return "[Not implemented]";
  }

as_window_specification
  = ident_name
  / LPAREN __ ws:window_specification? __ RPAREN {
    return "[Not implemented]";
  }

window_specification
  = bc:partition_by_clause? __ l:order_by_clause? __ w:window_frame_clause? {
    return "[Not implemented]";
  }

window_specification_frameless
  = bc:partition_by_clause? __
  l:order_by_clause? {
    return "[Not implemented]";
  }

window_frame_clause
  = kw:KW_ROWS __ s:(window_frame_following / window_frame_preceding) {
    return "[Not implemented]";
  }
  / KW_ROWS __ KW_BETWEEN __ p:window_frame_preceding __ KW_AND __ f:window_frame_following {
    return "[Not implemented]";
  }

window_frame_following
  = s:window_frame_value __ 'FOLLOWING'i  {
    return "[Not implemented]";
  }
  / window_frame_current_row

window_frame_preceding
  = s:window_frame_value __ 'PRECEDING'i  {
    return "[Not implemented]";
  }
  / window_frame_current_row

window_frame_current_row
  = 'CURRENT'i __ 'ROW'i {
    return "[Not implemented]";
  }

window_frame_value
  = s:'UNBOUNDED'i {
    return "[Not implemented]";
  }
  / literal_numeric

aggr_fun_count
  = name:(KW_COUNT / KW_GROUP_CONCAT) __ LPAREN __ arg:count_arg __ RPAREN __ bc:over_partition? {
    return "[Not implemented]";
  }

count_arg
  = e:star_expr {
    return "[Not implemented]";
  }
  / d:KW_DISTINCT? __ LPAREN __ c:expr __ RPAREN __ or:order_by_clause? {
    return "[Not implemented]";
  }
  / d:KW_DISTINCT? __ c:primary __ or:order_by_clause? {
    return "[Not implemented]";
  }

star_expr
  = "*" { return "[Not implemented]"; }

convert_args
  = c:(column_ref / literal_string) __ COMMA __ ch:data_type  __ cs:create_option_character_set_kw __ v:ident_name {
    return "[Not implemented]";
  }
  / c:(column_ref / literal_string) __ COMMA __ d:data_type {
    return "[Not implemented]";
  }
  / c:(column_ref / literal_string) __ KW_USING __ d:ident_name {
    return "[Not implemented]";
  }

trim_position
  = 'BOTH'i / 'LEADING'i / 'TRAILING'i

trim_rem
  = p:trim_position? __ rm:literal_string? __ k:KW_FROM {
    return "[Not implemented]";
  }

trim_func_clause
  = 'trim'i __ LPAREN __ tr:trim_rem? __ s:expr __ RPAREN {
    return "[Not implemented]";
  }
func_call
  = trim_func_clause
  / 'convert'i __ LPAREN __ l:convert_args __ RPAREN __ ca:collate_expr? {
    return "[Not implemented]";
  }
  / name:proc_func_name __ LPAREN __ l:expr? __ RPAREN __ bc:over_partition? {
    return "[Not implemented]";
  }
  / name:scalar_func __ LPAREN __ l:expr_list? __ RPAREN __ bc:over_partition? {
    return "[Not implemented]";
  }
  / f:KW_CURRENT_TIMESTAMP __ up:on_update_current_timestamp? {
    return "[Not implemented]";
  }

scalar_func
  = KW_CURRENT_DATE
  / KW_CURRENT_TIME
  / KW_CURRENT_TIMESTAMP
  / KW_CURRENT_USER
  / KW_USER
  / KW_SESSION_USER
  / KW_SYSTEM_USER

cast_expr
  = KW_CAST __ LPAREN __ e:expr __ KW_AS __ ch:data_type  __ cs:create_option_character_set_kw __ v:ident_name __ RPAREN __ ca:collate_expr? {
    return "[Not implemented]";
  }
  / KW_CAST __ LPAREN __ e:expr __ KW_AS __ t:data_type __ RPAREN {
    return "[Not implemented]";
  }
  / KW_CAST __ LPAREN __ e:expr __ KW_AS __ KW_DECIMAL __ LPAREN __ precision:int __ RPAREN __ RPAREN {
    return "[Not implemented]";
  }
  / KW_CAST __ LPAREN __ e:expr __ KW_AS __ KW_DECIMAL __ LPAREN __ precision:int __ COMMA __ scale:int __ RPAREN __ RPAREN {
    return "[Not implemented]";
  }
  / KW_CAST __ LPAREN __ e:expr __ KW_AS __ s:signedness __ t:KW_INTEGER? __ RPAREN { /* MySQL cast to un-/signed integer */
    return "[Not implemented]";
  }

signedness
  = KW_SIGNED
  / KW_UNSIGNED

literal
  = b:'BINARY'i? __ s:literal_string ca:(__ collate_expr)? {
    return s; // TODO
  }
  / literal_numeric
  / literal_bool
  / literal_null
  / literal_datetime

literal_null
  = kw:KW_NULL {
    return { type: "null", text: kw.text };
  }

literal_bool
  = kw:KW_TRUE {
    return { type: "bool", text: kw.text };
  }
  / kw:KW_FALSE {
    return { type: "bool", text: kw.text};
  }

literal_string
  = charset:charset_introducer c:__ string:literal_string_without_charset {
    return {
      type: "string_with_charset",
      charset,
      string: withComments(string, { leading: c }),
    };
  }
  / literal_string_without_charset
  / literal_natural_charset_string

charset_introducer
  = "_" cs:charset_name !ident_start { return cs; }

// these are sorted by length, so we try to match first the longest
charset_name
  = "armscii8"i
  / "macroman"i
  / "keybcs2"i
  / "utf8mb4"i
  / "utf16le"i
  / "geostd8"i
  / "eucjpms"i
  / "gb18030"i
  / "latin1"i
  / "latin2"i
  / "hebrew"i
  / "tis620"i
  / "gb2312"i
  / "cp1250"i
  / "latin5"i
  / "latin7"i
  / "cp1251"i
  / "cp1256"i
  / "cp1257"i
  / "binary"i
  / "cp850"i
  / "koi8r"i
  / "ascii"i
  / "euckr"i
  / "koi8u"i
  / "greek"i
  / "cp866"i
  / "macce"i
  / "cp852"i
  / "utf16"i
  / "utf32"i
  / "cp932"i
  / "big5"i
  / "dec8"i
  / "swe7"i
  / "ujis"i
  / "sjis"i
  / "utf8"i
  / "ucs2"i
  / "hp8"i
  / "gbk"i

literal_string_without_charset
  = literal_hex_string
  / literal_bit_string
  / literal_hex_sequence
  / literal_single_quoted_string

literal_string_without_charset$mysql
  = literal_hex_string
  / literal_bit_string
  / literal_hex_sequence
  / literal_single_quoted_string
  / literal_double_quoted_string

literal_hex_string
  = 'X'i "'" [0-9A-Fa-f]* "'" {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_bit_string
  = 'b'i "'" [01]* "'" {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_hex_sequence
  = '0x' [0-9A-Fa-f]* {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_single_quoted_string
  = "'" single_quoted_char* "'" {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_double_quoted_string
  = "\"" double_quoted_char* "\"" {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_natural_charset_string
  = "N"i literal_single_quoted_string {
    return {
      type: 'string',
      text: text(),
    };
  }

literal_datetime
  = kw:(KW_TIME / KW_DATE / KW_TIMESTAMP / KW_DATETIME) c:__
    str:(literal_single_quoted_string / literal_double_quoted_string) {
      return {
        type: "datetime",
        kw,
        string: withComments(str, { leading: c })
      };
    }

double_quoted_char
  = [^"\\\0-\x1F\x7f]
  / escape_char

single_quoted_char
  = [^'\\] // remove \0-\x1F\x7f pnCtrl char [^'\\\0-\x1F\x7f]
  / escape_char

escape_char
  = "\\'"  { return "\\'";  }
  / '\\"'  { return '\\"';  }
  / "\\\\" { return "\\\\"; }
  / "\\/"  { return "\\/";  }
  / "\\b"  { return "\b"; }
  / "\\f"  { return "\f"; }
  / "\\n"  { return "\n"; }
  / "\\r"  { return "\r"; }
  / "\\t"  { return "\t"; }
  / "\\u" h1:hexDigit h2:hexDigit h3:hexDigit h4:hexDigit {
      return String.fromCharCode(parseInt("0x" + h1 + h2 + h3 + h4));
    }
  / "\\" { return "\\"; }
  / "''" { return "''" }
  / '""' { return '""' }

line_terminator
  = [\n\r]

literal_numeric
  = int frac? exp? !ident_start {
    return {
      type: 'number',
      text: text(),
    };
  }

int
  = digits
  / [+-] digits { return text(); }

frac
  = "." digits

exp
  = [eE] [+-]? digits

digits
  = [0-9]+ { return text(); }

hexDigit
  = [0-9a-fA-F]

// separator
__
  = xs:(whitespace / comment)* {
    return xs.filter((ws) => isObject(ws) && options.preserveComments);
  }

comment
  = block_comment
  / line_comment
  / pound_sign_comment

block_comment
  = "/*" (!"*/" char)* "*/" {
    return {
      type: "block_comment",
      text: text(),
    };
  }

line_comment
  = "--" (!EOL char)* {
    return {
      type: "line_comment",
      text: text(),
    };
  }

pound_sign_comment
  = "#" (!EOL char)* {
    return {
      type: "line_comment",
      text: text(),
    };
  }

char = .

interval_unit
  = KW_UNIT_YEAR
  / KW_UNIT_MONTH
  / KW_UNIT_DAY
  / KW_UNIT_HOUR
  / KW_UNIT_MINUTE
  / KW_UNIT_SECOND

whitespace =
  [ \t\n\r]

EOL
  = EOF
  / [\n\r]+

EOF = !.

proc_stmt
  = __ s:(assign_stmt / return_stmt) {
    return "[Not implemented]";
  }

assign_stmt
  = va:(var_decl / without_prefix_var_decl) __ s: (":=" / "=") __ e:proc_expr {
    return "[Not implemented]";
  }

return_stmt
  = KW_RETURN __ e:proc_expr {
    return "[Not implemented]";
  }

proc_expr
  = select_stmt
  / proc_join
  / proc_additive_expr
  / proc_array

proc_additive_expr
  = head:proc_multiplicative_expr
    tail:(__ additive_operator  __ proc_multiplicative_expr)* {
      return "[Not implemented]";
    }

proc_multiplicative_expr
  = head:proc_primary
    tail:(__ multiplicative_operator  __ proc_primary)* {
      return "[Not implemented]";
    }

proc_join
  = lt:var_decl __ op:join_op  __ rt:var_decl __ expr:on_clause {
    return "[Not implemented]";
  }

proc_primary
  = literal
  / var_decl
  / column_ref
  / proc_func_call
  / param
  / LPAREN __ e:proc_additive_expr __ RPAREN {
    return "[Not implemented]";
  }

proc_func_name
  = dt:ident tail:(__ DOT __ ident)? {
    return "[Not implemented]";
  }
  / n:ident_name {
    return "[Not implemented]";
  }
  / quoted_ident

proc_func_call
  = name:proc_func_name __ LPAREN __ l:proc_primary_list? __ RPAREN {
    return "[Not implemented]";
  }
  / name:proc_func_name {
    return "[Not implemented]";
  }

proc_primary_list
  = head:proc_primary tail:(__ COMMA __ proc_primary)* {
    return "[Not implemented]";
  }

proc_array =
  LBRAKE __ l:proc_primary_list __ RBRAKE {
    return "[Not implemented]";
  }

var_decl_list
  = head:var_decl tail:(__ COMMA __ var_decl)* {
    return "[Not implemented]";
  }

var_decl
  = p:var_prefix d: without_prefix_var_decl {
    return "[Not implemented]";
  }

var_prefix = "@@" / "@" / "$"

without_prefix_var_decl
  = name:ident_name m:mem_chain {
    return "[Not implemented]";
  }

mem_chain
  = l:('.' ident_name)* {
    return "[Not implemented]";
  }

data_type
  = kw:type_name c:__ params:type_params {
    return { type: "data_type", nameKw: trailing(kw, c), params };
  }
  / kw:type_name {
    return { type: "data_type", nameKw: kw };
  }

type_params
  = LPAREN c1:__ head:literal tail:(__ COMMA __ literal)* c2:__ RPAREN {
    const params = readCommaSepList(head, tail);
    return withComments(params, {leading: c1, trailing: c2});
  }

type_name
  = KW_BOOLEAN
  / KW_BOOL
  / KW_BLOB
  / KW_TINYBLOB
  / KW_MEDIUMBLOB
  / KW_LONGBLOB
  / KW_BINARY
  / KW_VARBINARY
  / KW_DATE
  / KW_DATETIME
  / KW_TIME
  / KW_TIMESTAMP
  / KW_YEAR
  / KW_CHAR
  / KW_VARCHAR
  / KW_TINYTEXT
  / KW_TEXT
  / KW_MEDIUMTEXT
  / KW_LONGTEXT
  / KW_NUMERIC
  / KW_FIXED
  / KW_DECIMAL
  / KW_DEC
  / KW_INT
  / KW_INTEGER
  / KW_SMALLINT
  / KW_TINYINT
  / KW_BIGINT
  / KW_FLOAT
  / kws:(KW_DOUBLE __ KW_PRECISION) { return createKeywordList(kws); }
  / KW_DOUBLE
  / KW_REAL
  / KW_BIT
  / KW_JSON
  / KW_ENUM
  / KW_SET

// All keywords (sorted alphabetically)
KW_ACTION              = kw:"ACTION"i              !ident_part { return createKeyword(kw); }
KW_ADD                 = kw:"ADD"i                 !ident_part { return createKeyword(kw); }
KW_ADD_DATE            = kw:"ADDDATE"i             !ident_part { return createKeyword(kw); }
KW_ALL                 = kw:"ALL"i                 !ident_part { return createKeyword(kw); }
KW_ALTER               = kw:"ALTER"i               !ident_part { return createKeyword(kw); }
KW_AND                 = kw:"AND"i                 !ident_part { return createKeyword(kw); }
KW_AS                  = kw:"AS"i                  !ident_part { return createKeyword(kw); }
KW_ASC                 = kw:"ASC"i                 !ident_part { return createKeyword(kw); }
KW_AUTO_INCREMENT      = kw:"AUTO_INCREMENT"i      !ident_part { return createKeyword(kw); }
KW_AVG                 = kw:"AVG"i                 !ident_part { return createKeyword(kw); }
KW_AVG_ROW_LENGTH      = kw:"AVG_ROW_LENGTH"i      !ident_part { return createKeyword(kw); }
KW_BETWEEN             = kw:"BETWEEN"i             !ident_part { return createKeyword(kw); }
KW_BIGINT              = kw:"BIGINT"i              !ident_part { return createKeyword(kw); }
KW_BINARY              = kw:"BINARY"i              !ident_part { return createKeyword(kw); }
KW_BIT                 = kw:"BIT"i                 !ident_part { return createKeyword(kw); }
KW_BLOB                = kw:"BLOB"i                !ident_part { return createKeyword(kw); }
KW_BOOL                = kw:"BOOL"i                !ident_part { return createKeyword(kw); }
KW_BOOLEAN             = kw:"BOOLEAN"i             !ident_part { return createKeyword(kw); }
KW_BY                  = kw:"BY"i                  !ident_part { return createKeyword(kw); }
KW_CALL                = kw:"CALL"i                !ident_part { return createKeyword(kw); }
KW_CASCADE             = kw:"CASCADE"i             !ident_part { return createKeyword(kw); }
KW_CASE                = kw:"CASE"i                !ident_part { return createKeyword(kw); }
KW_CAST                = kw:"CAST"i                !ident_part { return createKeyword(kw); }
KW_CHAR                = kw:"CHAR"i                !ident_part { return createKeyword(kw); }
KW_CHARACTER           = kw:"CHARACTER"i           !ident_part { return createKeyword(kw); }
KW_CHARSET             = kw:"CHARSET"i             !ident_part { return createKeyword(kw); }
KW_CHECK               = kw:"CHECK"i               !ident_part { return createKeyword(kw); }
KW_COLLATE             = kw:"COLLATE"i             !ident_part { return createKeyword(kw); }
KW_COLUMN              = kw:"COLUMN"i              !ident_part { return createKeyword(kw); }
KW_COLUMN_FORMAT       = kw:"COLUMN_FORMAT"i       !ident_part { return createKeyword(kw); }
KW_COMMENT             = kw:"COMMENT"i             !ident_part { return createKeyword(kw); }
KW_COMPACT             = kw:"COMPACT"i             !ident_part { return createKeyword(kw); }
KW_COMPRESSED          = kw:"COMPRESSED"i          !ident_part { return createKeyword(kw); }
KW_COMPRESSION         = kw:"COMPRESSION"i         !ident_part { return createKeyword(kw); }
KW_CONNECTION          = kw:"CONNECTION"i          !ident_part { return createKeyword(kw); }
KW_CONSTRAINT          = kw:"CONSTRAINT"i          !ident_part { return createKeyword(kw); }
KW_COUNT               = kw:"COUNT"i               !ident_part { return createKeyword(kw); }
KW_CREATE              = kw:"CREATE"i              !ident_part { return createKeyword(kw); }
KW_CURRENT_DATE        = kw:"CURRENT_DATE"i        !ident_part { return createKeyword(kw); }
KW_CURRENT_TIME        = kw:"CURRENT_TIME"i        !ident_part { return createKeyword(kw); }
KW_CURRENT_TIMESTAMP   = kw:"CURRENT_TIMESTAMP"i   !ident_part { return createKeyword(kw); }
KW_CURRENT_USER        = kw:"CURRENT_USER"i        !ident_part { return createKeyword(kw); }
KW_DATABASE            = kw:"DATABASE"i            !ident_part { return createKeyword(kw); }
KW_DATE                = kw:"DATE"i                !ident_part { return createKeyword(kw); }
KW_DATETIME            = kw:"DATETIME"i            !ident_part { return createKeyword(kw); }
KW_DEC                 = kw:"DEC"i                 !ident_part { return createKeyword(kw); }
KW_DECIMAL             = kw:"DECIMAL"i             !ident_part { return createKeyword(kw); }
KW_DEFAULT             = kw:"DEFAULT"i             !ident_part { return createKeyword(kw); }
KW_DELETE              = kw:"DELETE"i              !ident_part { return createKeyword(kw); }
KW_DESC                = kw:"DESC"i                !ident_part { return createKeyword(kw); }
KW_DESCRIBE            = kw:"DESCRIBE"i            !ident_part { return createKeyword(kw); }
KW_DISK                = kw:"DISK"i                !ident_part { return createKeyword(kw); }
KW_DISTINCT            = kw:"DISTINCT"i            !ident_part { return createKeyword(kw); }
KW_DISTINCTROW         = kw:"DISTINCTROW"i         !ident_part { return createKeyword(kw); }
KW_DIV                 = kw:"DIV"i                 !ident_part { return createKeyword(kw); }
KW_DOUBLE              = kw:"DOUBLE"i              !ident_part { return createKeyword(kw); }
KW_DROP                = kw:"DROP"i                !ident_part { return createKeyword(kw); }
KW_DUAL                = kw:"DUAL"i                !ident_part { return createKeyword(kw); }
KW_DYNAMIC             = kw:"DYNAMIC"i             !ident_part { return createKeyword(kw); }
KW_ELSE                = kw:"ELSE"i                !ident_part { return createKeyword(kw); }
KW_END                 = kw:"END"i                 !ident_part { return createKeyword(kw); }
KW_ENFORCED            = kw:"ENFORCED"i            !ident_part { return createKeyword(kw); }
KW_ENGINE              = kw:"ENGINE"i              !ident_part { return createKeyword(kw); }
KW_ENUM                = kw:"ENUM"i                !ident_part { return createKeyword(kw); }
KW_EXISTS              = kw:"EXISTS"i              !ident_part { return createKeyword(kw); }
KW_EXPLAIN             = kw:"EXPLAIN"i             !ident_part { return createKeyword(kw); }
KW_FALSE               = kw:"FALSE"i               !ident_part { return createKeyword(kw); }
KW_FIXED               = kw:"FIXED"i               !ident_part { return createKeyword(kw); }
KW_FLOAT               = kw:"FLOAT"i               !ident_part { return createKeyword(kw); }
KW_FOR                 = kw:"FOR"i                 !ident_part { return createKeyword(kw); }
KW_FOREIGN             = kw:"FOREIGN"i             !ident_part { return createKeyword(kw); }
KW_FROM                = kw:"FROM"i                !ident_part { return createKeyword(kw); }
KW_FULL                = kw:"FULL"i                !ident_part { return createKeyword(kw); }
KW_FULLTEXT            = kw:"FULLTEXT"i            !ident_part { return createKeyword(kw); }
KW_GLOBAL              = kw:"GLOBAL"i              !ident_part { return createKeyword(kw); }
KW_GO                  = kw:"GO"i                  !ident_part { return createKeyword(kw); }
KW_GROUP               = kw:"GROUP"i               !ident_part { return createKeyword(kw); }
KW_GROUP_CONCAT        = kw:"GROUP_CONCAT"i        !ident_part { return createKeyword(kw); }
KW_HAVING              = kw:"HAVING"i              !ident_part { return createKeyword(kw); }
KW_HIGH_PRIORITY       = kw:"HIGH_PRIORITY"i       !ident_part { return createKeyword(kw); }
KW_IF                  = kw:"IF"i                  !ident_part { return createKeyword(kw); }
KW_IGNORE              = kw:"IGNORE"i              !ident_part { return createKeyword(kw); }
KW_IN                  = kw:"IN"i                  !ident_part { return createKeyword(kw); }
KW_INDEX               = kw:"INDEX"i               !ident_part { return createKeyword(kw); }
KW_INNER               = kw:"INNER"i               !ident_part { return createKeyword(kw); }
KW_INSERT              = kw:"INSERT"i              !ident_part { return createKeyword(kw); }
KW_INT                 = kw:"INT"i                 !ident_part { return createKeyword(kw); }
KW_INTEGER             = kw:"INTEGER"i             !ident_part { return createKeyword(kw); }
KW_INTERVAL            = kw:"INTERVAL"i            !ident_part { return createKeyword(kw); }
KW_INTO                = kw:"INTO"i                !ident_part { return createKeyword(kw); }
KW_IS                  = kw:"IS"i                  !ident_part { return createKeyword(kw); }
KW_JOIN                = kw:"JOIN"i                !ident_part { return createKeyword(kw); }
KW_JSON                = kw:"JSON"i                !ident_part { return createKeyword(kw); }
KW_KEY                 = kw:"KEY"i                 !ident_part { return createKeyword(kw); }
KW_KEY_BLOCK_SIZE      = kw:"KEY_BLOCK_SIZE"i      !ident_part { return createKeyword(kw); }
KW_LEFT                = kw:"LEFT"i                !ident_part { return createKeyword(kw); }
KW_LIKE                = kw:"LIKE"i                !ident_part { return createKeyword(kw); }
KW_LIMIT               = kw:"LIMIT"i               !ident_part { return createKeyword(kw); }
KW_LOCAL               = kw:"LOCAL"i               !ident_part { return createKeyword(kw); }
KW_LOCK                = kw:"LOCK"i                !ident_part { return createKeyword(kw); }
KW_LONGBLOB            = kw:"LONGBLOB"i            !ident_part { return createKeyword(kw); }
KW_LONGTEXT            = kw:"LONGTEXT"i            !ident_part { return createKeyword(kw); }
KW_MATCH               = kw:"MATCH"i               !ident_part { return createKeyword(kw); }
KW_MATERIALIZED        = kw:"MATERIALIZED"i        !ident_part { return createKeyword(kw); }
KW_MAX                 = kw:"MAX"i                 !ident_part { return createKeyword(kw); }
KW_MAX_ROWS            = kw:"MAX_ROWS"i            !ident_part { return createKeyword(kw); }
KW_MEDIUMBLOB          = kw:"MEDIUMBLOB"i          !ident_part { return createKeyword(kw); }
KW_MEDIUMTEXT          = kw:"MEDIUMTEXT"i          !ident_part { return createKeyword(kw); }
KW_MEMORY              = kw:"MEMORY"i              !ident_part { return createKeyword(kw); }
KW_MIN                 = kw:"MIN"i                 !ident_part { return createKeyword(kw); }
KW_MIN_ROWS            = kw:"MIN_ROWS"i            !ident_part { return createKeyword(kw); }
KW_MOD                 = kw:"MOD"i                 !ident_part { return createKeyword(kw); }
KW_NO                  = kw:"NO"i                  !ident_part { return createKeyword(kw); }
KW_NOT                 = kw:"NOT"i                 !ident_part { return createKeyword(kw); }
KW_NULL                = kw:"NULL"i                !ident_part { return createKeyword(kw); }
KW_NUMERIC             = kw:"NUMERIC"i             !ident_part { return createKeyword(kw); }
KW_OFFSET              = kw:"OFFSET"i              !ident_part { return createKeyword(kw); }
KW_ON                  = kw:"ON"i                  !ident_part { return createKeyword(kw); }
KW_OR                  = kw:"OR"i                  !ident_part { return createKeyword(kw); }
KW_ORDER               = kw:"ORDER"i               !ident_part { return createKeyword(kw); }
KW_OUTER               = kw:"OUTER"i               !ident_part { return createKeyword(kw); }
KW_OVER                = kw:"OVER"i                !ident_part { return createKeyword(kw); }
KW_PARTIAL             = kw:"PARTIAL"i             !ident_part { return createKeyword(kw); }
KW_PARTITION           = kw:"PARTITION"i           !ident_part { return createKeyword(kw); }
KW_PERSIST             = kw:"PERSIST"i             !ident_part { return createKeyword(kw); }
KW_PERSIST_ONLY        = kw:"PERSIST_ONLY"i        !ident_part { return createKeyword(kw); }
KW_PRECISION           = kw:"PRECISION"i           !ident_part { return createKeyword(kw); }
KW_PRIMARY             = kw:"PRIMARY"i             !ident_part { return createKeyword(kw); }
KW_REAL                = kw:"REAL"i                !ident_part { return createKeyword(kw); }
KW_RECURSIVE           = kw:"RECURSIVE"            !ident_part { return createKeyword(kw); }
KW_REDUNDANT           = kw:"REDUNDANT"i           !ident_part { return createKeyword(kw); }
KW_REFERENCES          = kw:"REFERENCES"i          !ident_part { return createKeyword(kw); }
KW_REGEXP              = kw:"REGEXP"i              !ident_part { return createKeyword(kw); }
KW_RENAME              = kw:"RENAME"i              !ident_part { return createKeyword(kw); }
KW_REPLACE             = kw:"REPLACE"i             !ident_part { return createKeyword(kw); }
KW_REPLICATION         = kw:"REPLICATION"i         !ident_part { return createKeyword(kw); }
KW_RESTRICT            = kw:"RESTRICT"i            !ident_part { return createKeyword(kw); }
KW_RETURN              = kw:'RETURN'i              !ident_part { return createKeyword(kw); }
KW_RIGHT               = kw:"RIGHT"i               !ident_part { return createKeyword(kw); }
KW_RLIKE               = kw:"RLIKE"i               !ident_part { return createKeyword(kw); }
KW_ROW_FORMAT          = kw:"ROW_FORMAT"i          !ident_part { return createKeyword(kw); }
KW_ROWS                = kw:"ROWS"i                !ident_part { return createKeyword(kw); }
KW_SCHEME              = kw:"SCHEME"i              !ident_part { return createKeyword(kw); }
KW_SELECT              = kw:"SELECT"i              !ident_part { return createKeyword(kw); }
KW_SESSION             = kw:"SESSION"i             !ident_part { return createKeyword(kw); }
KW_SESSION_USER        = kw:"SESSION_USER"i        !ident_part { return createKeyword(kw); }
KW_SET                 = kw:"SET"i                 !ident_part { return createKeyword(kw); }
KW_SHOW                = kw:"SHOW"i                !ident_part { return createKeyword(kw); }
KW_SIGNED              = kw:"SIGNED"i              !ident_part { return createKeyword(kw); }
KW_SIMPLE              = kw:"SIMPLE"i              !ident_part { return createKeyword(kw); }
KW_SMALLINT            = kw:"SMALLINT"i            !ident_part { return createKeyword(kw); }
KW_SPATIAL             = kw:"SPATIAL"i             !ident_part { return createKeyword(kw); }
KW_SQL_BIG_RESULT      = kw:"SQL_BIG_RESULT"i      !ident_part { return createKeyword(kw); }
KW_SQL_BUFFER_RESULT   = kw:"SQL_BUFFER_RESULT"i   !ident_part { return createKeyword(kw); }
KW_SQL_CACHE           = kw:"SQL_CACHE"i           !ident_part { return createKeyword(kw); }
KW_SQL_CALC_FOUND_ROWS = kw:"SQL_CALC_FOUND_ROWS"i !ident_part { return createKeyword(kw); }
KW_SQL_NO_CACHE        = kw:"SQL_NO_CACHE"i        !ident_part { return createKeyword(kw); }
KW_SQL_SMALL_RESULT    = kw:"SQL_SMALL_RESULT"i    !ident_part { return createKeyword(kw); }
KW_STATS_SAMPLE_PAGES  = kw:"STATS_SAMPLE_PAGES"i  !ident_part { return createKeyword(kw); }
KW_STORAGE             = kw:"STORAGE"i             !ident_part { return createKeyword(kw); }
KW_STRAIGHT_JOIN       = kw:"STRAIGHT_JOIN"i       !ident_part { return createKeyword(kw); }
KW_SUM                 = kw:"SUM"i                 !ident_part { return createKeyword(kw); }
KW_SYSTEM_USER         = kw:"SYSTEM_USER"i         !ident_part { return createKeyword(kw); }
KW_TABLE               = kw:"TABLE"i               !ident_part { return createKeyword(kw); }
KW_TABLES              = kw:"TABLES"i              !ident_part { return createKeyword(kw); }
KW_TEMPORARY           = kw:"TEMPORARY"i           !ident_part { return createKeyword(kw); }
KW_TEXT                = kw:"TEXT"i                !ident_part { return createKeyword(kw); }
KW_THEN                = kw:"THEN"i                !ident_part { return createKeyword(kw); }
KW_TIME                = kw:"TIME"i                !ident_part { return createKeyword(kw); }
KW_TIMESTAMP           = kw:"TIMESTAMP"i           !ident_part { return createKeyword(kw); }
KW_TINYBLOB            = kw:"TINYBLOB"i            !ident_part { return createKeyword(kw); }
KW_TINYINT             = kw:"TINYINT"i             !ident_part { return createKeyword(kw); }
KW_TINYTEXT            = kw:"TINYTEXT"i            !ident_part { return createKeyword(kw); }
KW_TO                  = kw:"TO"i                  !ident_part { return createKeyword(kw); }
KW_TRUE                = kw:"TRUE"i                !ident_part { return createKeyword(kw); }
KW_TRUNCATE            = kw:"TRUNCATE"i            !ident_part { return createKeyword(kw); }
KW_UNION               = kw:"UNION"i               !ident_part { return createKeyword(kw); }
KW_UNIQUE              = kw:"UNIQUE"i              !ident_part { return createKeyword(kw); }
KW_UNIT_DAY            = kw:"DAY"i                 !ident_part { return createKeyword(kw); }
KW_UNIT_HOUR           = kw:"HOUR"i                !ident_part { return createKeyword(kw); }
KW_UNIT_MINUTE         = kw:"MINUTE"i              !ident_part { return createKeyword(kw); }
KW_UNIT_MONTH          = kw:"MONTH"i               !ident_part { return createKeyword(kw); }
KW_UNIT_SECOND         = kw:"SECOND"i              !ident_part { return createKeyword(kw); }
KW_UNIT_YEAR           = kw:"YEAR"i                !ident_part { return createKeyword(kw); }
KW_UNLOCK              = kw:"UNLOCK"i              !ident_part { return createKeyword(kw); }
KW_UNSIGNED            = kw:"UNSIGNED"i            !ident_part { return createKeyword(kw); }
KW_UPDATE              = kw:"UPDATE"i              !ident_part { return createKeyword(kw); }
KW_USE                 = kw:"USE"i                 !ident_part { return createKeyword(kw); }
KW_USER                = kw:"USER"i                !ident_part { return createKeyword(kw); }
KW_USING               = kw:"USING"i               !ident_part { return createKeyword(kw); }
KW_VALUES              = kw:"VALUES"i              !ident_part { return createKeyword(kw); }
KW_VARBINARY           = kw:"VARBINARY"i           !ident_part { return createKeyword(kw); }
KW_VARCHAR             = kw:"VARCHAR"i             !ident_part { return createKeyword(kw); }
KW_VIEW                = kw:"VIEW"i                !ident_part { return createKeyword(kw); }
KW_WHEN                = kw:"WHEN"i                !ident_part { return createKeyword(kw); }
KW_WHERE               = kw:"WHERE"i               !ident_part { return createKeyword(kw); }
KW_WITH                = kw:"WITH"i                !ident_part { return createKeyword(kw); }
KW_XOR                 = kw:"XOR"i                 !ident_part { return createKeyword(kw); }
KW_YEAR                = kw:"YEAR"i                !ident_part { return createKeyword(kw); }
KW_ZEROFILL            = kw:"ZEROFILL"i            !ident_part { return createKeyword(kw); }

// Special characters
DOT           = '.'
COMMA         = ','
STAR          = '*'
LPAREN        = '('
RPAREN        = ')'
LBRAKE        = '['
RBRAKE        = ']'
SEMICOLON     = ';'
