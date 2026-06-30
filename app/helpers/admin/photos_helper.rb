module Admin
  module PhotosHelper
    # Shared styling for admin form text inputs, matching the auth forms.
    def input_class
      "block rounded-md border border-white/20 bg-white/5 focus:border-brand " \
        "focus:ring-1 focus:ring-brand px-3 py-2.5 mt-1 w-full placeholder-white/40 text-white"
    end
  end
end
