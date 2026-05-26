from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/check', methods=['POST'])
def check():
    name = request.form['name']
    age = request.form['age']
    aadhaar = request.form['aadhaar']

    # Validation
    if name == "" or age == "" or aadhaar == "":
        return "Error: All fields are required!"

    if not age.isdigit():
        return "Error: Age must be numeric!"

    if not aadhaar.isdigit() or len(aadhaar) != 12:
        return "Error: Aadhaar number must contain exactly 12 digits!"

    age = int(age)

    # Eligibility Check
    if age >= 18:
        status = "Eligible for Voting"
    else:
        status = "Not Eligible for Voting"

    return render_template(
        'index.html',
        success=True,
        name=name,
        age=age,
        aadhaar=aadhaar,
        status=status
    )


if __name__ == '__main__':
    app.run(debug=True)