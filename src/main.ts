
// 所有的 cst node 类型
export * from "./cst/Node";
// @public API
// 生成一个在整个 CST 树中行走的函数，并在遇到具有该类型的节点时调用 map 中的函数。
export * from "./cstVisitor";
// @public API
// cstTransformer，能够将 cst 转化为指定类型的对象，
export * from "./cstTransformer";
// 支持的语言关键字
export * from "./keywords";
// 解析器配置选项类型
export { DialectName, ParserOptions } from "./ParserOptions";
// 语法解析失败的错误捕获器
export { FormattedSyntaxError } from "./FormattedSyntaxError";

import type { Node, Program } from "./cst/Node";
import { parse as parseSql, PeggySyntaxError } from "./parser";
import { show as showSql } from "./show";
import { type ParserOptions, validDialectNames } from "./ParserOptions";
import { FormattedSyntaxError } from "./FormattedSyntaxError";


// 解析器导出
// @public API
export function parse(sql: string, options: ParserOptions): Program {
  if (!options || !options.dialect) {
    throw new Error(`No SQL dialect specified.`);
  }
  if (!validDialectNames[options.dialect]) {
    throw new Error(`Unsupported dialect name: "${options.dialect}"`);
  }
  try {
    return parseSql(sql, options) as Program;
  } catch (e) {
    if (e instanceof PeggySyntaxError) {
      throw new FormattedSyntaxError(e, sql, options.filename);
    }
    throw e;
  }
}

/**
 * Converts any syntax tree node back to SQL string.
 *
 * It's a very primitive serializer that won't insert any whitespace on its own.
 * It will only restore the whitespace from leading/trailing fields.
 * Not having this information available can lead to invalid SQL being generated.
 *
 * Therefore only feed it syntax trees parsed with options:
 *
 *     { includeSpaces: true, includeComments: true, includeNewlines: true }
 */
// @public API
export function show(node: Node): string {
  // This might look like an unnecessary wrapper around show() from src/show.
  // The goal here is to restrict the input type to just Node,
  // not allowing all the additional types that are largely an implementation detail.
  return showSql(node);
}
