from flask import Flask, jsonify
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

# DB configuration
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "devops_db")
DB_USER = os.getenv("DB_USER", "devops_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "devops_password")


def get_db_connection():
    """Сreate a connection to DB"""

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Connection error to DB: {e}")
        return None


def init_db():
    """DB initialization"""

    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS visits (
                    id SERIAL PRIMARY KEY,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    message TEXT
                )
            """
            )
            conn.commit()
            cur.close()
            conn.close()
            print("DB initialized")
        except Exception as e:
            print(f"DB initialization error: {e}")


@app.route("/")
def hello():
    """Main page"""

    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO visits (message) VALUES (%s)",
                ("Hello from DevOps!",),
            )
            # Get visits count
            cur.execute("SELECT COUNT(*) FROM visits")
            visit_count = cur.fetchone()[0]
            conn.commit()
            cur.close()
            conn.close()

            return jsonify(
                {
                    "message": "Hello, DevOps!",
                    "status": "success",
                    "database": "connected",
                    "visit_count": visit_count,
                    "timestamp": datetime.now().isoformat(),
                }
            )
        except Exception as e:
            return (
                jsonify(
                    {
                        "message": "Hello, DevOps!",
                        "status": "error",
                        "database": "error",
                        "error": str(e),
                        "timestamp": datetime.now().isoformat(),
                    }
                ),
                500,
            )
    else:
        return jsonify(
            {
                "message": "Hello, DevOps!",
                "status": "warning",
                "database": "disconnected",
                "timestamp": datetime.now().isoformat(),
            }
        )


@app.route("/health")
def health():
    """App status checking"""

    conn = get_db_connection()
    db_status = "connected" if conn else "disconnected"
    if conn:
        conn.close()

    return jsonify(
        {
            "status": "healthy",
            "database": db_status,
            "timestamp": datetime.now().isoformat(),
        }
    )


@app.route("/stats")
def stats():
    """Statistic of visits"""

    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM visits")
            total_visits = cur.fetchone()[0]

            cur.execute(
                """
                SELECT DATE(timestamp) as visit_date, COUNT(*) as daily_visits 
                FROM visits 
                GROUP BY DATE(timestamp) 
                ORDER BY visit_date DESC 
                LIMIT 7
            """
            )
            daily_stats = cur.fetchall()

            cur.close()
            conn.close()

            return jsonify(
                {
                    "total_visits": total_visits,
                    "daily_stats": [
                        {"date": str(row[0]), "visits": row[1]}
                        for row in daily_stats
                    ],
                    "timestamp": datetime.now().isoformat(),
                }
            )
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    else:
        return jsonify({"error": "Database not available"}), 500


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=True)
