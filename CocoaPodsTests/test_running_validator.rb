require 'cocoapods'
require 'cocoapods/validator'
require 'fileutils'

class TestRunningValidator < Pod::Validator
  APP_TARGET = 'App'
  TEST_TARGET = 'Tests'

  attr_accessor :test_files

  def create_app_project
    super.tap do
      project = Xcodeproj::Project.open(validation_dir + "#{APP_TARGET}.xcodeproj")
      create_test_target(project)
    end
  end

  def install_pod
    super.tap do
      if local?
        FileUtils.ln_s file.dirname, validation_dir + "Pods/#{spec.name}"
      end
    end
  end

  def podfile_from_spec(*args)
    super(*args).tap do |pod_file|
      add_test_target(pod_file)
    end
  end

  def build_pod
    super
    Pod::UI.message "\Testing with xcodebuild.\n".yellow do
      run_tests
    end
  end

  private
  def create_test_target(project)
    test_target = project.new_target(:unit_test_bundle, TEST_TARGET, consumer.platform_name, deployment_target)
    group = project.new_group(TEST_TARGET)
    test_target.add_file_references(test_files.map { |file| group.new_file(file) })
    project.save
    create_test_scheme(project, test_target)
    project
  end

  def create_test_scheme(project, test_target)
    project.recreate_user_schemes
    test_scheme = Xcodeproj::XCScheme.new(test_scheme_path(project))
    test_scheme.add_test_target(test_target)
    test_scheme.save!
  end

  def test_scheme_path(project)
    Xcodeproj::XCScheme.user_data_dir(project.path) + "#{TEST_TARGET}.xcscheme"
  end

  def add_test_target(pod_file)
    app_target = pod_file.target_definitions[APP_TARGET]
    Pod::Podfile::TargetDefinition.new(TEST_TARGET, app_target)
  end

  def run_tests
    command = %W(clean test -workspace #{APP_TARGET}.xcworkspace -scheme #{TEST_TARGET} -configuration Debug)
    case consumer.platform_name
    when :ios
      command += %w(CODE_SIGN_IDENTITY=- -sdk iphonesimulator)
      command += Fourflusher::SimControl.new.destination('iPhone 4s', deployment_target)
    when :osx
      command += %w(LD_RUNPATH_SEARCH_PATHS=@loader_path/../Frameworks)
    when :tvos
      command += %w(CODE_SIGN_IDENTITY=- -sdk appletvsimulator)
      command += Fourflusher::SimControl.new.destination('Apple TV 1080p', deployment_target)
    else
      return # skip watchos
    end

    output, status = Dir.chdir(validation_dir) { _xcodebuild(command) }
    unless status.success?
      message = 'Returned an unsuccessful exit code.'
      if config.verbose?
        message += "\nXcode output: \n#{output}\n"
      else
        message += ' You can use `--verbose` for more information.'
      end
      error('xcodebuild', message)
    end
  end
end
