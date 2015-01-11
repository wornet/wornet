
describe "Not found page", ->

	w = null

	beforeEach (done) ->
		iframeLoad '/not-found', ->
			w = @contentWindow
			do done

	it "should contain minimal stuff", ->

		expect(w.exists 'h1').toBe true, 'h1 must exist'
		expect(w.exists '.well').toBe true, '.well must exist'
		expect(w.exists '#navbar').toBe true, '#navbar must exist'
