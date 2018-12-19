#!/usr/bin/env ruby

require 'cocoapods'
require 'cocoapods/validator'
require 'minitest/autorun'

class IntegrationTest < Minitest::Test

  def test_validate_project
    assert validator.validate, "validation failed: #{validator.failure_reason}"
  end

  private

  def validator
    @validator ||= CustomValidator.new(podspec, ['https://github.com/CocoaPods/Specs.git']).tap do |validator|
        validator.config.verbose = true
        validator.no_clean = true
        validator.use_frameworks = true
        validator.fail_fast = true
        validator.local = true
        validator.allow_warnings = true
        subspec = ENV['VALIDATOR_SUBSPEC']
        if subspec == 'none'
          validator.no_subspecs = true
        else
          validator.only_subspec = subspec
        end
    end
  end

  def podspec
    File.expand_path(File.dirname(__FILE__) + '/../../SQLite.swift.podspec')
  end


  class CustomValidator < Pod::Validator
    def test_pod
      # https://github.com/CocoaPods/CocoaPods/issues/7009
      super unless consumer.platform_name == :watchos
    end

    def xcodebuild(action, scheme, configuration)
      require 'fourflusher'
      command = %W(#{action} -workspace #{File.join(validation_dir, 'App.xcworkspace')} -scheme #{scheme} -configuration #{configuration})
      case consumer.platform_name
      when :osx, :macos
        command += %w(CODE_SIGN_IDENTITY=)
      when :ios
        command += %w(CODE_SIGN_IDENTITY=- -sdk iphonesimulator)
        command += Fourflusher::SimControl.new.destination(nil, 'iOS', deployment_target)
      when :watchos
        command += %w(CODE_SIGN_IDENTITY=- -sdk watchsimulator)
        command += Fourflusher::SimControl.new.destination(:oldest, 'watchOS', deployment_target)
      when :tvos
        command += %w(CODE_SIGN_IDENTITY=- -sdk appletvsimulator)
        command += Fourflusher::SimControl.new.destination(:oldest, 'tvOS', deployment_target)
      end

      begin
        _xcodebuild(command, true)
      rescue => e
        message = 'Returned an unsuccessful exit code.'
        message += ' You can use `--verbose` for more information.' unless config.verbose?
        error('xcodebuild', message)
        e.message
      end
    end
  end
end
