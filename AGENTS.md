# Agent Instructions

- I don't like custom actions in controllers. Stick to CRUD actions. If you need to create a custom action only to edit the same resource (e.g., update its position), just use the update method. If the action is "custom" enough, use a new controller that clearly describes the resource/action, following Rails naming conventions.
- I don't like HTTP requests coming from the client. Instead, I prefer forms (even hidden forms, if needed). That way, we keep everything within Rails conventions and avoid weird hacks involving authenticity tokens, CSRF, etc. Keep in mind that you might need to use `requestSubmit` instead of submitting the form directly from JavaScript.
- A concept directory should match the entity or concept owned by that code. Follow Rails autoloading conventions so the directory and file path correspond to the class or module they define. For example, `app/concepts/charts/service.rb` should define `Charts::Service`.
- Concept file names should describe code roles or patterns, not business rules. Prefer names like `service`, `builder`, `factory`, `adapter`, `util`, `presenter`, etc.
- A service object holds business logic that serves an entity or concept. If logic merges, aggregates, or computes across concepts, choose the concept the action serves; if ownership is unclear, create a new concept and service object.
- An adapter wraps a library or external dependency so that the dependency is not exposed throughout the application and can be changed later. Ideally, it should also be reusable in other apps (so it should contain no business logic).
- A builder, factory, or other design-pattern object provides that pattern for the concept and should use Ruby/Rails naming and autoloading conventions.
- Since we're using Rails, not everything has to be a "concept." We can use concerns when it makes sense, but avoid adding two levels of nesting.
- Keep controllers and models slim as well.
- Keep controller private methods within the HTTP/request layer or use them to invoke model and concept APIs. Put relation construction, record eligibility, and reusable query composition in clearly named model scopes rather than hiding Active Record queries in controller methods.
- I don't like HTML in JavaScript or Rails helpers. I prefer to keep HTML in the views and show or hide it as needed (using template tags when appropriate).
- Use well-known, small, and well-documented libraries instead of making everything from scratch.
- A dependency may own and generate its internal UI when that is its documented interface. Keep application usage declarative in ERB, avoid duplicating the library's markup in JavaScript, and review the dependency's license, accessibility, styling, and asset-loading requirements before adopting it.
- I don't like data migrations or data "fixes" that use migrations. Keep migrations for schema changes only. If we need to fix data, use Rake tasks that allow us to perform backfills in phases so they are safe to apply.
