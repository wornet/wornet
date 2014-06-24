'use strict'

onready = require './test'

describe "functions", ->

	@timeout 5000

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
			empty(0).should.be.true
			empty(false).should.be.true
			empty(null).should.be.true
			empty(undefined).should.be.true
			empty("").should.be.true
			empty({}).should.be.true
			empty([]).should.be.true

			empty("e12").should.be.false
			empty(-1).should.be.false
			empty(0.2).should.be.false
			empty(" ").should.be.false
			empty({ foo: "" }).should.be.false
			empty([""]).should.be.false

	describe "trim", ->

		it "must return input value without starting and ending spaces", ->
			trim(" abc def ").should.be.equal("abc def")
			trim("abc def").should.be.equal("abc def")
			trim("\t \t\nabc def").should.be.equal("abc def")
			trim("\tabc def   \n\n\n    \t\t").should.be.equal("abc def")

	describe "jd", ->

		it "must return html code from jade input", ->
			jd("p Some Text").toString().should.be.equal("<p>Some Text</p>")
			jd("#id\n\tul\n\t\tli=\"Quoted Text\"").toString().should.be.equal("<div id=\"id\"><ul><li>Quoted Text</li></ul></div>")

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
