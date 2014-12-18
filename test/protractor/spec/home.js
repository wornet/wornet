describe('Wornet homepage', function() {
  it('should allow to test the password security in signin first step', function() {
    browser.get('http://localhost:8000/');

    //var todoList = element.all(by.repeater('todo in todos'));

    var password = element(by.css('[ng-controller="SigninFirstStepCtrl"] [type="password"]'));
    var bar = element(by.css('.pass-security'))

    password.sendKeys('az');
    expect(bar.getAttribute('class')).toContain('verylow');

    password.sendKeys('Aa_z9@dk-6(dh24#sqlkjd');
    expect(bar.getAttribute('class')).toContain('veryhigh');
  });
});