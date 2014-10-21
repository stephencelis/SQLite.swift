users.insert { u in
    u.set(email, "giles@acme.com")
    u.set(age, 42)
    u.set(admin, true)
}.ID

users.insert { $0.set(email, "haley@acme.com"); $0.set(age, 30) }.ID
users.insert { $0.set(email, "inigo@acme.com"); $0.set(age, 24) }.ID
