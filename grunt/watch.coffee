module.exports =
  jade:
    files: 'jade/**/**'
    tasks: ['jade']
    options:
      livereload: true

  compass:
    files: 'static/sass/**/**'
    tasks: ['compass']
    options:
      livereload: true

  coffee:
    files: 'static/coffee/**/**'
    tasks: ['coffee']
    options:
      livereload: true
