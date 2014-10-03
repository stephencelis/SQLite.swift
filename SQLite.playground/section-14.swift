let sr = db.prepare("INSERT INTO users (email, admin) VALUES (?, 1)")
let jr = db.prepare("INSERT INTO users (email, admin, manager_id) VALUES (?, 0, ?)")
