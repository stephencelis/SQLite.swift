Pod::Spec.new do |s|
  s.name = 'SQLite.swift'
  s.module_name = 'SQLite'
  s.version = '0.1.0.pre'
  s.summary = 'A type-safe, Swift-language layer over SQLite3.'

  s.description = <<-DESC
    SQLite.swift provides compile-time confidence in SQL statement syntax and
    intent.
  DESC

  s.homepage = 'https://github.com/stephencelis/SQLite.swift'
  s.license = { type: 'MIT', file: 'LICENSE.txt' }

  s.author = { 'Stephen Celis' => 'stephen@stephencelis.com' }
  s.social_media_url = 'https://twitter.com/stephencelis'

  s.library = 'sqlite3'

  s.source = {
    git: 'https://github.com/stephencelis/SQLite.swift.git',
    tag: s.version
  }

  s.source_files = 'SQLite/**/*.{swift,c,h,m}'
  s.private_header_files = 'SQLite/fts3_tokenizer.h'

  s.module_map = 'SQLite/module.modulemap'
end
