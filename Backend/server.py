import os

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import database
app = Flask(__name__)
CORS(app)  # Allow all origins to make requests

UPLOAD_FOLDER = os.path.expanduser("~/flaskUploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # Ensure folder exists


@app.route("/api/signup", methods=["POST"])
def signup():
    data = request.json
    username = data.get("username")
    password = data.get("password")

    conn = database.get_db_connection()
    cursor = conn.cursor()

    # Check if user already exists
    cursor.execute("SELECT * FROM users WHERE username = %s;", (username,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"message": "User already exists!"}), 400

    # Insert new user
    cursor.execute("INSERT INTO users (username, password) VALUES (%s, %s);", (username, password))
    conn.commit()
    conn.close()

    return jsonify({"message": "Signup successful!"}), 201


@app.route("/api/login", methods=["POST"])
def login():
    data = request.json
    username = data.get("username")
    password = data.get("password")

    conn = database.get_db_connection()
    cursor = conn.cursor()

    # Validate user credentials
    cursor.execute("SELECT * FROM users WHERE username = %s AND password = %s;", (username, password))
    user = cursor.fetchone()
    conn.close()
    if user:
        return jsonify({"message": "Login successful!"}), 200
    else:
        return jsonify({"message": "Invalid credentials!"}), 401


@app.route("/api/getFileMetaData", methods=["POST"])
def get_file_metadata():
    data = request.json
    username = data.get("username")

    if not username:
        return jsonify({"error": "Username is required"}), 400

    try:
        conn = database.get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT filename FROM files WHERE username = %s;", (username,))
        files = [row[0] for row in cursor.fetchall()]  # Extract filenames

        conn.close()
        return jsonify({"files": files}), 200
    except Exception as e:
        print(f"Error fetching file metadata: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/api/uploadFile", methods=["POST"])
def upload_file():
    username = request.form.get("username")
    filename = request.form.get("filename")
    filetype = request.form.get("filetype")
    filesize = request.form.get("filesize")
    file = request.files.get("file")

    if not all([username, filename, filetype, filesize, file]):
        return jsonify({"message": "Missing file metadata"}), 400

    # Create user-specific folder
    user_folder = os.path.join(UPLOAD_FOLDER, username)
    os.makedirs(user_folder, exist_ok=True)  # Ensures folder exists

    file_path = os.path.join(user_folder, filename)
    file.save(file_path)  # Save file inside user's folder

    try:
        conn = database.get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO files (username, filename, filetype, filesize)
            VALUES (%s, %s, %s, %s);
        """, (username, filename, filetype, int(filesize)))  # Store file path in DB

        conn.commit()
        conn.close()

        return jsonify({"message": "File uploaded successfully!"}), 200
    except Exception as e:
        print(f"Database error: {e}")
        return jsonify({"message": "Internal server error"}), 500


@app.route("/api/deleteFile", methods=["DELETE"])
def delete_file():
    data = request.json
    username = data.get("username")
    filename = data.get("filename")

    if not username or not filename:
        return jsonify({"message": "Missing username or filename"}), 400

    # Define user-specific file path
    user_folder = os.path.join(UPLOAD_FOLDER, username)
    file_path = os.path.join(user_folder, filename)

    try:
        # Delete file from disk
        if os.path.exists(file_path):
            os.remove(file_path)  

        # Remove entry from database
        conn = database.get_db_connection()
        cursor = conn.cursor()

        cursor.execute("DELETE FROM files WHERE username = %s AND filename = %s", (username, filename))
        conn.commit()
        conn.close()

        return jsonify({"message": "File deleted successfully!"}), 200
    except Exception as e:
        print(f"Error deleting file: {e}")
        return jsonify({"message": "Internal server error"}), 500

@app.route("/api/getFile", methods=["GET"])
def getFile():
    username = request.args.get("username")  # Fetch user parameter
    filename = request.args.get("filename")
    print(request.args)
    if not username or not filename:
        return jsonify({"message": "Missing username or filename"}), 400

    file_path = os.path.join(UPLOAD_FOLDER, username, filename)
    print(file_path)
    if os.path.exists(file_path):
        file_url = f"http://127.0.0.1:5002/flaskUploads/{username}/{filename}"
        print(file_url)
        return jsonify({"file_url": file_url}), 200  # Return the file URL
    else:
        return jsonify({"message": "File not found"}), 404


#  Serve static files from ~/flaskUploads
@app.route('/flaskUploads/<username>/<filename>')
def serve_static_file(username, filename):
    file_path = os.path.join(UPLOAD_FOLDER, username, filename)
    if os.path.exists(file_path):
        return send_file(file_path)  
    else:
        return "File not found", 404
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5002)
