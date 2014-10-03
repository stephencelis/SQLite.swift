db.transaction(
    sr.run("dolly@example.com"),
    jr.run("emery@example.com", db.lastID)
)
count.scalar()
