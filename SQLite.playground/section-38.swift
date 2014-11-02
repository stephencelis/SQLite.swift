let agelessAdmins = admins.filter(age == nil)

// SELECT count(*) FROM users WHERE (admin AND age IS NULL)
agelessAdmins.count
