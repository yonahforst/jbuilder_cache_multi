require "bundler/setup"
require "rake/testtask"

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  require "appraisal/task"
  Appraisal::Task.new
  task default: :appraisal
else
  Rake::TestTask.new do |test|
    require "rails/version"

    test.libs << "test"
    test.verbose = false
    test.warning = false

    if Rails::VERSION::MAJOR == 3
      test.test_files = %w[
        test/jbuilder_template_test.rb
        test/jbuilder_template_active_record_relation_test.rb
      ]
    else
      test.test_files = FileList["test/*_test.rb"]
    end
  end

  task default: :test
end
