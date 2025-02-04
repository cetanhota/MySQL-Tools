#!/home/wayne/weather-lab/bin/python3

import mysql.connector
from mysql.connector import Error
import json
import requests
import socket

servername = socket.gethostname()

def send_message():
    url = "https://api.callmebot.com/whatsapp.php"
    params = {
        'phone': '',
        'text': f'Replication is Down on {servername}',
        'apikey': ''}

    response = requests.post(url, params=params)
    if response.status_code == 200:
        print("Message sent successfully.")
    else:
        print("Failed to send message. Status code:", response.status_code)

# Opening JSON file
with open('/home/wayne/bin/.my.json') as f:
    # returns JSON object as a dictionary
    data = json.load(f)

hostname = str(data['hostname'])
username = str(data['username'])
password = str(data['password'])
database = str(data['database'])

try:
    # Establish the database connection
    connection = mysql.connector.connect(
        host=hostname,
        user=username,
        password=password,
        database=database
    )
    
    if connection.is_connected():
        print("Connected to MySQL Server")
        cursor = connection.cursor(dictionary=True)
        
        # Execute the SHOW SLAVE STATUS command
        cursor.execute("SHOW SLAVE STATUS")
        replication_status = cursor.fetchone()
        
        if replication_status:
            io_running = replication_status['Slave_IO_Running']
            sql_running = replication_status['Slave_SQL_Running']
            
            # Display key replication metrics
            print(f"Slave_IO_Running: {io_running}")
            print(f"Slave_SQL_Running: {sql_running}")
            print(f"Seconds_Behind_Master: {replication_status['Seconds_Behind_Master']}")
            
            if io_running == 'Yes' and sql_running == 'Yes':
                print("Replication is running smoothly.")
            else:
                print("Replication is facing issues. Check the replication logs and configuration.")
                send_message()
        else:
            print("This server is not a replica or replication status could not be determined.")
            send_message()
        cursor.close()

except Error as e:
    print(f"Error: {e}")

finally:
    if 'connection' in locals() and connection.is_connected():
        connection.close()
        print("MySQL connection closed.")
