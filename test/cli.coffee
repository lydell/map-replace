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

{expect, sinon, readFile, writeFile, exec} = require "./common"


describe "cli", ->

	beforeEach ->
		readFile.reset()
		readFile.resetBehavior()
		writeFile.reset()
		writeFile.resetBehavior()

		delete require.cache[require.resolve("../src/cli")]
		delete require.cache[require.resolve("commander")]
		cli = require "../src/cli"
		@exec = exec.bind(undefined, cli)


	it "shows usage information if given no files", (done)->
		help = sinon.stub(require("commander"), "help")

		count = 0
		callback = (code, stdout, stderr)->
			count++
			expect(help.callCount).to.equal(count)
			if count == 2
				help.restore()
				done()

		@exec callback
		@exec "-m", "regex", callback


	it """takes a map of search strings to replacements from stdin and applies that to each
	   provided file.""", (done)->
		stdin = JSON.stringify
			"foo": "bar"
			"app.js": "app-HASH.js"
		contents = """
			Have some foo, foobar in your app. js rocks. app.js isn't bapp.jsp.
			"""
		replaced = """
			Have some bar, barbar in your app. js rocks. app-HASH.js isn't bapp-HASH.jsp.
			"""
		readFile.yields(null, new Buffer contents)
		writeFile.yields(null)

		@exec {stdin}, "file1", "file2", "file3", (code, stdout, stderr)->
			expect(code).to.equal(0)
			expect(stdout).to.be.empty
			expect(stderr).to.be.empty

			expect(readFile).calledThrice
			expect(readFile.firstCall).to.have.been.calledWith("file1")
			expect(readFile.secondCall).to.have.been.calledWith("file2")
			# For some reason `.thirdCall` is `null`. Weird.
			expect(readFile.getCall(2)).to.have.been.calledWith("file3")

			expect(writeFile).calledThrice
			expect(writeFile.firstCall).to.have.been.calledWith("file1", replaced)
			expect(writeFile.secondCall).to.have.been.calledWith("file2", replaced)
			# For some reason `.thirdCall` is `null`. Weird.
			expect(writeFile.getCall(2)).to.have.been.calledWith("file3", replaced)

			done()


	describe "-m, --match", ->

		it "only replaces in substrings matching the supplied regex (as a string)", (done)->
			stdin = JSON.stringify
				"foo.jpg": "foo-HASH.jpg"
			contents = """
				<img src="/imgs/foo.jpg" alt="foo.jpg (sucky alt attribue)">
				Download <a href="/imgs/foo.jpg">foo.jpg</a> today!
				"""
			replaced =  """
				<img src="/imgs/foo-HASH.jpg" alt="foo-HASH.jpg (sucky alt attribue)">
				Download <a href="/imgs/foo-HASH.jpg">foo.jpg</a> today!
				"""
			readFile.yields(null, new Buffer contents)
			writeFile.yields(null)

			@exec {stdin}, "-m", "<[^>]+>", "file", (code, stdout, stderr)->
				expect(code).to.equal(0)
				expect(stdout).to.be.empty
				expect(stderr).to.be.empty
				expect(writeFile).to.have.been.calledWith("file", replaced)
				done()


	describe "-f, --flags", ->

		it "uses the supplied flags for a supplied regex", (done)->
			stdin = JSON.stringify
				"Firefox": "Thunderbird"
				"a browser": "an e-mail client"
			contents = """
				Mozilla Firefox is a browser. Some call it simply Firefox.
				Mozilla Firefox rocks. Mozilla Firefox is awesome.
				"""
			replaced = """
				Mozilla Thunderbird is an e-mail client. Some call it simply Firefox.
				Mozilla Thunderbird rocks. Mozilla Firefox is awesome.
				"""
			readFile.yields(null, new Buffer contents)
			writeFile.yields(null)

			@exec {stdin}, "-m", "^mozilla .+?\\.", "-f", "mi", "file", (code, stdout, stderr)->
				expect(code).to.equal(0)
				expect(stdout).to.be.empty
				expect(stderr).to.be.empty
				expect(writeFile).to.have.been.calledWith("file", replaced)
				done()


		it "has no effect when used without the -m option", (done)->
			readFile.yields(null, new Buffer "foo")
			writeFile.yields(null)

			@exec {stdin: '{"foo": "bar"}'}, "-f", "i", "file", (code, stdout, stderr)->
				expect(code).to.equal(0)
				expect(stdout).to.be.empty
				expect(stderr).to.be.empty
				expect(writeFile).to.have.been.calledWith("file", "bar")
				done()


	describe "error handling", ->

		it "handles read errors", (done)->
			readFile.yields(new Error "Message")

			@exec "file", (code, stdout, stderr)->
				expect(code).to.equal(1)
				expect(stdout).to.be.empty
				expect(stderr).to.equal("Error: Message\n")
				done()


		it "handles write errors", (done)->
			readFile.yields(null, new Buffer "contents")
			writeFile.yields(new Error "Message")

			@exec {stdin: "{}"}, "file", (code, stdout, stderr)->
				expect(code).to.equal(1)
				expect(stdout).to.be.empty
				expect(stderr).to.equal("Error: Message\n")
				done()


		it "handles JSON errors", (done)->
			readFile.yields(null, new Buffer "contents")

			@exec {stdin: "invalid JSON"}, "file", (code, stdout, stderr)->
				expect(code).to.equal(1)
				expect(stdout).to.be.empty
				expect(stderr).to.match(/^SyntaxError: Unexpected.*\n$/)
				done()


		it "handles invalid regex errors", (done)->
			readFile.yields(null, new Buffer "contents")

			@exec {stdin: "{}"}, "-m", "invalid regex: (", "file", (code, stdout, stderr)->
				expect(code).to.equal(1)
				expect(stdout).to.be.empty
				expect(stderr).to.match(/^SyntaxError: Invalid regular expression.*\n$/)
				done()


		it "handles invalid regex flags errors", (done)->
			readFile.yields(null, new Buffer "contents")

			@exec {stdin: "{}"}, "-m", "regex", "-f", ";", "file", (code, stdout, stderr)->
				expect(code).to.equal(1)
				expect(stdout).to.be.empty
				expect(stderr).to.match(/^SyntaxError: Invalid flags.*\n$/)
				done()
