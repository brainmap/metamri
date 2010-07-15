# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{metamri}
  s.version = "0.1.21"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kristopher J. Kosmatka"]
  s.date = %q{2010-07-15}
  s.description = %q{Extraction of MRI metadata and insertion into compatible sqlite3 databases.}
  s.email = %q{kk4@medicine.wisc.edu}
  s.executables = ["import_study.rb", "import_visit.rb", "import_respiratory_files.rb", "list_visit", "convert_visit.rb"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "Manifest",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/convert_visit.rb",
     "bin/import_respiratory_files.rb",
     "bin/import_study.rb",
     "bin/import_visit.rb",
     "bin/list_visit",
     "lib/metamri.rb",
     "lib/metamri/core_additions.rb",
     "lib/metamri/mysql_tools.rb",
     "lib/metamri/nifti_builder.rb",
     "lib/metamri/raw_image_dataset.rb",
     "lib/metamri/raw_image_dataset_resource.rb",
     "lib/metamri/raw_image_dataset_thumbnail.rb",
     "lib/metamri/raw_image_file.rb",
     "lib/metamri/series_description_parameters.rb",
     "lib/metamri/visit_raw_data_directory.rb",
     "lib/metamri/visit_raw_data_directory_resource.rb",
     "metamri.gemspec",
     "test/fixtures/respiratory_fixtures.yaml",
     "test/nifti_builder_spec.rb",
     "test/raw_image_dataset_test.rb",
     "test/raw_image_dataset_thumbnail_spec.rb",
     "test/raw_image_file_test.rb",
     "test/visit_duplication_test.rb",
     "test/visit_test.rb"
  ]
  s.homepage = %q{http://github.com/brainmap/metamri}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{MRI metadata}
  s.test_files = [
    "test/nifti_builder_spec.rb",
     "test/raw_image_dataset_test.rb",
     "test/raw_image_file_test.rb",
     "test/visit_duplication_test.rb",
     "test/visit_test.rb",
     "test/raw_image_dataset_thumbnail_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<dicom>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
      s.add_dependency(%q<dicom>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    s.add_dependency(%q<dicom>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

