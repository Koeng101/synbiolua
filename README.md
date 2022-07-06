# synbiolua

Synbiolua is a lua package for genetically engineering organisms.

* __Embeddable:__ synbiolua can be embedded in larger programs
* __Modern:__ synbiolua is built for engineering in the modern day, from codon optimization to synthesis fixing.
* __Maintainable:__ synbiolua is built for long term stability and continuous testing.

## Documentation

Reference documentation can be found [here](doc/index.html)

### Directories
* `src` contains source code (written in [teal](https://github.com/teal-language))
* `build` contains lua code, generated from teal
* `doc` contains automatically generated ldoc documentation
* `spec` contains specification files (ie, test files)

### Building and testing
To build from source, run:
```
cyan build
```

To test from source, run:
```
busted -c
```

### Thanks
Much of the code here is translated from [Poly](https://github.com/TimothyStiles/poly), a wonderful project you should follow.
