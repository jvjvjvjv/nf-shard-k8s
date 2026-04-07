import psycopg2
from psycopg2 import sql

def setup_postgres_user(pg_host, pg_port, pg_admin_user, pg_admin_password, user_name, user_dbname, user_password):
    def execute_sql(database, query):
        conn = psycopg2.connect(
            host=pg_host,
            port=pg_port,
            user=pg_admin_user,
            password=pg_admin_password,
            database=database
        )
        conn.autocommit = True
        try:
            with conn.cursor() as cur:
                cur.execute(query)
        finally:
            conn.close()
    
    execute_sql('postgres', sql.SQL("CREATE ROLE {} WITH LOGIN PASSWORD %s").format(
        sql.Identifier(temp_user)
    ), (temp_password,))
    
    execute_sql('postgres', sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
        sql.Identifier(user_db), sql.Identifier(temp_user)
    ))
    execute_sql('postgres', sql.SQL("GRANT TEMPORARY ON DATABASE {} TO {}").format(
        sql.Identifier(user_db), sql.Identifier(temp_user)
    ))
    execute_sql('postgres', sql.SQL("GRANT CREATE ON DATABASE {} TO {}").format(
        sql.Identifier(user_db), sql.Identifier(temp_user)
    ))
    
    execute_sql(user_db, sql.SQL("GRANT ALL PRIVILEGES ON SCHEMA public TO {}").format(
        sql.Identifier(temp_user)
    ))
    execute_sql(user_db, sql.SQL("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {}").format(
        sql.Identifier(temp_user)
    ))
    execute_sql(user_db, sql.SQL("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {}").format(
        sql.Identifier(temp_user)
    ))
    execute_sql(user_db, sql.SQL("GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO {}").format(
        sql.Identifier(temp_user)
    ))
    
    execute_sql(user_db, sql.SQL("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO {}").format(
        sql.Identifier(temp_user)
    ))
    execute_sql(user_db, sql.SQL("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO {}").format(
        sql.Identifier(temp_user)
    ))
    execute_sql(user_db, sql.SQL("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO {}").format(
        sql.Identifier(temp_user)
    ))
    
    execute_sql('postgres', sql.SQL("REVOKE CONNECT ON DATABASE postgres FROM {}").format(
        sql.Identifier(temp_user)
    ))
