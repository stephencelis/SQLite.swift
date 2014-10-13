let txn = db.transaction(
    sr.run("fiona@acme.com"),
    jr.run("emery@acme.com", db.lastID)
)
count.scalar()

txn.failed
txn.reason
