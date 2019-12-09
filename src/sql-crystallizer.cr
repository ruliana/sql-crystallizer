require "lingo"

module Sql::Crystallizer
  VERSION = "0.1.0"

  class QueryParser < Lingo::Parser
    rule(:space) { match(/\s+/) }
    rule(:select_statement) { str("select") }

    rule(:field_alias) do
      match(/\w+/).named(:alias)
    end

    rule(:field_raw) do
      match(/\w+/).named(:field)
    end

    rule(:field_missing_as) do
      field_raw >> space >> field_alias
    end

    rule(:field_as) do
      field_raw >>
        space >>
        str("as") >>
        space >>
        field_alias
    end

    rule(:field_eq) do
      field_alias >>
        space >>
        str("=") >>
        space >>
        field_raw
    end

    rule(:field) do
      (field_eq | field_as | field_missing_as | field_raw).named(:column)
    end

    rule(:fields) do
      field >> (space.maybe>>
                str(",") >>
                space.maybe >>
                fields).repeat(0)
    end

    rule(:projection) do
      select_statement.named(:select) >>
        space >>
        fields
    end

    root(:projection)
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
