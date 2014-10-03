for row in db.prepare("SELECT id, email FROM users") {
    println(row)
}
