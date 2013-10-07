###
Copyright 2013 Simon Lydell

This file is part of map-replace.

map-replace is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

map-replace is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along with map-replace. If not,
see <http://www.gnu.org/licenses/>.
###

program   = require "commander"
ucurry    = require "ucurry"
asyncEach = require "async-each"

{modify, mapReplace, readStdin} = require "./helpers"
__ = undefined


module.exports = (process)->
	program
		.version(require("../package").version)
		.usage("[options] <files>")
		.option("-m, --match <regex>", "Only replace in substrings that match <regex>")
		.option("-f, --flags <flags>", "Regex flags (g is implied)")

	program.on "--help", ->
		console.log """
			Takes a map of search strings to replacements from stdin and applies that to each
			provided file.
			"""

	program.parse(process.argv)

	if program.args.length is 0
		program.help()

	readStdin process, (map)->
		asyncEach program.args,
			ucurry(modify, __, ucurry(mapReplace, __, map, program), __),
			(error)->
				if error
					process.stderr.write error.toString() + "\n"
					process.exit 1
				else
					process.exit 0
