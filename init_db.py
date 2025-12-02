#!/usr/bin/env python3
"""
Database initialization script for Railway MySQL
Run this once to create all tables and import sample data
"""

import os
import pymysql
from dotenv import load_dotenv

load_dotenv()

def get_connection():
    """Create database connection"""
    return pymysql.connect(
        host=os.getenv('MYSQL_HOST', 'localhost'),
        user=os.getenv('MYSQL_USER', 'portal'),
        password=os.getenv('MYSQL_PASSWORD', '123456789'),
        database=os.getenv('MYSQL_DB', 'student_portal'),
        port=int(os.getenv('MYSQL_PORT', 3308)),
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

def init_database():
    """Initialize database with schema and sample data"""
    
    # Read SQL file
    sql_file_path = os.path.join(os.path.dirname(__file__), 'database', 'updated sql.sql')
    
    if not os.path.exists(sql_file_path):
        print(f"SQL file not found: {sql_file_path}")
        return False
    
    try:
        # Read the SQL file
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Connect to database
        conn = get_connection()
        cursor = conn.cursor()
        
        # Execute SQL statements
        # Split by semicolon and execute each statement
        statements = sql_content.split(';')
        
        executed = 0
        for statement in statements:
            statement = statement.strip()
            if statement and not statement.startswith('--') and not statement.startswith('/*'):
                try:
                    cursor.execute(statement)
                    executed += 1
                except Exception as e:
                    print(f"Error executing statement: {e}")
                    print(f"Statement: {statement[:100]}...")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✓ Database initialized successfully!")
        print(f"✓ Executed {executed} SQL statements")
        return True
        
    except Exception as e:
        print(f"✗ Error initializing database: {e}")
        return False

if __name__ == '__main__':
    print("Starting database initialization...")
    if init_database():
        print("\n✓ Database is ready!")
    else:
        print("\n✗ Database initialization failed")
