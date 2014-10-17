module.exports =
  dev:
    options:
      sourceMap: true
    expand: true
    cwd: 'static/coffee'
    src: ['**/**.coffee']
    dest: 'static/js'
    ext: '.js'
