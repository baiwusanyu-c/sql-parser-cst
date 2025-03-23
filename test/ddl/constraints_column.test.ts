import { dialect, parseStmt, test, withComments } from "../test_utils";

describe("column constraints", () => {
  function testColConstWc(constraint: string) {
    test(`CREATE TABLE t (id INT ${withComments(constraint)})`);
  }

  function parseColConstraint(constraint: string) {
    const stmt = parseStmt(`CREATE TABLE t (id INT ${constraint})`);
    if (stmt.type !== "create_table_stmt") {
      throw new Error("Expected create_table_stmt");
    }
    const columnDef = stmt.columns?.expr.items[0];
    if (columnDef?.type !== "column_definition") {
      throw new Error("Expected column_definition");
    }
    return columnDef.constraints[0];
  }

  function testWithIndexParameters(constraint: string) {
    testColConstWc(`${constraint} INCLUDE (col1, col2)`);
    testColConstWc(`${constraint} WITH (fillfactor = 70, autovacuum_enabled)`);
    testColConstWc(`${constraint} USING INDEX TABLESPACE my_tablespace`);
  }

  it("parses multiple constraints after column data type", () => {
    test(`CREATE TABLE foo (
        id INT  NOT NULL  DEFAULT 5
      )`);
  });

  describe("null / not null", () => {
    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("NULL", () => {
        testColConstWc("NULL");
      });
    });

    it("NOT NULL", () => {
      testColConstWc("NOT NULL");
    });
  });

  describe("default", () => {
    it("DEFAULT", () => {
      testColConstWc("DEFAULT 10");
      testColConstWc("DEFAULT (5 + 6 > 0 AND true)");
    });

    dialect("postgresql", () => {
      it("support DEFAULT expr, without needing parenthesis", () => {
        testColConstWc("DEFAULT 5 + 8");
      });
    });
  });

  describe("primary key", () => {
    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("PRIMARY KEY", () => {
        testColConstWc("PRIMARY KEY");
      });
    });
    dialect(["bigquery"], () => {
      it("PRIMARY KEY NOT ENFORCED", () => {
        testColConstWc("PRIMARY KEY NOT ENFORCED");
      });
    });

    dialect("sqlite", () => {
      it("AUTOINCREMENT on PRIMARY KEY column", () => {
        testColConstWc("PRIMARY KEY AUTOINCREMENT");
      });

      it("ASC / DESC on PRIMARY KEY column", () => {
        testColConstWc("PRIMARY KEY ASC");
      });
    });

    dialect(["mysql", "mariadb"], () => {
      it("supports KEY as shorthand for PRIMARY KEY", () => {
        testColConstWc("KEY");
      });

      it("parses KEY as constraint_primary_key", () => {
        expect(parseColConstraint("KEY").type).toBe("constraint_primary_key");
      });
    });

    dialect("postgresql", () => {
      it("supports index parameters", () => {
        testWithIndexParameters("PRIMARY KEY");
      });
    });
  });

  describe("unique", () => {
    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("UNIQUE", () => {
        testColConstWc("UNIQUE");
      });
    });
    dialect(["mysql", "mariadb"], () => {
      it("UNIQUE KEY", () => {
        testColConstWc("UNIQUE KEY");
      });
    });
    dialect(["postgresql"], () => {
      it("NULLS [NOT] DISTINCT", () => {
        testColConstWc("UNIQUE NULLS DISTINCT");
        testColConstWc("UNIQUE NULLS NOT DISTINCT");
      });

      it("supports index parameters", () => {
        testWithIndexParameters("UNIQUE");
        testWithIndexParameters("UNIQUE NULLS DISTINCT");
      });
    });
  });

  dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
    it("CHECK", () => {
      testColConstWc("CHECK (col > 10)");
    });
  });

  describe("foreign key", () => {
    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("REFERENCES", () => {
        // full syntax is tested under table constraints tests
        testColConstWc("REFERENCES tbl2 (col1)");
      });
    });
    dialect(["bigquery"], () => {
      it("REFERENCES .. NOT ENFORCED", () => {
        testColConstWc("REFERENCES tbl2 (col1) NOT ENFORCED");
      });
    });
    dialect("sqlite", () => {
      it("supports deferrability in references clause", () => {
        testColConstWc("REFERENCES tbl2 (id) DEFERRABLE");
      });
    });
  });

  describe("collate", () => {
    dialect(["mysql", "mariadb", "sqlite"], () => {
      it("COLLATE", () => {
        testColConstWc("COLLATE utf8mb4_bin");
      });
    });
    dialect("bigquery", () => {
      it("COLLATE", () => {
        testColConstWc("COLLATE 'und:ci'");
      });
    });
    dialect("postgresql", () => {
      it("COLLATE", () => {
        testColConstWc(`COLLATE "C"`);
      });
    });
  });

  describe("generated", () => {
    dialect(["mysql", "mariadb", "sqlite"], () => {
      it("GENERATED ALWAYS", () => {
        testColConstWc("GENERATED ALWAYS AS (col1 + col2)");
        testColConstWc("AS (col1 + col2)");
        testColConstWc("GENERATED ALWAYS AS ( true ) VIRTUAL");
      });
    });
    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("GENERATED ALWAYS AS (expr) STORED", () => {
        testColConstWc("GENERATED ALWAYS AS (true) STORED");
      });
    });
    dialect("postgresql", () => {
      it("GENERATED .. AS IDENTITY", () => {
        testColConstWc("GENERATED ALWAYS AS IDENTITY");
        testColConstWc("GENERATED BY DEFAULT AS IDENTITY");
      });

      it("GENERATED .. AS IDENTITY (sequence options)", () => {
        // For all sequence options, see test/ddl/sequence.test.ts
        testColConstWc("GENERATED ALWAYS AS IDENTITY (START WITH 10 INCREMENT BY 5)");
      });

      // SEQUENCE NAME, LOGGED, UNLOGGED are not among the general sequence options
      it("GENERATED .. AS IDENTITY (special options ...)", () => {
        testColConstWc("GENERATED ALWAYS AS IDENTITY (START WITH 10 SEQUENCE NAME schm.my_seq)");
        testColConstWc("GENERATED ALWAYS AS IDENTITY (LOGGED)");
        testColConstWc("GENERATED ALWAYS AS IDENTITY (UNLOGGED)");
      });
    });
  });

  dialect(["mysql", "mariadb"], () => {
    it("AUTO_INCREMENT", () => {
      testColConstWc("AUTO_INCREMENT");
      testColConstWc("AUTO_increment");
    });
  });

  dialect(["mysql", "mariadb"], () => {
    it("COMMENT", () => {
      testColConstWc("COMMENT 'Hello, world!'");
    });
  });

  dialect(["mysql", "mariadb"], () => {
    it("VISIBLE / INVISIBLE", () => {
      testColConstWc("VISIBLE");
      testColConstWc("INVISIBLE");
    });
  });

  dialect(["mysql", "mariadb"], () => {
    it("COLUMN_FORMAT", () => {
      testColConstWc("COLUMN_FORMAT FIXED");
      testColConstWc("COLUMN_FORMAT DYNAMIC");
      testColConstWc("COLUMN_FORMAT DEFAULT");
    });
  });

  describe("storage", () => {
    dialect(["mysql", "mariadb"], () => {
      it("STORAGE", () => {
        testColConstWc("STORAGE DISK");
        testColConstWc("STORAGE MEMORY");
      });
    });
    dialect("postgresql", () => {
      it("STORAGE", () => {
        testColConstWc("STORAGE PLAIN");
        testColConstWc("STORAGE EXTERNAL");
        testColConstWc("STORAGE EXTENDED");
        testColConstWc("STORAGE MAIN");
        testColConstWc("STORAGE DEFAULT");
      });
    });
  });

  dialect(["mysql", "mariadb"], () => {
    it("engine attributes", () => {
      testColConstWc("ENGINE_ATTRIBUTE = 'blah'");
      testColConstWc("ENGINE_ATTRIBUTE 'blah'");
      testColConstWc("SECONDARY_ENGINE_ATTRIBUTE = 'blah'");
      testColConstWc("SECONDARY_ENGINE_ATTRIBUTE 'blah'");
    });
  });

  dialect("postgresql", () => {
    it("COMPRESSION", () => {
      testColConstWc("COMPRESSION pglz");
      testColConstWc("COMPRESSION lz4");
      testColConstWc("COMPRESSION default");
    });
  });

  dialect("sqlite", () => {
    it("supports ON CONFLICT clause", () => {
      testColConstWc("UNIQUE ON CONFLICT ROLLBACK");
      testColConstWc("UNIQUE ON CONFLICT ABORT");
      testColConstWc("UNIQUE ON CONFLICT FAIL");
      testColConstWc("UNIQUE ON CONFLICT IGNORE");
      testColConstWc("UNIQUE ON CONFLICT REPLACE");

      testColConstWc("PRIMARY KEY ON CONFLICT ABORT");
      testColConstWc("NOT NULL ON CONFLICT ABORT");
      testColConstWc("CHECK (x > 0) ON CONFLICT ABORT");
    });
  });

  dialect("bigquery", () => {
    it("supports OPTIONS(..)", () => {
      testColConstWc("OPTIONS(description='this is a great column')");
    });
  });

  dialect(["mysql", "mariadb", "sqlite"], () => {
    it("supports CONSTRAINT keyword for keys and check()", () => {
      testColConstWc("CONSTRAINT PRIMARY KEY");
      testColConstWc("CONSTRAINT UNIQUE");
      testColConstWc("CONSTRAINT CHECK (true)");
    });
  });

  dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
    it("supports named column constraints for keys and check()", () => {
      testColConstWc("CONSTRAINT cname PRIMARY KEY");
      testColConstWc("CONSTRAINT cname UNIQUE");
      testColConstWc("CONSTRAINT cname CHECK (true)");
    });
  });

  dialect(["sqlite"], () => {
    it("supports CONSTRAINT keyword for column constraints", () => {
      testColConstWc("CONSTRAINT NULL");
      testColConstWc("CONSTRAINT NOT NULL");
      testColConstWc("CONSTRAINT DEFAULT 10");
      testColConstWc("CONSTRAINT COLLATE utf8");
      testColConstWc("CONSTRAINT GENERATED ALWAYS AS (x + y)");
      testColConstWc("CONSTRAINT REFERENCES tbl2 (col)");
    });
  });

  dialect(["sqlite", "postgresql"], () => {
    it("supports named column constraints", () => {
      testColConstWc("CONSTRAINT cname NULL");
      testColConstWc("CONSTRAINT cname NOT NULL");
      testColConstWc("CONSTRAINT cname DEFAULT 10");
      testColConstWc("CONSTRAINT cname COLLATE utf8");
      testColConstWc("CONSTRAINT cname GENERATED ALWAYS AS (x + y) STORED");
      testColConstWc("CONSTRAINT cname REFERENCES tbl2 (col)");
    });
  });

  describe("constraint modifiers", () => {
    dialect(["sqlite", "postgresql"], () => {
      it("supports deferrability of foreign keys", () => {
        testColConstWc("REFERENCES tbl2 (id) DEFERRABLE INITIALLY DEFERRED");
        testColConstWc("REFERENCES tbl2 (id) NOT DEFERRABLE INITIALLY IMMEDIATE");
      });
    });

    dialect(["postgresql"], () => {
      it("supports deferrability of all constraints", () => {
        testColConstWc("NOT NULL NOT DEFERRABLE");
        testColConstWc("DEFAULT 10 INITIALLY DEFERRED");
        testColConstWc("GENERATED ALWAYS AS (10) STORED INITIALLY DEFERRED");
        testColConstWc("PRIMARY KEY INITIALLY IMMEDIATE");
      });

      it("supports NO INHERIT modifier on CHECK() constraint", () => {
        testColConstWc("CHECK (x > 10) NO INHERIT");
      });
    });
  });
});
