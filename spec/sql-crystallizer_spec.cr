require "./spec_helper"

module Sql::Crystallizer
  class Assert
    def self.transform(source, target)
      ast = QueryParser.new.parse(source)
      visitor = PlainStringVisitor.new
      visitor.visit(ast)
      visitor.rslt.to_str.should eq target
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

      it "with (=) equal" do
        Assert.transform("select test = 1", "select 1 as test")
      end
    end
  end
end
