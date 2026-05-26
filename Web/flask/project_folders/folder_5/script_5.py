from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/bill', methods=['POST'])
def bill():
    customer_name = request.form['customer_name']
    consumer_id = request.form['consumer_id']
    units = request.form['units']

    # Validation
    if customer_name == "" or consumer_id == "" or units == "":
        return "Error: All fields are required!"

    try:
        units = float(units)
    except:
        return "Error: Units consumed must be numeric!"

    # Electricity Bill Calculation
    if units <= 100:
        amount = units * 5
    elif units <= 300:
        amount = (100 * 5) + ((units - 100) * 7)
    else:
        amount = (100 * 5) + (200 * 7) + ((units - 300) * 10)

    return render_template(
        'index.html',
        success=True,
        customer_name=customer_name,
        consumer_id=consumer_id,
        units=units,
        amount=amount
    )


if __name__ == '__main__':
    app.run(debug=True)