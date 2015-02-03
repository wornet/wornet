'use strict'

onready = require './test'

describe "functions", ->

	@timeout 5.seconds

	beforeEach (done) ->
		onready.utils ->
			done()

	model = [1, 5, 1, 4, 5, 3, 1, 3, 4, 6, 3]

	describe "isFirst", ->

		it "must return true when a position is the first instance", ->
			model.isFirst(0).should.be.true "0"
			model.isFirst(1).should.be.true "1"
			model.isFirst(3).should.be.true "3"
			model.isFirst(5).should.be.true "5"
			model.isFirst(9).should.be.true "9"

		it "must return false when a position is not the first instance", ->
			model.isFirst(2).should.be.false "2"
			model.isFirst(4).should.be.false "4"
			model.isFirst(6).should.be.false "6"
			model.isFirst(7).should.be.false "7"
			model.isFirst(8).should.be.false "8"
			model.isFirst(10).should.be.false "10"

	describe "unique", ->

		it "must return arrays with no doublons", ->
			model.unique().join(',').should.equal "1,5,4,3,6"

		it "must return arrays as it if already with unique values", ->
			model.unique().unique().join(',').should.equal "1,5,4,3,6"
			'a,b,c'.split(/,/g).unique().join(',').should.equal "a,b,c"
