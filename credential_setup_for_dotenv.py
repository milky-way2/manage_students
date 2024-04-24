def main() -> None:
	MYSQL_HOST: str = input("Enter Mysql Host : ").strip()
	MYSQL_USER: str = input("Enter Mysql User name : ").strip()
	MYSQL_PASSWORD: str = input(f"Enter Mysql password of {MYSQL_USER} : ").strip()
	with open(".env", "a") as env:
		env.write(f"MYSQL_HOST={MYSQL_HOST}\n")
		env.write(f"MYSQL_USER={MYSQL_USER}\n")
		env.write(f"MYSQL_PASSWORD={MYSQL_PASSWORD}\n")


if __name__ == "__main__":
	main()

