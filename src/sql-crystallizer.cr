require "lingo"

module Sql::Crystallizer
  VERSION = "0.1.0"

  class QueryParser < Lingo::Parser
    rule(:space) { match(/\s+/) }
    rule(:select_statement) { str("select") }

    rule(:field_raw) {
      match(/\w+/).named(:field)
    }

    rule(:field_as) {
      match(/\w+/).named(:field) >>
       space >>
       str("as") >>
       space >>
       match(/\w+/).named(:alias)
    }

    rule(:field_eq) {
      match(/\w+/).named(:alias) >>
        space >>
        str("=") >>
        space >>
        match(/\w+/).named(:field)
    }

    rule(:field) {
      (field_eq | field_as | field_raw).named(:column)
    }

    rule(:fields) {
      field >> (space.maybe>>
                str(",") >>
                space.maybe >>
                fields).repeat(0)
    }

    rule(:projection) {
      select_statement.named(:select) >>
        space >>
        fields
    }

    root(:projection)
  end

  struct NilColumn
    def named(name : String)
      SimpleColumn.new(name)
    end

    def alias(name : String)
      AliasedColumn.new("", name)
    end
  end

  struct SimpleColumn
    def initialize(@name : String)
    end

    def named(name : String)
      SimpleColumn.new(name)
    end

    def alias(name : String)
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

    def alias(name : String)
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

    enter(:field) {
      visitor.current_column = visitor.current_column.named(node.full_value)
    }

    enter(:alias) {
      visitor.current_column = visitor.current_column.alias(node.full_value)
    }

    exit(:column) {
      visitor.rslt.columns << visitor.current_column
      visitor.current_column = EMPTY_COLUMN
    }
  end
end
