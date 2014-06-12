'use strict';


module.exports = function clean(grunt) {
    // Load task
    grunt.registerTask('i18n', [ 'clean', 'localizr', 'false', 'clean:tmp' ]);

    // Options
    return {};
};
