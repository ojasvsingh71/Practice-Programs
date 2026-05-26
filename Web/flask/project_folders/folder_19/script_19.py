from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/recharge', methods=['POST'])
def recharge():
    mobile_number = request.form['mobile_number']
    recharge_amount = request.form['recharge_amount']
    operator_name = request.form['operator_name']

    # Validation
    if mobile_number == "" or recharge_amount == "" or operator_name == "":
        return "Error: All fields are required!"

    if not mobile_number.isdigit() or len(mobile_number) != 10:
        return "Error: Mobile number must contain exactly 10 digits!"

    try:
        recharge_amount = float(recharge_amount)
    except:
        return "Error: Recharge amount must be numeric!"

    return render_template(
        'index.html',
        success=True,
        mobile_number=mobile_number,
        recharge_amount=recharge_amount,
        operator_name=operator_name
    )


if __name__ == '__main__':
    app.run(debug=True)