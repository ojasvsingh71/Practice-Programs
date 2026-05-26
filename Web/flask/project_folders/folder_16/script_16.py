from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/gst', methods=['POST'])
def gst():
    product_name = request.form['product_name']
    product_price = request.form['product_price']
    gst_percentage = request.form['gst_percentage']

    # Validation
    if product_name == "" or product_price == "" or gst_percentage == "":
        return "Error: All fields are required!"

    try:
        product_price = float(product_price)
        gst_percentage = float(gst_percentage)
    except:
        return "Error: Product Price and GST Percentage must be numeric!"

    # GST Calculation
    gst_amount = (product_price * gst_percentage) / 100
    final_price = product_price + gst_amount

    return render_template(
        'index.html',
        success=True,
        product_name=product_name,
        product_price=product_price,
        gst_percentage=gst_percentage,
        gst_amount=round(gst_amount, 2),
        final_price=round(final_price, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)