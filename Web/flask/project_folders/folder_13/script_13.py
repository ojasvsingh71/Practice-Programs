from flask import Flask, render_template, request
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/compare', methods=['POST'])
def compare():
    dob1 = request.form['dob1']
    dob2 = request.form['dob2']

    # Validation
    if dob1 == "" or dob2 == "":
        return "Error: Both Date of Birth fields are required!"

    # Convert string to date
    date1 = datetime.strptime(dob1, "%Y-%m-%d")
    date2 = datetime.strptime(dob2, "%Y-%m-%d")

    # Calculate Difference
    difference = abs((date1 - date2).days)

    years = difference // 365
    months = (difference % 365) // 30
    days = (difference % 365) % 30

    return render_template(
        'index.html',
        success=True,
        dob1=dob1,
        dob2=dob2,
        years=years,
        months=months,
        days=days
    )


if __name__ == '__main__':
    app.run(debug=True)