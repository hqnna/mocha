Mocha
![license](https://img.shields.io/github/license/xhxnnx/mocha?style=flat-square)
![build](https://img.shields.io/github/actions/workflow/status/xhxnnx/mocha/tests.yml?style=flat-square)
================================================================================

An elegant, simple human and machine readable configuration language.

## Specification

The language and format specification can be found in the docs folder,
[here](https://github.com/xhxnnx/mocha/blob/main/docs/specification.md).

## Running Tests

To run the library tests you'll need to install [Zig](https://ziglang.org)
first, afterwords, you can test the library by doing the following:

```sh
git clone https://github/xhxnnx/mocha
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
