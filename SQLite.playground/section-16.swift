db.transaction() &&
    sr.run("dolly@acme.com") &&
    jr.run("emery@acme.com", db.lastId) &&
    db.commit() || db.rollback()
