import os
import pymysql

# Database connection parameters
host = 'db-dev.1stype.io'  # Replace with your database host
port = 3306  # Replace with your database port
user = 'admin'  # Replace with your database username
password = 'tkffudigksek1!'  # Replace with your database password
database = 'firsttype'  # Replace with your database name

# Connect to the MySQL database
connection = pymysql.connect(host=host, port=port, user=user, password=password, database=database)

# Base path and season ID
base_path = '/Users/charlie.hyun/Documents/퍼스트타입/novel/special_forces_female_prison_text_chunks/'
season_id = 7

try:
    with connection.cursor() as cursor:
        # Insert each episode
        for i in range(1, 43):
            episode_id = str(i)
            title = f'제국군 특별 여자 수용소 ({i})'
            file_path = os.path.join(base_path, f'special_forces_female_prison_chunk_{i}.txt')

            with open(file_path, 'r') as file:
                contents = file.read()

            sql = "INSERT INTO episode (episodeId, title, seasonId, contents) VALUES (%s, %s, %s, %s)"
            cursor.execute(sql, (episode_id, title, season_id, contents))

    # Commit the transaction
    connection.commit()
finally:
    # Close the connection
    connection.close()

