[."key.substructure"[] |
    select(."key.kind" == "source.lang.swift.decl.class") |
    select(."key.inheritedtypes"[]."key.name" == "XCTestCase" or ."key.inheritedtypes"[]."key.name" == "SQLiteTestCase") |
    {key: ."key.name", value: [
      (."key.substructure"[] |
        select(."key.kind" == "source.lang.swift.decl.function.method.instance") |
        select(."key.name" | startswith("test")) |
        ."key.name")]
    }
] | from_entries
