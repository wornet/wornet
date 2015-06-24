'use strict'

onready = require './test'

describe "functions", ->

	@timeout 5.seconds

	beforeEach (done) ->
		onready.utils ->
			done()

	model = [1, 5, 1, 4, 5, 3, 1, 3, 4, 6, 3]
	objectModel =
		a: 'a'
		b: 'b'
		c: 'c'
		da: 'da'

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

	describe "matchFilter", ->

		it "must return filtered values", ->
			model.matchFilter((v) -> v&1).join(',').should.equal "1,5,1,5,3,1,3,3"
			firstObject = JSON.stringify objectModel
			expected = JSON.stringify
				a: 'a'
				da: 'da'
			JSON.stringify(objectModel.matchFilter((v) -> v.indexOf('a') isnt -1)).should.equal expected
			JSON.stringify(objectModel).should.equal firstObject, "should keep the source object untouched"

	describe "has", ->

		it "must return true if a matched value is found", ->
			model.has((v) -> v&1).should.be.true "v&1"
			model.has((v) -> v>10).should.be.false "v>10"
			objectModel.has((v) -> v.indexOf('a') isnt -1).should.be.true "a"
			objectModel.has((v) -> v.indexOf('z') isnt -1).should.be.false "z"
			[{}, objectModel, {}].has(a: 'a').should.be.true "a:a"
			[{}, objectModel, {}].has(b: 'c').should.be.false "b:c"

	describe "with", ->

		_object = JSON.stringify objectModel

		it "return new object/array", ->
			model.with([42]).join(',').should.equal "1,5,1,4,5,3,1,3,4,6,3,42"
			model.join(',').should.equal "1,5,1,4,5,3,1,3,4,6,3"
			nObject = objectModel.with
				foo: 42
				bar: "lala"
			nObject.foo.should.equal 42
			nObject.bar.should.equal "lala"
			nObject.da.should.equal "da"
			nObject.b.should.equal "b"
			_object.should.equal JSON.stringify objectModel
