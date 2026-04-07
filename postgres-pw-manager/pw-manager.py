from flask import Flask, request, jsonify
import sqlite3
import bcrypt
import secrets
import os
from contextlib import closing
from pg-utils import setup_postgres_user

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
                shard_token TEXT NOT NULL
            )
        ''')
        conn.commit()

def get_user(username):
    with closing(sqlite3.connect(DB_PATH)) as conn:
        cursor = conn.execute(
            'SELECT key_hash, shard_token FROM users WHERE username = ?',
            (username,)
        )
        return cursor.fetchone()

def add_user(username, key):
    key_hash = bcrypt.hashpw(key.encode(), bcrypt.gensalt())
    shard_token = secrets.token_urlsafe(32)

    setup_postgres_user(
        pg_host=os.getenv('PG_HOST'),
        pg_port=os.getenv('PG_PORT'),
        pg_admin_user=os.getenv('PG_ADMIN_USER'),
        pg_admin_password=os.getenv('PG_ADMIN_PASSWORD'),
        user_db=f'{username}_db',
        user_name=username,
        user_password=shard_token
    )
    
    with closing(sqlite3.connect(DB_PATH)) as conn:
        conn.execute(
            'INSERT INTO users (username, key_hash, shard_token) VALUES (?, ?, ?)',
            (username, key_hash, shard_token)
        )
        conn.commit()
    
    return shard_token

def format_postgres_uri(username, password):
    POSTGRES_URI="postgresql://{}:{}@{}:${}/{}".format(
        username, password,
        os.getenv("PG_HOST"), os.getenv("PG_PORT"),
        f'{username}_db')

@app.route('/authenticate', methods=['POST'])
def authenticate():
    data = request.get_json()
    username = data.get('username')
    key = data.get('key')
    
    if not username or not key:
        return 'Missing username or key', 400
    
    user = get_user(username)
    
    if user is None:
        shard_token = add_user(username, key)
        return format_postgres_uri(username, shard_token), 201
    
    key_hash, shard_token = user
    
    if bcrypt.checkpw(key.encode(), key_hash):
        return format_postgres_uri(username, shard_token), 200
    else:
        return 'Authentication failed', 401

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)