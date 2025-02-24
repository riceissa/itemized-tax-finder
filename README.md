# itemized-tax-finder

This is a pretty simple program. The only technically interesting thing about
it is that the backend is implemented using a [single Nim file](./find_tax.nim)
which compiles to both JavaScript and a native executable. Let me repeat that.
There is a single source file which can be compiled to either JavaScript (to be
used in the browser) or a program you can run on the command line.

You can compile the project with:

```
make
```

and run the executable with e.g.:

```
./find_tax --amounts="22.09, 81.89, 16.24" --total="124.13" --tax-rates="1.100, 1.101, 1.102, 1.103"
```

Alternatively, you can visit `docs/index.html` in your browser to use the
JavaScript version, which is just the same as the [live
version](https://riceissa.github.io/itemized-tax-finder/).
