from flask import Flask, render_template, request, redirect, url_for, jsonify

app = Flask(__name__)

users = []

@app.route("/")
def home():
    return render_template("home.html", users=users)

@app.route("/form", methods=["GET", "POST"])
def form():
    error = None

    if request.method == "POST":
        name = request.form.get("name")
        age = request.form.get("age")

        if not name or not age:
            error = "All fields are required!"
        elif not age.isdigit():
            error = "Age must be a number!"
        else:
            users.append({"name": name, "age": int(age)})
            return redirect(url_for("home"))

    return render_template("form.html", error=error)

@app.route("/api/users", methods=["GET"])
def get_users():
    return jsonify(users)

@app.route("/api/users", methods=["POST"])
def add_user():
    data = request.get_json()

    if not data or "name" not in data or "age" not in data:
        return jsonify({"error": "Invalid data"}), 400

    users.append(data)
    return jsonify({"message": "User added", "user": data}), 201


if __name__ == "__main__":
    app.run(debug=True)