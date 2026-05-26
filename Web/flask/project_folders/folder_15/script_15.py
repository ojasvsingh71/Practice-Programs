from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/check', methods=['POST'])
def check():
    applicant_name = request.form['applicant_name']
    age = request.form['age']
    monthly_income = request.form['monthly_income']

    # Validation
    if applicant_name == "" or age == "" or monthly_income == "":
        return "Error: All fields are required!"

    try:
        age = int(age)
        monthly_income = float(monthly_income)
    except:
        return "Error: Age and Monthly Income must be numeric!"

    # Eligibility Check
    if age >= 18 and monthly_income >= 10000:
        status = "Approved for Bank Account"
    else:
        status = "Rejected for Bank Account"

    return render_template(
        'index.html',
        success=True,
        applicant_name=applicant_name,
        age=age,
        monthly_income=monthly_income,
        status=status
    )


if __name__ == '__main__':
    app.run(debug=True)