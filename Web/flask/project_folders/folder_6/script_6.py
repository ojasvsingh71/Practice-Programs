from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/calculate', methods=['POST'])
def calculate():
    customer_name = request.form['customer_name']
    principal = request.form['principal']
    rate = request.form['rate']
    time = request.form['time']

    # Validation
    if customer_name == "" or principal == "" or rate == "" or time == "":
        return "Error: All fields are required!"

    try:
        principal = float(principal)
        rate = float(rate)
        time = float(time)
    except:
        return "Error: Principal Amount, Rate, and Time must be numeric!"

    # Simple Interest Formula
    simple_interest = (principal * rate * time) / 100

    # Final Amount
    final_amount = principal + simple_interest

    return render_template(
        'index.html',
        success=True,
        customer_name=customer_name,
        principal=principal,
        rate=rate,
        time=time,
        simple_interest=simple_interest,
        final_amount=final_amount
    )


if __name__ == '__main__':
    app.run(debug=True)