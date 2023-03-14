Mocha
![license](https://img.shields.io/badge/license-BSD--3--Clause--Clear-blue)
![build](https://builds.sr.ht/~hanna/mocha.svg)
================================================================================

An elegant, simple human and machine readable configuration language.

## Examples

Mocha is based on YAML, JSON, and a tiny bit of Nix, it aims to be readable for
both humans and machines, while also only providing the minimal amount of
features to prevent edge cases all while keeping a small footprint.

```
hello: {
  id: 1024
  admin: true
  # this is an example comment
  inventory: ['apple' 'cake' 'sword']
  metadata: {
    heck: false
  }
}
```

There is more examples of the format in the `examples` folder.

## Running Tests

To run the library tests you'll need to install [Zig](https://ziglang.org)
first, afterwords, you can test the library by doing the following commands:

```sh
git clone https://git.sr.ht/~hanna/mocha
cd mocha && zig build test
```

## Differences to other formats

While somewhat similar and inspired by other languages, it's also different.

### Compared to JSON

```
- The "global" object is implicit rather than explicit
- Keys aren't allowed to have quotes or spaces
- Mocha uses `nil` rather than json/yaml's `null`
```

### Compared to YAML

```
- Objects must be explicitly denoted with braces
- Arrays must be explicitly denoted with brackets
- White space is mostly ignored except in the case of:
    - Seperating values and fields on a single line
```

### Diferences to both

```
- Strings are only allowed to use single quotes
- Only integer and floating point numbers work[1]
- Commas are completely removed from the format

[1]: Hexadecimal and binary literals are planned
```