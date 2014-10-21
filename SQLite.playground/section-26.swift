db.transaction(
    users.insert { $0.set(email, "julie@acme.com") },
    users.insert { $0.set(email, "kelly@acme.com"); $0.set(manager_id, db.lastID) }
)
