desc 'Measures test coverage'
task :test_coverage do
  rm_f "coverage"
  rm_f "coverage.data"
  rcov = "rcov --aggregate coverage.data --text-summary -Ilib"
  system("#{rcov} --html test/test_*.rb")
  system("open coverage/index.html") if PLATFORM['darwin']
end

