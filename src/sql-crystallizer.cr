require "lingo"

module Sql::Crystallizer
  VERSION = "0.1.0"

  class QueryParser < Lingo::Parser
    # Reserved words and symbols

    rule(:select_word) { match(/\bselect\b/i) }
    rule(:distinct) { match(/\bdistinct\b/i) }
    rule(:all) { match(/\ball\b/i) }
    rule(:star) { str("*") }
    rule(:dot) { str(".") }
    rule(:as_word) { match(/\bas\b/i) }
    rule(:comma) { match(/\s*,\s*/) }
    rule(:space) { match(/\s+/) }
    rule(:space?) { match(/\s*/) }
    rule(:lparen) { match(/\s*\(\s*/)}
    rule(:rparen) { match(/\s*\)\s*/)}
    rule(:identifier) { match(/"[^"]+"/) | match(/[A-Za-z]\w+/) | match(/\d+/)}

    rule(:and_word) { match(/\band\b/i) }
    rule(:or_word) { match(/\bor\b/i) }
    rule(:not_word) { match(/\bnot\b/i) }
    rule(:is_word) { match(/\bis\b/i) }
    rule(:true_word) { match(/\btrue\b/i) }
    rule(:false_word) { match(/\bfalse\b/i) }
    rule(:unknown) { match(/\bunknown\b/i) }
    rule(:null) { match(/\bnull\b/i) }

    rule(:query_specification) do
      select_word >>
        (space >> set_quantifier).maybe >>
        space >> select_list.named(:select_list) >>
        (space >> table_expression).maybe
    end

    rule(:set_quantifier) { distinct | all }

    rule(:select_list) do
      star |
        (select_sublist >> (comma >> select_sublist).repeat(0))
    end

    rule(:select_sublist) do
      qualified_asterisk | derived_column
    end

    rule(:qualified_asterisk) do
      ((identifier >> dot).repeat(1) >> star).named(:derived_column)
    end

    rule(:derived_column) do
      value_expression.named(:derived_column) >> (space >> as_clause).maybe
    end

    rule(:as_clause) do
      (as_word >> space).maybe >> identifier.named(:as_clause)
    end

    rule(:value_expression) do
      # common_value_expression | boolean_value_expression | row_value_expression
      # boolean_value_expression |
      column_reference | function | identifier
    end

    rule(:column_reference) do
      identifier >> (dot >> identifier).repeat
    end

    rule(:boolean_value_expression) do
      boolean_term | (boolean_value_expression >> space >> or_word >> space >> boolean_term)
    end

    rule(:boolean_term) do
      boolean_factor | (boolean_term >> space >> and_word >> space >> boolean_factor)
    end

    rule(:boolean_factor) do
      (not_word >> space).maybe >> boolean_test
    end

    rule(:boolean_test) do
      boolean_primary >> (space >> is_word >> (space >> not_word).maybe >> space >> truth_value).maybe
    end

    rule(:truth_value) do
      true_word | false_word | null | unknown
    end

    rule(:boolean_primary) do
      predicate | boolean_predicand
    end

    rule(:boolean_predicand) do
      parenthesized_boolean_value_expression | nonparenthesized_value_expression
    end

    rule(:predicate) do
      str("xxx") # TODO
    end

    rule(:parenthesized_boolean_value_expression) do
      lparen >> value_expression >> rparen
    end

    rule(:nonparenthesized_value_expression) do
      str("xxx") # TODO
    end

    rule(:function) do
      identifier >> lparen >> value_expression.maybe >> rparen
    end

    rule(:table_expression) do
      str("xxx") # TODO
    end

    root(:query_specification)
  end

  class PlainStringVisitor < Lingo::Visitor
    getter builder = String::Builder.new(2048)
    property fields = [] of String

    def print(text : String)
      builder.print(text)
    end

    enter(:select_list) do
      visitor.fields = [] of String

      visitor.print("select")
      visitor.print(" ")
    end

    exit(:select_list) do
      fields = visitor.fields
      visitor.print(fields.join(", "))
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

  abstract class Doc
    NIL = Nil.new
    LINE = Line.new

    abstract def layout(builder : String::Builder, spaces : Int16)

    def layout
      builder = String::Builder.new(1024 * 8)
      layout(builder, 0)
      builder.to_s
    end

    def +(other : Doc)
      Concat.new(self, other)
    end

    def +(other : _)
      self + Text.new(other)
    end
  end

  class Concat < Doc
    def initialize(@a : Doc, @b : Doc)
    end

    def layout(builder, spaces)
      @a.layout(builder, spaces)
      @b.layout(builder, spaces)
    end
  end

  class Nil < Doc
    def layout(builder, spaces)
      # Do nothing
    end
  end

  class Line < Doc
    def layout(builder, spaces)
      builder.puts
      spaces.times { builder.print(" ") }
    end
  end

  class Nest < Doc
    def initialize(@spaces : Int16, @doc : Doc)
    end

    def layout(builder, spaces)
      @doc.layout(builder, spaces + @spaces)
    end
  end

  class Text(T) < Doc
    def initialize(thing : T)
      @thing = thing
    end

    def layout(builder, spaces)
      builder.print(@thing)
    end
  end
end
