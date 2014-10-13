for row in db.prepare("SELECT id, email FROM users") {
    println("id: \(row[0]), email: \(row[1])")
}
