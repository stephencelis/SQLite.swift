let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
for (email, admin) in ["alice@example.com": true, "betsy@example.com": false] {
    stmt.run(email, admin)
}
