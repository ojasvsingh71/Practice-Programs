from flask import Flask, render_template, request

app = Flask(__name__)

# Sample Currency Rates
currency_rates = {
    "USD": 0.012,
    "EUR": 0.011,
    "GBP": 0.0095,
    "JPY": 1.75
}

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/convert', methods=['POST'])
def convert():
    user_name = request.form['user_name']
    amount_inr = request.form['amount_inr']
    currency_type = request.form['currency_type']

    # Validation
    if user_name == "" or amount_inr == "" or currency_type == "":
        return "Error: All fields are required!"

    try:
        amount_inr = float(amount_inr)
    except:
        return "Error: Amount must be numeric!"

    # Currency Conversion
    converted_amount = amount_inr * currency_rates[currency_type]

    return render_template(
        'index.html',
        success=True,
        user_name=user_name,
        amount_inr=amount_inr,
        currency_type=currency_type,
        converted_amount=round(converted_amount, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)