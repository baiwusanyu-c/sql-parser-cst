import { dialect, test, testWc, withComments } from "../test_utils";

describe("alter table", () => {
  function testAlterWc(alter: string) {
    test(`ALTER TABLE t ${withComments(alter)}`);
  }

  it("supports basic ALTER TABLE", () => {
    testWc("ALTER TABLE schm.my_tbl RENAME TO new_name");
  });

  dialect(["bigquery", "postgresql"], () => {
    it("supports ALTER TABLE IF EXISTS", () => {
      testWc("ALTER TABLE IF EXISTS my_tbl RENAME TO new_name");
    });
  });

  dialect(["postgresql"], () => {
    it("supports ALTER TABLE [ONLY] name [*]", () => {
      testWc("ALTER TABLE ONLY my_tbl RENAME TO new_name");
      testWc("ALTER TABLE my_tbl * RENAME TO new_name");
    });
  });

  it("supports multiple alter actions", () => {
    testWc(`
      ALTER TABLE tbl
      ADD COLUMN col1 INT,
      DROP COLUMN col2
    `);
  });

  describe("rename table", () => {
    it("RENAME TO", () => {
      testAlterWc("RENAME TO new_name");
    });

    dialect(["mysql"], () => {
      it("supports RENAME AS", () => {
        testAlterWc("RENAME AS new_name");
      });
    });

    dialect(["mysql", "mariadb"], () => {
      it("supports plain RENAME", () => {
        testAlterWc("RENAME new_name");
      });
    });
  });

  describe("rename column", () => {
    it("RENAME COLUMN col1 TO col2", () => {
      testAlterWc("RENAME COLUMN col1 TO col2");
    });

    dialect(["sqlite", "postgresql"], () => {
      it("supports RENAME col1 TO col2", () => {
        testAlterWc("RENAME col1 TO col2");
      });
    });

    dialect("bigquery", () => {
      it("supports RENAME COLUMN IF EXISTS", () => {
        testAlterWc("RENAME COLUMN IF EXISTS col1 TO col2");
      });
    });
  });

  describe("add column", () => {
    it("supports ADD COLUMN", () => {
      testAlterWc("ADD COLUMN col1 INT NOT NULL");
    });

    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("supports plain ADD", () => {
        testAlterWc("ADD col1 INT");
      });
    });

    dialect(["bigquery", "postgresql", "mariadb"], () => {
      it("supports ADD COLUMN IF NOT EXISTS", () => {
        testAlterWc("ADD COLUMN IF NOT EXISTS col1 INT");
      });
    });
  });

  describe("drop column", () => {
    it("supports DROP COLUMN", () => {
      testAlterWc("DROP COLUMN col1");
    });

    dialect(["mysql", "mariadb", "sqlite", "postgresql"], () => {
      it("supports plain DROP", () => {
        testAlterWc("DROP col1");
      });
    });

    dialect(["bigquery", "postgresql"], () => {
      it("supports DROP COLUMN IF EXISTS", () => {
        testAlterWc("DROP COLUMN IF EXISTS col1");
      });
    });

    dialect(["postgresql"], () => {
      it("supports DROP COLUMN [CASCADE | RESTRICT]", () => {
        testAlterWc("DROP COLUMN col1 CASCADE");
        testAlterWc("DROP COLUMN col2 RESTRICT");
      });
    });
  });

  describe("alter column", () => {
    dialect(["mysql", "mariadb", "bigquery", "postgresql"], () => {
      it("supports ALTER COLUMN colname", () => {
        testAlterWc("ALTER COLUMN col1 DROP DEFAULT");
      });
    });
    dialect(["mysql", "mariadb", "postgresql"], () => {
      it("supports ALTER colname", () => {
        testAlterWc("ALTER col1 DROP DEFAULT");
      });
    });
    dialect("bigquery", () => {
      it("supports ALTER COLUMN IF EXISTS", () => {
        testAlterWc("ALTER COLUMN IF EXISTS col1 DROP DEFAULT");
      });
    });

    dialect(["mysql", "mariadb", "bigquery", "postgresql"], () => {
      it("supports SET DEFAULT", () => {
        testAlterWc("ALTER COLUMN foo SET DEFAULT 125");
      });

      it("supports DROP DEFAULT", () => {
        testAlterWc("ALTER COLUMN foo DROP DEFAULT");
      });
    });

    dialect(["postgresql"], () => {
      it("supports SET NOT NULL", () => {
        testAlterWc("ALTER COLUMN foo SET NOT NULL");
      });
    });
    dialect(["bigquery", "postgresql"], () => {
      it("supports DROP NOT NULL", () => {
        testAlterWc("ALTER COLUMN foo DROP NOT NULL");
      });
    });

    dialect(["bigquery", "postgresql"], () => {
      it("supports SET DATA TYPE", () => {
        testAlterWc("ALTER COLUMN foo SET DATA TYPE INT");
        testAlterWc("ALTER COLUMN foo SET DATA TYPE DECIMAL(5, 8)");
      });

      dialect("postgresql", () => {
        it("supports just TYPE", () => {
          testAlterWc("ALTER COLUMN foo TYPE DECIMAL(5, 8)");
        });

        it("supports additional clauses", () => {
          testAlterWc(`ALTER COLUMN foo SET DATA TYPE text COLLATE "C"`);
          testAlterWc(`
            ALTER COLUMN foo
              SET DATA TYPE timestamp with time zone
              USING foo_timestamp + INTERVAL '1 second'`);
          testAlterWc(`ALTER COLUMN foo TYPE text COLLATE "C" USING bar || '!'`);
        });
      });
    });

    dialect("bigquery", () => {
      it("supports SET OPTIONS", () => {
        testAlterWc("ALTER COLUMN foo SET OPTIONS ( description = 'Blah' )");
      });
    });
    dialect("postgresql", () => {
      it("supports SET (..postgresql options..)", () => {
        testAlterWc("ALTER COLUMN foo SET (n_distinct = 100, n_distinct_inherited = -1)");
      });
      it("supports RESET (..postgresql options..)", () => {
        testAlterWc("ALTER COLUMN foo SET (n_distinct, n_distinct_inherited)");
      });
    });

    dialect(["mysql"], () => {
      it("supports SET VISIBLE / INVISIBLE", () => {
        testAlterWc("ALTER COLUMN foo SET VISIBLE");
        testAlterWc("ALTER COLUMN foo SET INVISIBLE");
      });
    });

    dialect("postgresql", () => {
      it("supports SET COMPRESSION", () => {
        testAlterWc("ALTER COLUMN foo SET COMPRESSION zstd");
        testAlterWc("ALTER COLUMN foo SET COMPRESSION DEFAULT");
      });
    });

    dialect("postgresql", () => {
      it("supports SET STORAGE", () => {
        testAlterWc("ALTER COLUMN foo SET STORAGE PLAIN");
        testAlterWc("ALTER COLUMN foo SET STORAGE EXTERNAL");
        testAlterWc("ALTER COLUMN foo SET STORAGE EXTENDED");
        testAlterWc("ALTER COLUMN foo SET STORAGE MAIN");
        testAlterWc("ALTER COLUMN foo SET STORAGE DEFAULT");
      });
    });

    dialect("postgresql", () => {
      it("supports SET STATISTICS", () => {
        testAlterWc("ALTER COLUMN foo SET STATISTICS 100");
      });
    });

    dialect("postgresql", () => {
      it("supports DROP EXPRESSION [IF EXISTS]", () => {
        testAlterWc("ALTER COLUMN foo DROP EXPRESSION");
        testAlterWc("ALTER COLUMN foo DROP EXPRESSION IF EXISTS");
      });

      it("supports DROP IDENTITY [IF EXISTS]", () => {
        testAlterWc("ALTER COLUMN foo DROP IDENTITY");
        testAlterWc("ALTER COLUMN foo DROP IDENTITY IF EXISTS");
      });

      it("supports ADD GENERATED .. AS IDENTITY", () => {
        testAlterWc("ALTER COLUMN foo ADD GENERATED ALWAYS AS IDENTITY");
        testAlterWc("ALTER COLUMN foo ADD GENERATED BY DEFAULT AS IDENTITY");
      });
      it("supports ADD GENERATED .. AS IDENTITY (sequence options)", () => {
        // For all sequence options, see test/ddl/sequence.test.ts
        testAlterWc(
          "ALTER COLUMN foo ADD GENERATED ALWAYS AS IDENTITY (START WITH 10 INCREMENT BY 5)"
        );
      });
      // SEQUENCE NAME, LOGGED, UNLOGGED are not among the general sequence options
      it("supports ADD GENERATED .. AS IDENTITY (special options ...)", () => {
        testAlterWc(
          "ALTER COLUMN foo ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME my_seq START WITH 10)"
        );
        testAlterWc("ALTER COLUMN foo ADD GENERATED ALWAYS AS IDENTITY (LOGGED)");
        testAlterWc("ALTER COLUMN foo ADD GENERATED ALWAYS AS IDENTITY (UNLOGGED)");
      });

      describe("alter identity column", () => {
        it("supports SET GENERATED", () => {
          testAlterWc("ALTER COLUMN foo SET GENERATED ALWAYS");
          testAlterWc("ALTER COLUMN foo SET GENERATED BY DEFAULT");
        });

        it("supports SET sequence option", () => {
          // For all sequence options, see test/ddl/sequence.test.ts
          testAlterWc("ALTER COLUMN foo SET NO CYCLE");
          testAlterWc("ALTER COLUMN foo SET MAXVALUE 100");
        });

        it("supports RESTART", () => {
          testAlterWc("ALTER COLUMN foo RESTART");
          testAlterWc("ALTER COLUMN foo RESTART 45");
          testAlterWc("ALTER COLUMN foo RESTART WITH 100");
        });

        it("supports multiple identity column alterations", () => {
          testAlterWc("ALTER COLUMN foo RESTART SET GENERATED ALWAYS");
          testAlterWc("ALTER COLUMN foo SET GENERATED BY DEFAULT RESTART WITH 100");
        });
      });
    });
  });

  dialect("bigquery", () => {
    it("supports SET DEFAULT COLLATE", () => {
      testAlterWc("SET DEFAULT COLLATE 'und:ci'");
    });
  });

  dialect("bigquery", () => {
    it("supports SET OPTIONS (...)", () => {
      testAlterWc("SET OPTIONS (description='My lovely table')");
    });

    it("supports SET OPTIONS with all possible BigQuery table options", () => {
      testAlterWc(`
        SET OPTIONS (
          expiration_timestamp=NULL,
          partition_expiration_days=128,
          require_partition_filter=true,
          kms_key_name='blah',
          friendly_name='Little bobby tables',
          description="Robert'); DROP TABLE Students;--",
          labels = [("org_unit", "development")]
        )
      `);
    });
  });

  dialect("postgresql", () => {
    it("supports SET (..postgresql storage parameters..)", () => {
      testAlterWc(`SET (
        fillfactor = 50,
        toast.autovacuum_enabled = FALSE,
        vacuum_truncate,
        vacuum_index_cleanup = ON
      )`);
    });

    it("supports RESET (..postgresql storage parameters..)", () => {
      testAlterWc(`RESET (fillfactor, toast.autovacuum_enabled)`);
    });
  });

  dialect(["mysql", "mariadb", "postgresql"], () => {
    it("supports ADD CONSTRAINT", () => {
      testAlterWc("ADD CONSTRAINT pk PRIMARY KEY (col1)");
      testAlterWc("ADD PRIMARY KEY (col1)");
      testAlterWc("ADD FOREIGN KEY (col1) REFERENCES tbl (col2)");
      testAlterWc("ADD UNIQUE (col1)");
      testAlterWc("ADD CHECK (col1 > 0)");
    });
  });
  dialect("bigquery", () => {
    it("supports ADD PRIMARY KEY .. NOT ENFORCED", () => {
      testAlterWc("ADD PRIMARY KEY (col1) NOT ENFORCED");
    });
    it("supports ADD [CONSTRAINT name] FORIGN KEY .. NOT ENFORCED", () => {
      testAlterWc("ADD FOREIGN KEY (col1) REFERENCES tbl (col2) NOT ENFORCED");
      testAlterWc("ADD CONSTRAINT fk FOREIGN KEY (col1) REFERENCES tbl (col2) NOT ENFORCED");
    });
    it("supports ADD CONSTRAINT IF NOT EXISTS name FORIGN KEY", () => {
      testAlterWc(`
        ADD CONSTRAINT IF NOT EXISTS fk
          FOREIGN KEY (col1) REFERENCES tbl (col2) NOT ENFORCED
      `);
    });
  });
  dialect(["postgresql"], () => {
    it("supports ADD CONSTRAINT .. [NOT VALID]", () => {
      testAlterWc("ADD FOREIGN KEY (col1) REFERENCES tbl (col2) NOT VALID");
      testAlterWc("ADD CONSTRAINT ch CHECK (col1 > 0) NOT VALID");
    });

    it("supports ADD PRIMARY KEY USING INDEX", () => {
      testAlterWc("ADD PRIMARY KEY USING INDEX my_index");
      testAlterWc("ADD CONSTRAINT ch PRIMARY KEY USING INDEX my_index DEFERRABLE");
    });

    it("supports ADD UNIQUE USING INDEX", () => {
      testAlterWc("ADD UNIQUE USING INDEX my_index");
      testAlterWc("ADD CONSTRAINT ch UNIQUE USING INDEX my_index DEFERRABLE");
    });
  });

  dialect(["mysql", "mariadb", "postgresql", "bigquery"], () => {
    it("supports DROP CONSTRAINT", () => {
      testAlterWc("DROP CONSTRAINT my_constraint");
    });
  });
  dialect(["mysql"], () => {
    it("supports DROP CHECK (equivalent to DROP CONSTRAINT)", () => {
      testAlterWc("DROP CHECK my_constraint");
    });
  });
  dialect(["postgresql", "mariadb", "bigquery"], () => {
    it("supports DROP CONSTRAINT [IF EXISTS]", () => {
      testAlterWc("DROP CONSTRAINT IF EXISTS my_constraint");
    });
  });
  dialect(["postgresql"], () => {
    it("supports DROP CONSTRAINT [RESTRICT | CASCADE]", () => {
      testAlterWc("DROP CONSTRAINT my_constraint RESTRICT");
      testAlterWc("DROP CONSTRAINT my_constraint CASCADE");
    });
  });
  dialect(["bigquery"], () => {
    it("supports DROP PRIMARY KEY [IF EXISTS]", () => {
      testAlterWc("DROP PRIMARY KEY");
      testAlterWc("DROP PRIMARY KEY IF EXISTS");
    });
  });

  dialect("postgresql", () => {
    it("supports ALTER CONSTRAINT", () => {
      testAlterWc("ALTER CONSTRAINT my_constraint DEFERRABLE");
      testAlterWc("ALTER CONSTRAINT my_constraint NOT DEFERRABLE");
      testAlterWc("ALTER CONSTRAINT my_constraint INITIALLY DEFERRED");
      testAlterWc("ALTER CONSTRAINT my_constraint DEFERRABLE INITIALLY IMMEDIATE");
    });
  });
  dialect("mysql", () => {
    it("supports ALTER CONSTRAINT", () => {
      testAlterWc("ALTER CONSTRAINT my_constraint ENFORCED");
      testAlterWc("ALTER CONSTRAINT my_constraint NOT ENFORCED");
      testAlterWc("ALTER CHECK my_constraint ENFORCED");
      testAlterWc("ALTER CHECK my_constraint NOT ENFORCED");
    });
  });

  dialect("postgresql", () => {
    it("supports RENAME CONSTRAINT", () => {
      testAlterWc("RENAME CONSTRAINT foo TO bar");
    });
  });

  dialect("postgresql", () => {
    it("supports OWNER TO", () => {
      testAlterWc("OWNER TO my_user");
      testAlterWc("OWNER TO CURRENT_USER");
      testAlterWc("OWNER TO SESSION_USER");
      testAlterWc("OWNER TO CURRENT_ROLE");
    });
  });

  dialect("postgresql", () => {
    it("supports SET SCHEMA", () => {
      testAlterWc("SET SCHEMA my_schema");
    });
  });

  dialect("postgresql", () => {
    it("supports [NO] FORCE ROW LEVEL SECURITY", () => {
      testAlterWc(`FORCE ROW LEVEL SECURITY`);
      testAlterWc(`NO FORCE ROW LEVEL SECURITY`);
    });

    it("supports {ENABLE | DISABLE} ROW LEVEL SECURITY", () => {
      testAlterWc(`ENABLE ROW LEVEL SECURITY`);
      testAlterWc(`DISABLE ROW LEVEL SECURITY`);
    });

    it("supports {ENABLE | DISABLE} TRIGGER", () => {
      testAlterWc(`ENABLE TRIGGER foo`);
      testAlterWc(`ENABLE TRIGGER ALL`);
      testAlterWc(`ENABLE TRIGGER USER`);
      testAlterWc(`ENABLE REPLICA TRIGGER foo`);
      testAlterWc(`ENABLE ALWAYS TRIGGER foo`);
      testAlterWc(`DISABLE TRIGGER bar`);
    });

    it("supports {ENABLE | DISABLE} RULE", () => {
      testAlterWc(`ENABLE RULE my_rule`);
      testAlterWc(`ENABLE REPLICA RULE foo`);
      testAlterWc(`ENABLE ALWAYS RULE foo`);
      testAlterWc(`DISABLE RULE bar`);
    });
  });

  dialect("postgresql", () => {
    it("supports SET TABLESPACE", () => {
      testAlterWc(`SET TABLESPACE my_space`);
      testAlterWc(`SET TABLESPACE my_space NOWAIT`);
    });

    it("supports SET ACCESS METHOD", () => {
      testAlterWc(`SET ACCESS METHOD "SP-GiST"`);
    });

    it("supports CLUSTER ON", () => {
      testAlterWc(`CLUSTER ON my_index`);
    });

    it("supports SET WITHOUT CLUSTER", () => {
      testAlterWc(`SET WITHOUT CLUSTER`);
    });

    it("supports SET WITHOUT OIDS", () => {
      testAlterWc(`SET WITHOUT OIDS`);
    });

    it("supports SET {LOGGED | UNLOGGED}", () => {
      testAlterWc(`SET LOGGED`);
      testAlterWc(`SET UNLOGGED`);
    });
  });

  dialect("postgresql", () => {
    it("supports INHERIT", () => {
      testAlterWc(`INHERIT my_table`);
      testAlterWc(`INHERIT my_schema.my_table`);
    });

    it("supports NO INHERIT", () => {
      testAlterWc(`NO INHERIT my_schema.my_table`);
    });

    it("supports OF type", () => {
      testAlterWc(`OF my_type`);
      testAlterWc(`OF my_schema.my_type`);
    });

    it("supports NOT OF type", () => {
      testAlterWc(`NOT OF`);
    });
  });

  dialect("postgresql", () => {
    it("supports REPLICA IDENTITY", () => {
      testAlterWc(`REPLICA IDENTITY DEFAULT`);
      testAlterWc(`REPLICA IDENTITY FULL`);
      testAlterWc(`REPLICA IDENTITY NOTHING`);
      testAlterWc(`REPLICA IDENTITY USING INDEX my_index`);
    });
  });

  dialect("postgresql", () => {
    describe("ALTER TABLE ALL IN TABLESPACE", () => {
      it("supports ALTER TABLE ALL IN TABLESPACE", () => {
        testWc(`
          ALTER TABLE ALL IN TABLESPACE my_tspace
            SET TABLESPACE new_tablespace
        `);
      });

      it("supports OWNED BY clause", () => {
        testWc(`
          ALTER TABLE ALL IN TABLESPACE my_tspace
            OWNED BY user1, CURRENT_ROLE, user2
            SET TABLESPACE new_tablespace NOWAIT
        `);
      });
    });
  });
});
