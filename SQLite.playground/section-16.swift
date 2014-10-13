db.transaction(
    sr.run("dolly@acme.com"),
    jr.run("emery@acme.com", db.lastID)
)
count.scalar()
