# Mocha

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