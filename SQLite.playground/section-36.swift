let ordered = admins.order(email.asc, age.asc).limit(3)

// SELECT * FROM users WHERE admin ORDER BY email ASC, age ASC LIMIT 3
for admin in ordered {
    println(admin[id])
    println(admin[age])
}
