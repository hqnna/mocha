# Mocha Specification ![version](https://img.shields.io/badge/version-1.2-blue)

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