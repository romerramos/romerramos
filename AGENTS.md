# Agent Instructions

- I dont like custom actions on Controllers, stick to CRUD actions, if you need to create custom actions only to edit the same resource (e.g. update the position) just use the update method, if the action is "custom" enough then use a new controller that describe the resource/action clearly using the Rails naming conventions.
- I dont like HTTP requests coming from the client, instead I prefer forms (even hidden forms if needed) that way we keep everything in the Rails way avoiding weird hacks on authenticity tokens, CSRF, etc. Keep in mind that you might need to use requestSubmit instead of subminting the form fron JS directly
- A concept directory should match the entity or concept owned by that code. Follow Rails autoloading conventions so the directory and file path correspond to the class or module they define. For example, `app/concepts/charts/service.rb` should define `Charts::Service`.
- Concept file names should describe code roles or patterns, not business rules. Prefer names like `service`, `builder`, `factory`, `adapter`, `util`, `presenter`, etc.
- A service object holds business logic that serves an entity or concept. If logic merges, aggregates, or computes across concepts, choose the concept the action serves; if ownership is unclear, create a new concept and service object.
- An adapter wraps a library or external dependency so the dependency is not exposed throughout the application and can be changed later, also ideally it should be reusable in other apps (so no business logic).
- A builder, factory, or other design-pattern object provides that pattern for the concept and should use Ruby/Rails naming and autoloading conventions.
- Since we're in Rails not everything has to be a "concept" we can use concerns when it makes sense, just not add two level deep of nesting.
- Keep slim controllers and slim models as well
- I dont like HTML in JS or/and Rails herlpers, I prefer to keep HTML in the views, and show/hide as needed (using template tags when makes sense it's preferable)
- Use known/small and well documented libraries instead of making everything from scratch
- A dependency may own and generate its internal UI when that is its documented interface. Keep application usage declarative in ERB, avoid duplicating the library's markup in JavaScript, and review the dependency's license, accessibility, styling, and asset-loading requirements before adopting it.
