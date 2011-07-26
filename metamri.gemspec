# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{metamri}
  s.version = "0.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kristopher J. Kosmatka", "Erik Kastman"]
  s.date = %q{2011-07-26}
  s.description = %q{Extraction of MRI metadata and insertion into compatible sqlite3 databases.}
  s.email = %q{kk4@medicine.wisc.edu}
  s.executables = ["convert_visit.rb", "import_visit.rb", "import_respiratory_files.rb", "import_study.rb", "list_visit"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
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
    "lib/metamri/dicom_additions.rb",
    "lib/metamri/image_dataset_quality_check_resource.rb",
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
    "spec/helper_spec.rb",
    "spec/unit/dicom_additions_spec.rb",
    "spec/unit/nifti_builder_spec.rb",
    "spec/unit/raw_image_dataset_spec.rb",
    "spec/unit/raw_image_dataset_thumbnail_spec.rb",
    "spec/unit/raw_image_file_spec.rb",
    "test/fixtures/respiratory_fixtures.yaml",
    "test/fixtures/s03_bravo.0156",
    "test/fixtures/s03_bravo.0156.yml",
    "test/fixtures/thumbnail.png",
    "test/fixtures/thumbnail_slicer.png",
    "test/raw_image_dataset_test.rb",
    "test/raw_image_file_test.rb",
    "test/test_helper.rb",
    "test/visit_duplication_test.rb",
    "test/visit_test.rb"
  ]
  s.homepage = %q{http://github.com/brainmap/metamri}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{MRI metadata}
  s.test_files = [
    "spec/helper_spec.rb",
    "spec/unit/dicom_additions_spec.rb",
    "spec/unit/nifti_builder_spec.rb",
    "spec/unit/raw_image_dataset_spec.rb",
    "spec/unit/raw_image_dataset_thumbnail_spec.rb",
    "spec/unit/raw_image_file_spec.rb",
    "test/raw_image_dataset_test.rb",
    "test/raw_image_file_test.rb",
    "test/test_helper.rb",
    "test/visit_duplication_test.rb",
    "test/visit_test.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<metamri>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_runtime_dependency(%q<sqlite3>, ["~> 1.3.3"])
      s.add_runtime_dependency(%q<dicom>, ["~> 0.8"])
      s.add_runtime_dependency(%q<activeresource>, ["~> 3.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_runtime_dependency(%q<hirb>, ["~> 0.4"])
    else
      s.add_dependency(%q<metamri>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
      s.add_dependency(%q<dicom>, ["~> 0.8"])
      s.add_dependency(%q<activeresource>, ["~> 3.0"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<hirb>, ["~> 0.4"])
    end
  else
    s.add_dependency(%q<metamri>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
    s.add_dependency(%q<dicom>, ["~> 0.8"])
    s.add_dependency(%q<activeresource>, ["~> 3.0"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<hirb>, ["~> 0.4"])
  end
end

