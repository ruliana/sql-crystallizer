require "lingo"

module Sql::Crystallizer
  VERSION = "0.1.0"

  class QueryParser < Lingo::Parser
    rule(:query_specification) do
      match(/select/i) >>
        space >>
        (set_quantifier >> space).maybe >>
        select_list >>
        (space >> table_expression).maybe
    end

    rule(:set_quantifier) { match(/distinct/i) | match(/all/i) }

    rule(:select_list) do
      str("*") | (select_sublist >> (comma >> select_sublist).repeat(0))
    end

    rule(:select_sublist) do
      derived_column | qualified_asterisk
    end

    rule(:qualified_asterisk) do
      (identifier >> str(".")).repeat >> str("*")
    end

    rule(:derived_column) do
      identifier >> (space >> as_clause).maybe
    end

    rule(:as_clause) do
      (match(/as/i) >> space).maybe >> identifier
    end

    rule(:table_expression) do
      str("")
    end


    rule(:comma) { match(/\s*,\s*/) }
    rule(:identifier) { match(/"[^"]+"/) | match(/[A-Za-z]\w+/) | match(/\d+/)}
    rule(:space) { match(/\s+/) }
    rule(:space?) { match(/\s*/) }

    root(:query_specification)
  end

  struct NilColumn
    def named(name : String)
      SimpleColumn.new(name)
    end

    def aliased(name : String)
      AliasedColumn.new("", name)
    end
  end

  struct SimpleColumn
    def initialize(@name : String)
    end

    def named(name : String)
      SimpleColumn.new(name)
    end

    def aliased(name : String)
      AliasedColumn.new(@name, name)
    end

    def to_s
      @name
    end
  end

  struct AliasedColumn
    def initialize(@name : String, @alias : String)
    end

    def named(name : String)
      AliasedColumn.new(name, @alias)
    end

    def aliased(name : String)
      AliasedColumn.new(@name, name)
    end

    def to_s
      "#{@name} as #{@alias}"
    end
  end

  alias Column = (NilColumn | SimpleColumn | AliasedColumn)

  class Query
    property columns = [] of Column

    def to_str
      "select " + columns.map(&.to_s).join(", ")
    end
  end

  class PlainStringVisitor < Lingo::Visitor
    EMPTY_COLUMN = NilColumn.new
    getter rslt = Query.new
    property current_column : Column = EMPTY_COLUMN

    enter(:field) do
      visitor.current_column = visitor.current_column.named(node.full_value)
    end

    enter(:alias) do
      visitor.current_column = visitor.current_column.aliased(node.full_value)
    end

    exit(:column) do
      visitor.rslt.columns << visitor.current_column
      visitor.current_column = EMPTY_COLUMN
    end
  end
end
