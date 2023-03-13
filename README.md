Mocha
![license](https://img.shields.io/badge/license-BSD--3--Clause--Clear-blue?style=flat-square)
![fun](https://img.shields.io/badge/justforfunnoreally-dev-9ff?style=flat-square)
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