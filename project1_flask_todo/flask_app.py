from flask import Flask, render_template, request
import psycopg2
import os

app = Flask(__name__)

# Get PostgreSQL connection details from environment variables

DB_HOST = os.environ.get('DB_HOST')
DB_PORT = os.environ.get('DB_PORT')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD
)

# Create a cursor object to interact with the database
cur = conn.cursor()

# Create a table to store the ToDo items
cur.execute('''
    CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        task TEXT NOT NULL,
        completed BOOLEAN DEFAULT FALSE
    )
''')
conn.commit()

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        task = request.form['task']
        cur.execute('INSERT INTO todos (task) VALUES (%s)', (task,))
        conn.commit()
    
    cur.execute('SELECT * FROM todos')
    todos = cur.fetchall()
    
    return render_template('templates/index.html', todos=todos)

if __name__ == '__main__':
    app.run(debug=True)