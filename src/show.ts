import { Whitespace, Node } from "./cst/Node";
import { cstTransformer } from "./cstTransformer";
import { transformMap } from "./showNode/transformMap";

import { isDefined, isString } from "./utils/generic";

type NodeArray = (Node | NodeArray | string | undefined)[];

/**
 * 根据 cst node 返回 sql 语句
 * @param node
 * @param joinString
 * @public api
 */
export function show(
  node: Node | NodeArray | string,
  joinString: string = ""
): string {
  if (isString(node)) {
    return node;
  }
  if (node instanceof Array) {
    return node
      .filter(isDefined)
      .map((n) => show(n))
      .join(joinString);
  }

  return [
    showWhitespace(node.leading),
    showNode(node),
    showWhitespace(node.trailing),
  ]
    .filter(isDefined)
    .join("");
}

const showWhitespace = (ws?: Whitespace[]): string | undefined => {
  if (!ws) {
    return undefined;
  }
  return ws.map(showWhitespaceItem).join("");
};

const showWhitespaceItem = (ws: Whitespace): string => ws.text;

const showNode = cstTransformer<string>(transformMap);
