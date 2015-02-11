let txn = db.transaction(
    sr.run("fiona@acme.com"),
    jr.run("emery@acme.com", db.lastId)
)
count.scalar()

txn.failed
txn.reason
