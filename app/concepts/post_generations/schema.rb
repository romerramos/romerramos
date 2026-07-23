require "ruby_llm/schema"

class PostGenerations::Schema < RubyLLM::Schema
  object :en do
    string :title, min_length: 1, max_length: 120
    string :description, min_length: 1, max_length: 220
    string :content, min_length: 1
  end

  object :es do
    string :title, min_length: 1, max_length: 120
    string :description, min_length: 1, max_length: 220
    string :content, min_length: 1
  end
end
