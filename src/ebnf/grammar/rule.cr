module EBNF
  # A part of a production that consits of one or more Atoms
  class Rule
    include Enumerable(Atom)

    def initialize(@atoms = Array(Atom).new)
    end

    def clone
      Rule.new @atoms.clone
    end

    JSON.mapping(
      atoms: Array(Atom)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      if grammar_type == Grammar::Type::EBNF
        @atoms.join(", ", io) { |a, io| a.to_s io, grammar_type }
      else
        @atoms.join(" ", io) { |a, io| a.to_s io, grammar_type }
      end
    end

    def pretty_print(pp)
      pp.text self.to_s
    end

    def resolve(grammar : Grammar)
      resolve grammar, true
    end

    def resolve?(grammar : Grammar)
      resolve grammar, false
    end

    private def resolve(grammar : Grammar, exception? : Bool)
      @atoms.each do |atom|
        if atom.is_a? Nonterminal
          production = grammar[atom.value]?
          unless production
            if exception?
              raise "Could not resolve Nonterminal #{atom.value}: No such production in grammar!"
            else
              return nil
            end
          end
          atom.production = production
        elsif atom.is_a? EBNF::Special
          return nil unless atom.resolve grammar, exception?
        end
      end
    end

    delegate :[], :[]?, :<<, :each, :size, :empty?, to: @atoms

    def_hash @atoms
  end

  # An Empty `Rule` in a grammar
  #
  # <foo> ::= | '1' | '0'
  class Empty < Rule
    def initialize
      @atoms = Array(Atom).new
    end

    def to_s(io, grammar_type = Grammar::Type::Bison)
    end
  end

  module Bison
    class Rule < Rule
      def initialize(@atoms = Array(Atom).new, @action = nil)
      end

      def clone
        Bison::Rule.new @atoms.clone, @action.clone
      end

      JSON.mapping(
        atoms: Array(Atom),
        action: String?
      )

      def to_s(io, grammar_type = Grammar::Type::Bison)
        super(io, grammar_type)
        io << "\t\t\t{#{@action}}" if @action
      end

      def_hash @atoms, @action
    end
  end
end
