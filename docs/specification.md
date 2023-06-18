Mocha Specification
![version](https://img.shields.io/badge/version-1.4-blue?style=flat-square)
================================================================================

This document contains the grammar and language specifications for the **Mocha**
configuration and data serialization format. Everything in this document should
be followed when implementing a parser or deserializer for the language. Should
you implement your own parser, tokenizer, and/or deserializer for the format, it
should be noted that currently the language and format is ever evolving, tagged
versions however will not change as they are meant to be "concrete" in terms of
changes. The current version of the specification will always be in the title.

## Official Implementation

The original implementation of the language's tokenizer, parser, and
deserializer are in this repository and *only* this repository. The original
implementation is written in the [Zig](https://ziglang.org) language and not any
other programming language. Any other repository or source code claiming to be
the language or format's official or original implementation should not be
trusted. Forks are allowed  as long as the license is respected.

## Global Namespace

Unlike JSON the "global" namespace or object is implicit rather than explicit,
it is not necessary to surround the document in brackets, this is actually
completely prohibited due to it being useless and adding extra bloat. Instead,
only objects that are values for fields require brackets to denote them.

```
id: 1024
admin: true
# this is an example comment
inventory: ['apple' 'cake' 'sword']
metadata: {
  heck: false
}
```

## Identifiers

Unlike JSON or YAML, identifiers can not contain spaces, it is recommended to
use underscores instead. Identifiers can not be surrounded by any form of
quotes, they are raw strings that do not allow spaces.

```
this_is_valid
'this is not'
"this is also not"
`as well as this`
```

## Whitespace

Tokens and identifiers can be separated by any amount of whitespace, including no whitespace.
The only exception to this are references.
Whitespace is defined as any of the following characters:
space ` ` (`0x20`), newline `\n` (`0x0a`), carriage return `\r` (`0x0d`), and tab `\t` (`0x09`).

## Comments

A `#` character outside a string starts a comment which ends at next newline `\n`.

## References

As of Mocha version 0.4.0 and specification version 1.3, mocha now supports field and object
references. This allows you to reuse values from other fields and objects across multiple fields
with ease. Note that references are **position dependent** meaning a field has to be previously
defined above it for a reference to be able to properly resolve. To reference another field, you can
use it's identifier, to reference a field in an object, you can use the field/namespace (`:`)
operator. It should be noted that references are resolved at the **scope** level, to reference
things outside of the field's current scope, it is possible to use the root (`@`) namespace to
reference the root of the document.

```
defaults: {
  user_id: 0
}

hanna: {
  name: 'hanna rose'
  id: @:defaults:user_id
  inventory: ['banana' 'apple']
}
```

As of specification version 1.4, it also now possible to reference values in arrays by index.
Indexing can be done with the common syntax: a non-negative integer enclosed by square brackets.
Array indices start at 0. An example using this functionality can be seen below.

```
defaults: {
  user_ids: [1231 237286 2323 1231]
  complex: [{ hello: 'hello world' }]
}

hanna: {
  # this is equal to 237286
  id: @:defaults:user_ids[1]
  message: @:defaults:complex[0]:hello
}
```

## Data Types

Mocha consists of 5 basic types: `string`, `int`, `float`, `boolean`, and `nil`,
it also has 2 complex types, namely `Array` and `Object`. Strings must start and
end with single quotes and can contain new lines. Integers can be standard
integers but they can also be in hexidecimal, octal and binary formats. Floats
can be both standard and scientific notation. Booleans are the standard values
most formats use, finally `nil` is used in-place of `null` unlike other
languages. It should be noted that you can escape single quotes in strings to
allow the use of the character in them, however unlike most languages, other
things such as `\n`, `\t`, `\s`, `\`, etc work out of the box and don't need to
be escaped.

```
# strings
'basic string'
'escaped \' string'
'multiline
string'

# integers
1024
0xffff
0b11000000
0o777
-1024

# floats
12.32
-64.2
1.024e3
1.024e+3
-1.024e+3
-1024e-3
1024e-3
1.0e3

# boolean
true
false

# null values
nil
```

Arrays are similar to JSON arrays except they do not use commas.

```
['hello' 'world' 'how' 'are' 'you']
```

Objects contain fields, which are an identifier and value seperated by a colon.

```
{
    id: 1024
    admin: false
    name: 'hanna'
}
```
