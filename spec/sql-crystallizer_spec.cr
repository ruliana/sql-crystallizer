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
    it "most basic select" do
      Assert.transform("select 1", "select 1")
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
        Assert.transform("select greatest(1, some_field, 1)", "select greatest(1, some_field, 1)")
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
  end
end
