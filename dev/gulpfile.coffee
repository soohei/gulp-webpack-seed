################################
# Settings
################################

# ソースディレクトリ
SRC_DIR = './source'

# Bowerディレクトリ
BOWER_DIR = './bower_components'

# ビルドディレクトリ
BUILD_DIR = '../htdocs'

# 納品ディレクトリ
RELEASE_DIR = '../release'

# クリーンするディレクトリ
CLEAN_DIR = [ "#{BUILD_DIR}/**/*", "#{RELEASE_DIR}/**/*" ]

# autoprefixerのオプション
AUTOPREFIXER_OPT = [ 'last 2 versions', 'ie 8', 'ie 9', 'Android 4', 'iOS 8' ]


################################
# Modules
################################

autoprefixer = require 'gulp-autoprefixer'
browserSync  = require 'browser-sync'
coffee       = require 'gulp-coffee'
coffeelint   = require 'gulp-coffeelint'
concat       = require 'gulp-concat'
del          = require 'del'
gulp         = require 'gulp'
notify       = require 'gulp-notify'
plumber      = require 'gulp-plumber'
runSequence  = require 'run-sequence'
sass         = require 'gulp-sass'
source       = require 'vinyl-source-stream'
uglify       = require 'gulp-uglify'
webpack      = require "webpack-stream"
reload       = browserSync.reload


################################
# clean
################################

gulp.task 'clean', (callback) ->
  del CLEAN_DIR, { force: true }, callback


################################
# build
################################

gulp.task 'copyHtml', ->
  gulp
    .src [ "#{SRC_DIR}/**/*.html" ]
    .pipe gulp.dest "#{BUILD_DIR}"
    .pipe reload { stream: true }

# bundle.js
gulp.task 'webpack', ->
  config =
    entry:
      bundle: "#{SRC_DIR}/assets/scripts/main.coffee"
    output:
      filename: '[name].js'
    module:
      loaders: [
        test: /\.coffee$/
        loader: "coffee-loader"
      ]

  gulp
    .src "#{SRC_DIR}/assets/scripts/main.coffee"
    .pipe plumber { errorHandler: notify.onError('<%= error.message %>') }
    .pipe webpack config
    .pipe gulp.dest "#{BUILD_DIR}/assets/scripts"
    .pipe reload { stream: true }


# vendor.js
gulp.task 'concat-vendor.js', ->
  gulp
    .src [
      "#{BOWER_DIR}/css_browser_selector/css_browser_selector.min.js"
      "#{BOWER_DIR}/jquery/dist/jquery.min.js"
    ]
    .pipe concat "vendor.js"
    .pipe gulp.dest "#{BUILD_DIR}/assets/scripts"

# vendor.css
gulp.task 'concat-vendor.css', ->
  gulp
    .src [
      "#{BOWER_DIR}/normalize-css/normalize.css"
    ]
    .pipe concat "vendor.css"
    .pipe gulp.dest "#{BUILD_DIR}/assets/styles"

# css
gulp.task 'sass', ->
  gulp
    .src [
      "#{SRC_DIR}/assets/styles/*.scss"
    ]
    .pipe plumber { errorHandler: notify.onError('<%= error.message %>') }
    .pipe sass
      outputStyle: 'expanded'
    .pipe autoprefixer
      browsers: AUTOPREFIXER_OPT
    .pipe gulp.dest "#{BUILD_DIR}/assets/styles"
    .pipe reload { stream: true }


################################
# release
################################

gulp.task 'release-copy', ->
  gulp
    .src [
      "#{BUILD_DIR}/assets/**/*.{png,jpg,gif,svg,ico,pdf,js,css,woff2,woff,ttf,eot}"
      "#{BUILD_DIR}/**/*.html"
      ], {
        base: BUILD_DIR
      }
    .pipe gulp.dest RELEASE_DIR


gulp.task 'uglify', ->
  gulp
    .src([
      "#{RELEASE_DIR}/assets/scripts/**/*.js"
    ])
    .pipe uglify()
    .pipe gulp.dest "#{RELEASE_DIR}/assets/scripts"


################################
# watch, server
################################

gulp.task 'watch', ->
  gulp.watch "#{SRC_DIR}/assets/styles/**/*.scss", ['sass']
  gulp.watch "#{SRC_DIR}/assets/scripts/**/*.coffee", ['webpack']
  gulp.watch "#{SRC_DIR}/**/*.html", ['copyHtml']
  gulp.watch "#{BOWER_DIR}/**/*.js", ['concat-vendor.js']
  gulp.watch "#{BOWER_DIR}/**/*.css", ['concat-vendor.css']


gulp.task 'server', ->
  browserSync.init
    server:
      baseDir: BUILD_DIR


################################
# tasks
################################

gulp.task 'build', ->
  runSequence [ 'copyHtml', 'sass', 'webpack', 'concat-vendor.js', 'concat-vendor.css' ]

gulp.task 'release', [], ->
  runSequence 'release-copy', 'uglify'

gulp.task 'default', [], ->
  runSequence 'clean', 'build', 'server', 'watch'

