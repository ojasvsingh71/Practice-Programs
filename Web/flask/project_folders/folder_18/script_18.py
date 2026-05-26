from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/fuel', methods=['POST'])
def fuel():
    distance = request.form['distance']
    mileage = request.form['mileage']
    fuel_price = request.form['fuel_price']

    # Validation
    if distance == "" or mileage == "" or fuel_price == "":
        return "Error: All fields are required!"

    try:
        distance = float(distance)
        mileage = float(mileage)
        fuel_price = float(fuel_price)
    except:
        return "Error: Distance, Mileage, and Fuel Price must be numeric!"

    if mileage <= 0:
        return "Error: Mileage must be greater than 0!"

    # Fuel Calculation
    fuel_required = distance / mileage
    total_cost = fuel_required * fuel_price

    return render_template(
        'index.html',
        success=True,
        distance=distance,
        mileage=mileage,
        fuel_price=fuel_price,
        fuel_required=round(fuel_required, 2),
        total_cost=round(total_cost, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)