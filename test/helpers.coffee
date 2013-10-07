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

{expect, sinon, readFile, writeFile} = require "./common"
{modify, mapReplace, readStdin} = require "../lib/helpers"


describe "modify", ->

	beforeEach ->
		readFile.reset()
		readFile.resetBehavior()
		writeFile.reset()
		writeFile.resetBehavior()


	it "modifies the given file using the given modify function", ->
		modifyFn = sinon.stub().returns("new contents")
		callback = sinon.spy()
		readFile.yields(null, new Buffer "contents")
		writeFile.yields(null)

		modify "file", modifyFn, callback

		expect(readFile).to.have.been.calledWith("file")
		expect(modifyFn).to.have.been.calledWith("contents")
		expect(writeFile).to.have.been.calledWith("file", "new contents")
		expect(callback).to.have.been.calledWith(null)


	it "handles read errors", ->
		modifyFn = sinon.spy()
		callback = sinon.spy()
		error = new Error
		readFile.yields(error)

		modify "file", modifyFn, callback

		expect(readFile).to.have.been.called
		expect(callback).to.have.been.calledWith(error)
		expect(modifyFn).to.not.have.been.called
		expect(writeFile).to.not.have.been.called


	it "handles write errors", ->
		modifyFn = sinon.spy()
		callback = sinon.spy()
		readFile.yields(null, new Buffer "contents")
		error = new Error
		writeFile.yields(error)

		modify "file", modifyFn, callback

		expect(readFile).to.have.been.called
		expect(modifyFn).to.have.been.called
		expect(writeFile).to.have.been.called
		expect(callback).to.have.been.calledWith(error)


	it "handles modify function errors", ->
		error = new Error
		modifyFn = sinon.stub().throws(error)
		callback = sinon.spy()
		readFile.yields(null, new Buffer "contents")

		modify "file", modifyFn, callback

		expect(readFile).to.have.been.called
		expect(modifyFn).to.have.been.called
		expect(callback).to.have.been.calledWith(error)
		expect(writeFile).to.not.have.been.called


describe "mapReplace", ->

	it "applies the replacements described in a map to a string", ->
		map =
			"foo": "bar"
			"app.js": "app-HASH.js"
		string = """
			Have some foo, foobar in your app. js rocks. app.js isn't bapp.jsp.
			"""
		replaced = mapReplace(string, map)
		expect(replaced).to.equal """
			Have some bar, barbar in your app. js rocks. app-HASH.js isn't bapp-HASH.jsp.
			"""


	it "regex-escapes", ->
		map =
			"/* \\n/ */": "/* \\m/ */"
		string = """
			\n//
			///// \n/   /
			/* \\n/ */
			"""
		replaced = mapReplace(string, map)
		expect(replaced).to.equal """
			\n//
			///// \n/   /
			/* \\m/ */
			"""


	it "accepts a map also as a JSON string", ->
		map = """
			{
				"foo": "bar",
				"app.js": "app-HASH.js"
			}
			"""
		string = """
			Have some foo, foobar in your app. js rocks. app.js isn't bapp.jsp.
			"""
		replaced = mapReplace(string, map)
		expect(replaced).to.equal """
			Have some bar, barbar in your app. js rocks. app-HASH.js isn't bapp-HASH.jsp.
			"""


	it "handles all of the other JSON values", ->
		expect(mapReplace("foo", null)).to.equal("foo")
		expect(mapReplace("foo", true)).to.equal("foo")
		expect(mapReplace("foo", false)).to.equal("foo")
		expect(mapReplace("foo", 123)).to.equal("foo")
		expect(mapReplace("foo", '"string"')).to.equal("foo")
		expect(mapReplace("foo", [])).to.equal("foo")


	it "only replaces in substrings matching the supplied regex (as a string)", ->
		map =
			"foo.jpg": "foo-HASH.jpg"
		string = """
			<img src="/imgs/foo.jpg" alt="foo.jpg (sucky alt attribue)">
			Download <a href="/imgs/foo.jpg">foo.jpg</a> today!
			"""
		replaced = mapReplace(string, map, {match: "<[^>]+>"})
		expect(replaced).to.equal """
			<img src="/imgs/foo-HASH.jpg" alt="foo-HASH.jpg (sucky alt attribue)">
			Download <a href="/imgs/foo-HASH.jpg">foo.jpg</a> today!
			"""


	it "uses the supplied flags for a supplied regex", ->
		map =
			"Firefox": "Thunderbird"
			"a browser": "an e-mail client"
		string = """
			Mozilla Firefox is a browser. Some call it simply Firefox.
			Mozilla Firefox rocks. Mozilla Firefox is awesome.
			"""
		replaced = mapReplace(string, map, {match: "^mozilla .+?\\.", flags: "mi"})
		expect(replaced).to.equal """
			Mozilla Thunderbird is an e-mail client. Some call it simply Firefox.
			Mozilla Thunderbird rocks. Mozilla Firefox is awesome.
			"""


describe "readStdin", ->

	it "reads process.stdin", ->
		stdinEvents = {}
		stdin =
			resume: sinon.spy()
			on: ->
		sinon.stub(stdin, "on", (event, callback)-> stdinEvents[event] = callback)
		callback = sinon.spy()

		readStdin({stdin}, callback)

		expect(stdin.resume).to.have.been.called
		expect(stdinEvents).to.have.property("data").and.be.a("function")
		expect(stdinEvents).to.have.property("end").and.be.a("function")

		stdinEvents.data("First chunk. ")
		stdinEvents.data("Second chunk. ")
		stdinEvents.end()

		expect(callback).to.have.been.calledWith("First chunk. Second chunk. ")
