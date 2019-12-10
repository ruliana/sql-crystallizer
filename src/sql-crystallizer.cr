require "lingo"

module Sql::Crystallizer
  VERSION = "0.1.0"

  class QueryParser < Lingo::Parser
    rule(:query_specification) do
      match(/select/i) >>
        space >>
        (set_quantifier >> space).maybe >>
        select_list.named(:select_list) >>
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
      value_expression.named(:derived_column) >> (space >> as_clause).maybe
    end

    rule(:as_clause) do
      (match(/as/i) >> space).maybe >> identifier.named(:as_clause)
    end

    rule(:value_expression) do
      # common_value_expression | boolean_value_expression | row_value_expression
      function | identifier
    end

    rule(:function) do
      identifier >> str("(") >> value_expression.maybe >> str(")")
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

  class PlainStringVisitor < Lingo::Visitor
    getter builder = String::Builder.new(2048)
    property fields = [] of String

    enter(:select_list) do
      visitor.fields = [] of String

      visitor.builder.print("select")
      visitor.builder.print(" ")
    end

    exit(:select_list) do
      fields = visitor.fields
      visitor.builder.print(fields.join(", "))
    end

    enter(:derived_column) do
      visitor.fields << node.full_value
    end

    enter(:as_clause) do
      visitor.fields[-1] = visitor.fields[-1] + " as #{node.full_value}"
    end

    def to_s
      builder.to_s
    end
  end
end
