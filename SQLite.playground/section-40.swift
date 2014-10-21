// UPDATE users SET admin = 0 WHERE admin AND age IS NULL
agelessAdmins.update { $0.set(admin, false) }.changes
