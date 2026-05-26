from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/weather', methods=['POST'])
def weather():
    city_name = request.form['city_name']
    celsius = request.form['celsius']

    # Validation
    if city_name == "" or celsius == "":
        return "Error: All fields are required!"

    try:
        celsius = float(celsius)
    except:
        return "Error: Temperature must be numeric!"

    # Celsius to Fahrenheit Conversion
    fahrenheit = (celsius * 9/5) + 32

    # Weather Report
    if celsius >= 35:
        weather_report = "Very Hot Weather"
    elif celsius >= 25:
        weather_report = "Warm Weather"
    elif celsius >= 15:
        weather_report = "Pleasant Weather"
    else:
        weather_report = "Cold Weather"

    return render_template(
        'index.html',
        success=True,
        city_name=city_name,
        celsius=round(celsius, 2),
        fahrenheit=round(fahrenheit, 2),
        weather_report=weather_report
    )


if __name__ == '__main__':
    app.run(debug=True)