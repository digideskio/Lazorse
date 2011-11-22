# LAZORSE!

What do lazers and horses have in common? They will both kill you without a second thought (or a first thought).

Also, they share a few phonemes with "lazy" and "resource", which is what Lazorse is all about.

## K, wtf is it?

Lazorse is a connect middleware stack that routes requests, coerces parameters,
dispatches to handlers, and renders a response. It borrows heavily from
[other][zappa] [awesome][coffeemate] [web frameworks][express] but with a couple
of twists designed to make writing machine-consumable ReSTful APIs a little
easier.

### Routing

First and foremost of these is the route syntax: it's the same syntax as the 
[draft spec][uri template rfc] for URI templates, but extends them with
parameter matching semantics as well. These are covered more extensively later
in this document.

Lazorse by default owns the `/` and `/schema/*` routes. The root route will
respond with an object that maps all registered routes/URI templates to a
route object. So an app with a single route like:

```coffee
greetingLookup = english: "Hi", french: "Salut"

@route '/{language}/greeting':
  description: "Retrieve or store per-language greetings"
  shortName: 'localGreeting'
  GET: -> @ok greetingLookup[@language]
  POST: -> greetingLookup[@language] = @req.body; @ok()
```

Will return a spec object like:

```json
{
  "/{language}/greetings": {
    "description": "Retrieve or store per-language greetings",
    "shortName": "localGreeting",
    "methods": ["GET", "POST"]
  }
}
```

All of the keys are optional, but chances are you want to include at least one
HTTP method handler, or your route will be unreachable. Additionally, the
shortname can be nice for giving client a consistent way to refer to the URI.

### Coercions

Coercions are a direct rip-off of [Express'][express] `app.param` functionality.
You can declare a coercion callback anywhere in your app, and it will be called
whenever a URI template matches a parameter of the same name. For example:

```coffee
@coerce language: (lang, next) ->
  lang = lang.toLowerCase()
  if lang not in greetings
    next new Error "Invalid language!"
  else
    next null, lang
```

Will ensure that only pre-defined languages are allowed to reach the actual
handler functions.

### Handlers and environments

Of course you're probably wondering about those handler functions. Each handler
function is called with `this` bound to a context containing the following keys:

 - `req` and `res`: request and response objects direct from connect.
 - `data` and `ok`: Callbacks that will set the data property for the rendering
    layer. (Don't worry, that's next). The only difference is that `ok` does
    _not_ handle errors, it only accepts a single argument and assumes that's
    what you want to return to the client. `data` on the other hand, will treat
    the first argument as an error in typical node callback style.
 - `link`: Takes a route shortName and a context object and returns the result
    of expanding the corresponding URI template in that context.

Although the examples have taken no parameters, handlers _do_ get one parameter:
the request context. This means you can use fat-arrow handlers if necessary.

### Rendering

Lazorse includes no templating. Instead, rendering is handled as another
middleware in the stack. The default rendering middleware supports (bare-bones)
HTML and JSON. It inspects the `Accept` header to see what the client wants,
and falls back to JSON when it can't provide it. You can easily add or override
the renderer for a new content type like so:

```coffee
render = require('lazorse/render')
render['application/vnd.wonka-ticket'] = (req, res, next) ->
	ticket = res.data
	res.write bufferOverflowThatTransportsClientToTheChocolateFactory()
	res.end "pwnd"
```

Obviously, your own renderers would do something actually useful. In addition to
`res.data`, Lazorse will add a `req.route` property that is the route object
that serviced the request. This could be used to do something like look up a
template or XML schema with `req.route.shortName`.

### URI Template matching

The matching semantics for URI templates are my addition to the RFC that
specifies their expansion algorithm. My intention is to meet and maintain the
constraint that expanding a template with the vars it returned when parsing a
URL will return the same URL. In order to do this we need the following rules
for what can and cannot match:

  * All parameters, excepting query string parameters, are required.
  * Query string parameters cannot do positional matching. E.g. ?one&two&three
		will always fail. You must use named parameters in a query string.
  * Query string parameters with an explode modifier (e.g. {?list*}) currently
		will parse differently than they expand. I strongly recommend not to use
		the explode modifier for query string params

### Schemas

TODO - Determine if these are even useful.

## TODO

* More tests, as always.
* Factor different operators into different Expression specializations,
	hopefully this will help clean up some of the logic in Expression::match

## License

MIT

[express]: http://expressjs.com
[zappa]: http://zappajs.org
[coffeemate]: https://github.com/kadirpekel/coffeemate
[uri template rfc]: http://tools.ietf.org/html/draft-gregorio-uritemplate-07
