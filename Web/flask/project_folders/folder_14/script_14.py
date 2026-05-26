from flask import Flask, render_template, request
import re

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/check', methods=['POST'])
def check():
    username = request.form['username']
    password = request.form['password']

    # Validation
    if username == "" or password == "":
        return "Error: All fields are required!"

    # Password Checks
    has_upper = re.search(r'[A-Z]', password)
    has_lower = re.search(r'[a-z]', password)
    has_number = re.search(r'[0-9]', password)
    has_special = re.search(r'[@#$%^&*!]', password)

    # Strength Logic
    if has_upper and has_lower and has_number and has_special:

        if len(password) >= 10:
            strength = "Strong Password"
        elif len(password) >= 8:
            strength = "Medium Password"
        else:
            strength = "Weak Password"

    else:
        return """
        Error: Password must contain:
        <br>• Uppercase Letter
        <br>• Lowercase Letter
        <br>• Number
        <br>• Special Character
        """

    return render_template(
        'index.html',
        success=True,
        username=username,
        password=password,
        strength=strength
    )


if __name__ == '__main__':
    app.run(debug=True)