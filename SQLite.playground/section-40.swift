// UPDATE users SET admin = 0 WHERE (admin AND age IS NULL)
agelessAdmins.update(admin <- false).changes
