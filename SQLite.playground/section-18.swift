let txn = db.transaction(
    sr.run("fiona@example.com"),
    jr.run("emery@example.com", db.lastID)
)
count.scalar()

txn.failed
txn.reason
