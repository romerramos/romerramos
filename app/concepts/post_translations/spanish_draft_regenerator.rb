class PostTranslations::SpanishDraftRegenerator
  SOURCE_LOCALE = "en"
  TARGET_LOCALE = "es"

  def initialize(translation, adapter: PostGenerations::Adapter.new, force: false)
    @translation = translation
    @adapter = adapter
    @force = force
  end

  def call
    translation.reload
    return :published if translation.published?
    return :already_regenerated if regenerated? && !force

    source = translation.post.post_translations.find { |item| item.locale == SOURCE_LOCALE }
    return :missing_source unless source&.content.present?

    original_draft = draft_attributes
    response = adapter.generate(
      JSON.generate(
        source_locale: SOURCE_LOCALE,
        transcript: source_material(source)
      ),
      instructions: PostGenerations::Service::WRITING_INSTRUCTIONS,
      schema: PostGenerations::Schema
    )

    persist(response.content.fetch(TARGET_LOCALE), original_draft)
  end

  private

    attr_reader :translation, :adapter, :force

    def source_material(source)
      [
        "Title: #{source.title}",
        ("Description: #{source.description}" if source.description.present?),
        "Content:",
        source.content
      ].compact.join("\n\n")
    end

    def draft_attributes
      translation.attributes.slice("title", "description", "content")
    end

    def regenerated?
      translation.spanish_draft_regenerated_at.present?
    end

    def persist(spanish_translation, original_draft)
      translation.with_lock do
        translation.reload
        return :published if translation.published?
        return :already_regenerated if regenerated? && !force
        return :changed unless draft_attributes == original_draft

        translation.update!(
          title: spanish_translation.fetch("title"),
          description: spanish_translation.fetch("description"),
          content: spanish_translation.fetch("content"),
          spanish_draft_regenerated_at: Time.current
        )
      end

      :regenerated
    end
end
