'use strict'

require './test'

describe "functions", ->
	functions = require __dirname + '/../core/utils/functions'

	describe "intval", ->

		it "must return 0 when receive a null value", ->
			functions.intval(0).should.equal 0
			functions.intval(false).should.equal 0
			functions.intval(null).should.equal 0
			functions.intval(undefined).should.equal 0
			functions.intval("").should.equal 0
			functions.intval("e12").should.equal 0

		it "must return integer value from parameter", ->
			functions.intval(2).should.equal 2
			functions.intval(2.9).should.equal 2
			functions.intval(-7/3).should.equal -2
			functions.intval("3").should.equal 3
			functions.intval("3rt").should.equal 3

	describe "empty", ->

		it "must return true only if the value is empty", ->
			functions.empty(0).should.be.true
			functions.empty(false).should.be.true
			functions.empty(null).should.be.true
			functions.empty(undefined).should.be.true
			functions.empty("").should.be.true
			functions.empty({}).should.be.true
			functions.empty([]).should.be.true

			functions.empty("e12").should.be.false
			functions.empty(-1).should.be.false
			functions.empty(0.2).should.be.false
			functions.empty(" ").should.be.false
			functions.empty({ foo: "" }).should.be.false
			functions.empty([""]).should.be.false

	describe "trim", ->

		it "must return input value without starting and ending spaces", ->
			functions.trim(" abc def ").should.be.equal("abc def")
			functions.trim("abc def").should.be.equal("abc def")
			functions.trim("\t \t\nabc def").should.be.equal("abc def")
			functions.trim("\tabc def   \n\n\n    \t\t").should.be.equal("abc def")

	describe "jd", ->

		it "must return html code from jade input", ->
			functions.jd("p Some Text").toString().should.be.equal("<p>Some Text</p>")
			functions.jd("#id\n\tul\n\t\tli=\"Quoted Text\"").toString().should.be.equal("<div id=\"id\"><ul><li>Quoted Text</li></ul></div>")
