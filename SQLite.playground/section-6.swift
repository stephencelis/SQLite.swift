let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
for (email, admin) in ["alice@acme.com": true, "betsy@acme.com": false] {
    stmt.run(email, admin)
}
