lazorse = require '../'
lazorse ->
  greetingLookup = english: "Hi", french: "Salut"

  # This defines a route that accepts both GET and POST
  @route "/greeting/{language}":
    description: "Retrieve or store a per-language greeting"
    shortName: 'localGreeting'
    GET:  -> @ok greeting: greetingLookup[@language], language: @language
    POST: -> greetingLookup[@language] = @req.body; @ok()
    examples: [
      {method: 'GET', vars: {language: 'english'}}
      {method: 'POST', vars: {language: 'english'}, body: "howdy"}
    ]

  # Define a coercion that restricts input languages to the
  # ones we have pre-defined
  @coerce language: (lang, next) ->
    lang = lang.toLowerCase()
    unless greetingLookup[lang]?
      return next new lazorse.InvalidParameter 'language', lang
    next null, lang