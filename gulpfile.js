var gulp = require('gulp');
var sass = require('gulp-sass');
var del  = require('del');

gulp.task('styles', function() {
  gulp.src('gulp/stylesheet/**/*.scss')
      .pipe(sass().on('error', sass.logError))
      .pipe(gulp.dest('./public/css'));
});

gulp.task('clean', function() {
  return del(['public/css']);
});

gulp.task('watch', function() {
  gulp.watch('gulp/stylesheet/**/*.scss', ['styles'])
});

gulp.task('default', ['clean'], function() {
  gulp.start('styles', 'watch');
});
