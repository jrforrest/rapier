Rapier
======

This was intended to be a library for providing a simpler way of defining
object-oriented, JSON based REST APIs.  It was also inteded to provide
automated documentation generation in both MarkDown and JSON formats.  The
JSON format documentation would allow a single client library to dynamically
service any Rapier API, or other APIs which followed the same JSON documentation
convention.

__This is a failed experiment.  The code is left here as there are parts
of it I wanted to share, but I will not maintain or support this package,
and I highly recommend that nobody actually try to use this__

Why This Failed
---------------

Some of the ideas behind this project were good, but there were too many
parts of the design I did not consider until well into the implementation
stage.  I also failed to consider the real life implications of the
horribly inconvienient and verbose configuration interface.

### The good ideas

* The global object thing might not be a bad idea.  I'm thinking that this
  would make a lot more sense to implement as a mixin for objects in the model
  layer.  Going the mixin route would also allow the user to specify another
  mapping layer above the ORM for translating database objects (or combinations
  of database objects) to API objects.)
* Automatic parameter validation and type casting is pretty sweet.  Too bad I
  made the interface for specifying these such a pain in the ass.  I guess
  I could have allowed use of object fields as request parameters, since those
  already have a type and all.
* The JSON documentation (spec I suppose?) is nifty.  I have a client library
  (too shoddy to post here) that generates an API client object dynamically
  using the spec.  This could save a lot of time in writing client libraries
  for all target languages.
* Response objects are nice for telling the user what they'll get back, but
  are perhaps too inflexible.
* The top level exception handlers (not fully implemented) are cool.  I need
  some sort of exeption-case response handlers for these though, as the
  {:message => ''} format is not always adequate.

### The bad ideas

 * Using a block-oriented configuration scheme is what really sunk the ship.
   Implementation was a pain in the ass, and while that seems to be a trendy
   way of doing things in Ruby it really doesn't offer much in this case, as
   far as I can tell.
 * The interface for specifying response objects sucks.  I should have put
   that field method behind a mixin for existing objects so there's not
   too definitions of what an object exposes.
 * Lack of Arrays was dumb.  Arrays are absolutely a necessary primitive type.
 * Lack of HTTP method configuration was pretty stupid.  Any route responds
   to any method is just not a good scheme.

My Next Attempt
---------------

I think there's enough good ideas here to make something useful.  The tricky
part is designing something cohesive and elegant of course, but I think
the idea of using mixins for defining objects, and perhaps allowing easy
exposing of those objects via a REST interface might work out.  I'll probably
give that a shot in the near future.

The JSON spec which allows self-generating clients is frikin' rad.  I want
to find a way to make that actually work.
