db.execute(
    "CREATE TABLE users (" +
        "id INTEGER PRIMARY KEY, " +
        "email TEXT NOT NULL UNIQUE, " +
        "age INTEGER, " +
        "admin BOOLEAN NOT NULL DEFAULT 0 CHECK (admin IN (0, 1)), " +
        "manager_id INTEGER, " +
        "FOREIGN KEY(manager_id) REFERENCES users(id)" +
    ")"
)
