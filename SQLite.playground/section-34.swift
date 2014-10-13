let ordered = admins.order("email", "age").limit(3)

// SELECT * FROM users WHERE admin = 1 ORDER BY email ASC, age ASC LIMIT 3
for admin in ordered {
    println(admin)
}
