# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{metamri}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kristopher J. Kosmatka"]
  s.date = %q{2009-08-20}
  s.description = %q{Extraction of MRI metadata and insertion into compatible sqlite3 databases.}
  s.email = %q{kk4@medicine.wisc.edu}
  s.executables = ["import_study.rb", "import_visit.rb"]
  s.extra_rdoc_files = ["bin/import_study.rb", "bin/import_visit.rb", "lib/metamri.rb", "lib/mysql_tools.rb", "lib/raw_image_dataset.rb", "lib/raw_image_file.rb", "lib/series_description_parameters.rb", "lib/visit_raw_data_directory.rb", "README.rdoc"]
  s.files = ["bin/import_study.rb", "bin/import_visit.rb", "lib/metamri.rb", "lib/mysql_tools.rb", "lib/raw_image_dataset.rb", "lib/raw_image_file.rb", "lib/series_description_parameters.rb", "lib/visit_raw_data_directory.rb", "Manifest", "Rakefile", "README.rdoc", "test/raw_image_dataset_test.rb", "test/raw_image_file_test.rb", "test/visit_duplication_test.rb", "test/visit_test.rb", "metamri.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/brainmap/metamri}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Metamri", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{metamri}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Extraction of MRI metadata and insertion into compatible sqlite3 databases.}
  s.test_files = ["test/raw_image_dataset_test.rb", "test/raw_image_file_test.rb", "test/visit_duplication_test.rb", "test/visit_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
