class LanguagesController < ApplicationController
  def index
    # Read the languages.json file and parse it into an array of hashes
    @languages = JSON.parse(File.read(Rails.root.join('app/assets/languages.json')))
    
    # If a search query parameter is present, filter the array by the query
    if params[:search]
      search_query = params[:search].downcase
      @languages = @languages.select { |language| match_language?(language, search_query) }
      @languages = order_by_relevance(@languages, search_query)
    end

    # Render the index.html.erb view with the languages
    # Respond to requests for JSON data with the languages array as JSON
    respond_to do |format|
      format.html { render "index" }
      format.json { render json: @languages } 
    end 
  end
  
  private
  
  # Method to determine if a language matches a search query
  def match_language?(language, query)
    # Split the query into individual words
    query_terms = query.split(' ')
    
    # Check if all search terms match at least one field in hash
    query_terms.all? do |term|
      # Check if the search query has negative terms
      negative_search = term.start_with?('-')
      term = term[1..-1] if negative_search
      
      # Extract all fields from the hash and convert to lowercase
      matching_fields = [
        language['Name'],
        language['Type'],
        language['Designed by']
      ].compact.map(&:downcase)
      
      # Check if the search term matches any of the matching fields
      # If the search term is negated, invert the match result
      match = matching_fields.any? { |field| field.include?(term) }
      negative_search ? !match : match
    end
  end
  
  # Method to order languages by relevance
  def order_by_relevance(languages, query)
    languages.sort_by do |language|
      # Combine the matching fields into a single string and convert to lowercase
      matching_fields = [
        language['Name'],
        language['Type'],
        language['Designed by']
      ].compact.join(' ').downcase
      
      # Calculate the relevance score for the language based on the number of query terms that match
      relevance = 0
      query.split(' ').each do |term|
        relevance += 1 if matching_fields.include?(term.downcase)
      end
      
      # Return the negative relevance score to sort the array in descending order
      -relevance
    end
  end
end