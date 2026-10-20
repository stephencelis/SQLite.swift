import XCTest
import SQLite

class RTreeIntegrationTests: SQLiteTestCase {
    public func testBasic() throws {
        try createOrSkip { connection in
            try connection.run("""
                               CREATE VIRTUAL TABLE test USING rtree(id, minX, maxX, minY, maxY)
                               """)

            try connection.run("""
                               INSERT INTO test VALUES
                               (28215, -80.781227, -80.604706, 35.208813, 35.297367),
                               (28216, -80.957283, -80.840599, 35.235920, 35.367825),
                               (28217, -80.960869, -80.869431, 35.133682, 35.208233),
                               (28226, -80.878983, -80.778275, 35.060287, 35.154446),
                               (28227, -80.745544, -80.555382, 35.130215, 35.236916),
                               (28244, -80.844208, -80.841988, 35.223728, 35.225471),
                               (28262, -80.809074, -80.682938, 35.276207, 35.377747),
                               (28269, -80.851471, -80.735718, 35.272560, 35.407925),
                               (28270, -80.794983, -80.728966, 35.059872, 35.161823),
                               (28273, -80.994766, -80.875259, 35.074734, 35.172836),
                               (28277, -80.876793, -80.767586, 35.001709, 35.101063),
                               (28278, -81.058029, -80.956375, 35.044701, 35.223812),
                               (28280, -80.844208, -80.841972, 35.225468, 35.227203),
                               (28282, -80.846382, -80.844193, 35.223972, 35.225655);
                               """)

            let result = try connection.run("""
                           SELECT id FROM test WHERE minX<=-80.77470 AND maxX>=-80.77470
                           AND minY<=35.37785  AND maxY>=35.37785;
                           """)

            let ids = result.compactMap({ row in row[0] as? Int64 } )
            XCTAssertEqual(ids, [28269])
        }
    }

    private func createOrSkip(_ createIndex: (Connection) throws -> Void) throws {
        #if RTree
        try createIndex(db)
        #else
        throw XCTSkip("RTree is not enabled")
        #endif
    }
}

