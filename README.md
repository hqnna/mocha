Mocha
![license](https://img.shields.io/badge/license-BSD--3--Clause--Clear-blue)
![build](https://builds.sr.ht/~hanna/mocha.svg)
================================================================================

An elegant, simple human and machine readable configuration language.

## Specification

The language and format specification can be found in the docs folder,
[here](https://git.sr.ht/~hanna/mocha/tree/main/item/docs/specification.md).

## Running Tests

To run the library tests you'll need to install [Zig](https://ziglang.org)
first, afterwords, you can test the library by doing the following commands:

```sh
git clone https://git.sr.ht/~hanna/mocha
cd mocha && zig build test
```

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
