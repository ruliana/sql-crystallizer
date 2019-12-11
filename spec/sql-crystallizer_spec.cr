require "./spec_helper"

module Sql::Crystallizer
  class Assert
    def self.transform(source, target)
      ast = QueryParser.new.parse(source)
      visitor = PlainStringVisitor.new
      visitor.visit(ast)
      visitor.to_s.should eq target
    end
  end

  describe Sql::Crystallizer do
    it "experiment" do
      ast = QueryParser.new.parse("select blah")
      puts ast
    end


    it "most basic select" do
      Assert.transform("select 1", "select 1")
    end

    it "multiple fields" do
      Assert.transform("select 1, 2", "select 1, 2")
      Assert.transform("select 1,2", "select 1, 2")
      Assert.transform("select 1  ,2", "select 1, 2")
    end

    describe "column reference" do
      Assert.transform("select blah", "select blah")
      Assert.transform("select table.blah", "select table.blah")
      Assert.transform("select schema.table.blah", "select schema.table.blah")
      Assert.transform("select db.schema.table.blah", "select db.schema.table.blah")
      Assert.transform("select table.*", "select table.*")
    end

    describe "aliases" do
      it "with no separator" do
        Assert.transform("select 1 test", "select 1 as test")
      end

      it "with AS" do
        Assert.transform("select 1 as test", "select 1 as test")
      end

      it "on multiple lines" do
        Assert.transform("select\n1\n    as    test", "select 1 as test")
      end
    end

    describe "functions" do
      it "simple" do
        Assert.transform("select now()", "select now()")
        Assert.transform("select greatest(some_field)", "select greatest(some_field)")
        # Assert.transform("select greatest(1, some_field, 1)", "select greatest(1, some_field, 1)")
      end

      it "binary" do
      end

      it "nested" do
      end

      it "in" do
      end

      it "between" do
      end

      it "case when" do
      end

    end

    describe "Pretty printer" do
      it "prints text" do
        Text.new("123").layout.should eq "123"
      end

      it "join things" do
        (Text.new("1") + Text.new("2")).layout.should eq "12"
      end

      it "nil is empty string" do
        Doc::NIL.layout.should eq ""
      end

      it "line is new line" do
        Doc::LINE.layout.should eq "\n"
      end

      it "concat anything" do
        (Doc::NIL + 123 + "abc").layout.should eq "123abc"
      end

      it "indent after new lines" do
        Nest.new(2, Text.new("x")).layout.should eq "x"
        Nest.new(2, Doc::LINE + "x").layout.should eq "\n  x"
        Nest.new(2, Doc::LINE + "x" + Doc::LINE + "y").layout.should eq "\n  x\n  y"
      end

      it "nested layout sum indents" do
        (Text.new("level 0") +
         Nest.new(2,
                  Doc::LINE + "level 1a" +
                  Doc::LINE + "level 1b" +
                  Nest.new(2,
                           Doc::LINE + "level 2a" +
                           Doc::LINE + "level 2b")))
          .layout.should eq "level 0\n  level 1a\n  level 1b\n    level 2a\n    level 2b"
      end

      it "format things just nicely" do
      end
    end
  end
end
