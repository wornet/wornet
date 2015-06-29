'use strict'

onready = require './test'

describe "functions", ->

	@timeout 5.seconds

	beforeEach (done) ->
		onready.utils ->
			done()

	describe "intval", ->

		it "must return 0 when receive a null value", ->
			intval(0).should.equal 0
			intval(false).should.equal 0
			intval(null).should.equal 0
			intval(undefined).should.equal 0
			intval("").should.equal 0
			intval("e12").should.equal 0

		it "must return integer value from parameter", ->
			intval(2).should.equal 2
			intval(2.9).should.equal 2
			intval(-7/3).should.equal -2
			intval("3").should.equal 3
			intval("3rt").should.equal 3

	describe "floatval", ->

		it "must return 0 when receive a null value", ->
			floatval(0).should.equal 0
			floatval(false).should.equal 0
			floatval(null).should.equal 0
			floatval(undefined).should.equal 0
			floatval("").should.equal 0
			floatval("e12").should.equal 0

		it "must return integer value from parameter", ->
			floatval(2).should.equal 2
			floatval(2.9).should.equal 2.9
			floatval(-7.0/3.0).should.be.above -2.33334
			floatval(-7.0/3.0).should.be.below -2.33333
			floatval("3").should.equal 3
			floatval("3rt").should.equal 3

	describe "empty", ->

		it "must return true only if the value is empty", ->
			empty(0).should.be.true "0"
			empty(false).should.be.true "false"
			empty(null).should.be.true "null"
			empty(undefined).should.be.true "undefined"
			empty("").should.be.true '""'
			empty({}).should.be.true "{}"
			empty([]).should.be.true "[]"

			empty("e12").should.be.false "e12"
			empty(-1).should.be.false "-1"
			empty(0.2).should.be.false "0.2"
			empty(" ").should.be.false '" "'
			empty({ foo: "" }).should.be.false '{ foo: "" }'
			recursive = {}
			recursive.a = recursive
			empty(recursive).should.be.false 'recursive object'
			empty([""]).should.be.false '[""]'

	describe "trim", ->

		it "must return input value without starting and ending spaces", ->
			trim(" abc def ").should.equal "abc def"
			trim("abc def").should.equal "abc def"
			trim("abc def", "a").should.equal "bc def"
			trim("\t \t\nabc def").should.equal "abc def"
			trim("\tabc def   \n\n\n    \t\t").should.equal "abc def"
			trim("87.4k90", "[0-9]").should.equal ".4k"
			trim(trim("la li lo buto nimo", "\\w")).should.equal "li lo buto"

	describe "jd", ->

		it "must return html code from jade input", ->
			jd("p Some Text").toString().should.equal "<p>Some Text</p>"
			jd("#id\n\tul\n\t\tli=\"Quoted Text\"").toString().should.equal "<div id=\"id\"><ul><li>Quoted Text</li></ul></div>"

	describe "s", ->

		it "must return replaced and plurialized text", ->
			s("abc").should.equal "abc"
			s("abc", { a: "b" }).should.equal "abc"
			s("abc", { a: "b" }, 4).should.equal "abc"
			s("abc", 0, { a: "b" }).should.equal "abc"
			s("abc|def", 0, { a: "b" }).should.equal "abc"
			s("abc|def", { a: "b" }, 1).should.equal "abc"
			s("{count} comment|{count} comments {a}", { a: "b" }, 2).should.equal "2 comments b"
			s("No comments|{count} comment|{count} comments {a}", { a: "b" }, 1).should.equal "1 comment"

	describe "cesar, cesarLeft, cesarRight", ->

		it "must crypt strings", ->
			str = "7db23cdef32d20219878b3"
			cesarLeft(str).should.not.equal str
			cesarRight(str).should.not.equal str
			cesarLeft(str).length.should.equal str.length
			cesarRight(str).length.should.equal str.length

		it "must decrypt strings", ->
			str = "ef32d20217db23cd9878b3"
			cesarLeft(cesarRight(str)).should.equal str
			cesarRight(cesarLeft(str)).should.equal str

	describe "strrev", ->

		it "must reverse a string", ->
			strrev("abc").should.equal "cba"
			strrev(" @9_").should.equal "_9@ "
			strrev("ggg").should.equal "ggg"

	describe "standartError", ->

		it "must return a PublicError", ->
			standartError().should.be.an.instanceof PublicError

	describe "objectResolve", ->

		it "must preserve objects", ->
			objectResolve( a: b: 42 ).a.b.should.equal 42

		it "must convert dates", ->
			date = objectResolve( a: '2014-10-06T21:34:23.091Z' ).a
			date.should.be.an.instanceof Date
			date.getDate().should.equal 6

		it "must convert dates in deep nested arrays and objects", ->
			obj = objectResolve [
				'2014-10-06T21:34:23.091Z'
				['2014-10-06T21:34:23.091Z']
				a: '2014-10-06T21:34:23.091Z'
				b: ['2014-10-06T21:34:23.091Z']
			]
			obj[0].should.be.an.instanceof Date
			obj[1][0].should.be.an.instanceof Date
			obj[2].a.should.be.an.instanceof Date
			obj[2].b[0].should.be.an.instanceof Date

	describe "codeId", ->

		it "must return a string", ->
			code = codeId()
			code.should.be.a 'string'
			code.length.should.be.above 10

		it "must be unique", ->
			code = codeId()
			code.should.not.equal codeId()
