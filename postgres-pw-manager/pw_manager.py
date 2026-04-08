from flask import Flask, request, jsonify
import sqlite3
import bcrypt
import secrets
import os
from contextlib import closing
from pg_utils import setup_postgres_user

# The following environment variables must be set:
# PG_HOST
# PG_PORT
# PG_ADMIN_USER 
# PG_ADMIN_PASSWORD

# JSON data must be sent to /authenticate with the following attributes:
# username
# key

app = Flask(__name__)
DB_PATH = 'users.db'

def init_db():
    with closing(sqlite3.connect(DB_PATH)) as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                key_hash BLOB NOT NULL,
                token TEXT NOT NULL
            )
        ''')
        conn.commit()

@app.route('/initialize', methods=['POST'])
def initialize():
    username = f"user_{secrets.token_hex(8)}"
    token = secrets.token_urlsafe(32)
    key_hash = bcrypt.hashpw(token.encode(), bcrypt.gensalt())
    
    postgres_uri = setup_postgres_user(pg_host=os.getenv('PG_HOST'), 
                                       pg_port=os.getenv('PG_PORT', 5432),
                                       pg_admin_user=os.getenv('PG_ADMIN_USER'),
                                       pg_admin_password=os.getenv('PG_ADMIN_PASSWORD'),
                                       user_name=username,
                                       user_dbname=f'{username}_db',
                                       user_password=token)
    
    with closing(sqlite3.connect(DB_PATH)) as conn:
        conn.execute(
            'INSERT INTO users (username, key_hash, token) VALUES (?, ?, ?)',
            (username, key_hash, token)
        )
        conn.commit()
    
    return f"{username}\n{token}\n{postgres_uri}", 201

@app.route('/authenticate', methods=['POST'])
def authenticate():
    username = request.headers.get('X-Username')
    token = request.headers.get('X-Token')
    
    if not username or not token:
        return 'Missing credentials', 401
    
    with closing(sqlite3.connect(DB_PATH)) as conn:
        cursor = conn.execute(
            'SELECT key_hash FROM users WHERE username = ?',
            (username,)
        )
        result = cursor.fetchone()
    
    if result is None or not bcrypt.checkpw(token.encode(), result[0]):
        return 'Authentication failed', 401
    
    db_name = f"{username}_db"
    pg_host = os.getenv('PG_HOST')
    pg_port = os.getenv('PG_PORT', '5432')
    
    return f"postgresql://{username}:{token}@{pg_host}:{pg_port}/{db_name}", 200

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)