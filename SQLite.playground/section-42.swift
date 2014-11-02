// DELETE FROM users WHERE (email = 'alice@acme.com')
users.filter(email == "alice@acme.com").delete().changes
