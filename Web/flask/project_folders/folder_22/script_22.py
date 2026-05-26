from flask import Flask, render_template, request

app = Flask(__name__)

TAX_PERCENTAGE = 5  # 5% Restaurant Tax

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/bill', methods=['POST'])
def bill():
    customer_name = request.form['customer_name']
    food_item = request.form['food_item']
    quantity = request.form['quantity']
    price = request.form['price']

    # Validation
    if customer_name == "" or food_item == "" or quantity == "" or price == "":
        return "Error: All fields are required!"

    try:
        quantity = int(quantity)
        price = float(price)
    except:
        return "Error: Quantity and Price must be numeric!"

    # Bill Calculation
    subtotal = quantity * price
    tax_amount = (subtotal * TAX_PERCENTAGE) / 100
    total_bill = subtotal + tax_amount

    return render_template(
        'index.html',
        success=True,
        customer_name=customer_name,
        food_item=food_item,
        quantity=quantity,
        price=price,
        subtotal=round(subtotal, 2),
        tax_amount=round(tax_amount, 2),
        total_bill=round(total_bill, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)