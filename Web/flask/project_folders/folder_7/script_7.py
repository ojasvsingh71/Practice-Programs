from flask import Flask, render_template, request
import math

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/emi', methods=['POST'])
def emi():
    applicant_name = request.form['applicant_name']
    loan_amount = request.form['loan_amount']
    interest_rate = request.form['interest_rate']
    loan_duration = request.form['loan_duration']

    # Validation
    if applicant_name == "" or loan_amount == "" or interest_rate == "" or loan_duration == "":
        return "Error: All fields are required!"

    try:
        loan_amount = float(loan_amount)
        interest_rate = float(interest_rate)
        loan_duration = int(loan_duration)
    except:
        return "Error: Loan Amount, Interest Rate, and Duration must be numeric!"

    # EMI Calculation
    monthly_rate = interest_rate / (12 * 100)
    months = loan_duration * 12

    emi_amount = (
        loan_amount * monthly_rate * math.pow(1 + monthly_rate, months)
    ) / (
        math.pow(1 + monthly_rate, months) - 1
    )

    total_payment = emi_amount * months
    total_interest = total_payment - loan_amount

    return render_template(
        'index.html',
        success=True,
        applicant_name=applicant_name,
        loan_amount=round(loan_amount, 2),
        interest_rate=interest_rate,
        loan_duration=loan_duration,
        emi_amount=round(emi_amount, 2),
        total_payment=round(total_payment, 2),
        total_interest=round(total_interest, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)