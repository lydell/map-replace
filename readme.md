Overview
========

map-replace is a command line tool that applies replacements described in a JSON map to files.

Installation: `npm install -g map-replace`

```sh
$ cat hello.txt
Hello, World! Hello, everyone! And hello, you!
$ cat map.json
{
  "Hello": "Howdy",
  "!": "."
}
$ map-replace hello.txt < map.json
$ cat hello.txt
Howdy, World. Howdy, everyone. And hello, you.
$ map-replace --help

  Usage: map-replace [options] <files>

  Options:

    -h, --help           output usage information
    -V, --version        output the version number
    -m, --match <regex>  Only replace in substrings that match <regex>
    -f, --flags <flags>  Regex flags (g is implied)

Takes a map of search strings to replacements from stdin and applies that to each
provided file.
```

It was created as a companion to [hash-filename], to update paths in static HTML and CSS files to
their cache busted variants. hash-filename emits the JSON map.

```sh
$ map-replace --match "<[^>]+>" *.html < map.json
$ map-replace --match "url\([^)]+\)" *.css < map.json
```

The above only replaces inside HTML start tags (such as in attributes) and inside the `url()`
function in CSS. (Of course those regexes are not bullet proof, but good enough. KISS.)

[hash-filename]: https://github.com/lydell/hash-filename


License
=======

[GPLv3](COPYING).
