module Sunspot
  module Query

    #
    # Solr full-text queries use Solr's DisMaxRequestHandler, a search handler
    # designed to process user-entered phrases, and search for individual
    # words across a union of several fields.
    #
    class Dismax < AbstractFulltext
      attr_writer :minimum_match, :phrase_slop, :query_phrase_slop, :tie, :phrase_2_slop, :phrase_3_slop

      def initialize(keywords)
        @keywords = keywords
        @fulltext_fields = {}
        @boost_queries = []
        @boost_functions = []
        @highlights = []

        @minimum_match = nil
        @phrase_fields = nil
        @phrase_slop = nil
        @query_phrase_slop = nil
        @tie = nil
        @phrase_2_slop = nil
        @phrase_3_slop = nil
      end

      #
      # The query as Solr parameters
      #
      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:qf] = @fulltext_fields.values.map { |field| field.to_boosted_field }.join(' ')
        params[:defType] = 'edismax'
        params[:mm] = @minimum_match if @minimum_match
        params[:ps] = @phrase_slop if @phrase_slop
        params[:qs] = @query_phrase_slop if @query_phrase_slop
        params[:tie] = @tie if @tie
        params[:ps2] = @phrase_2_slop if @phrase_2_slop
        params[:ps3] = @phrase_3_slop if @phrase_3_slop

        if @phrase_fields
          params[:pf] = @phrase_fields.map { |field| field.to_boosted_field }.join(' ')
        end

        if @phrase_2_fields
          params[:pf2] = @phrase_2_fields.map { |field| field.to_boosted_field }.join(' ')
        end

        if @phrase_3_fields
          params[:pf3] = @phrase_3_fields.map { |field| field.to_boosted_field }.join(' ')
        end

        unless @boost_queries.empty?
          params[:bq] = @boost_queries.map do |boost_query|
            boost_query.to_boolean_phrase
          end
        end

        unless @boost_functions.empty?
          params[:bf] = @boost_functions.map do |boost_function|
            boost_function.to_s
          end
        end

        @highlights.each do |highlight|
          Sunspot::Util.deep_merge!(params, highlight.to_params)
        end

        params
      end

      #
      # Serialize the query as a Solr nested subquery.
      #
      def to_subquery
        params = self.to_params
        params.delete :defType
        params.delete :fl

        keywords = escape_quotes(params.delete(:q))
        options = params.map { |key, value| escape_param(key, value) }.join(' ')

        { :q => "_query_:\"{!edismax #{options}}#{keywords}\"" }
      end

      #
      # Add a fulltext field to be searched, with optional boost.
      #
      def add_fulltext_field(field, boost = nil)
        super unless field.is_a?(Sunspot::JoinField)
      end

    end
  end
end
