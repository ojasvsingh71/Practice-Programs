from flask import Flask, render_template, request

app = Flask(__name__)

GST_RATE = 18  # 18% GST

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/invoice', methods=['POST'])
def invoice():
    product_name = request.form['product_name']
    quantity = request.form['quantity']
    price_per_item = request.form['price_per_item']

    # Validation
    if product_name == "" or quantity == "" or price_per_item == "":
        return "Error: All fields are required!"

    try:
        quantity = int(quantity)
        price_per_item = float(price_per_item)
    except:
        return "Error: Quantity and Price must be numeric!"

    # Bill Calculation
    subtotal = quantity * price_per_item
    gst_amount = subtotal * GST_RATE / 100
    total_amount = subtotal + gst_amount

    return render_template(
        'index.html',
        success=True,
        product_name=product_name,
        quantity=quantity,
        price_per_item=price_per_item,
        subtotal=round(subtotal, 2),
        gst_amount=round(gst_amount, 2),
        total_amount=round(total_amount, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)