let count = db.prepare("SELECT count(*) FROM users")
count.scalar()

db.scalar("SELECT email FROM users WHERE id = ?", 1)
