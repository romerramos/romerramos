require "ruby_llm/schema"

class PostTranslations::Schema < RubyLLM::Schema
  string :rewritten, min_length: 1
end
