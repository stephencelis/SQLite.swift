// UPDATE users SET admin = 0 WHERE admin = 1 AND age IS NULL
agelessAdmins.update(["admin": false]).changes
