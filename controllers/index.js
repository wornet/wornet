'use strict';


module.exports = function (router) {

    var model = new IndexModel();


    router.get('/', function (req, res) {

        res.render('index', model);

    });

};
