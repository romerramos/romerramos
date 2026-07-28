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
end
