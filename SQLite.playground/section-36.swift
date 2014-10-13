let agelessAdmins = admins.filter(["age": nil])

// SELECT count(*) FROM users WHERE admin = 1 AND age IS NULL
agelessAdmins.count
