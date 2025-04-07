import { show } from "../show";
import { FullTransformMap } from "../cstTransformer";
import { AllSequenceNodes } from "../cst/Node";

export const sequenceMap: FullTransformMap<string, AllSequenceNodes> = {
  // CREATE SEQUENCE
  create_sequence_stmt: (node) =>
    show([
      node.createKw,
      node.kind,
      node.sequenceKw,
      node.ifNotExistsKw,
      node.name,
      node.options,
    ]),
  sequence_option_list: (node) => show(node.options),
  sequence_option_as_type: (node) => show([node.asKw, node.dataType]),
  sequence_option_increment: (node) =>
    show([node.incrementKw, node.byKw, node.value]),
  sequence_option_start: (node) =>
    show([node.startKw, node.withKw, node.value]),
  sequence_option_restart: (node) =>
    show([node.restartKw, node.withKw, node.value]),
  sequence_option_minvalue: (node) => show([node.minvalueKw, node.value]),
  sequence_option_maxvalue: (node) => show([node.maxvalueKw, node.value]),
  sequence_option_no_minvalue: (node) => show(node.noMinvalueKw),
  sequence_option_no_maxvalue: (node) => show(node.noMaxvalueKw),
  sequence_option_cache: (node) => show([node.cacheKw, node.value]),
  sequence_option_cycle: (node) => show(node.cycleKw),
  sequence_option_no_cycle: (node) => show(node.noCycleKw),
  sequence_option_owned_by: (node) => show([node.ownedByKw, node.owner]),
  sequence_option_sequence_name: (node) =>
    show([node.sequenceNameKw, node.name]),
  sequence_option_logged: (node) => show(node.loggedKw),
  sequence_option_unlogged: (node) => show(node.unloggedKw),

  // ALTER SEQUENCE
  alter_sequence_stmt: (node) =>
    show([
      node.alterKw,
      node.sequenceKw,
      node.ifExistsKw,
      node.sequence,
      node.actions,
    ]),

  // DROP SEQUENCE
  drop_sequence_stmt: (node) =>
    show([
      node.dropKw,
      node.sequenceKw,
      node.ifExistsKw,
      node.sequences,
      node.behaviorKw,
    ]),
};
