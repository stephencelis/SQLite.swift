Pod::Spec.new do |s|
  s.name             = "SQLite.swift"
  s.version          = "0.15.4"
  s.summary          = "A type-safe, Swift-language layer over SQLite3."

  s.description      = <<-DESC
    SQLite.swift provides compile-time confidence in SQL statement syntax and
    intent.
                       DESC

  s.homepage         = "https://github.com/stephencelis/SQLite.swift"
  s.license          = 'MIT'
  s.author           = { "Stephen Celis" => "stephen@stephencelis.com" }
  s.source           = { :git => "https://github.com/stephencelis/SQLite.swift.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stephencelis'

  s.module_name      = 'SQLite'
  s.default_subspec  = 'standard'
  s.swift_versions = ['5']

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'
  s.watchos.deployment_target = '4.0'
  s.visionos.deployment_target = '1.0'

  s.subspec 'standard' do |ss|
    ss.source_files = 'Sources/SQLite/**/*.{c,h,m,swift}'
    ss.exclude_files = 'Sources/**/Cipher.swift'
    ss.library = 'sqlite3'
    ss.resource_bundle = { 'SQLite.swift' => 'Sources/SQLite/PrivacyInfo.xcprivacy' }
    
    ss.test_spec 'tests' do |test_spec|
      test_spec.resources = 'Tests/SQLiteTests/Resources/*'
      test_spec.source_files = 'Tests/SQLiteTests/*.swift'
    end
  end

  s.subspec 'standalone' do |ss|
    ss.source_files = 'Sources/SQLite/**/*.{c,h,m,swift}'
    ss.exclude_files = 'Sources/**/Cipher.swift'
    ss.resource_bundle = { 'SQLite.swift' => 'Sources/SQLite/PrivacyInfo.xcprivacy' }

    ss.xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_STANDALONE',
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_SWIFT_STANDALONE=1'
    }
    ss.dependency 'sqlite3'
    
    ss.test_spec 'tests' do |test_spec|
      test_spec.resources = 'Tests/SQLiteTests/Resources/*'
      test_spec.source_files = 'Tests/SQLiteTests/*.swift'
    end
  end

  s.subspec 'SQLCipher' do |ss|
    # Disable unsupported visionOS
    # https://github.com/sqlcipher/sqlcipher/issues/483
    ss.ios.deployment_target = s.deployment_target(:ios)
    ss.tvos.deployment_target = s.deployment_target(:tvos)
    ss.osx.deployment_target = s.deployment_target(:osx)
    ss.watchos.deployment_target = s.deployment_target(:watchos)

    ss.source_files = 'Sources/SQLite/**/*.{c,h,m,swift}'
    ss.resource_bundle = { 'SQLite.swift' => 'Sources/SQLite/PrivacyInfo.xcprivacy' }

    ss.xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_SQLCIPHER',
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1 SQLITE_SWIFT_SQLCIPHER=1'
    }
    ss.dependency 'SQLCipher', '>= 4.0.0'
    
    ss.test_spec 'tests' do |test_spec|
      test_spec.resources = 'Tests/SQLiteTests/Resources/*'
      test_spec.source_files = 'Tests/SQLiteTests/*.swift'
    end
  end
end
