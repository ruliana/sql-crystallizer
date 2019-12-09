require "./spec_helper"

module Sql::Crystallizer
  describe Sql::Crystallizer do
    it "most basic select" do
      ast = QueryParser.new.parse("select 1")
      visitor = PlainStringVisitor.new
      visitor.visit(ast)
      visitor.rslt.to_str.should eq "select 1"
    end

    describe "aliases" do
      it "with no separator" do
        ast = QueryParser.new.parse("select 1 test")
        visitor = PlainStringVisitor.new
        visitor.visit(ast)
        visitor.rslt.to_str.should eq "select 1 as test"
      end

      it "with AS" do
        ast = QueryParser.new.parse("select 1 as test")
        visitor = PlainStringVisitor.new
        visitor.visit(ast)
        visitor.rslt.to_str.should eq "select 1 as test"
      end

      it "with (=) equal" do
        ast = QueryParser.new.parse("select test = 1")
        visitor = PlainStringVisitor.new
        visitor.visit(ast)
        visitor.rslt.to_str.should eq "select 1 as test"
      end
    end
  end
end
