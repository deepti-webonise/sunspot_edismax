module Sunspot
  module Query

    #
    # Solr query abstraction
    #
    class AbstractFulltext
      attr_reader :fulltext_fields

      #
      # Assign a new boost query and return it.
      #
      def create_boost_query(factor)
        @boost_queries << boost_query = BoostQuery.new(factor)
        boost_query
      end

      #
      # Add a boost function
      #
      def add_boost_function(function_query)
        @boost_functions << function_query
      end

      #
      # Add a fulltext field to be searched, with optional boost.
      #
      def add_fulltext_field(field, boost = nil)
        @fulltext_fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      #
      # Add a phrase field for extra boost.
      #
      def add_phrase_field(field, boost = nil)
        @phrase_fields ||= []
        @phrase_fields << TextFieldBoost.new(field, boost)
      end

      # Add a pf2 field for extra boost and proximity.
      def add_phrase_2_field(field, boost = nil)
        @phrase_2_fields ||= []
        @phrase_2_fields << TextFieldBoost.new(field, boost)
      end

      # Add a pf3 field for extra boost and proximity.
      def add_phrase_3_field(field, boost = nil)
        @phrase_3_fields ||= []
        @phrase_3_fields << TextFieldBoost.new(field, boost)
      end

      #
      # Set highlighting options for the query. If fields is empty, the
      # Highlighting object won't pass field names at all, which means
      # the dismax's :qf parameter will be used by Solr.
      #
      def add_highlight(fields=[], options={})
        @highlights << Highlighting.new(fields, options)
      end

      #
      # Determine if a given field is being searched. Used by DSL to avoid
      # overwriting boost parameters when injecting defaults.
      #
      def has_fulltext_field?(field)
        @fulltext_fields.has_key?(field.indexed_name)
      end

      private

      def escape_param(key, value)
        "#{key}='#{escape_quotes(Array(value).join(" "))}'"
      end

      def escape_quotes(value)
        return value unless value.is_a? String
        value.gsub(/(['"])/, '\\\\\1')
      end
    end
  end
end
