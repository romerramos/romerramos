namespace :post_translations do
  desc "Copy legacy post publication state to translations that have not been backfilled"
  task backfill_publication: :environment do
    scope = PostTranslation.where(published: nil).includes(:post)
    updated = 0

    scope.find_each do |translation|
      translation.update_columns(
        published: translation.post.published?,
        published_at: translation.post.published_at,
        updated_at: Time.current
      )
      updated += 1
    end

    puts "Backfilled #{updated} post translations."
  end

  desc "Regenerate unpublished Spanish drafts using the current writing instructions"
  task regenerate_spanish_drafts: :environment do
    force = ENV["FORCE"] == "1"
    scope = (force ? PostTranslation.spanish_drafts : PostTranslation.pending_spanish_draft_regeneration)
      .includes(post: :post_translations)

    if ENV["POST_IDS"].present?
      scope = scope.where(post_id: ENV["POST_IDS"].split(",").map(&:strip))
    end

    adapter = PostGenerations::Adapter.new
    counts = Hash.new(0)
    failures = []

    scope.find_each do |translation|
      result = PostTranslations::SpanishDraftRegenerator.new(
        translation,
        adapter: adapter,
        force: force
      ).call
      counts[result] += 1
    rescue StandardError => error
      failures << translation.id
      warn "Failed to regenerate Spanish draft ##{translation.id}: #{error.class}: #{error.message}"
    end

    puts "Regenerated #{counts[:regenerated]} Spanish drafts."
    puts "Skipped #{counts.values_at(:published, :already_regenerated, :missing_source, :changed).sum} translations."

    raise "Spanish draft regeneration failed for translations: #{failures.join(", ")}" if failures.any?
  end
end
