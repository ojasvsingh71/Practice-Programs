from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/fare', methods=['POST'])
def fare():
    customer_name = request.form['customer_name']
    distance = request.form['distance']
    fare_per_km = request.form['fare_per_km']

    # Validation
    if customer_name == "" or distance == "" or fare_per_km == "":
        return "Error: All fields are required!"

    try:
        distance = float(distance)
        fare_per_km = float(fare_per_km)
    except:
        return "Error: Distance and Fare per KM must be numeric!"

    # Fare Calculation
    total_fare = distance * fare_per_km

    return render_template(
        'index.html',
        success=True,
        customer_name=customer_name,
        distance=distance,
        fare_per_km=fare_per_km,
        total_fare=round(total_fare, 2)
    )


if __name__ == '__main__':
    app.run(debug=True)