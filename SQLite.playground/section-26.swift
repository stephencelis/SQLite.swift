db.transaction() &&
    users.insert(email <- "julie@acme.com") &&
    users.insert(email <- "kelly@acme.com", manager_id <- db.lastId) &&
    db.commit() || db.rollback()
