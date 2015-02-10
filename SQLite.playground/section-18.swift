let txn = db.transaction() &&
    sr.run("fiona@acme.com") &&
    jr.run("emery@acme.com", db.lastId) &&
    db.commit()
txn || db.rollback()

count.scalar()

txn.failed
txn.reason
