let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
for (email, admin) in ["alice@acme.com": 1, "betsy@acme.com": 0] {
    stmt.run(email, admin)
}
