import { dialect, parseExpr, testExpr } from "../test_utils";

describe("string literal", () => {
  it("single-quoted string", () => {
    expect(parseExpr(`'hello'`)).toMatchInlineSnapshot(`
      {
        "text": "'hello'",
        "type": "string",
        "value": "hello",
      }
    `);
  });
  it("single-quoted string with repeated-quote escapes", () => {
    testExpr(`'hel''lo'`);
  });
  dialect("mysql", () => {
    it("single-quoted string with backslash escapes", () => {
      testExpr(`'hel\\'lo'`);
    });
  });

  dialect("mysql", () => {
    it("double-quoted string", () => {
      expect(parseExpr(`"hello"`)).toMatchInlineSnapshot(`
        {
          "text": ""hello"",
          "type": "string",
          "value": "hello",
        }
      `);
    });
    it("double-quoted string with repeated-quote escapes", () => {
      testExpr(`"hel""lo"`);
    });
    it("double-quoted string with backslash escapes", () => {
      testExpr(`"hel\\"lo"`);
    });
  });

  it("hex string", () => {
    expect(parseExpr(`x'AFC123'`)).toMatchInlineSnapshot(`
      {
        "text": "x'AFC123'",
        "type": "string",
        "value": "AFC123",
      }
    `);
  });

  dialect("mysql", () => {
    it("bit string", () => {
      expect(parseExpr(`b'011001'`)).toMatchInlineSnapshot(`
        {
          "text": "b'011001'",
          "type": "string",
          "value": "011001",
        }
      `);
    });
  });

  dialect("mysql", () => {
    describe("string with charset", () => {
      it("parses single-quoted string with charset to syntax tree", () => {
        expect(parseExpr(`_binary 'hello'`)).toMatchInlineSnapshot(`
          {
            "charset": "binary",
            "string": {
              "text": "'hello'",
              "type": "string",
              "value": "hello",
            },
            "type": "string_with_charset",
          }
        `);
      });
      it("single-quoted string with charset", () => {
        testExpr(`_latin1 'hello'`);
        testExpr(`_latin1 /*c*/ 'hello'`);
      });
      it("double-quoted string with charset", () => {
        testExpr(`_latin1 'hello'`);
      });
      it("hex literal with charset", () => {
        testExpr(`_utf8 0xAAFF11`);
      });
      it("bit string with charset", () => {
        testExpr(`_big5 b'011001'`);
      });
      it("hex string with charset", () => {
        testExpr(`_utf16le X'AFC123'`);
      });
    });
  });

  dialect("mysql", () => {
    it("natural character set string", () => {
      expect(parseExpr(`N'hello'`)).toMatchInlineSnapshot(`
        {
          "text": "N'hello'",
          "type": "string",
          "value": "hello",
        }
      `);
    });
    it("natural character set string with repeated-quote escapes", () => {
      testExpr(`N'hel''lo'`);
    });
    it("natural character set string with backslash escapes", () => {
      testExpr(`n'hel\\'lo'`);
    });
  });
});
