module.exports =
  tmpl:
    options:
      pretty: true

    files: [
      expand: true
      cwd: 'jade/'
      src: ['**/**.jade']
      dest: "tmpl"
      ext: '.tx'
      filter: (path) ->
        not path.match(/\/_parts\//)
    ]
