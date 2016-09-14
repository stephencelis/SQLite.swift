require 'cocoapods'
require 'cocoapods/validator'
require 'fileutils'

class TestRunningValidator < Pod::Validator
  APP_TARGET = 'App'
  TEST_TARGET = 'Tests'

  attr_accessor :test_files
  attr_accessor :iphone_simulator
  attr_accessor :tvos_simulator

  def initialize(spec_or_path, source_urls)
    super(spec_or_path, source_urls)
    self.iphone_simulator = 'iPhone SE' # :oldest
    self.tvos_simulator = :oldest
  end

  def create_app_project
    super.tap do
      project = Xcodeproj::Project.open(validation_dir + "#{APP_TARGET}.xcodeproj")
      test_target = create_test_target(project)
      project.root_object.attributes['TargetAttributes'] = {
        test_target.uuid => { 'ProvisioningStyle' => 'Manual' }
      }
      set_swift_version(project, '2.3')
      project.save
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
  def set_swift_version(project, version)
    project.targets.each do |target|
      target.build_configuration_list.build_configurations.each do |configuration|
        configuration.build_settings['SWIFT_VERSION'] = version
      end
    end
  end

  def create_test_target(project)
    test_target = project.new_target(:unit_test_bundle, TEST_TARGET, consumer.platform_name, deployment_target)
    group = project.new_group(TEST_TARGET)
    test_target.add_file_references(test_files.map { |file| group.new_file(file) })
    project.save
    create_test_scheme(project, test_target)
    test_target
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
    command = [
      'clean', 'test',
      '-workspace', File.join(validation_dir, "#{APP_TARGET}.xcworkspace"),
      '-scheme', TEST_TARGET,
      '-configuration', 'Debug'
    ]
    case consumer.platform_name
    when :ios
      command += %w(CODE_SIGN_IDENTITY=- -sdk iphonesimulator)
      command += Fourflusher::SimControl.new.destination(iphone_simulator, 'iOS', deployment_target)
    when :osx
      command += %w(LD_RUNPATH_SEARCH_PATHS=@loader_path/../Frameworks)
    when :tvos
      command += %w(CODE_SIGN_IDENTITY=- -sdk appletvsimulator)
      command += Fourflusher::SimControl.new.destination(tvos_simulator, 'tvOS', deployment_target)
    else
      return # skip watchos
    end

    Pod::UI.puts 'xcodebuild ' << command.join(' ') if config.verbose
    Pod::Executable.execute_command('xcodebuild', command)
  end
end
