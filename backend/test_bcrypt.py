import bcrypt
plain = b"Admin@123"
hash = b"$2b$12$2szcYzN3xlpm5dRxVj5wwOGit7nYqx7MHaJb7q.1eeYHiFqb1XbrG"
try:
    print(f"Match: {bcrypt.checkpw(plain, hash)}")
except Exception as e:
    print(f"Error: {e}")
