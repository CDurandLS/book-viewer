require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'

before do
  @contents = File.readlines("data/toc.txt")
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/search" do
  query = params[:query]
  @results = paragraphs_matching(params[:query])
  
  erb :search
end


get "/chapters/:chapter_number" do 
  @chapter_number = params[:chapter_number].to_i
  redirect '/' unless (1..@contents.size).cover? @chapter_number
  @title = "Chapter #{@chapter_number}: #{@contents[@chapter_number - 1]}"
  @chapter = File.read("data/chp#{@chapter_number}.txt")

  erb :chapter
end

helpers do
  def highlight(query, text)
    text.gsub(/(#{Regexp.quote(query)})/, '<strong>\1</strong>')
  end

  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |chapter, index|
      "<p id=\"p#{index}\" style=\"text-indent: 40px\">#{chapter}</p>"
    end.join("")
  end

  def each_chapter
    @contents.each_with_index do |title, index|
      number = index+1
      contents = File.read("data/chp#{number}.txt")
      yield number, title, contents
    end
  end

  def paragraphs_matching(query)
    results = chapters_matching(query)
    results.each do |result|
      result[:matches] = []
      result[:contents].split("\n\n").each_with_index do |paragraph, number|
        result[:matches] << {p: paragraph, id: "p#{number}"} if paragraph.include?(query)
      end
    end
    results
  end


  def chapters_matching(query)
    results = []
    return results if !query || query.empty?

    each_chapter do |number, title, contents|
      results << {contents: contents, number: number, title: title} if contents.include?(query)
    end
    results
  end
end

